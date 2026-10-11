import { randomBytes, scrypt as scryptCallback, timingSafeEqual, createHash } from 'node:crypto';
import { promisify } from 'node:util';
const scrypt = promisify(scryptCallback);
export class ApiError extends Error {
  constructor(status, message) { super(message); this.status = status; }
}
export function requireValue(condition, message, status = 400) { if (!condition) throw new ApiError(status, message); }
export function text(value, label, max = 200) {
  requireValue(typeof value === 'string' && value.trim().length > 0 && value.length <= max, `${label} غير صحيح`);
  return value.trim();
}
export function id(value) { const v = text(value, 'المعرّف', 100); requireValue(/^[a-zA-Z0-9_+.-]+$/.test(v), 'المعرّف غير صحيح'); return v; }
export function phone(value) { const p = text(value, 'الموبايل').replace(/[\s()-]/g, '').replace(/^\+20/, '0'); requireValue(/^01[0125][0-9]{8}$/.test(p), 'رقم الموبايل غير صحيح'); return p; }
export function email(value) { const v = text(value, 'الإيميل').toLowerCase(); requireValue(/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(v), 'الإيميل غير صحيح'); return v; }
export function money(value, allowZero = false) {
  requireValue(typeof value === 'number' && Number.isFinite(value) && value >= (allowZero ? 0 : 0.01) && value <= 1e8 && Math.abs(value * 100 - Math.round(value * 100)) < 1e-6, 'المبلغ غير صحيح');
  return Math.round(value * 100) / 100;
}
export function integer(value, min = 0, max = 1e6) { requireValue(Number.isInteger(value) && value >= min && value <= max, 'القيمة غير صحيحة'); return value; }
export function stamp(value = new Date()) { return { __type: 'timestamp', value: new Date(value).toISOString() }; }
export function date(value) {
  const result = new Date(value?.__type === 'timestamp' ? value.value : value);
  requireValue(value != null && Number.isFinite(result.getTime()), 'التاريخ غير صحيح'); return result;
}
export function hash(value) { return createHash('sha256').update(value).digest('hex'); }
export async function passwordHash(password) {
  requireValue(typeof password === 'string' && password.length >= 8 && password.length <= 256, 'الباسورد لازم يكون من 8 إلى 256 حرف');
  const salt = randomBytes(16).toString('hex');
  const derived = await scrypt(password, salt, 64);
  return `${salt}:${derived.toString('hex')}`;
}
export async function verifyPassword(password, stored) {
  if (typeof password !== 'string' || password.length > 256) return false;
  const [salt, derived] = stored.split(':');
  const actual = await scrypt(password, salt, 64);
  const expected = Buffer.from(derived, 'hex');
  return expected.length === actual.length && timingSafeEqual(expected, actual);
}
export function temporaryPassword() { return randomBytes(12).toString('base64url'); }
