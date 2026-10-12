import {randomUUID} from 'node:crypto';
import {requireValue,id,text,date,stamp,integer} from '../security.js';
function wallTime(value){const values=Object.fromEntries(new Intl.DateTimeFormat('en-GB',{timeZone:'Africa/Cairo',year:'numeric',month:'2-digit',day:'2-digit',hour:'2-digit',minute:'2-digit',second:'2-digit',hourCycle:'h23'}).formatToParts(value).filter(p=>p.type!=='literal').map(p=>[p.type,Number(p.value)]));return Date.UTC(values.year,values.month-1,values.day,values.hour,values.minute,values.second);}
export function addCairoWeeks(value,weeks){const wall=wallTime(value)+weeks*7*86400000;let candidate=wall;for(let i=0;i<3;i++)candidate=wall-(wallTime(new Date(candidate))-candidate);return new Date(candidate);}
export async function classCommand(service,tx,user,gymId,name,body){
 if(!['class-series','class-cancel','class-attendance','staff-permissions','staff-disable','staff-settings'].includes(name))return null;
 const root=`gyms/${gymId}`;
 if(name.startsWith('staff-')){
  service.requirePermission(user,'members',true);
  const uid=id(body.uid),row=await tx.get(`users/${uid}`);
  requireValue(row && row.data.gymId===gymId && row.data.role==='staff','حساب الموظف غير موجود',404);
  let changes={};
  if(name!=='staff-permissions'){
   requireValue(typeof body.isActive==='boolean','حالة الحساب غير صحيحة');changes.isActive=body.isActive;
  }
  if(name!=='staff-disable'){
   const allowed=['members','attendance','subscriptions','collections','classes','expenses','loyalty','reports'];
   requireValue(Array.isArray(body.permissions) && body.permissions.every(p=>allowed.includes(p)),'الصلاحيات غير صحيحة');changes.permissions=[...new Set(body.permissions)];
  }
  await tx.put(row.path,{...row.data,...changes});if(changes.isActive===false)await tx.revokeSessions(uid);
  return {handled:true,result:{saved:true}};
 }
 service.requirePermission(user,'classes',name!=='class-attendance');
 if(name==='class-series'){
  const count=integer(body.count??1,1,12),start=date(body.dateTime);requireValue(start>new Date(),'ميعاد الحصة لازم يكون قادم');
  const trainer=await tx.get(`${root}/trainers/${id(body.trainerId)}`);requireValue(trainer && trainer.data.isActive!==false,'المدرب غير متاح',404);
  const seriesId=randomUUID(),ids=[];
  for(let i=0;i<count;i++){const classId=randomUUID();ids.push(classId);await tx.put(`${root}/classes/${classId}`,{name:text(body.name,'اسم الحصة'),trainerId:body.trainerId,trainerName:trainer.data.name,dateTime:stamp(addCairoWeeks(start,i)),durationMinutes:integer(body.durationMinutes,1,1440),capacity:integer(body.capacity,1,10000),bookedMemberIds:[],attendedMemberIds:[],absentMemberIds:[],isCancelled:false,seriesId});}
  return {handled:true,result:{classIds:ids,seriesId}};
 }
 const row=await tx.get(`${root}/classes/${id(body.classId)}`);requireValue(row && !row.data.isCancelled,'الحصة غير موجودة أو ملغية',409);
 if(name==='class-cancel'){
  const reason=text(body.reason,'سبب الإلغاء',500);
  requireValue(date(row.data.dateTime)>new Date(),'الحصة بدأت بالفعل؛ سجل الحضور بدل إلغاء الحصة');
  await tx.put(row.path,{...row.data,isCancelled:true,cancelledAt:stamp(),cancellationReason:reason});
  const recipients=(await tx.list('users')).filter(u=>u.data.gymId===gymId && (row.data.bookedMemberIds??[]).includes(u.data.memberId));
  for(const u of recipients)await tx.put(`${u.path}/notifications/${randomUUID()}`,{title:'تم إلغاء حصة',body:`${row.data.name}: ${reason}`,date:stamp(),isRead:false});
  return {handled:true,result:{cancelled:true}};
 }
 const memberId=id(body.memberId);requireValue((row.data.bookedMemberIds??[]).includes(memberId),'العضو مش حاجز الحصة');
 requireValue(date(row.data.dateTime).getTime()<=Date.now()+30*60000,'تسجيل حضور الحصة متاح قبل الميعاد بنصف ساعة');
 requireValue(['present','absent'].includes(body.status),'حالة الحضور غير صحيحة');
 const present=(row.data.attendedMemberIds??[]).filter(v=>v!==memberId),absent=(row.data.absentMemberIds??[]).filter(v=>v!==memberId);
 (body.status==='present'?present:absent).push(memberId);
 await tx.put(row.path,{...row.data,attendedMemberIds:present,absentMemberIds:absent});
 return {handled:true,result:{saved:true}};
}
