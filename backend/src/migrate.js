import pg from 'pg';
import { PostgresStore } from './postgres.js';
if (!process.env.DATABASE_URL) throw new Error('DATABASE_URL is required');
const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL });
try { await new PostgresStore(pool).migrate(); console.log('Database schema ready'); }
finally { await pool.end(); }
