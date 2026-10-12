import {randomUUID} from 'node:crypto';
import {requireValue,id,text,money,date,stamp,integer} from '../security.js';
export const paymentMethod=value=>{const method=value??'cash';requireValue(['cash','card','transfer'].includes(method),'طريقة الدفع غير صحيحة');return method;};
const rowResult=row=>({id:row.path.split('/').at(-1),data:row.data,version:Number(row.version)});
const rounded=n=>Math.round(n*100)/100;
export async function subscriptionBalance(tx,root,subscriptionId){
 const payments=(await tx.select(`${root}/payments`,[{field:'relatedSubscriptionId',op:'eq',value:subscriptionId}]));
 return {payments,total:rounded(payments.reduce((sum,r)=>sum+r.data.amount,0))};
}
export async function receipt(tx,root,user,member,subscriptionId,amount,method,extra={}){
 const paymentId=randomUUID();
 return tx.put(`${root}/payments/${paymentId}`,{memberId:member.path.split('/').at(-1),memberName:member.data.name,relatedSubscriptionId:subscriptionId,amount,method:paymentMethod(method),date:stamp(),recordedBy:user.uid,receiptNumber:`GG-${paymentId.toUpperCase()}`,kind:amount<0?'refund':'collection',...extra});
}
export async function reconcileDebt(tx,root,member,sub,collected){
 const subscriptionId=sub.path.split('/').at(-1), rows=await tx.select(`${root}/debts`,[{field:'relatedSubscriptionId',op:'eq',value:subscriptionId}]);
 const existing=rows[0],price=sub.data.price??existing?.data.totalAmount??sub.data.paidAmount;
 const paid=Math.max(0,Math.min(collected,price));
 if(existing || paid<price)await tx.put(existing?.path??`${root}/debts/${randomUUID()}`,{...existing?.data,memberId:member.path.split('/').at(-1),memberName:member.data.name,planName:sub.data.planName??'',relatedSubscriptionId:subscriptionId,totalAmount:price,paidAmount:paid,isPaid:paid>=price,createdAt:existing?.data.createdAt??stamp()});
 return price;
}
export async function financeCommand(service,tx,user,gymId,name,body){
 if(!['subscription-cancel','subscription-change','payment-reverse','gym-policy'].includes(name))return null;
 service.requirePermission(user,'subscriptions',true);
 const root=`gyms/${gymId}`;
 if(name==='gym-policy'){
  const policy={freezeMaxDays:integer(body.freezeMaxDays,1,90),freezeMaxTimes:integer(body.freezeMaxTimes,0,12),bookingCancelHours:integer(body.bookingCancelHours,0,72)};
  const gym=await tx.get(root);await tx.put(root,{...gym.data,...policy});return {handled:true,result:policy};
 }
 if(name==='payment-reverse'){
  service.requirePermission(user,'collections',true);
  const original=await tx.get(`${root}/payments/${id(body.paymentId)}`);
  requireValue(original && original.data.amount>0 && !original.data.reversedBy,'التحصيل غير موجود أو اتعكس بالفعل',409);
  const sub=await tx.get(`${root}/subscriptions/${id(original.data.relatedSubscriptionId)}`);
  requireValue(sub && !['cancelled','replaced'].includes(sub.data.status),'راجع إلغاء الاشتراك أو تغيير الباقة قبل عكس التحصيل',409);
  const member=await tx.get(`${root}/members/${id(original.data.memberId)}`);requireValue(member,'العضو غير موجود',404);
  const balance=await subscriptionBalance(tx,root,sub.path.split('/').at(-1));
  requireValue(balance.total>=original.data.amount,'جزء من التحصيل اترد بالفعل، مينفعش يتعكس كامل',409);
  const negative=await receipt(tx,root,user,member,original.data.relatedSubscriptionId,-original.data.amount,original.data.method,{kind:'reversal',reversesPaymentId:body.paymentId,reason:text(body.reason,'سبب التصحيح',500)});
  await tx.put(original.path,{...original.data,reversedBy:negative.path.split('/').at(-1)});
  await reconcileDebt(tx,root,member,sub,rounded(balance.total-original.data.amount));
  if(original.data.pointsAwarded){
   const path=`${root}/members/${original.data.memberId}/loyalty/summary`,points=await tx.get(path);
   if(points){const deducted=Math.min(points.data.totalPoints,original.data.pointsAwarded);await tx.put(path,{...points.data,totalPoints:points.data.totalPoints-deducted,lifetimePoints:Math.max(0,points.data.lifetimePoints-original.data.pointsAwarded)});await tx.put(`${path}/transactions/${randomUUID()}`,{points:-deducted,reason:'عكس تحصيل',date:stamp(),recordedByUid:user.uid});}
  }
  return {handled:true,result:rowResult(negative)};
 }
 const memberId=id(body.memberId),member=await tx.get(`${root}/members/${memberId}`);requireValue(member,'العضو غير موجود',404);
 const subscriptionId=id(body.subscriptionId??member.data.currentSubscriptionId),sub=await tx.get(`${root}/subscriptions/${subscriptionId}`);
 requireValue(sub && sub.data.memberId===memberId && sub.data.status!=='cancelled','الاشتراك غير موجود أو ملغي',409);
 const current=member.data.currentSubscriptionId===subscriptionId,queued=member.data.nextSubscription?.currentSubscriptionId===subscriptionId;
 requireValue(current||queued,'العملية متاحة للاشتراك الحالي أو القادم فقط',409);
 const balance=await subscriptionBalance(tx,root,subscriptionId),reason=text(body.reason,'السبب',500);
 if(name==='subscription-cancel'){
  const refund=money(body.refundAmount??0,true);requireValue(refund<=balance.total,'المبلغ المسترد أكبر من صافي التحصيل الحالي',409);
  if(refund)await receipt(tx,root,user,member,subscriptionId,-refund,body.method,{reason,kind:'refund'});
  const debts=await tx.select(`${root}/debts`,[{field:'relatedSubscriptionId',op:'eq',value:subscriptionId}]);
  for(const debt of debts)await tx.put(debt.path,{...debt.data,cancelledOutstanding:rounded(debt.data.totalAmount-debt.data.paidAmount),totalAmount:debt.data.paidAmount,isPaid:true,cancelled:true});
  await tx.put(sub.path,{...sub.data,status:'cancelled',cancelledAt:stamp(),cancellationReason:reason,originalPrice:sub.data.price??balance.total,price:rounded(balance.total-refund),refundedAmount:refund});
  await tx.put(member.path,queued?{...member.data,nextSubscription:null}:{...member.data,status:'cancelled',subscriptionEnd:stamp(new Date(Date.now()-1)),frozenAt:null,frozenUntil:null,freezeReason:null});
  return {handled:true,result:{cancelled:true,refundedAmount:refund}};
 }
 requireValue(current && !member.data.nextSubscription && member.data.status!=='frozen','تغيير الباقة يحتاج اشتراك حالي غير مجمد ومن غير تجديد قادم',409);
 requireValue(date(sub.data.endDate)>new Date(),'الاشتراك انتهى؛ اعمل تجديد جديد');
 const plan=await tx.get(`${root}/plans/${id(body.planId)}`);requireValue(plan && plan.data.isActive!==false,'الباقة غير متاحة',404);
 requireValue(plan.data.visitsAllowed===0 || plan.data.visitsAllowed>=member.data.visitsUsed,'أيام الباقة أقل من الزيارات المستخدمة');
 const end=new Date(date(sub.data.startDate).getTime()+integer(plan.data.durationDays,1,3650)*86400000);
 requireValue(end>new Date(),'مدة الباقة الجديدة انتهت بالفعل من تاريخ بداية الاشتراك');
 const price=money(plan.data.price),paid=money(body.paidAmount??0,true),due=Math.max(0,rounded(price-balance.total));
 requireValue(paid<=due,'التحصيل أكبر من فرق الباقة');
 const refund=Math.max(0,rounded(balance.total-price));
 if(paid)await receipt(tx,root,user,member,subscriptionId,paid,body.method,{reason});
 if(refund)await receipt(tx,root,user,member,subscriptionId,-refund,body.method,{reason,kind:'refund'});
 const updated={...sub.data,originalPlanId:sub.data.originalPlanId??sub.data.planId,planId:body.planId,planName:plan.data.name,price,endDate:stamp(end),visitsAllowed:plan.data.visitsAllowed,planChangedAt:stamp(),changeReason:reason};
 await tx.put(sub.path,updated);await reconcileDebt(tx,root,member,{...sub,data:updated},rounded(balance.total+paid-refund));
 await tx.put(member.path,{...member.data,currentPlanId:body.planId,subscriptionEnd:stamp(end),visitsAllowed:plan.data.visitsAllowed});
 return {handled:true,result:{changed:true,refundedAmount:refund,collectedAmount:paid,remainingAmount:rounded(due-paid),endDate:stamp(end)}};
}
