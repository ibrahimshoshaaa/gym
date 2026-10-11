import { createServer } from 'node:http';
import { ApiError, requireValue, hash } from './security.js';

async function readBody(request) {
  let size = 0; const chunks = [];
  for await (const chunk of request) {
    size += chunk.length; requireValue(size <= 256 * 1024, 'الطلب أكبر من المسموح', 413); chunks.push(chunk);
  }
  try { const body = JSON.parse(Buffer.concat(chunks).toString() || '{}'); requireValue(body && typeof body === 'object' && !Array.isArray(body), 'طلب غير صحيح'); return body; }
  catch (error) { if (error instanceof ApiError) throw error; throw new ApiError(400, 'طلب غير صحيح'); }
}
export function createApp(service, options = {}) {
  const origins = new Set(options.corsOrigins ?? []);
  return createServer(async (req, res) => {
    res.setHeader('Content-Type', 'application/json; charset=utf-8');
    res.setHeader('Cache-Control', 'no-store');
    res.setHeader('X-Content-Type-Options', 'nosniff');
    const origin = req.headers.origin;
    if (origin && origins.has(origin)) { res.setHeader('Access-Control-Allow-Origin', origin); res.setHeader('Vary', 'Origin'); res.setHeader('Access-Control-Allow-Headers', 'Authorization, Content-Type'); res.setHeader('Access-Control-Allow-Methods', 'GET, POST, DELETE, OPTIONS'); }
    try {
      if (origin) requireValue(origins.has(origin), 'المصدر غير مسموح', 403);
      if (req.method === 'OPTIONS') { res.writeHead(204).end(); return; }
      const path = new URL(req.url, 'http://localhost').pathname;
      if (req.method === 'GET' && path === '/health') { await service.store.health(); res.end(JSON.stringify({ status: 'ok' })); return; }
      const body = req.method === 'POST' ? await readBody(req) : {};
      let output;
      if (req.method === 'POST' && path === '/api/auth/login') output = await service.login(body, req.socket.remoteAddress ?? 'unknown');
      else if (req.method === 'POST' && path === '/api/auth/signup') {
        requireValue(await service.store.attempt(hash(`signup:${req.socket.remoteAddress}`)) <= 5, 'محاولات كتير، حاول بعد 15 دقيقة', 429);
        output = await service.signup(body);
      } else {
        const user = await service.authenticate(req.headers.authorization?.replace(/^Bearer /, ''));
        if (req.method === 'GET' && path === '/api/auth/me') output = await service.me(user);
        else if (req.method === 'POST' && path === '/api/auth/password') output = await service.changePassword(user, body);
        else if (req.method === 'POST' && path === '/api/auth/logout') { await service.store.removeSession(user.tokenHash); output = { loggedOut: true }; }
        else {
          requireValue(!user.mustChangePassword, 'غيّر الباسورد الأول', 403);
          if (req.method === 'POST' && path === '/api/auth/gym-owner') output = await service.signup(body, user);
          else if (req.method === 'POST' && path === '/api/auth/staff') output = await service.createStaff(user, body);
          else if (req.method === 'POST' && path === '/api/auth/member-account') output = await service.createMemberAccount(user, body);
          else if (req.method === 'DELETE' && path.startsWith('/api/auth/staff/')) output = await service.deleteStaff(user, path.split('/').at(-1));
          else if (req.method === 'POST' && path === '/api/data/read') output = await service.read(user, body.path);
          else if (req.method === 'POST' && path === '/api/data/query') output = await service.query(user, body);
          else if (req.method === 'POST' && path === '/api/data/write') output = await service.write(user, body);
          else if (req.method === 'POST' && path.startsWith('/api/commands/')) output = await service.command(user, path.split('/').at(-1), body);
          else if (req.method === 'GET' && path === '/api/notifications') output = await service.notifications(user);
          else throw new ApiError(404, 'المسار غير موجود');
        }
      }
      res.end(JSON.stringify({ data: output }));
    } catch (error) {
      const status = error instanceof ApiError ? error.status : error.code === '23505' ? 409 : 500;
      if (status === 500) console.error('API request failed:', error.code ?? error.name);
      res.statusCode = status;
      res.end(JSON.stringify({ error: status === 500 ? 'حصل خطأ في الخدمة، حاول تاني' : error.code === '23505' ? 'البيانات مستخدمة بالفعل' : error.message }));
    }
  });
}
