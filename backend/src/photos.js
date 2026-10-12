import { createHash, randomUUID } from 'node:crypto';
import { ApiError, requireValue, id } from './security.js';

const config = () => ({ cloud: process.env.CLOUDINARY_CLOUD_NAME || 'dzbvceezc', key: process.env.CLOUDINARY_API_KEY, secret: process.env.CLOUDINARY_API_SECRET });
export function signature(params, secret) {
  const canonical = Object.keys(params).sort().map(k => `${k}=${params[k]}`).join('&');
  return createHash('sha1').update(canonical + secret).digest('hex');
}
export async function photoUpload(service, user, body) {
  const gymId = id(body.gymId), memberId = id(body.memberId);
  await service.operational(service.store, user, gymId);
  service.requirePermission(user,'members');
  requireValue(await service.store.get(`gyms/${gymId}/members/${memberId}`), 'العضو غير موجود', 404);
  const c = config();
  requireValue(/^[a-zA-Z0-9_-]+$/.test(c.cloud), 'إعداد الصور غير صحيح', 503);
  if (c.key && c.secret) {
    const fields = { public_id: `gym_manager/${gymId}/members/${memberId}`, timestamp: String(Math.floor(Date.now()/1000)), overwrite: 'true', transformation: 'c_limit,h_1024,w_1024/q_auto:good' };
    return { cloudName:c.cloud, fields:{...fields, api_key:c.key, signature:signature(fields,c.secret)}, signed:true };
  }
  // Preserve existing installations while private server credentials are configured.
  return { cloudName:c.cloud, signed:false, fields:{upload_preset:process.env.GYM_CLOUDINARY_UPLOAD_PRESET || 'Workshop', public_id:`gym_manager/${gymId}/members/${memberId}-${randomUUID()}`} };
}
export async function photoDelete(service, user, body) {
  const gymId=id(body.gymId), memberId=id(body.memberId), c=config();
  await service.operational(service.store,user,gymId,['admin']);
  const member=await service.store.get(`gyms/${gymId}/members/${memberId}`);
  requireValue(member,'العضو غير موجود',404);
  requireValue(c.key && c.secret,'حذف الصورة من التخزين يحتاج إعداد مفاتيح Cloudinary على السيرفر',503);
  const url=member.data.photoUrl;
  if (url) {
    const parsed=new URL(url), prefix=`/${c.cloud}/image/upload/`;
    requireValue(parsed.hostname==='res.cloudinary.com' && parsed.pathname.startsWith(prefix),'الصورة مش تابعة لتخزين الجيم');
    const image=parsed.pathname.slice(prefix.length).replace(/^v\d+\//,'').replace(/\.[^.\/]+$/,'');
    requireValue(image.startsWith(`gym_manager/${gymId}/members/${memberId}`),'مسار الصورة غير مسموح');
    const fields={public_id:image,timestamp:String(Math.floor(Date.now()/1000)),invalidate:'true'};
    let response;
    try { response=await fetch(`https://api.cloudinary.com/v1_1/${c.cloud}/image/destroy`,{method:'POST',body:new URLSearchParams({...fields,api_key:c.key,signature:signature(fields,c.secret)}),signal:AbortSignal.timeout(20000)}); }
    catch { throw new ApiError(502,'تعذر الاتصال بتخزين الصور؛ حاول تاني'); }
    const result=await response.json();
    requireValue(response.ok && ['ok','not found'].includes(result.result),'فشل حذف الصورة من التخزين',502);
  }
  await service.store.transaction(async tx=>{
    const current=await tx.get(member.path);
    requireValue(current?.data.photoUrl===url,'الصورة اتغيّرت، حدّث الصفحة وحاول تاني',409);
    await tx.put(member.path,{...current.data,photoUrl:null});
    await service.audit(tx,user,gymId,'member-photo-delete',{memberId});
  });
  return {deleted:true};
}
