import pg from 'pg';
import {readFile} from 'node:fs/promises';
import {PostgresStore} from '../src/postgres.js';
import {restoreEmpty} from '../src/backup.js';
const input=process.argv[2];
if(!input || !process.env.DATABASE_URL_UNPOOLED)throw new Error('Usage: DATABASE_URL_UNPOOLED=<new empty direct database URL> node scripts/restore.js <backup.json>');
const pool=new pg.Pool({connectionString:process.env.DATABASE_URL_UNPOOLED});
try{const store=new PostgresStore(pool);await store.migrate();console.log(await restoreEmpty(store,JSON.parse(await readFile(input,'utf8'))));}finally{await pool.end();}
