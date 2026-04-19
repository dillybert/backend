-- +goose Up

CREATE TABLE users (
    id         BIGSERIAL PRIMARY KEY,
    role       VARCHAR(20) NOT NULL
                   CHECK (role IN ('customer', 'partner', 'admin')),
    is_active  BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE sessions (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id    BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    user_agent TEXT,
    ip_address INET,
    expires_at TIMESTAMPTZ NOT NULL,
    revoked_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_sessions_user_active
    ON sessions(user_id)
    WHERE revoked_at IS NULL;

CREATE INDEX idx_sessions_expires
    ON sessions(expires_at)
    WHERE revoked_at IS NULL;

-- +goose Down

DROP INDEX IF EXISTS idx_sessions_expires;
DROP INDEX IF EXISTS idx_sessions_user_active;
DROP TABLE IF EXISTS sessions;
DROP TABLE IF EXISTS users;
