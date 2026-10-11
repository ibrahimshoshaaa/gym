import { readFile } from 'node:fs/promises';

export class PostgresStore {
  constructor(pool, connection = pool) { this.pool = pool; this.connection = connection; }
  async migrate() {
    const sql = await readFile(new URL('./schema.sql', import.meta.url), 'utf8');
    // Cold starts can initialize several API replicas at the same time.
    await this.transaction(tx => tx.connection.query(sql));
  }
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
  async select(collection, filters = [], order = null, count = null) {
    const params = [collection], clauses = ['collection_path=$1'];
    const bind = value => { params.push(value); return `$${params.length}`; };
    for (const f of filters) {
      const field = bind(f.field), expr = `(data->${field})`;
      if (f.op === 'in') clauses.push(`(${f.value.map(v => `${expr}=${bind(JSON.stringify(v))}::jsonb`).join(' OR ') || 'false'})`);
      else clauses.push(`${expr}${{eq:'=',gte:'>=',lte:'<='}[f.op]}${bind(JSON.stringify(f.value))}::jsonb`);
    }
    let sorting = 'path ASC';
    if (order) sorting = `data->${bind(order.field)} ${order.descending ? 'DESC' : 'ASC'}, path ${order.descending ? 'DESC' : 'ASC'}`;
    const limit = count == null ? '' : ` LIMIT ${bind(count)}`;
    const { rows } = await this.connection.query(`SELECT path,data,version FROM documents WHERE ${clauses.join(' AND ')} ORDER BY ${sorting}${limit}`, params);
    return rows;
  }
  async financialSummary(gymId, from, to) {
    const root=`gyms/${gymId}`, time=field=>`($2::timestamptz IS NULL OR (data->'${field}'->>'value')::timestamptz >= $2) AND ($3::timestamptz IS NULL OR (data->'${field}'->>'value')::timestamptz < $3)`;
    const incoming=await this.connection.query(`SELECT COALESCE(sum((data->>'amount')::numeric),0) AS total,count(*)::int AS count FROM documents WHERE collection_path=$1 AND ${time('date')}`,[`${root}/payments`,from,to]);
    const outgoing=await this.connection.query(`SELECT COALESCE(sum((data->>'amount')::numeric),0) AS total FROM documents WHERE collection_path=$1 AND ${time('date')}`,[`${root}/expenses`,from,to]);
    const contracts=await this.connection.query(`SELECT COALESCE(sum(COALESCE((s.data->>'price')::numeric,(SELECT (d.data->>'totalAmount')::numeric FROM documents d WHERE d.collection_path=$4 AND d.data->>'relatedSubscriptionId'=split_part(s.path,'/',4) LIMIT 1),(s.data->>'paidAmount')::numeric)),0) AS total FROM documents s WHERE collection_path=$1 AND ${time('createdAt')}`,[`${root}/subscriptions`,from,to,`${root}/debts`]);
    const debt=await this.connection.query(`SELECT COALESCE(sum(GREATEST((data->>'totalAmount')::numeric-(data->>'paidAmount')::numeric,0)),0) AS total FROM documents WHERE collection_path=$1`,[`${root}/debts`]);
    const collected=Number(incoming.rows[0].total), spent=Number(outgoing.rows[0].total);
    return {collected,spent,netCash:collected-spent,collectionsCount:incoming.rows[0].count,subscriptionValue:Number(contracts.rows[0].total),outstanding:Number(debt.rows[0].total)};
  }
  async searchMembers(gymId, search, after = '') {
    const escaped = search.replace(/[\\%_]/g, '\\$&');
    const { rows } = await this.connection.query(`SELECT path,data,version FROM documents WHERE collection_path=$1 AND path>$2 AND (data->>'name' ILIKE $3 OR data->>'phone' ILIKE $3) ORDER BY path LIMIT 26`, [`gyms/${gymId}/members`, after, `%${escaped}%`]);
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
