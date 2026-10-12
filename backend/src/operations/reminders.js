import {date,stamp} from '../security.js';
export async function reminders(service,user){
 if(user.role!=='member')return [];
 const member=await service.read(user,`gyms/${user.gymId}/members/${user.memberId}`),m=member?.data;
 const rows=[];
 if(m && !['frozen','cancelled'].includes(m.status) && m.subscriptionEnd && !m.nextSubscription){
  const end=date(m.subscriptionEnd);
  for(const days of [3,0]){const at=new Date(end.getTime()-days*86400000);if(at>new Date())rows.push({id:`expiry-${days}`,title:days?'اشتراكك قرب يخلص':'اشتراكك انتهى',body:days?'فاضل ٣ أيام على نهاية اشتراكك. تواصل مع الجيم للتجديد.':'راجع الجيم لتجديد الاشتراك قبل التمرين.',at:stamp(at),kind:'expiry'});}
 }
 const classes=await service.store.select(`gyms/${user.gymId}/classes`,[{field:'dateTime',op:'gte',value:stamp()}],{field:'dateTime'},100);
 for(const c of classes)if(!c.data.isCancelled && c.data.bookedMemberIds?.includes(user.memberId)){
  const at=new Date(date(c.data.dateTime).getTime()-15*60000);
  if(at>new Date())rows.push({id:`class-${c.path.split('/').at(-1)}`,title:'حصتك قربت تبدأ',body:`${c.data.name} بعد ربع ساعة.`,at:stamp(at),kind:'class'});
 }
 return rows.slice(0,40);
}
