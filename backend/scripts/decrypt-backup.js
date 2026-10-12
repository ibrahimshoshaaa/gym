import {readFile,writeFile} from 'node:fs/promises';
import {decryptBackup} from '../src/operations/cloud-backups.js';
const [input,output]=process.argv.slice(2);
if(!input||!output||!process.env.BACKUP_ENCRYPTION_KEY)throw new Error('Usage: BACKUP_ENCRYPTION_KEY=<private key> node scripts/decrypt-backup.js <encrypted.ggbackup> <private-output.json>');
const data=decryptBackup(await readFile(input),process.env.BACKUP_ENCRYPTION_KEY);
await writeFile(output,JSON.stringify(data),{mode:0o600,flag:'wx'});console.log('Backup decrypted; restore only into a new empty database.');
