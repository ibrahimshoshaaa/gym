import pg from 'pg';
import { PostgresStore } from './postgres.js';
import { GymService } from './service.js';
import { createApp } from './http.js';
if (!process.env.DATABASE_URL) throw new Error('DATABASE_URL is required');
const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL, max: 10, connectionTimeoutMillis: 10000 });
const store = new PostgresStore(pool);
await store.migrate();
const service = new GymService(store, { allowSignup: process.env.ALLOW_SIGNUP !== 'false' });
await service.bootstrap({ email: process.env.BOOTSTRAP_ADMIN_EMAIL, password: process.env.BOOTSTRAP_ADMIN_PASSWORD, name: process.env.BOOTSTRAP_ADMIN_NAME });
await service.migratePendingMemberPasswords();
const server = createApp(service, { corsOrigins: (process.env.CORS_ORIGINS ?? '').split(',').filter(Boolean) });
const cleanup = setInterval(() => store.cleanup().catch(() => console.error('Session cleanup failed')), 3600000);
cleanup.unref();
server.requestTimeout = 15000;
server.headersTimeout = 10000;
server.listen(Number(process.env.PORT ?? 3000), '0.0.0.0', () => console.log('Gym API ready'));
async function stop() { clearInterval(cleanup); server.close(async () => { await pool.end(); process.exit(0); }); }
process.on('SIGTERM', stop); process.on('SIGINT', stop);
