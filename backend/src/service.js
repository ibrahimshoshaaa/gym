import {classCommand} from './operations/classes.js';
import {financeCommand,paymentMethod} from './operations/finance.js';
import { randomUUID, randomBytes } from 'node:crypto';
import { ApiError, requireValue, text, id, phone, email, money, integer, stamp, date, hash, passwordHash, verifyPassword } from './security.js';

const staffRoles = ['admin', 'staff'];
const collections = ['members', 'plans', 'subscriptions', 'attendance', 'classes', 'trainers', 'payments', 'debts', 'expenses', 'rewards', 'audit'];
const managedCollections = ['plans', 'classes', 'trainers', 'rewards'];
const uidOf = row => row.path.split('/').at(-1);
const resultOf = row => {
  if (!row) return null;
  let data = row.data;
  if(data.status==='frozen' && data.frozenUntil && date(data.frozenUntil)<=new Date()){data={...data,status:'active',subscriptionEnd:stamp(new Date(date(data.subscriptionEnd).getTime()+date(data.frozenUntil).getTime()-date(data.frozenAt).getTime())),frozenAt:null,frozenUntil:null,freezeReason:null};}
  if (data.nextSubscription && date(data.nextSubscription.subscriptionStart) <= new Date()) data = { ...data, ...data.nextSubscription, nextSubscription: null };
  const parts = row.path.split('/');
  if (parts[0] === 'gyms' && parts[2] === 'members' && parts.length === 4 && !['frozen','cancelled'].includes(data.status)) {
    const now = new Date();
    const status = data.subscriptionStart && date(data.subscriptionStart) > now ? 'pending' : !data.subscriptionEnd || date(data.subscriptionEnd) < now ? 'expired' : 'active';
    data = { ...data, status };
  }
  return { id: uidOf(row), data, version: Number(row.version) };
};
const memberLogin = (p, gymId) => `member:${id(gymId)}:${phone(p)}`;
const limits = plan => ({ maxMembers: plan === 'basic' ? 200 : plan === 'pro' ? 500 : 9999, maxStaff: plan === 'basic' ? 3 : plan === 'pro' ? 10 : 50 });
const profileFields = ['name', 'phone', 'photoUrl', 'notes', 'gender', 'nationalId', 'dateOfBirth', 'occupation'];
function pick(object, fields) { return Object.fromEntries(fields.filter(k => Object.hasOwn(object, k)).map(k => [k, object[k]])); }
function cairoDay(value = new Date()) { return new Intl.DateTimeFormat('en-CA', { timeZone: 'Africa/Cairo', year: 'numeric', month: '2-digit', day: '2-digit' }).format(value); }

