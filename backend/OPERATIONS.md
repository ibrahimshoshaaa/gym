# Golden Gym operations (2.4)

New commands persist client operation IDs and atomically record financial entries and audit metadata. Collections are never deleted: reversal/refund adds a negative receipt and retains the original. Plan changes retain the original start date and used visits; a downgrade refunds any excess collected. Cancellation clears remaining debt and allows an explicit refund up to net collected. Only the current or queued subscription can be cancelled.

Administrators configure freeze day and count limits and member booking cancellation cutoff. Freeze defaults to at most 30 days and two uses per subscription. Automatic thaw adds the frozen duration to the end; earlier manual resume adds elapsed duration. Queued renewals must be reviewed before freezing.

Staff access is enforced by the backend, including members, attendance, subscriptions, collections, classes, expenses, loyalty and optional reports. Disabled accounts lose sessions. Recovery codes are hashed, single-use, and must be created while signed in. Gym admins reset staff; system owners reset gym admins. Members reset through their gym administrator to their phone and choose a new password on first login.

## Photos

Production needs CLOUDINARY_CLOUD_NAME, CLOUDINARY_API_KEY and CLOUDINARY_API_SECRET for signed upload/replacement and actual storage deletion. No private API secret goes to the app. Legacy unsigned installations remain compatible while upgrading.

## Encrypted backups

The server implements a daily 02:00 UTC Vercel cron and owner-only manual backup/download. Activation requires CRON_SECRET and a 32-byte base64 BACKUP_ENCRYPTION_KEY plus the three private Cloudinary settings. Deployment alone does not activate backups without those variables.

Backups are AES-256-GCM encrypted before authenticated raw storage upload and retain 14 successful daily snapshots. A failed upload preserves a previous successful same-day snapshot. Files include all gyms, account hashes and recovery hashes, excluding sessions. Preserve the key independently: losing it makes snapshots unusable.

Use BACKUP_ENCRYPTION_KEY with `node scripts/decrypt-backup.js <snapshot.ggbackup> <private-snapshot.json>`. Then use a NEW EMPTY direct Postgres DATABASE_URL_UNPOOLED with `node scripts/restore.js <private-snapshot.json>`. Restore refuses overwriting existing data. Never commit keys or decoded snapshots. The plaintext manual scripts remain available for private offline use.

## Device notifications

There is no Firebase dependency. Saved notifications have per-user read state. Subscription and booked-class reminders schedule on the device in Cairo time after foreground synchronization. Optional Android WorkManager polling fetches new alerts approximately every 15 minutes with network access; Android battery restrictions may delay it. This is periodic synchronization, not realtime push. Logout cancels local reminders and background work.
