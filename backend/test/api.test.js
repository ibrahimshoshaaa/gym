import test from 'node:test';
import assert from 'node:assert/strict';
import { randomUUID } from 'node:crypto';
import pg from 'pg';
import { PostgresStore } from '../src/postgres.js';
import { GymService } from '../src/service.js';
import { createApp, createHandler } from '../src/http.js';
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
  await t.test('member account has random temporary password and forced server-side change', async () => {
    const account = await call('/api/auth/member-account', { gymId: gymA, memberId: memberA, phone: '01599999999' }, adminA);
    assert.equal(account.status, 200);
    assert.notEqual(account.data.temporaryPassword, '01212345678');
    const login = await call('/api/auth/login', { gymId: gymA, phone: '01212345678', password: account.data.temporaryPassword });
    assert.equal(login.status, 200); memberToken = login.data.token;
    assert.equal((await call('/api/data/read', { path: `gyms/${gymA}/members/${memberA}` }, memberToken)).status, 403);
    assert.equal((await call('/api/auth/password', { password: 'Member-password1' }, memberToken)).status, 200);
    const history = await call('/api/data/query', { path: `gyms/${gymA}/attendance`, filters: [{ field: 'memberId', op: 'eq', value: memberA }] }, memberToken);
    assert.equal(history.status, 200); assert.equal(history.data.length, 1);
    assert.equal((await call('/api/data/read', { path: `gyms/${gymB}/members/${memberB}` }, memberToken)).status, 403);
    assert.equal((await call('/api/data/query', { path: `gyms/${gymA}/expenses` }, memberToken)).data.length, 0);
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
  await t.test('server enforces gym suspension and logout revokes saved sessions', async () => {
    assert.equal((await call('/api/data/write', { path: `gyms/${gymA}`, operation: 'update', data: { isActive: false } }, system)).status, 200);
    assert.equal((await call('/api/commands/check-in', { gymId: gymA, memberId: memberA }, adminA)).status, 403);
    assert.equal((await call('/api/auth/logout', {}, adminA)).status, 200);
    assert.equal((await call('/api/auth/me', null, adminA, 'GET')).status, 401);
  });
});
