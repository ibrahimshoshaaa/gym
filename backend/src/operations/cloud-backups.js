import {createCipheriv,createDecipheriv,randomBytes} from 'node:crypto';
import {v2 as cloudinary} from 'cloudinary';
import {snapshot} from '../backup.js';
import {requireValue,stamp,id} from '../security.js';
export function encryptBackup(data,key){
 const material=Buffer.from(key,'base64');requireValue(material.length===32,'مفتاح النسخ الاحتياطي غير صحيح',503);
 const nonce=randomBytes(12),cipher=createCipheriv('aes-256-gcm',material,nonce);
 const payload=Buffer.concat([cipher.update(JSON.stringify(data),'utf8'),cipher.final()]);
 return Buffer.from(JSON.stringify({format:'golden-gym-encrypted-v1',nonce:nonce.toString('base64'),tag:cipher.getAuthTag().toString('base64'),payload:payload.toString('base64')}));
}
export function decryptBackup(bytes,key){
 const envelope=JSON.parse(bytes.toString());requireValue(envelope.format==='golden-gym-encrypted-v1','صيغة الملف غير صحيحة');
 const decipher=createDecipheriv('aes-256-gcm',Buffer.from(key,'base64'),Buffer.from(envelope.nonce,'base64'));decipher.setAuthTag(Buffer.from(envelope.tag,'base64'));
 return JSON.parse(Buffer.concat([decipher.update(Buffer.from(envelope.payload,'base64')),decipher.final()]).toString());
}
function configuredCloud(){
 const cloud_name=process.env.CLOUDINARY_CLOUD_NAME,api_key=process.env.CLOUDINARY_API_KEY,api_secret=process.env.CLOUDINARY_API_SECRET;
 requireValue(cloud_name&&api_key&&api_secret,'إعداد تخزين النسخ الاحتياطي ناقص',503);
 cloudinary.config({cloud_name,api_key,api_secret,secure:true});return cloudinary;
}
export async function createCloudBackup(service,{cloud:injectedCloud,key=process.env.BACKUP_ENCRYPTION_KEY,now=new Date()}={}){
 requireValue(key,'مفتاح تشفير النسخ الاحتياطي ناقص',503);
 const cloud=injectedCloud??configuredCloud(),day=now.toISOString().slice(0,10),path=`system/backups/${day}`;
 const previous=await service.store.transaction(async tx=>{
  const previous=await tx.get(path);requireValue(!(previous?.data.state==='uploading' && Date.now()-new Date(previous.data.date.value)<180000),'النسخ الاحتياطي شغال بالفعل',409);
  await tx.put(path,{state:'uploading',date:stamp()});return previous?.data;
 });
 try{
  const data=await snapshot(service.store),bytes=encryptBackup(data,key);
  requireValue(bytes.length<=30*1024*1024,'النسخة تجاوزت حد الحفظ الحالي، راجع حجم قاعدة البيانات',503);
  const publicId=`golden_gym_backups/${day}.ggbackup`;
  const uploaded=await new Promise((resolve,reject)=>{const stream=cloud.uploader.upload_stream({resource_type:'raw',type:'authenticated',public_id:publicId,overwrite:true},(error,value)=>error?reject(error):resolve(value));stream.end(bytes);});
  const metadata={state:'ready',date:stamp(),publicId:uploaded.public_id,bytes:uploaded.bytes,records:data.documents.length};
  await service.store.put(path,metadata);
  const all=(await service.store.select('system/backups',[],{field:'date',descending:true})).filter(r=>r.data.state==='ready');
  for(const old of all.slice(14))if(old.data.state==='ready' && old.data.publicId?.startsWith('golden_gym_backups/')){
   try{const removed=await cloud.uploader.destroy(old.data.publicId,{resource_type:'raw',type:'authenticated',invalidate:true});if(['ok','not found'].includes(removed.result))await service.store.remove(old.path);}catch{/* Retention is retried at the next backup; a valid new backup stays ready. */}
  }
  return {id:day,...metadata};
 }catch(error){await service.store.put(path,previous?.state==='ready'?{...previous,lastAttemptFailedAt:stamp()}:{state:'failed',date:stamp()});throw error;}
}
export async function listBackups(service,user){requireValue(user.role==='superAdmin','غير مسموح',403);return (await service.store.select('system/backups',[],{field:'date',descending:true},20)).map(r=>({id:r.path.split('/').at(-1),...r.data}));}
export async function backupDownload(service,user,body){
 requireValue(user.role==='superAdmin','غير مسموح',403);const row=await service.store.get(`system/backups/${id(body.id)}`);requireValue(row?.data.state==='ready','النسخة غير جاهزة',404);
 return {url:configuredCloud().utils.private_download_url(row.data.publicId,'',{resource_type:'raw',type:'authenticated',expires_at:Math.floor(Date.now()/1000)+120,attachment:true})};
}