export class GymService {
  constructor(store, options = {}) { this.store = store; this.allowSignup = options.allowSignup ?? true; }
  requirePermission(user,permission,adminOnly=false){
    if(user.role==='superAdmin'||user.role==='admin')return;
    const defaults=['members','attendance','subscriptions','collections','classes','expenses','loyalty'];
    requireValue(!adminOnly && user.role==='staff' && (user.permissions??defaults).includes(permission),'الصلاحية دي مش متاحة لحسابك',403);
  }
  async authenticate(token) {
    requireValue(typeof token === 'string' && token.length >= 32 && token.length <= 200, 'سجل دخول الأول', 401);
    const uid = await this.store.session(hash(token));
    const row = uid && await this.store.get(`users/${uid}`);
    requireValue(row && row.data.isActive!==false, 'الجلسة انتهت أو الحساب متوقف، سجل دخول تاني', 401);
    return { uid, ...row.data, tokenHash: hash(token) };
  }
  async me(user) { return resultOf(await this.store.get(`users/${user.uid}`)); }
  async session(store, uid) {
    const token = randomBytes(32).toString('base64url');
    await store.addSession(hash(token), uid, new Date(Date.now() + 14 * 86400000));
    return { token, user: resultOf(await store.get(`users/${uid}`)) };
  }
  async bootstrap({ email: address, password, name = 'System owner', mustChangePassword = false }) {
    if (!address && !password) return;
    const login = email(address);
    const passwordEncoded = await passwordHash(password);
    await this.store.transaction(async tx => {
      if ((await tx.list('users')).some(r => r.data.role === 'superAdmin')) return;
      const uid = randomUUID();
      await tx.put(`users/${uid}`, { gymId: '', name, phone: '', email: login, role: 'superAdmin', createdAt: stamp(), mustChangePassword });
      await tx.addAccount(uid, login, passwordEncoded);
    });
  }
  async login(body, networkKey) {
    const login = body.gymId ? memberLogin(body.phone, body.gymId) : email(body.email);
    const key = hash(`${networkKey}:${login}`);
    requireValue(await this.store.attempt(key) <= 10, 'محاولات كتير، حاول بعد 15 دقيقة', 429);
    const account = await this.store.account(login);
    // Run the same password operation for unknown accounts to avoid cheap timing enumeration.
    const dummyHash = '00000000000000000000000000000000:' + '00'.repeat(64);
    const valid = await verifyPassword(body.password, account?.password_hash ?? dummyHash);
    requireValue(account && valid, 'بيانات الدخول غير صحيحة', 401);
    requireValue((await this.store.get(account.uid))?.data.isActive!==false,'بيانات الدخول غير صحيحة',401);
    await this.store.clearAttempt(key);
    return this.session(this.store, account.uid.split('/')[1]);
  }
  async signup(body, user = null) {
    if (user) requireValue(user.role === 'superAdmin', 'غير مسموح', 403);
    else requireValue(this.allowSignup, 'التسجيل متوقف، تواصل مع إدارة النظام', 403);
    const gymId = user && body.gymId ? id(body.gymId) : randomUUID().slice(0, 8);
    const plan = body.plan ?? 'basic';
    requireValue(['basic', 'pro', 'lifetime'].includes(plan), 'الخطة غير صحيحة');
    const login = email(body.adminEmail);
    const encoded = await passwordHash(body.adminPassword);
    const now = new Date();
    const trialEnd = new Date(now.getTime() + 14 * 86400000);
    const licenseEnd = user ? date(body.licenseEnd) : trialEnd;
    const gym = { name: text(body.name, 'اسم الجيم'), ownerName: text(body.ownerName ?? body.adminName, 'اسم المالك'), phone: phone(body.phone), address: body.address ?? null, email: body.email ?? null, logoUrl: null, plan, ...limits(plan), licenseStart: stamp(now), licenseEnd: stamp(licenseEnd), createdAt: stamp(now), isActive: true, isTrial: !user, trialEndDate: user ? null : stamp(trialEnd) };
    return this.store.transaction(async tx => {
      requireValue(!await tx.get(`gyms/${gymId}`), 'كود الجيم مستخدم بالفعل', 409);
      requireValue(!await tx.account(login), 'الإيميل مستخدم بالفعل', 409);
      const uid = randomUUID();
      await tx.put(`gyms/${gymId}`, gym);
      await tx.put(`users/${uid}`, { gymId, name: text(body.adminName, 'اسم الأدمن'), phone: phone(body.adminPhone), email: login, role: 'admin', createdAt: stamp(now), mustChangePassword: false });
      await tx.addAccount(uid, login, encoded);
      return { gymId, user: resultOf(await tx.get(`users/${uid}`)) };
    });
  }
  async operational(tx, user, gymId, roles = staffRoles) {
    requireValue(!user.mustChangePassword, 'غيّر الباسورد الأول', 403);
    requireValue(user.role === 'superAdmin' || (user.gymId === gymId && roles.includes(user.role)), 'غير مسموح', 403);
    const gym = await tx.get(`gyms/${gymId}`);
    requireValue(gym, 'الجيم غير موجود', 404);
    const now = Date.now();
    const activeLicense = date(gym.data.licenseStart).getTime() <= now && date(gym.data.licenseEnd).getTime() >= now;
    const activeTrial = gym.data.isTrial && gym.data.trialEndDate && date(gym.data.trialEndDate).getTime() >= now;
    requireValue(user.role === 'superAdmin' || (gym.data.isActive && (activeLicense || activeTrial)), 'ترخيص الجيم منتهي أو الجيم متوقف', 403);
    return gym.data;
  }
  async createStaff(user, body) {
    const gymId = id(body.gymId);
    requireValue(['admin', 'staff'].includes(body.role), 'الدور غير مسموح');
    const login = email(body.email);
    const encoded = await passwordHash(body.password);
    return this.store.transaction(async tx => {
      const gym = await this.operational(tx, user, gymId, ['admin']);
      const staff = (await tx.list('users')).filter(r => r.data.gymId === gymId && staffRoles.includes(r.data.role));
      requireValue(staff.length < gym.maxStaff, 'وصلت لحد الموظفين في الخطة', 409);
      requireValue(!await tx.account(login), 'الإيميل مستخدم بالفعل', 409);
      const uid = randomUUID();
      const data = { gymId, name: text(body.name, 'الاسم'), email: login, phone: phone(body.phone), role: body.role, salary: body.salary == null ? null : money(body.salary, true), address: body.address ?? null, notes: body.notes ?? null, createdAt: stamp(), mustChangePassword: true };
      await tx.put(`users/${uid}`, data);
      await tx.addAccount(uid, login, encoded);
      return resultOf(await tx.get(`users/${uid}`));
    });
  }
  async createMemberAccount(user, body) {
    const gymId = id(body.gymId), memberId = id(body.memberId);
    return this.store.transaction(async tx => {
      await this.operational(tx, user, gymId);
      const member = await tx.get(`gyms/${gymId}/members/${memberId}`);
      requireValue(member, 'العضو غير موجود', 404);
      const temporary = phone(member.data.phone);
      const encoded = await passwordHash(temporary);
      const login = memberLogin(temporary, gymId);
      requireValue(!await tx.account(login), 'حساب العضو مفعّل بالفعل', 409);
      const uid = randomUUID();
      await tx.put(`users/${uid}`, { gymId, name: member.data.name, phone: member.data.phone, email: null, role: 'member', memberId, initialPasswordScheme: 'phone-v1', mustChangePassword: true, createdAt: stamp() });
      await tx.addAccount(uid, login, encoded);
      await tx.put(member.path, { ...member.data, hasLoginAccount: true });
      return { temporaryPassword: temporary };
    });
  }
  async resetMemberPassword(user, body) {
    const gymId = id(body.gymId), memberId = id(body.memberId);
    return this.store.transaction(async tx => {
      await this.operational(tx, user, gymId, ['admin']);
      const member = await tx.get(`gyms/${gymId}/members/${memberId}`);
      requireValue(member, 'العضو غير موجود', 404);
      const target = (await tx.list('users')).find(r => r.data.gymId === gymId && r.data.memberId === memberId && r.data.role === 'member');
      requireValue(target, 'فعّل حساب العضو الأول', 404);
      const temporary = phone(member.data.phone);
      await tx.changePassword(uidOf(target), await passwordHash(temporary));
      await tx.revokeSessions(uidOf(target));
      await tx.put(target.path, { ...target.data, mustChangePassword: true, initialPasswordScheme: 'phone-v1' });
      await this.audit(tx, user, gymId, 'member-password-reset', { memberId });
      return { temporaryPassword: temporary };
    });
  }
  async audit(tx, user, gymId, action, body = {}) {
    await tx.put(`gyms/${gymId}/audit/${randomUUID()}`, {
      action, actorUid: user.uid, actorName: user.name, date: stamp(),
      ...pick(body, ['memberId', 'debtId', 'planId', 'amount', 'paidAmount', 'recordPath']),
    });
  }
  async businessTransaction(user, name, body, work) {
    const gymId = id(body.gymId);
    return this.store.transaction(async tx => {
      await this.operational(tx, user, gymId, ['admin', 'staff', 'member']);
      const key = body.requestId == null ? null : id(body.requestId);
      const canonical = value => Array.isArray(value) ? value.map(canonical) : value && typeof value === 'object' ? Object.fromEntries(Object.keys(value).sort().map(k => [k, canonical(value[k])])) : value;
      const fingerprint = hash(JSON.stringify(canonical({ ...body, name })));
      const path = key ? `operations/${hash(`${user.uid}:${gymId}:${key}`)}` : null;
      const previous = path && await tx.get(path);
      if (previous) {
        requireValue(previous.data.fingerprint === fingerprint, 'الطلب اتغيّر، ابدأ عملية جديدة', 409);
        return previous.data.result;
      }
      const result = await work(tx);
      await this.audit(tx, user, gymId, name, body);
      if (path) await tx.put(path, { fingerprint, result, date: stamp() });
      return result;
    });
  }
  async migratePendingMemberPasswords() {
    await this.store.transaction(async tx => {
      if (await tx.get('system/member-phone-password-v1')) return;
      for (const row of await tx.list('users')) {
        if (row.data.role !== 'member' || !row.data.mustChangePassword || row.data.initialPasswordScheme === 'phone-v1') continue;
        await tx.changePassword(uidOf(row), await passwordHash(phone(row.data.phone)));
        await tx.revokeSessions(uidOf(row));
        await tx.put(row.path, { ...row.data, initialPasswordScheme: 'phone-v1' });
      }
      await tx.put('system/member-phone-password-v1', { completedAt: stamp() });
    });
  }
  async changePassword(user, body) {
    const encoded = await passwordHash(body.password);
    await this.store.transaction(async tx => {
      const row = await tx.get(`users/${user.uid}`);
      requireValue(row, 'الحساب غير موجود', 401);
      requireValue(!(row.data.role === 'member' && row.data.mustChangePassword && body.password === phone(row.data.phone)), 'اختار كلمة مرور جديدة مختلفة عن رقم الموبايل');
      await tx.changePassword(user.uid, encoded);
      await tx.revokeSessions(user.uid, user.tokenHash);
      await tx.put(row.path, { ...row.data, mustChangePassword: false });
    });
    return { changed: true };
  }
  async deleteStaff(user, uid) {
    id(uid);
    await this.store.transaction(async tx => {
      const target = await tx.get(`users/${uid}`);
      requireValue(target && staffRoles.includes(target.data.role), 'الموظف غير موجود', 404);
      await this.operational(tx, user, target.data.gymId, ['admin']);
      requireValue(uid !== user.uid, 'مينفعش تمسح حسابك الحالي');
      if (target.data.role === 'admin') {
        const admins = (await tx.list('users')).filter(r => r.data.gymId === target.data.gymId && r.data.role === 'admin');
        requireValue(admins.length > 1, 'مينفعش تمسح آخر أدمن');
      }
      await tx.remove(target.path); // FK cascade deletes credentials and sessions as well.
    });
    return { deleted: true };
  }
  path(path, collection = false) {
    requireValue(typeof path === 'string' && path.length <= 500 && path.split('/').every(v => /^[a-zA-Z0-9_+.-]+$/.test(v)), 'المسار غير صحيح');
    const p = path.split('/');
    requireValue((p.length % 2 === 1) === collection, 'المسار غير صحيح');
    if (p[0] === 'users' && (p.length <= 2 || (p[2] === 'notifications' && p.length <= 4))) return p;
    if (p[0] === 'gyms' && p.length <= 2) return p;
    requireValue(p[0] === 'gyms' && (collections.includes(p[2]) || p[2] === 'phoneIndex'), 'المسار غير مسموح', 403);
    requireValue(p.length <= 4 || (p[2] === 'members' && p[4] === 'loyalty' && p[5] === 'summary' && (p.length === 6 || (p[6] === 'transactions' && p.length <= 8))), 'المسار غير مسموح', 403);
    return p;
  }
  canRead(user, path, data) {
    const p = path.split('/');
    if (p[0] === 'users') {
      if (p[2] === 'notifications') return p[1] === user.uid;
      return p[1] === user.uid || user.role === 'superAdmin' || (user.role === 'admin' && data?.gymId === user.gymId);
    }
    if (user.role !== 'superAdmin' && p[1] !== user.gymId) return false;
    if (p.length === 2) return true;
    if (p[2] === 'audit') return ['admin', 'superAdmin'].includes(user.role);
    if(user.role==='staff'){const permission={members:'members',plans:'subscriptions',subscriptions:'subscriptions',attendance:'attendance',classes:'classes',trainers:'classes',payments:'collections',debts:'collections',expenses:'expenses',rewards:'loyalty'}[p[2]];if(permission){const defaults=['members','attendance','subscriptions','collections','classes','expenses','loyalty'];return (user.permissions??defaults).includes(permission);}}
    if (user.role !== 'member') return true;
    if (['classes', 'plans', 'trainers', 'rewards'].includes(p[2])) return true;
    if (p[2] === 'members') return p[3] === user.memberId;
    if (['attendance', 'subscriptions', 'debts', 'payments'].includes(p[2])) return data?.memberId === user.memberId;
    return false;
  }
  async read(user, path) {
    this.path(path);
    const row = await this.store.get(path);
    requireValue(this.canRead(user, path, row?.data), 'غير مسموح', 403);
    return resultOf(row);
  }
  async query(user, body) {
    const p = this.path(body.path, true);
    // Reject the tenant before querying, even if its collection is empty.
    if (p[0] === 'gyms') requireValue(user.role === 'superAdmin' || p[1] === user.gymId, 'غير مسموح', 403);
    if (p[0] === 'users') requireValue(user.role === 'superAdmin' || user.role === 'admin' || p[1] === user.uid, 'غير مسموح', 403);
    requireValue(Array.isArray(body.filters ?? []), 'الفلاتر غير صحيحة');
    const filters = [...(body.filters ?? [])];
    requireValue(filters.length <= 12, 'الفلاتر غير صحيحة');
    for (const f of filters) {
      text(f.field, 'الحقل', 100);
      requireValue(['eq', 'gte', 'lte', 'in'].includes(f.op), 'الفِلتر غير صحيح');
      if (f.op === 'in') requireValue(Array.isArray(f.value) && f.value.length <= 30, 'الفِلتر غير صحيح');
    }
    if (p[0] === 'users' && p.length === 1 && user.role !== 'superAdmin') filters.push({ field: 'gymId', op: 'eq', value: user.gymId });
    if (p[0] === 'gyms' && p.length > 2 && user.role === 'member' && ['attendance', 'subscriptions', 'debts', 'payments'].includes(p[2])) filters.push({ field: 'memberId', op: 'eq', value: user.memberId });
    const order = body.order ? { field: text(body.order.field, 'ترتيب', 100), descending: !!body.order.descending } : null;
    if (order && body.startAt?.length) filters.push({field:order.field,op:'gte',value:body.startAt[0]});
    if (order && body.endAt?.length) filters.push({field:order.field,op:'lte',value:body.endAt[0]});
    const limit = body.limit == null ? null : integer(body.limit, 1, 10000);
    let rows = await this.store.select(body.path, filters, order, limit);
    rows = rows.filter(r => this.canRead(user, r.path, r.data));
    return rows.map(resultOf);
  }
  async write(user, body) {
    const p = this.path(body.path);
    requireValue(['set', 'update', 'delete'].includes(body.operation), 'العملية غير صحيحة');
    return this.store.transaction(async tx => {
      const existing = await tx.get(body.path);
      if (body.operation === 'update') requireValue(existing, 'السجل غير موجود', 404);
      const data = body.operation === 'update' ? { ...existing.data, ...body.data } : body.data;
      if (p[0] === 'users') {
        requireValue(p.length === 2 && body.operation === 'update' && existing && staffRoles.includes(existing.data.role), 'غير مسموح', 403);
        await this.operational(tx, user, existing.data.gymId, ['admin']);
        requireValue(Object.keys(body.data).every(k => ['salary', 'address', 'notes'].includes(k)), 'مينفعش تغيير الدور أو الجيم', 403);
        if (data.salary != null) money(data.salary, true);
      } else if (p.length === 2) {
        requireValue(user.role === 'superAdmin' && body.operation !== 'delete', 'غير مسموح', 403);
        requireValue(data && typeof data === 'object' && !Array.isArray(data), 'بيانات غير صحيحة');
        text(data.name, 'اسم الجيم'); date(data.licenseStart); date(data.licenseEnd);
        requireValue(typeof data.isActive === 'boolean' && ['basic', 'pro', 'lifetime'].includes(data.plan), 'بيانات الجيم غير صحيحة');
        integer(data.maxMembers, 1, 100000); integer(data.maxStaff, 1, 10000);
      } else {
        requireValue(p.length === 4 && [...managedCollections, 'expenses'].includes(p[2]), 'العملية محتاجة مسارها المخصص', 403);
        this.requirePermission(user,{plans:'subscriptions',classes:'classes',trainers:'classes',rewards:'loyalty',expenses:'expenses'}[p[2]]);
        await this.operational(tx, user, p[1], p[2] === 'expenses' && body.operation !== 'delete' ? staffRoles : ['admin']);
        if (body.operation !== 'delete') {
          requireValue(data && typeof data === 'object' && !Array.isArray(data), 'بيانات غير صحيحة');
          if (p[2] === 'plans') { text(data.name, 'اسم الخطة'); money(data.price); integer(data.durationDays, 1, 3650); integer(data.visitsAllowed); }
          if (p[2] === 'classes') { text(data.name, 'اسم الحصة'); date(data.dateTime); integer(data.capacity, 1, 10000); integer(data.durationMinutes, 1, 1440); for(const key of ['bookedMemberIds','attendedMemberIds','absentMemberIds','isCancelled','cancelledAt','cancellationReason','seriesId']){if(existing?.data[key]!==undefined)data[key]=existing.data[key];else delete data[key];} data.bookedMemberIds ??= []; }
          if (p[2] === 'trainers') { text(data.name, 'اسم المدرب'); phone(data.phone); }
          if (p[2] === 'rewards') { text(data.title, 'الهدية'); integer(data.pointsCost, 1); requireValue(['discount', 'freeMonth', 'physical', 'service'].includes(data.type), 'نوع الهدية غير صحيح'); }
          if (p[2] === 'expenses') { money(data.amount); date(data.date); data.recordedByUid = user.uid; }
        }
      }
      if(p[0] === 'gyms' && p.length === 4) await this.audit(tx,user,p[1],`${p[2]}-${body.operation}`,{recordPath:body.path});
      if (body.operation === 'delete') { await tx.remove(body.path); return null; }
      return resultOf(await tx.put(body.path, data));
    });
  }
  async command(user, name, body) {
    const gymId = id(body.gymId);
    return this.businessTransaction(user, name, body, async tx => {
      const memberCommands = ['book-class', 'cancel-booking', 'redeem'];
      const gym = await this.operational(tx, user, gymId, memberCommands.includes(name) ? [...staffRoles, 'member'] : staffRoles);
      const permission={ 'member-save':'members','member-delete':'members','subscribe':'subscriptions','subscription-freeze':'subscriptions','subscription-resume':'subscriptions','debt-pay':'collections','check-in':'attendance','check-out':'attendance','points-add':'loyalty'}[name];
      if(permission)this.requirePermission(user,permission);
      const extension=await financeCommand(this,tx,user,gymId,name,body)??await classCommand(this,tx,user,gymId,name,body);
      if(extension)return extension.result;
      const root = `gyms/${gymId}`;
      const loadMember = async (memberId) => {
        const row = await tx.get(`${root}/members/${id(memberId)}`);
        requireValue(row, 'العضو غير موجود', 404);
        if (user.role === 'member') requireValue(user.memberId === memberId, 'غير مسموح', 403);
        const resolved = resultOf(row).data;
        if(row.data.status==='frozen' && resolved.status!=='frozen'){const sub=await tx.get(`${root}/subscriptions/${row.data.currentSubscriptionId}`);if(sub)await tx.put(sub.path,{...sub.data,endDate:resolved.subscriptionEnd,frozenAt:null,frozenUntil:null});return tx.put(row.path,resolved);}
        if (row.data.nextSubscription && !resolved.nextSubscription) return tx.put(row.path, resolved);
        return row;
      };
      if (name === 'member-save') {
        const data = pick(body.data ?? {}, profileFields);
        data.name = text(data.name, 'اسم العضو'); data.phone = phone(data.phone);
        for (const field of ['notes', 'occupation', 'photoUrl', 'nationalId']) {
          requireValue(data[field] == null || (typeof data[field] === 'string' && data[field].length <= (field === 'notes' ? 4000 : 1000)), 'بيانات العضو غير صحيحة');
        }
        requireValue(data.gender == null || ['male', 'female'].includes(data.gender), 'النوع غير صحيح');
        if (data.dateOfBirth != null) date(data.dateOfBirth);
        const memberId = body.memberId ? id(body.memberId) : randomUUID();
        const old = await tx.get(`${root}/members/${memberId}`);
        if (body.memberId) requireValue(old, 'العضو غير موجود', 404);
        else requireValue((await tx.list(`${root}/members`)).length < gym.maxMembers, 'وصلت لحد الأعضاء في الخطة', 409);
        const index = await tx.get(`${root}/phoneIndex/${data.phone}`);
        requireValue(!index || index.data.memberId === memberId, 'رقم الموبايل موجود بالفعل', 409);
        if (old?.data.phone && old.data.phone !== data.phone) await tx.remove(`${root}/phoneIndex/${old.data.phone}`);
        await tx.put(`${root}/phoneIndex/${data.phone}`, { memberId, name: data.name });
        const linked = (await tx.list('users')).filter(r => r.data.gymId === gymId && r.data.memberId === memberId);
        for (const row of linked) {
          await tx.changeLogin(uidOf(row), memberLogin(data.phone, gymId));
          await tx.put(row.path, { ...row.data, phone: data.phone, name: data.name });
        }
        return resultOf(await tx.put(`${root}/members/${memberId}`, old ? { ...old.data, ...data } : { ...data, joinDate: stamp(), status: 'expired', visitsAllowed: 0, visitsUsed: 0, hasLoginAccount: false }));
      }
      if (name === 'member-delete') {
        requireValue(['admin', 'superAdmin'].includes(user.role), 'غير مسموح', 403);
        const member = await loadMember(body.memberId);
        await tx.remove(`${root}/phoneIndex/${member.data.phone}`);
        for (const row of await tx.list('users')) if (row.data.gymId === gymId && row.data.memberId === body.memberId) await tx.remove(row.path);
        await tx.remove(member.path);
        return { deleted: true };
      }
      if (['subscription-freeze', 'subscription-resume'].includes(name)) {
        requireValue(['admin', 'superAdmin'].includes(user.role), 'غير مسموح', 403);
        const member = await loadMember(body.memberId), m = member.data, now = new Date();
        requireValue(m.currentSubscriptionId && m.subscriptionEnd, 'مفيش اشتراك حالي');
        const sub = await tx.get(`${root}/subscriptions/${m.currentSubscriptionId}`);
        requireValue(sub, 'بيانات الاشتراك غير مكتملة', 409);
        let changes;
        if (name === 'subscription-freeze') {
          requireValue(!m.nextSubscription, 'في تجديد قادم؛ راجع موعده قبل التجميد');
          requireValue(m.status !== 'frozen' && date(m.subscriptionEnd) > now && (!m.subscriptionStart || date(m.subscriptionStart) <= now), 'محتاج اشتراك نشط غير مجمد');
          const days=integer(body.days??7,1,gym.freezeMaxDays??30);
          requireValue((sub.data.freezeCount??0)<(gym.freezeMaxTimes??2),'وصلت لعدد مرات التجميد المسموح');
          changes = { status: 'frozen', frozenUntil:stamp(new Date(now.getTime()+days*86400000)), frozenAt: stamp(now), freezeReason: text(body.reason, 'سبب التجميد', 500) };
        } else {
          requireValue(m.status === 'frozen' && m.frozenAt, 'الاشتراك مش مجمد');
          const elapsed = Math.max(0, now - date(m.frozenAt));
          changes = { status: 'active', frozenAt: null, frozenUntil:null, freezeReason: null, subscriptionEnd: stamp(new Date(date(m.subscriptionEnd).getTime() + elapsed)) };
        }
        await tx.put(member.path, { ...m, ...changes });
        await tx.put(sub.path, { ...sub.data, frozenAt: changes.frozenAt, frozenUntil:changes.frozenUntil, freezeCount:(sub.data.freezeCount??0)+(name==='subscription-freeze'?1:0), freezeReason: changes.freezeReason, ...(changes.subscriptionEnd ? { endDate: changes.subscriptionEnd } : {}) });
        return resultOf(await tx.get(member.path));
      }
      if (name === 'subscribe') {
        const member = await loadMember(body.memberId);
        const plan = await tx.get(`${root}/plans/${id(body.planId)}`);
        requireValue(plan && plan.data.isActive !== false, 'الخطة غير موجودة أو متوقفة', 404);
        const paid = money(body.paidAmount, true), price = money(plan.data.price);
        requireValue(paid <= price, 'المدفوع أكبر من سعر الخطة');
        const now = new Date();
        requireValue(member.data.status !== 'frozen', 'فك تجميد الاشتراك قبل التجديد');
        requireValue(!member.data.nextSubscription, 'في تجديد قادم مسجل بالفعل', 409);
        const oldEnd = member.data.subscriptionEnd ? date(member.data.subscriptionEnd) : null;
        const start = body.startAfterCurrent && oldEnd && oldEnd > now ? oldEnd : body.startDate ? date(body.startDate) : now;
        const end = new Date(start.getTime() + integer(plan.data.durationDays, 1, 3650) * 86400000);
        const subId = randomUUID();
        const subscription = { memberId: body.memberId, planId: body.planId, startDate: stamp(start), endDate: stamp(end), paidAmount: paid, createdAt: stamp(now), visitsAllowed: plan.data.visitsAllowed ?? 0, visitsUsed: 0, planName: plan.data.name, price, recordedByUid: user.uid };
        await tx.put(`${root}/subscriptions/${subId}`, subscription);
        const next = { currentPlanId: body.planId, currentSubscriptionId: subId, subscriptionStart: stamp(start), subscriptionEnd: stamp(end), visitsAllowed: subscription.visitsAllowed, visitsUsed: 0, status: start > now ? 'pending' : end < now ? 'expired' : 'active' };
        await tx.put(member.path, start > now && oldEnd && oldEnd > now ? { ...member.data, nextSubscription: next } : { ...member.data, ...next, nextSubscription: null });
        if (paid > 0) await tx.put(`${root}/payments/${randomUUID()}`, { memberId: body.memberId, memberName: member.data.name, amount: paid, date: stamp(now), receiptNumber: `GG-${randomUUID().slice(0, 8).toUpperCase()}`, method: paymentMethod(body.method), recordedBy: user.uid, pointsAwarded:body.requestId?Math.floor(paid/10):0, relatedSubscriptionId: subId });
        if (paid < price) await tx.put(`${root}/debts/${randomUUID()}`, { memberId: body.memberId, memberName: member.data.name, totalAmount: price, paidAmount: paid, createdAt: stamp(now), relatedSubscriptionId: subId, planName: plan.data.name, recordedByUid: user.uid, isPaid: false });
        const earned = body.requestId ? Math.floor(paid / 10) : 0;
        if (earned > 0) {
          const path = `${root}/members/${body.memberId}/loyalty/summary`;
          const points = (await tx.get(path))?.data ?? { totalPoints: 0, lifetimePoints: 0 };
          await tx.put(path, { totalPoints: points.totalPoints + earned, lifetimePoints: points.lifetimePoints + earned });
          await tx.put(`${path}/transactions/${randomUUID()}`, { points: earned, reason: 'دفع اشتراك', date: stamp(now), recordedByUid: user.uid });
        }
        return resultOf(await tx.get(`${root}/subscriptions/${subId}`));
      }
      if (name === 'debt-pay') {
        const debt = await tx.get(`${root}/debts/${id(body.debtId)}`);
        requireValue(debt, 'المديونية غير موجودة', 404);
        const amount = money(body.amount), remaining = Math.round((debt.data.totalAmount - debt.data.paidAmount) * 100) / 100;
        requireValue(amount <= remaining, 'المبلغ أكبر من المتبقي الحالي', 409);
        const newPaid = money(debt.data.paidAmount + amount, true);
        await tx.put(debt.path, { ...debt.data, paidAmount: newPaid, isPaid: newPaid >= debt.data.totalAmount });
        await tx.put(`${root}/payments/${randomUUID()}`, { memberId: debt.data.memberId, memberName: debt.data.memberName, amount, date: stamp(), receiptNumber: `GG-${randomUUID().slice(0, 8).toUpperCase()}`, method: paymentMethod(body.method), recordedBy: user.uid, debtId:body.debtId, relatedSubscriptionId: debt.data.relatedSubscriptionId });
        return { paid: true };
      }
      if (name === 'check-in') {
        const member = await loadMember(body.memberId), m = member.data, now = new Date();
        requireValue(!['frozen','cancelled'].includes(m.status), 'اشتراك العضو مجمد أو ملغي');
        requireValue(m.subscriptionEnd && date(m.subscriptionEnd) >= now, 'اشتراك العضو منتهي');
        requireValue(!m.subscriptionStart || date(m.subscriptionStart) <= now, 'تاريخ بداية الاشتراك لسه ما جاش');
        requireValue(!m.visitsAllowed || (m.visitsUsed ?? 0) < m.visitsAllowed, 'العضو استنفد عدد أيامه');
        const day = cairoDay(now);
        const today = (await tx.list(`${root}/attendance`)).find(r => r.data.memberId === body.memberId && cairoDay(date(r.data.checkInTime)) === day);
        requireValue(!today, 'حضور العضو مسجل النهارده بالفعل', 409);
        const visitsUsed = (m.visitsUsed ?? 0) + 1;
        // Device biometrics verifies the operator, never the selected member's identity.
        const attendance = { memberId: body.memberId, memberName: m.name, checkInTime: stamp(now), checkOutTime: null, biometricVerified: false, recordedByUid: user.uid };
        const row = await tx.put(`${root}/attendance/${randomUUID()}`, attendance);
        await tx.put(member.path, { ...m, visitsUsed });
        if (m.currentSubscriptionId) {
          const sub = await tx.get(`${root}/subscriptions/${m.currentSubscriptionId}`);
          requireValue(sub, 'بيانات الاشتراك غير مكتملة', 409);
          await tx.put(sub.path, { ...sub.data, visitsUsed });
        }
        return resultOf(row);
      }
      if (name === 'check-out') {
        const row = await tx.get(`${root}/attendance/${id(body.attendanceId)}`);
        requireValue(row && !row.data.checkOutTime, 'الحضور غير موجود أو تم تسجيل الخروج', 409);
        await tx.put(row.path, { ...row.data, checkOutTime: stamp() });
        return { checkedOut: true };
      }
      if (['book-class', 'cancel-booking'].includes(name)) {
        const member = await loadMember(body.memberId);
        const row = await tx.get(`${root}/classes/${id(body.classId)}`);
        requireValue(row && !row.data.isCancelled, 'الحصة غير موجودة أو ملغية', 404);
        if(user.role==='staff')this.requirePermission(user,'classes');
        const booked = row.data.bookedMemberIds ?? [];
        requireValue(date(row.data.dateTime) > new Date(), 'الحصة بدأت بالفعل');
        if (name === 'book-class') {
          requireValue(!['frozen','cancelled'].includes(member.data.status), 'الاشتراك مجمد؛ فك التجميد قبل الحجز');
          requireValue(member.data.subscriptionEnd && date(member.data.subscriptionEnd) >= new Date() && (!member.data.subscriptionStart || date(member.data.subscriptionStart) <= new Date()), 'لازم اشتراك ساري عشان تحجز');
          requireValue(!booked.includes(body.memberId), 'محجوز بالفعل', 409);
          requireValue(booked.length < row.data.capacity, 'الحصة مكتملة العدد', 409);
        }
        if(name==='cancel-booking' && user.role==='member')requireValue(date(row.data.dateTime).getTime()-Date.now()>=(gym.bookingCancelHours??0)*3600000,'فترة إلغاء الحجز انتهت، تواصل مع الاستقبال');
        await tx.put(row.path, { ...row.data, bookedMemberIds: name === 'book-class' ? [...booked, body.memberId] : booked.filter(v => v !== body.memberId) });
        return { booked: name === 'book-class' };
      }
      if (['points-add', 'redeem'].includes(name)) {
        await loadMember(body.memberId);
        const loyaltyPath = `${root}/members/${body.memberId}/loyalty/summary`;
        const current = (await tx.get(loyaltyPath))?.data ?? { totalPoints: 0, lifetimePoints: 0 };
        let points, reason, rewardId = null;
        if (name === 'points-add') {
          requireValue(staffRoles.includes(user.role) || user.role === 'superAdmin', 'غير مسموح', 403);
          points = integer(body.points, 1); reason = text(body.reason, 'السبب', 500);
        } else {
          rewardId = id(body.rewardId);
          const reward = await tx.get(`${root}/rewards/${rewardId}`);
          requireValue(reward && reward.data.isActive, 'الهدية غير متاحة', 404);
          points = -integer(reward.data.pointsCost, 1);
          requireValue(current.totalPoints + points >= 0, 'النقاط غير كافية', 409);
          reason = `استبدال: ${reward.data.title}`;
        }
        await tx.put(loyaltyPath, { totalPoints: current.totalPoints + points, lifetimePoints: current.lifetimePoints + Math.max(points, 0) });
        await tx.put(`${loyaltyPath}/transactions/${randomUUID()}`, { points, reason, date: stamp(), rewardId, recordedByUid: user.uid });
        return { redeemed: name === 'redeem' };
      }
      throw new ApiError(404, 'العملية غير موجودة');
    });
  }
  async financialReport(user,body) {
    const gymId=id(body.gymId);
    await this.operational(this.store,user,gymId);
    this.requirePermission(user,'reports');
    const from=body.from==null?null:date(body.from).toISOString(),to=body.to==null?null:date(body.to).toISOString();
    requireValue(!from || !to || from<to,'فترة التقرير غير صحيحة');
    return this.store.financialSummary(gymId,from,to);
  }
  async reception(user, body) {
    const gymId = id(body.gymId);
    await this.operational(this.store, user, gymId);
    this.requirePermission(user,'members');
    const search = typeof body.search === 'string' ? body.search.trim().slice(0, 100) : '';
    const after = body.after ? `gyms/${gymId}/members/${id(body.after)}` : '';
    const rows = await this.store.searchMembers(gymId, search, after);
    const page = rows.slice(0, 25);
    const attendance=await this.store.select(`gyms/${gymId}/attendance`,[{field:'checkInTime',op:'gte',value:stamp(new Date(Date.now()-86400000))}]);
    const debts=user.role!=='staff'||(user.permissions??['collections']).includes('collections')?await this.store.select(`gyms/${gymId}/debts`,[{field:'isPaid',op:'eq',value:false}]):[];
    return { members: page.map(row=>{const result=resultOf(row),today=attendance.find(a=>a.data.memberId===result.id && cairoDay(date(a.data.checkInTime))===cairoDay());return {...result,data:{...result.data,checkedInToday:!!today,todayAttendanceId:today?.path.split('/').at(-1)??null,todayCheckedOut:!!today?.data.checkOutTime,remainingDebt:debts.filter(d=>d.data.memberId===result.id).reduce((sum,d)=>sum+d.data.totalAmount-d.data.paidAmount,0)}};}), next: rows.length > 25 ? uidOf(page.at(-1)) : null };
  }
  async markNotificationsRead(user, body) {
    requireValue(Array.isArray(body.ids) && body.ids.length <= 50, 'الطلبات غير صحيحة');
    await this.store.transaction(async tx => {
      for (const value of body.ids) {
        const path = `users/${user.uid}/notifications/${id(value)}`, row = await tx.get(path);
        if (row) await tx.put(path, { ...row.data, isRead: true });
      }
    });
    return { saved: true };
  }
  async notifications(user) {
    if (!user.gymId) return [];
    const end = stamp(new Date(Date.now() + 3 * 86400000));
    const filters = [{field:'subscriptionEnd',op:'gte',value:stamp()},{field:'subscriptionEnd',op:'lte',value:end}];
    if (user.role === 'member') {
      const row = await this.store.get(`gyms/${user.gymId}/members/${user.memberId}`);
      if (row && !['frozen','cancelled'].includes(row.data.status) && !row.data.nextSubscription && row.data.subscriptionEnd && date(row.data.subscriptionEnd) >= new Date() && date(row.data.subscriptionEnd) <= date(end)) {
        await this.store.transaction(async tx => {
          const path = `users/${user.uid}/notifications/${cairoDay()}-expiry`;
          if (!await tx.get(path)) await tx.put(path, { title:'اشتراكك قرب يخلص',body:'اشتراكك هيخلص خلال 3 أيام، تواصل مع الجيم للتجديد.',date:stamp(),isRead:false });
        });
      }
    } else {
      const members = (await this.store.select(`gyms/${user.gymId}/members`, filters)).filter(r=>!['frozen','cancelled'].includes(r.data.status)&&!r.data.nextSubscription);
      if (members.length) await this.store.transaction(async tx => {
        const path = `users/${user.uid}/notifications/${cairoDay()}-expiry`;
        if (!await tx.get(path)) await tx.put(path,{title:'اشتراكات قربت تخلص',body:`${members.length} عضو اشتراكهم هيخلص خلال 3 أيام`,date:stamp(),isRead:false});
      });
    }
    return (await this.store.select(`users/${user.uid}/notifications`, [], {field:'date',descending:true}, 50)).map(row => ({id:uidOf(row),...row.data}));
  }
}
