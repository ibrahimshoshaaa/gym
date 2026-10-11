import { readFile } from 'node:fs/promises';

export class PostgresStore {
  constructor(pool, connection = pool) { this.pool = pool; this.connection = connection; }
  async migrate() { await this.pool.query(await readFile(new URL('./schema.sql', import.meta.url), 'utf8')); }
  async health() { await this.pool.query('SELECT 1'); }
  async transaction(work) {
    const client = await this.pool.connect();
    try {
      await client.query('BEGIN');
      // Serialize business writes across API replicas, including absent-record uniqueness checks.
      await client.query('SELECT pg_advisory_xact_lock(728391)');
      const result = await work(new PostgresStore(this.pool, client));
      await client.query('COMMIT');
      return result;
    } catch (error) { await client.query('ROLLBACK'); throw error; }
    finally { client.release(); }
  }
  async get(path) {
    const { rows } = await this.connection.query('SELECT path, data, version FROM documents WHERE path=$1', [path]);
    return rows[0] ?? null;
  }
  async list(collection) {
    const { rows } = await this.connection.query('SELECT path, data, version FROM documents WHERE collection_path=$1', [collection]);
    return rows;
  }
  async put(path, data) {
    const collection = path.slice(0, path.lastIndexOf('/'));
    await this.connection.query(`INSERT INTO documents(path,collection_path,data) VALUES($1,$2,$3)
      ON CONFLICT(path) DO UPDATE SET data=EXCLUDED.data, version=documents.version+1, updated_at=now()`, [path, collection, data]);
    return this.get(path);
  }
  async remove(path) { await this.connection.query('DELETE FROM documents WHERE path=$1', [path]); }
  async account(login) {
    const { rows } = await this.connection.query('SELECT * FROM accounts WHERE login=$1', [login]);
    return rows[0] ?? null;
  }
  async addAccount(uid, login, passwordHash) {
    await this.connection.query('INSERT INTO accounts(uid,login,password_hash) VALUES($1,$2,$3)', [`users/${uid}`, login, passwordHash]);
  }
  async changePassword(uid, hash) {
    await this.connection.query('UPDATE accounts SET password_hash=$2 WHERE uid=$1', [`users/${uid}`, hash]);
  }
  async changeLogin(uid, login) { await this.connection.query('UPDATE accounts SET login=$2 WHERE uid=$1', [`users/${uid}`, login]); }
  async addSession(tokenHash, uid, expiry) {
    await this.connection.query('INSERT INTO sessions(token_hash,uid,expires_at) VALUES($1,$2,$3)', [tokenHash, `users/${uid}`, expiry]);
  }
  async session(tokenHash) {
    const { rows } = await this.connection.query('SELECT uid FROM sessions WHERE token_hash=$1 AND expires_at>now()', [tokenHash]);
    return rows[0]?.uid.split('/')[1] ?? null;
  }
  async removeSession(hash) { await this.connection.query('DELETE FROM sessions WHERE token_hash=$1', [hash]); }
  async revokeSessions(uid, except = '') {
    await this.connection.query('DELETE FROM sessions WHERE uid=$1 AND token_hash<>$2', [`users/${uid}`, except]);
  }
  async attempt(key) {
    const { rows } = await this.connection.query(`INSERT INTO auth_attempts(key,attempts,window_start) VALUES($1,1,now())
      ON CONFLICT(key) DO UPDATE SET attempts=CASE WHEN auth_attempts.window_start<now()-interval '15 minutes' THEN 1 ELSE auth_attempts.attempts+1 END,
      window_start=CASE WHEN auth_attempts.window_start<now()-interval '15 minutes' THEN now() ELSE auth_attempts.window_start END RETURNING attempts`, [key]);
    return rows[0].attempts;
  }
  async clearAttempt(key) { await this.connection.query('DELETE FROM auth_attempts WHERE key=$1', [key]); }
  async cleanup() {
    await this.connection.query('DELETE FROM sessions WHERE expires_at<now()');
    await this.connection.query("DELETE FROM auth_attempts WHERE window_start<now()-interval '1 day'");
  }
}
