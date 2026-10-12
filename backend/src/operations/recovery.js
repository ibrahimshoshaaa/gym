import {randomBytes} from 'node:crypto';
import {requireValue,email,id,passwordHash,hash,stamp} from '../security.js';
export async function issueRecoveryCode(service,user){
 requireValue(['admin','staff','superAdmin'].includes(user.role),'غير مسموح',403);
 const code=randomBytes(18).toString('base64url');
 await service.store.transaction(tx=>tx.put(`recovery/${user.uid}`,{codeHash:hash(code),createdAt:stamp()}));
 return {code};
}
export async function recoverAccount(service,body,network){
 const login=email(body.email);requireValue(await service.store.attempt(hash(`recover:${network}:${login}`))<=5,'محاولات كتير، حاول بعد 15 دقيقة',429);
 const account=await service.store.account(login),uid=account?.uid.split('/')[1],row=uid&&await service.store.get(`recovery/${uid}`);
 const code=typeof body.code==='string'?body.code.trim():'';
 requireValue(account && row && !row.data.usedAt && code.length<=100 && row.data.codeHash===hash(code),'بيانات الاسترجاع غير صحيحة',401);
 const encoded=await passwordHash(body.password);
 await service.store.transaction(async tx=>{
  const current=await tx.get(`recovery/${uid}`);requireValue(current && !current.data.usedAt && current.data.codeHash===hash(code),'بيانات الاسترجاع غير صحيحة',401);
  await tx.changePassword(uid,encoded);await tx.revokeSessions(uid);await tx.put(current.path,{...current.data,usedAt:stamp()});
  const profile=await tx.get(`users/${uid}`);await tx.put(profile.path,{...profile.data,mustChangePassword:false});
 });
 return {changed:true};
}
export async function resetStaffAccount(service,user,body){
 const gymId=id(body.gymId),login=email(body.email);
 return service.store.transaction(async tx=>{
  await service.operational(tx,user,gymId,['admin']);
  const account=await tx.account(login),profile=account&&await tx.get(account.uid);
  requireValue(profile && profile.data.gymId===gymId && ['admin','staff'].includes(profile.data.role),'الحساب غير موجود في الجيم',404);
  requireValue(profile.data.role==='staff'||user.role==='superAdmin','استرجاع حساب الأدمن من مالك النظام فقط',403);
  requireValue(profile.path!==`users/${user.uid}`,'استخدم تغيير كلمة المرور أو كود الاسترجاع لحسابك');
  const uid=profile.path.split('/').at(-1),password=randomBytes(9).toString('base64url');
  await tx.changePassword(uid,await passwordHash(password));await tx.revokeSessions(uid);await tx.remove(`recovery/${uid}`);
  await tx.put(profile.path,{...profile.data,mustChangePassword:true});await service.audit(tx,user,gymId,'staff-password-reset',{recordPath:profile.path});
  return {temporaryPassword:password};
 });
}
