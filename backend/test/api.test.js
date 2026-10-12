import test from 'node:test';
import assert from 'node:assert/strict';
import { randomUUID } from 'node:crypto';
import pg from 'pg';
import { PostgresStore } from '../src/postgres.js';
import { GymService } from '../src/service.js';
import { createApp, createHandler } from '../src/http.js';
import {snapshot,restoreEmpty} from '../src/backup.js';
import {signature} from '../src/photos.js';
import { stamp } from '../src/security.js';

async function database() {
  if (process.env.TEST_DATABASE_URL) {
    const schema = `gym_test_${randomUUID().replaceAll('-', '')}`;
    const admin = new pg.Pool({ connectionString: process.env.TEST_DATABASE_URL });
    await admin.query(`CREATE SCHEMA ${schema}`);
    const pool = new pg.Pool({ connectionString: process.env.TEST_DATABASE_URL, options: `-c search_path=${schema}` });
    return { pool, close: async () => { await pool.end(); await admin.query(`DROP SCHEMA ${schema} CASCADE`); await admin.end(); } };
  }
  // Real PostgreSQL WASM engine for environments without a server. CI runs this
  // same suite against PostgreSQL 16 to verify SQL and concurrent connections.
  const { PGlite } = await import('@electric-sql/pglite');
  const db = new PGlite();
  let tail = Promise.resolve();
  async function connect() {
    const old = tail; let release;
    tail = new Promise(resolve => { release = resolve; });
    await old;
    return { query: async (sql, params) => sql.startsWith('CREATE TABLE') ? { rows: await db.exec(sql) } : db.query(sql, params), release };
  }
  const pool = { connect, query: async (sql, params) => { const client = await connect(); try { return await client.query(sql, params); } finally { client.release(); } } };
  return { pool, close: () => db.close() };
}

