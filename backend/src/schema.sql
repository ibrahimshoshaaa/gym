CREATE TABLE IF NOT EXISTS documents (
  path text PRIMARY KEY,
  collection_path text NOT NULL,
  data jsonb NOT NULL,
  version bigint NOT NULL DEFAULT 1,
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS documents_collection ON documents(collection_path);
CREATE INDEX IF NOT EXISTS documents_gym ON documents((data->>'gymId')) WHERE collection_path = 'users';
CREATE TABLE IF NOT EXISTS accounts (
  uid text PRIMARY KEY REFERENCES documents(path) ON DELETE CASCADE,
  login text UNIQUE NOT NULL,
  password_hash text NOT NULL
);
CREATE TABLE IF NOT EXISTS sessions (
  token_hash text PRIMARY KEY,
  uid text NOT NULL REFERENCES accounts(uid) ON DELETE CASCADE,
  expires_at timestamptz NOT NULL
);
CREATE INDEX IF NOT EXISTS sessions_expiry ON sessions(expires_at);
CREATE TABLE IF NOT EXISTS auth_attempts (
  key text PRIMARY KEY,
  attempts integer NOT NULL,
  window_start timestamptz NOT NULL
);
