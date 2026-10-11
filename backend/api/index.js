import pg from 'pg';
import { attachDatabasePool } from '@vercel/functions';
import { PostgresStore } from '../src/postgres.js';
import { GymService } from '../src/service.js';
import { createHandler } from '../src/http.js';

if (!process.env.DATABASE_URL) throw new Error('DATABASE_URL is required');
const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL, max: 5, connectionTimeoutMillis: 10000, idleTimeoutMillis: 10000 });
attachDatabasePool(pool);
pool.on('error', error => console.error('Database connection failed:', error.code ?? error.name));
let initializing;
function handler() {
  initializing ??= (async () => {
    const store = new PostgresStore(pool);
    await store.migrate();
    const service = new GymService(store, { allowSignup: process.env.ALLOW_SIGNUP === 'true' });
    await service.bootstrap({ email: process.env.BOOTSTRAP_ADMIN_EMAIL, password: process.env.BOOTSTRAP_ADMIN_PASSWORD, name: process.env.BOOTSTRAP_ADMIN_NAME, mustChangePassword: true });
    await service.migratePendingMemberPasswords();
    await store.cleanup();
    return createHandler(service, { corsOrigins: (process.env.CORS_ORIGINS ?? '').split(',').filter(Boolean) });
  })().catch(error => { initializing = undefined; throw error; });
  return initializing;
}
export default async function api(request, response) {
  const route = new URL(request.url, 'https://localhost').searchParams.get('__route');
  if (route !== null) request.url = `/${route}`;
  try { await (await handler())(request, response); }
  catch (error) {
    console.error('API initialization failed:', error.code ?? error.name);
    response.statusCode = 503;
    response.setHeader('Content-Type', 'application/json; charset=utf-8');
    response.setHeader('Cache-Control', 'no-store');
    response.setHeader('Retry-After', '5');
    response.end(JSON.stringify({ error: 'الخدمة بتجهز، حاول تاني بعد ثواني' }));
  }
}
