// Run with a DIRECT DATABASE_URL_UNPOOLED. Backup includes account hashes and must stay private.
import pg from 'pg';
import { writeFile } from 'node:fs/promises';
const output=process.argv[2];
if (!output || !process.env.DATABASE_URL_UNPOOLED) throw new Error('Usage: DATABASE_URL_UNPOOLED=<direct URL> node scripts/backup.js <private-output.json>');
const pool=new pg.Pool({connectionString:process.env.DATABASE_URL_UNPOOLED});
const client=await pool.connect();
try {
  await client.query('BEGIN ISOLATION LEVEL REPEATABLE READ READ ONLY');
  const documents=(await client.query('SELECT path,collection_path,data,version,updated_at FROM documents ORDER BY path')).rows;
  const accounts=(await client.query('SELECT uid,login,password_hash FROM accounts ORDER BY uid')).rows;
  await writeFile(output,JSON.stringify({format:'golden-gym-backup-v1',createdAt:new Date().toISOString(),documents,accounts},null,2),{mode:0o600,flag:'wx'});
  await client.query('COMMIT');
  console.log(`Saved ${documents.length} records and ${accounts.length} accounts. Sessions excluded.`);
} finally {client.release();await pool.end();}