test('API account, tenant, subscription and money flows', async t => {
  const { pool, close } = await database();
  const store = new PostgresStore(pool);
  await store.migrate();
  const service = new GymService(store);
  const server = createApp(service);
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  t.after(async () => { await new Promise(resolve => server.close(resolve)); await close(); });
  const base = `http://127.0.0.1:${server.address().port}`;
  async function call(path, body, token, method = 'POST') {
    const response = await fetch(base + path, { method, headers: { 'Content-Type': 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}) }, ...(method === 'POST' ? { body: JSON.stringify(body ?? {}) } : {}) });
    return { status: response.status, ...(await response.json()) };
  }
  await service.bootstrap({ email: 'owner@example.com', password: 'SystemOwner-password1' });
  const systemLogin = await call('/api/auth/login', { email: 'owner@example.com', password: 'SystemOwner-password1' });
  assert.equal(systemLogin.status, 200);
  const system = systemLogin.data.token;
  await t.test('serverless parsed JSON preserves auth and rejects invalid or oversized bodies', async () => {
    const handler = createHandler(service);
    async function invoke(body) {
      const req = { method: 'POST', url: '/api/auth/login', headers: {}, socket: { remoteAddress: 'serverless' }, body };
      let payload;
      const res = { statusCode: 200, setHeader() {}, end(value) { payload = JSON.parse(value); } };
      await handler(req, res);
      return { status: res.statusCode, ...payload };
    }
    const login = await invoke({ email: 'owner@example.com', password: 'SystemOwner-password1' });
    assert.equal(login.status, 200);
    assert.ok(login.data.token);
    assert.equal((await invoke([])).status, 400);
    assert.equal((await invoke('invalid JSON')).status, 400);
    assert.equal((await invoke({ email: 'a'.repeat(256 * 1024) })).status, 413);
  });
  let gymA, gymB, adminA, adminB, memberA, memberB, memberToken, staffToken, staffId, planId, debtId;

  await t.test('signup is atomic; clients cannot choose lifetime license or system role', async () => {
    const signup = await call('/api/auth/signup', { name: 'Gym A', phone: '01012345678', adminName: 'Admin A', adminPhone: '01012345678', adminEmail: 'admin-a@example.com', adminPassword: 'Admin-password1', role: 'superAdmin', licenseEnd: stamp('2099-01-01'), plan: 'pro' });
    assert.equal(signup.status, 200); gymA = signup.data.gymId;
    assert.equal(signup.data.user.data.role, 'admin');
    const row = await store.get(`gyms/${gymA}`);
    assert.ok(new Date(row.data.licenseEnd.value) < new Date(Date.now() + 15 * 86400000));
    const duplicate = await call('/api/auth/signup', { name: 'Orphan', phone: '01012345678', adminName: 'Duplicate', adminPhone: '01012345678', adminEmail: 'admin-a@example.com', adminPassword: 'Admin-password1' });
    assert.equal(duplicate.status, 409);
    assert.equal((await store.list('gyms')).length, 1);
    const second = await call('/api/auth/gym-owner', { gymId: 'gym-b', name: 'Gym B', phone: '01112345678', adminName: 'Admin B', adminPhone: '01112345678', adminEmail: 'admin-b@example.com', adminPassword: 'Admin-password2', plan: 'pro', licenseEnd: stamp(new Date(Date.now() + 365 * 86400000)) }, system);
    assert.equal(second.status, 200); gymB = second.data.gymId;
    adminA = (await call('/api/auth/login', { email: 'admin-a@example.com', password: 'Admin-password1' })).data.token;
    adminB = (await call('/api/auth/login', { email: 'admin-b@example.com', password: 'Admin-password2' })).data.token;
  });
  await t.test('member uniqueness and signup use one committed transaction', async () => {
    const make = (token, gymId, name, phone) => call('/api/commands/member-save', { gymId, data: { name, phone, visitsUsed: 999, hasLoginAccount: true } }, token);
    const [a, duplicate] = await Promise.all([make(adminA, gymA, 'Member A', '01212345678'), make(adminA, gymA, 'Duplicate', '01212345678')]);
    assert.deepEqual([a.status, duplicate.status].sort(), [200, 409]);
    memberA = (a.status === 200 ? a : duplicate).data.id;
    assert.equal((a.status === 200 ? a : duplicate).data.data.visitsUsed, 0);
    memberB = (await make(adminB, gymB, 'Member B', '01512345678')).data.id;
  });
  await t.test('tenant admins cannot read, change roles or write another gym', async () => {
    assert.equal((await call('/api/data/read', { path: `gyms/${gymB}/members/${memberB}` }, adminA)).status, 403);
    assert.equal((await call('/api/data/query', { path: `gyms/${gymB}/members` }, adminA)).status, 403);
    const otherUid = (await call('/api/auth/me', null, adminB, 'GET')).data.id;
    assert.equal((await call('/api/data/write', { path: `users/${otherUid}`, operation: 'update', data: { role: 'superAdmin' } }, adminA)).status, 403);
    assert.equal((await call('/api/data/write', { path: `gyms/${gymA}/members/${memberA}`, operation: 'update', data: { subscriptionEnd: stamp('2099-01-01') } }, adminA)).status, 403);
  });
  await t.test('subscriptions use server plan price; payment and debt are atomic', async () => {
    const plan = await call('/api/data/write', { path: `gyms/${gymA}/plans/monthly`, operation: 'set', data: { name: 'Monthly', price: 500, durationDays: 30, visitsAllowed: 12, isActive: true } }, adminA);
    assert.equal(plan.status, 200); planId = plan.data.id;
    const subscription = await call('/api/commands/subscribe', { gymId: gymA, memberId: memberA, planId, paidAmount: 400, recordedByUid: 'forged', price: 1 }, adminA);
    assert.equal(subscription.status, 200);
    const debts = await call('/api/data/query', { path: `gyms/${gymA}/debts` }, adminA);
    debtId = debts.data[0].id; assert.equal(debts.data[0].data.totalAmount, 500);
    const payments = await store.list(`gyms/${gymA}/payments`);
    assert.equal(payments[0].data.amount, 400);
    assert.notEqual(payments[0].data.recordedBy, 'forged');
  });
  await t.test('concurrent debt payments cannot overcollect and append duplicate receipts', async () => {
    const results = await Promise.all([1, 2].map(() => call('/api/commands/debt-pay', { gymId: gymA, debtId, amount: 100 }, adminA)));
    assert.deepEqual(results.map(r => r.status).sort(), [200, 409]);
    const paid = await store.get(`gyms/${gymA}/debts/${debtId}`);
    assert.equal(paid.data.paidAmount, 500);
    assert.equal((await store.list(`gyms/${gymA}/payments`)).reduce((sum, row) => sum + row.data.amount, 0), 500);
    assert.equal((await call('/api/commands/debt-pay', { gymId: gymA, debtId, amount: -10 }, adminA)).status, 400);
  });
  await t.test('concurrent attendance deducts a single visit per Cairo day', async () => {
    const results = await Promise.all([1, 2].map(() => call('/api/commands/check-in', { gymId: gymA, memberId: memberA, biometricVerified: true }, adminA)));
    assert.deepEqual(results.map(r => r.status).sort(), [200, 409]);
    const member = await store.get(`gyms/${gymA}/members/${memberA}`);
    assert.equal(member.data.visitsUsed, 1);
    assert.equal((await store.get(`gyms/${gymA}/subscriptions/${member.data.currentSubscriptionId}`)).data.visitsUsed, 1);
    const records = await store.list(`gyms/${gymA}/attendance`);
    assert.equal(records.length, 1); assert.equal(records[0].data.biometricVerified, false);
  });
  await t.test('member account uses stored phone and requires a different password', async () => {
    const account = await call('/api/auth/member-account', { gymId: gymA, memberId: memberA, phone: '01599999999' }, adminA);
    assert.equal(account.status, 200);
    assert.equal(account.data.temporaryPassword, '01212345678');
    const login = await call('/api/auth/login', { gymId: gymA, phone: '01212345678', password: account.data.temporaryPassword });
    assert.equal(login.status, 200); memberToken = login.data.token;
    assert.equal((await call('/api/data/read', { path: `gyms/${gymA}/members/${memberA}` }, memberToken)).status, 403);
    assert.equal((await call('/api/auth/password', { password: '01212345678' }, memberToken)).status, 400);
    assert.equal((await call('/api/auth/password', { password: 'Member-password1' }, memberToken)).status, 200);
    const history = await call('/api/data/query', { path: `gyms/${gymA}/attendance`, filters: [{ field: 'memberId', op: 'eq', value: memberA }] }, memberToken);
    assert.equal(history.status, 200); assert.equal(history.data.length, 1);
    assert.equal((await call('/api/data/read', { path: `gyms/${gymB}/members/${memberB}` }, memberToken)).status, 403);
    assert.equal((await call('/api/data/query', { path: `gyms/${gymA}/expenses` }, memberToken)).data.length, 0);
  });
  await t.test('phone migration only changes legacy pending members and runs once', async () => {
    const { passwordHash, verifyPassword } = await import('../src/security.js');
    await store.put('users/legacy-member', { role: 'member', phone: '01012345678', gymId: gymA, mustChangePassword: true });
    await store.addAccount('legacy-member', `member:${gymA}:01012345678`, await passwordHash('Old-random-password'));
    await store.addSession('legacy-session', 'legacy-member', new Date(Date.now() + 86400000));
    await service.migratePendingMemberPasswords();
    assert.equal(await verifyPassword('01012345678', (await store.account(`member:${gymA}:01012345678`)).password_hash), true);
    assert.equal(await store.session('legacy-session'), null);
    assert.equal((await store.get('users/legacy-member')).data.mustChangePassword, true);
    assert.equal(await verifyPassword('Member-password1', (await store.account(`member:${gymA}:01212345678`)).password_hash), true);
    await store.changePassword('legacy-member', await passwordHash('New-user-password'));
    await service.migratePendingMemberPasswords();
    assert.equal(await verifyPassword('New-user-password', (await store.account(`member:${gymA}:01012345678`)).password_hash), true);
    await store.remove('users/legacy-member');
  });
  await t.test('booking validates member ownership, capacity and preserves class metadata', async () => {
    const row = await call('/api/data/write', { path: `gyms/${gymA}/classes/class1`, operation: 'set', data: { name: 'Training', trainerId: 'trainer', trainerName: 'Coach', dateTime: stamp(new Date(Date.now() + 86400000)), capacity: 1, durationMinutes: 60 } }, adminA);
    assert.equal(row.status, 200);
    assert.equal((await call('/api/data/write', { path: `gyms/${gymA}/classes/class1`, operation: 'update', data: { capacity: 100 } }, memberToken)).status, 403);
    assert.equal((await call('/api/commands/book-class', { gymId: gymA, classId: 'class1', memberId: memberA }, memberToken)).status, 200);
    assert.equal((await call('/api/commands/book-class', { gymId: gymA, classId: 'class1', memberId: memberB }, memberToken)).status, 404);
    assert.equal((await store.get(`gyms/${gymA}/classes/class1`)).data.capacity, 1);
  });
  await t.test('loyalty redemption uses server reward price and cannot overspend', async () => {
    await call('/api/commands/points-add', { gymId: gymA, memberId: memberA, points: 100, reason: 'Bonus' }, adminA);
    await call('/api/data/write', { path: `gyms/${gymA}/rewards/reward1`, operation: 'set', data: { title: 'Gift', description: 'A gift', pointsCost: 100, isActive: true, type: 'physical' } }, adminA);
    const results = await Promise.all([1, 2].map(() => call('/api/commands/redeem', { gymId: gymA, memberId: memberA, rewardId: 'reward1', points: 1 }, memberToken)));
    assert.deepEqual(results.map(r => r.status).sort(), [200, 409]);
    assert.equal((await store.get(`gyms/${gymA}/members/${memberA}/loyalty/summary`)).data.totalPoints, 0);
    assert.equal((await call('/api/data/read', { path: `gyms/${gymA}/members/${memberA}/loyalty/summary` }, memberToken)).status, 200);
  });
  await t.test('staff can be created without changing admin session; deletion revokes login', async () => {
    const staff = await call('/api/auth/staff', { gymId: gymA, name: 'Employee', email: 'staff@example.com', password: 'Staff-password1', phone: '01099999999', role: 'staff' }, adminA);
    assert.equal(staff.status, 200); staffId = staff.data.id;
    const login = await call('/api/auth/login', { email: 'staff@example.com', password: 'Staff-password1' });
    staffToken = login.data.token;
    await call('/api/auth/password', { password: 'Staff-password2' }, staffToken);
    assert.equal((await call(`/api/auth/staff/${staffId}`, null, adminA, 'DELETE')).status, 200);
    assert.equal((await call('/api/auth/me', null, staffToken, 'GET')).status, 401);
    assert.equal((await call('/api/auth/login', { email: 'staff@example.com', password: 'Staff-password2' })).status, 401);
    assert.equal((await call('/api/auth/me', null, adminA, 'GET')).status, 200);
  });
  await t.test('member edits preserve visits and update linked login and phone index together', async () => {
    const updated = await call('/api/commands/member-save', { gymId: gymA, memberId: memberA, data: { name: 'Renamed', phone: '01299999999', visitsUsed: 0, hasLoginAccount: false } }, adminA);
    assert.equal(updated.status, 200); assert.equal(updated.data.data.visitsUsed, 1);
    assert.equal(await store.get(`gyms/${gymA}/phoneIndex/01212345678`), null);
    assert.equal((await store.get(`gyms/${gymA}/phoneIndex/01299999999`)).data.memberId, memberA);
    assert.equal((await call('/api/auth/login', { gymId: gymA, phone: '01299999999', password: 'Member-password1' })).status, 200);
  });
  await t.test('replayed subscriptions and partial debt payments collect once, with one receipt and points award', async () => {
    const member = (await call('/api/commands/member-save',{gymId:gymA,data:{name:'Replay test',phone:'01122222222'}},adminA)).data.id;
    const body={gymId:gymA,memberId:member,planId,paidAmount:200,requestId:'subscribe-replay'};
    const [first,retry]=await Promise.all([call('/api/commands/subscribe',body,adminA),call('/api/commands/subscribe',body,adminA)]);
    assert.equal(first.status,200);assert.deepEqual(first.data,retry.data);
    assert.equal((await store.list(`gyms/${gymA}/subscriptions`)).filter(r=>r.data.memberId===member).length,1);
    const receipts=(await store.list(`gyms/${gymA}/payments`)).filter(r=>r.data.memberId===member);
    assert.equal(receipts.length,1);assert.ok(receipts[0].data.receiptNumber);
    assert.equal((await store.get(`gyms/${gymA}/members/${member}/loyalty/summary`)).data.totalPoints,20);
    assert.equal((await call('/api/commands/subscribe',{...body,paidAmount:300},adminA)).status,409);
    const debt=(await store.list(`gyms/${gymA}/debts`)).find(r=>r.data.memberId===member);
    const pay={gymId:gymA,debtId:debt.path.split('/').at(-1),amount:50,requestId:'pay-replay'};
    assert.equal((await call('/api/commands/debt-pay',pay,adminA)).status,200);
    assert.equal((await call('/api/commands/debt-pay',pay,adminA)).status,200);
    assert.equal((await store.get(debt.path)).data.paidAmount,250);
    const audit=(await call('/api/data/query',{path:`gyms/${gymA}/audit`,filters:[{field:'action',op:'eq',value:'debt-pay'}]},adminA)).data;
    assert.equal(audit.filter(r=>r.data.debtId===pay.debtId).length,1);
    assert.equal((await call('/api/data/write',{path:`gyms/${gymA}/audit/forged`,operation:'set',data:{actorUid:'forged'}},adminA)).status,403);
  });
  await t.test('freeze blocks attendance and resume restores remaining duration; early renewal keeps current visits',async()=>{
    const member=(await call('/api/commands/member-save',{gymId:gymA,data:{name:'Freeze test',phone:'01133333333'}},adminA)).data.id;
    await call('/api/commands/subscribe',{gymId:gymA,memberId:member,planId,paidAmount:500,requestId:'freeze-sub'},adminA);
    const path=`gyms/${gymA}/members/${member}`,before=await store.get(path);
    assert.equal((await call('/api/commands/subscription-freeze',{gymId:gymA,memberId:member,reason:'Travel'},adminA)).status,200);
    assert.equal((await call('/api/commands/check-in',{gymId:gymA,memberId:member},adminA)).status,400);
    await store.put(path,{...(await store.get(path)).data,frozenAt:stamp(new Date(Date.now()-2*86400000))});
    assert.equal((await call('/api/commands/subscription-resume',{gymId:gymA,memberId:member},adminA)).status,200);
    const resumed=await store.get(path);
    assert.ok(new Date(resumed.data.subscriptionEnd.value)-new Date(before.data.subscriptionEnd.value)>=2*86400000);
    const currentId=resumed.data.currentSubscriptionId;
    await call('/api/commands/subscribe',{gymId:gymA,memberId:member,planId,paidAmount:500,startAfterCurrent:true,requestId:'early-renewal'},adminA);
    const renewed=await store.get(path);assert.equal(renewed.data.currentSubscriptionId,currentId);assert.ok(renewed.data.nextSubscription);
    assert.equal((await call('/api/commands/check-in',{gymId:gymA,memberId:member},adminA)).status,200);
    assert.equal((await store.get(path)).data.visitsUsed,1);
    assert.equal((await call('/api/commands/subscribe',{gymId:gymA,memberId:member,planId,paidAmount:500,startAfterCurrent:true,requestId:'another-early'},adminA)).status,409);
    const stored=(await store.get(path)).data;
    await store.put(path,{...stored,nextSubscription:{...stored.nextSubscription,subscriptionStart:stamp(new Date(Date.now()-1000))}});
    const promoted=(await call('/api/data/read',{path},adminA)).data.data;
    assert.equal(promoted.currentSubscriptionId,stored.nextSubscription.currentSubscriptionId);assert.equal(promoted.visitsUsed,0);
  });
  await t.test('password reset is admin scoped, revokes sessions and forces a new non-phone password',async()=>{
    assert.equal((await call('/api/auth/member-reset',{gymId:gymB,memberId:memberB},adminA)).status,403);
    assert.equal((await call('/api/auth/member-reset',{gymId:gymA,memberId:memberA},memberToken)).status,403);
    const result=await call('/api/auth/member-reset',{gymId:gymA,memberId:memberA},adminA);assert.equal(result.status,200);
    assert.equal((await call('/api/auth/me',null,memberToken,'GET')).status,401);
    const m=await store.get(`gyms/${gymA}/members/${memberA}`);
    const login=await call('/api/auth/login',{gymId:gymA,phone:m.data.phone,password:m.data.phone});
    assert.equal(login.status,200);memberToken=login.data.token;
    assert.equal((await call('/api/data/query',{path:`gyms/${gymA}/members`},memberToken)).status,403);
    assert.equal((await call('/api/auth/password',{password:m.data.phone},memberToken)).status,400);
    assert.equal((await call('/api/auth/password',{password:'Restored-password1'},memberToken)).status,200);
  });
  await t.test('reception pages are bounded, search respects literal wildcards and cannot cross tenants',async()=>{
    await store.transaction(async tx=>{for(let i=0;i<30;i++)await tx.put(`gyms/${gymA}/members/search-${i.toString().padStart(2,'0')}`,{name:'Search fixture',phone:'01144444444',joinDate:stamp(),status:'expired'});});
    const first=await call('/api/reception',{gymId:gymA,search:'Search fixture'},adminA);
    assert.equal(first.data.members.length,25);assert.ok(first.data.next);
    const next=await call('/api/reception',{gymId:gymA,search:'Search fixture',after:first.data.next},adminA);
    assert.equal(next.data.members.length,5);assert.equal(next.data.next,null);
    assert.equal((await call('/api/reception',{gymId:gymA,search:'%'},adminA)).data.members.length,0);
    assert.equal((await call('/api/reception',{gymId:gymB},adminA)).status,403);
    assert.equal((await call('/api/reception',{gymId:gymA},memberToken)).status,403);
  });
  await t.test('notifications persist read state and users cannot mark another inbox',async()=>{
    const user=await service.authenticate(adminA),path=`users/${user.uid}/notifications/notice1`;
    await store.put(path,{title:'Reminder',body:'Test',date:stamp(),isRead:false});
    const result=await call('/api/notifications',null,adminA,'GET');assert.ok(result.data.some(r=>r.id==='notice1'));
    await call('/api/notifications/read',{ids:['notice1']},adminB);assert.equal((await store.get(path)).data.isRead,false);
    await call('/api/notifications/read',{ids:['notice1']},adminA);assert.equal((await store.get(path)).data.isRead,true);
  });
  await t.test('backup restores accounts and data to an empty database, excludes sessions and refuses overwrites',async()=>{
    const backup=await snapshot(store);assert.equal(backup.sessions,undefined);
    const isolated=await database();
    try{
      const target=new PostgresStore(isolated.pool);await target.migrate();await restoreEmpty(target,backup);
      assert.equal((await target.list(`gyms/${gymA}/members`)).length,(await store.list(`gyms/${gymA}/members`)).length);
      assert.ok(await target.account('admin-a@example.com'));
      assert.equal((await isolated.pool.query('SELECT count(*)::int AS count FROM sessions')).rows[0].count,0);
      await assert.rejects(()=>restoreEmpty(target,backup),/فارغة/);
    }finally{await isolated.close();}
  });
  await t.test('photo signing parameters are stable, scoped and do not expose the API secret',async()=>{
    const {createHash}=await import('node:crypto');
    const secret='test-secret';assert.equal(signature({timestamp:'1',public_id:'gym/test'},secret),createHash('sha1').update('public_id=gym/test&timestamp=1'+secret).digest('hex'));
    assert.equal((await call('/api/photos/upload',{gymId:gymB,memberId:memberB},adminA)).status,403);
    assert.equal((await call('/api/photos/upload',{gymId:gymA,memberId:memberA},memberToken)).status,403);
    assert.equal((await call('/api/photos/delete',{gymId:gymA,memberId:memberA},adminA)).status,503);
  });
  await t.test('financial summary separates contract values, cash and current debt and respects period and tenant',async()=>{
    const result=await call('/api/reports/summary',{gymId:gymA},adminA);assert.equal(result.status,200);
    const payments=await store.list(`gyms/${gymA}/payments`);
    assert.equal(result.data.collected,payments.reduce((sum,r)=>sum+r.data.amount,0));
    const debt=await store.list(`gyms/${gymA}/debts`);
    assert.equal(result.data.outstanding,debt.reduce((sum,r)=>sum+r.data.totalAmount-r.data.paidAmount,0));
    assert.ok(result.data.subscriptionValue>=result.data.collected);
    assert.equal((await call('/api/reports/summary',{gymId:gymA,from:'2098-01-01',to:'2099-01-01'},adminA)).data.collected,0);
    assert.equal((await call('/api/reports/summary',{gymId:gymB},adminA)).status,403);
    assert.equal((await call('/api/reports/summary',{gymId:gymA},memberToken)).status,403);
  });
  await t.test('payment reversal, plan changes and cancellation preserve a signed cash ledger and current debt',async()=>{
    const m=(await call('/api/commands/member-save',{gymId:gymA,data:{name:'Lifecycle',phone:'01055558888'}},adminA)).data.id;
    const sub=(await call('/api/commands/subscribe',{gymId:gymA,memberId:m,planId,paidAmount:200,method:'card',requestId:'lifecycle-sub'},adminA)).data.id;
    const original=(await store.select(`gyms/${gymA}/payments`,[{field:'relatedSubscriptionId',op:'eq',value:sub}]))[0];
    const reverse={gymId:gymA,paymentId:original.path.split('/').at(-1),reason:'Wrong collection',requestId:'reverse-once'};
    assert.equal((await call('/api/commands/payment-reverse',reverse,adminB)).status,403);
    const a=await call('/api/commands/payment-reverse',reverse,adminA);assert.equal(a.status,200);assert.equal(a.data.data.amount,-200);assert.equal(a.data.data.method,'card');
    assert.equal((await call('/api/commands/payment-reverse',reverse,adminA)).data.id,a.data.id);
    assert.equal((await call('/api/commands/payment-reverse',{...reverse,requestId:'second-reversal'},adminA)).status,409);
    let debt=(await store.select(`gyms/${gymA}/debts`,[{field:'relatedSubscriptionId',op:'eq',value:sub}]))[0];assert.equal(debt.data.paidAmount,0);
    assert.equal((await call('/api/commands/debt-pay',{gymId:gymA,debtId:debt.path.split('/').at(-1),amount:300,method:'transfer'},adminA)).status,200);
    await call('/api/data/write',{path:`gyms/${gymA}/plans/cheaper`,operation:'set',data:{name:'Cheaper',price:250,durationDays:40,visitsAllowed:12,isActive:true}},adminA);
    const before=await store.get(`gyms/${gymA}/members/${m}`);
    const changed=await call('/api/commands/subscription-change',{gymId:gymA,memberId:m,subscriptionId:sub,planId:'cheaper',paidAmount:0,reason:'Downgrade',method:'transfer'},adminA);assert.equal(changed.status,200);assert.equal(changed.data.refundedAmount,50);
    const after=await store.get(before.path);assert.deepEqual(after.data.subscriptionStart,before.data.subscriptionStart);assert.equal(after.data.visitsUsed,before.data.visitsUsed);
    assert.equal((await call('/api/commands/subscription-cancel',{gymId:gymA,memberId:m,subscriptionId:sub,refundAmount:251,reason:'Cancel'},adminA)).status,409);
    const cancellation={gymId:gymA,memberId:m,subscriptionId:sub,refundAmount:250,reason:'Cancel',requestId:'cancel-once'};
    assert.equal((await call('/api/commands/subscription-cancel',cancellation,adminA)).status,200);
    assert.equal((await call('/api/commands/subscription-cancel',cancellation,adminA)).status,200);
    assert.equal((await call('/api/commands/check-in',{gymId:gymA,memberId:m},adminA)).status,400);
    assert.equal((await store.select(`gyms/${gymA}/payments`,[{field:'relatedSubscriptionId',op:'eq',value:sub}])).reduce((sum,r)=>sum+r.data.amount,0),0);
    assert.equal((await store.get(`gyms/${gymA}/subscriptions/${sub}`)).data.status,'cancelled');
  });
  await t.test('staff permissions are enforced server-side and disabling an account revokes sessions',async()=>{
    const row=await call('/api/auth/staff',{gymId:gymA,name:'Limited',email:'limited@example.com',password:'Limited-password1',phone:'01055556666',role:'staff'},adminA);assert.equal(row.status,200);
    const uid=row.data.id,token=(await call('/api/auth/login',{email:'limited@example.com',password:'Limited-password1'})).data.token;
    await call('/api/auth/password',{password:'Limited-password2'},token);
    assert.equal((await call('/api/commands/staff-permissions',{gymId:gymB,uid,permissions:[]},adminB)).status,404);
    assert.equal((await call('/api/commands/staff-permissions',{gymId:gymA,uid,permissions:['members']},adminA)).status,200);
    assert.equal((await call('/api/reception',{gymId:gymA},token)).status,200);
    assert.equal((await call('/api/commands/check-in',{gymId:gymA,memberId:memberA},token)).status,403);
    assert.equal((await call('/api/reports/summary',{gymId:gymA},token)).status,403);
    assert.equal((await call('/api/commands/staff-permissions',{gymId:gymA,uid,permissions:['superAdmin']},adminA)).status,400);
    assert.equal((await call('/api/commands/staff-disable',{gymId:gymA,uid,isActive:false},adminA)).status,200);
    assert.equal((await call('/api/auth/me',null,token,'GET')).status,401);
    assert.equal((await call('/api/auth/login',{email:'limited@example.com',password:'Limited-password2'})).status,401);
  });
  await t.test('recurring classes retain Cairo time through DST, cancellation keeps roster and notifies members',async()=>{
    const {addCairoWeeks}=await import('../src/operations/classes.js');
    const april=new Date('2027-04-22T16:00:00Z');const next=addCairoWeeks(april,1);
    assert.equal(new Intl.DateTimeFormat('en',{timeZone:'Africa/Cairo',hour:'numeric',hourCycle:'h23'}).format(next),'18');
    await call('/api/data/write',{path:`gyms/${gymA}/trainers/series-trainer`,operation:'set',data:{name:'Coach',phone:'01022221111',isActive:true}},adminA);
    const series=await call('/api/commands/class-series',{gymId:gymA,trainerId:'series-trainer',name:'Series',dateTime:stamp(new Date(Date.now()+86400000)),durationMinutes:60,capacity:10,count:3},adminA);assert.equal(series.status,200);assert.equal(series.data.classIds.length,3);
    const classId=series.data.classIds[0],path=`gyms/${gymA}/classes/${classId}`,row=await store.get(path);
    await store.put(path,{...row.data,bookedMemberIds:[memberA],dateTime:stamp(new Date(Date.now()+15*60000))});
    assert.equal((await call('/api/commands/class-attendance',{gymId:gymA,classId,memberId:memberA,status:'present'},adminA)).status,200);
    assert.equal((await call('/api/commands/class-attendance',{gymId:gymA,classId,memberId:memberA,status:'absent'},adminA)).status,200);
    assert.deepEqual((await store.get(path)).data.attendedMemberIds,[]);
    assert.equal((await call('/api/commands/class-cancel',{gymId:gymA,classId,reason:'Coach unavailable'},adminA)).status,200);
    const cancelled=await store.get(path);assert.deepEqual(cancelled.data.bookedMemberIds,[memberA]);assert.equal(cancelled.data.isCancelled,true);
    const uid=(await service.authenticate(memberToken)).uid;assert.ok((await store.list(`users/${uid}/notifications`)).some(r=>r.data.title==='تم إلغاء حصة'));
    assert.equal((await call('/api/commands/book-class',{gymId:gymA,classId,memberId:memberA},adminA)).status,404);
    await call('/api/data/write',{path,operation:'update',data:{isCancelled:false,attendedMemberIds:[memberB]}},adminA);
    assert.equal((await store.get(path)).data.isCancelled,true);
  });
  await t.test('recovery codes are hashed, single-use and revoke every old session',async()=>{
    const issued=await call('/api/auth/recovery-code',{},adminB);assert.equal(issued.status,200);
    const uid=(await service.authenticate(adminB)).uid;const saved=await store.get(`recovery/${uid}`);assert.notEqual(saved.data.codeHash,issued.data.code);
    assert.equal((await call('/api/data/read',{path:`recovery/${uid}`},adminB)).status,403);
    const body={email:'admin-b@example.com',code:issued.data.code,password:'Recovered-password2'};
    assert.equal((await call('/api/auth/recover',{...body,code:'wrong'})).status,401);
    assert.equal((await call('/api/auth/recover',body)).status,200);
    assert.equal((await call('/api/auth/me',null,adminB,'GET')).status,401);
    assert.equal((await call('/api/auth/recover',body)).status,401);
    const login=await call('/api/auth/login',{email:body.email,password:body.password});assert.equal(login.status,200);adminB=login.data.token;
  });
  await t.test('encrypted backups restore exactly, reject tampering and preserve a previous successful backup after upload failure',async()=>{
    const {encryptBackup,decryptBackup,createCloudBackup}=await import('../src/operations/cloud-backups.js');const {randomBytes}=await import('node:crypto');
    const key=randomBytes(32).toString('base64'),data=await snapshot(store),bytes=encryptBackup(data,key);
    assert.deepEqual(decryptBackup(bytes,key),JSON.parse(JSON.stringify(data)));assert.ok(!bytes.toString().includes('admin-a@example.com'));
    const broken=JSON.parse(bytes.toString());broken.tag=Buffer.alloc(16).toString('base64');assert.throws(()=>decryptBackup(Buffer.from(JSON.stringify(broken)),key));
    let uploaded;const cloud={uploader:{upload_stream:(options,callback)=>({end(value){uploaded=value;callback(null,{public_id:options.public_id,bytes:value.length});}}),destroy:async()=>({result:'ok'})}};
    const backup=await createCloudBackup(service,{cloud,key});assert.equal(backup.state,'ready');assert.ok(backup.records>0);assert.equal(decryptBackup(uploaded,key).format,'golden-gym-backup-v1');
    cloud.uploader.upload_stream=(_,callback)=>({end(){callback(new Error('provider failed'));}});
    await assert.rejects(()=>createCloudBackup(service,{cloud,key}),/provider failed/);assert.equal((await store.get(`system/backups/${backup.id}`)).data.state,'ready');
    assert.equal((await call('/api/backups',null,adminA,'GET')).status,403);
    assert.equal((await call('/api/cron/backup',null,null,'GET')).status,401);
  });
  await t.test('freeze limits, automatic thaw and zero-paid subscriptions retain correct lifecycle state',async()=>{
    const m=(await call('/api/commands/member-save',{gymId:gymA,data:{name:'Thaw',phone:'01055559999'}},adminA)).data.id;
    const sub=await call('/api/commands/subscribe',{gymId:gymA,memberId:m,planId,paidAmount:0,requestId:'zero-sub'},adminA);assert.equal(sub.status,200);
    await call('/api/commands/gym-policy',{gymId:gymA,freezeMaxDays:2,freezeMaxTimes:1,bookingCancelHours:24},adminA);
    assert.equal((await call('/api/commands/subscription-freeze',{gymId:gymA,memberId:m,days:3,reason:'Trip'},adminA)).status,400);
    assert.equal((await call('/api/commands/subscription-freeze',{gymId:gymA,memberId:m,days:1,reason:'Trip'},adminA)).status,200);
    const row=await store.get(`gyms/${gymA}/members/${m}`),end=new Date(row.data.subscriptionEnd.value);
    await store.put(row.path,{...row.data,frozenAt:stamp(new Date(Date.now()-2*86400000)),frozenUntil:stamp(new Date(Date.now()-86400000))});
    assert.equal((await call('/api/commands/check-in',{gymId:gymA,memberId:m},adminA)).status,200);
    const thawed=await store.get(row.path);assert.equal(thawed.data.status,'active');assert.equal(new Date(thawed.data.subscriptionEnd.value)-end,86400000);
    assert.equal((await call('/api/commands/subscription-freeze',{gymId:gymA,memberId:m,days:1,reason:'Again'},adminA)).status,400);
    const next=await call('/api/commands/subscribe',{gymId:gymA,memberId:m,planId,paidAmount:0,startAfterCurrent:true,requestId:'queued-cancel'},adminA);assert.equal(next.status,200);
    assert.equal((await call('/api/commands/subscription-cancel',{gymId:gymA,memberId:m,subscriptionId:next.data.id,refundAmount:0,reason:'Cancel next'},adminA)).status,200);
    const preserved=await store.get(row.path);assert.equal(preserved.data.currentSubscriptionId,sub.data.id);assert.equal(preserved.data.visitsUsed,1);assert.equal(preserved.data.nextSubscription,null);
  });
  await t.test('account reset scopes, forced password change and reminder ownership are enforced',async()=>{
    const staff=await call('/api/auth/staff',{gymId:gymA,name:'Recover staff',email:'recover-staff@example.com',password:'Staff-initial1',phone:'01055550001',role:'staff'},adminA);assert.equal(staff.status,200);
    assert.equal((await call('/api/auth/staff-reset',{gymId:gymB,email:'recover-staff@example.com'},adminB)).status,404);
    assert.equal((await call('/api/auth/staff-reset',{gymId:gymB,email:'admin-b@example.com'},adminA)).status,403);
    const reset=await call('/api/auth/staff-reset',{gymId:gymA,email:'recover-staff@example.com'},adminA);assert.equal(reset.status,200);
    const login=await call('/api/auth/login',{email:'recover-staff@example.com',password:reset.data.temporaryPassword});assert.equal(login.data.user.data.mustChangePassword,true);
    const uid=staff.data.id;
    assert.equal((await call('/api/commands/staff-settings',{gymId:gymA,uid,permissions:['invalid'],isActive:false},adminA)).status,400);
    assert.equal((await store.get(`users/${uid}`)).data.isActive,undefined);
    const profile=await service.authenticate(memberToken),row=await store.get(`gyms/${gymA}/members/${profile.memberId}`);
    await store.put(row.path,{...row.data,status:'active',subscriptionEnd:stamp(new Date(Date.now()+2*86400000)),nextSubscription:null});
    const scheduled=await call('/api/reminders',null,memberToken,'GET');assert.equal(scheduled.status,200);assert.ok(scheduled.data.some(r=>r.kind==='expiry-now'));
    assert.deepEqual((await call('/api/reminders',null,adminA,'GET')).data,[]);
    await store.put(row.path,{...row.data,status:'cancelled'});assert.ok(!(await call('/api/reminders',null,memberToken,'GET')).data.some(r=>r.id.startsWith('expiry')));
  });
  await t.test('server enforces gym suspension and logout revokes saved sessions', async () => {
    assert.equal((await call('/api/data/write', { path: `gyms/${gymA}`, operation: 'update', data: { isActive: false } }, system)).status, 200);
    assert.equal((await call('/api/commands/check-in', { gymId: gymA, memberId: memberA }, adminA)).status, 403);
    assert.equal((await call('/api/auth/logout', {}, adminA)).status, 200);
    assert.equal((await call('/api/auth/me', null, adminA, 'GET')).status, 401);
  });
});
