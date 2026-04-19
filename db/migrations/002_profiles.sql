-- +goose Up

CREATE TABLE customers (
    id          BIGSERIAL PRIMARY KEY,
    user_id     BIGINT NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    telegram_id BIGINT NOT NULL UNIQUE,
    first_name  TEXT,
    last_name   TEXT,
    username    TEXT,
    phone       VARCHAR(20),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_customers_telegram ON customers(telegram_id);

CREATE TABLE partners (
    id              BIGSERIAL PRIMARY KEY,
    user_id         BIGINT NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    partner_code    VARCHAR(50) NOT NULL UNIQUE,
    password_hash   TEXT NOT NULL,
    must_change_pwd BOOLEAN NOT NULL DEFAULT true,
    last_login_at   TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE admins (
    id            BIGSERIAL PRIMARY KEY,
    user_id       BIGINT NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    username      VARCHAR(100) NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- +goose Down

DROP TABLE IF EXISTS admins;
DROP TABLE IF EXISTS partners;
DROP INDEX IF EXISTS idx_customers_telegram;
DROP TABLE IF EXISTS customers;
