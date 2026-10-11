import { requireValue } from './security.js';
export async function snapshot(store) {
  return store.transaction(async tx=>({format:'golden-gym-backup-v1',createdAt:new Date().toISOString(),documents:(await tx.connection.query('SELECT path,collection_path,data,version,updated_at FROM documents ORDER BY path')).rows,accounts:(await tx.connection.query('SELECT uid,login,password_hash FROM accounts ORDER BY uid')).rows}));
}
export async function restoreEmpty(store,backup) {
  requireValue(backup?.format==='golden-gym-backup-v1' && Array.isArray(backup.documents) && Array.isArray(backup.accounts),'صيغة النسخة الاحتياطية غير صحيحة');
  return store.transaction(async tx=>{
    const existing=(await tx.connection.query('SELECT count(*)::int AS count FROM documents')).rows[0].count;
    requireValue(existing===0,'الاسترجاع مسموح لقاعدة فارغة فقط');
    for(const row of backup.documents){
      requireValue(typeof row.path==='string' && row.collection_path===row.path.slice(0,row.path.lastIndexOf('/')) && row.data && typeof row.data==='object','سجل النسخة غير صحيح');
      await tx.connection.query('INSERT INTO documents(path,collection_path,data,version,updated_at) VALUES($1,$2,$3,$4,$5)',[row.path,row.collection_path,row.data,row.version,row.updated_at]);
    }
    for(const row of backup.accounts)await tx.connection.query('INSERT INTO accounts(uid,login,password_hash) VALUES($1,$2,$3)',[row.uid,row.login,row.password_hash]);
    return {records:backup.documents.length,accounts:backup.accounts.length};
  });
}
