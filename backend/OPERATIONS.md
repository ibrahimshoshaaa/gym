# Operational changes

Member account recovery is performed by the gym administrator from the member profile. It resets the password to the stored phone, revokes existing sessions, and requires a different password on next login. Admin/owner recovery is not a public password-reset endpoint.

New clients persist an operation ID before submitting a command. Ambiguous retries use the same ID; the server atomically returns the committed result, and rejects reuse with a changed payload. Old clients remain compatible but do not have the retry guarantee. Payment points are awarded by the server only for new requests with an operation ID; old clients keep their previous points flow.

Early renewal queues one next subscription and leaves the current subscription and visits available until the next start. Freeze is indefinite until administrator resume; resume adds elapsed frozen time to the end. Queued renewals must be reviewed before freezing.

## Photos

Existing unsigned uploads continue while upgrading. Unique image IDs avoid the old assumption that unsigned uploads overwrite existing images. Configure `CLOUDINARY_CLOUD_NAME`, `CLOUDINARY_API_KEY`, `CLOUDINARY_API_SECRET` on the backend to enable signed replacement and actual storage deletion. The secret is never sent to the app. Legacy preset can be configured with `GYM_CLOUDINARY_UPLOAD_PRESET`.

## Backups

Use a direct connection in `DATABASE_URL_UNPOOLED`. `node scripts/backup.js <private-file.json>` creates a consistent backup; preserve it in private encrypted storage. It contains account password hashes and member data. Do not commit or upload it to public CI artifacts.

`node scripts/restore.js <private-file.json>` restores into an empty database only. It refuses overwrites, restores atomically and omits sessions so users must sign in again. The automated integration suite tests restore to an isolated PostgreSQL database. Production backup scheduling and retention require deployment/account configuration; these scripts do not claim that scheduled backups are active.

Notifications are stored per user, with read state. They are in-app reminders, not background push notifications.
