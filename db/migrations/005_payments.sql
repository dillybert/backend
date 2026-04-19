-- +goose Up

CREATE TYPE payment_status AS ENUM (
    'pending',
    'paid',
    'failed',
    'cancelled',
    'refunded'
);

CREATE TABLE payments (
    id                 BIGSERIAL PRIMARY KEY,
    order_id           BIGINT NOT NULL REFERENCES orders(id),
    idempotency_key    VARCHAR(255) NOT NULL UNIQUE,
    gateway            VARCHAR(50) NOT NULL DEFAULT 'apipay',
    gateway_invoice_id TEXT,
    amount             NUMERIC(10,2) NOT NULL CHECK (amount > 0),
    status             payment_status NOT NULL DEFAULT 'pending',
    paid_at            TIMESTAMPTZ,
    created_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at         TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Частичный UNIQUE: только один успешный платёж на заказ.
-- Обычный UNIQUE(order_id) блокировал бы retry после failed.
CREATE UNIQUE INDEX idx_payments_order_paid
    ON payments(order_id)
    WHERE status = 'paid';

CREATE TABLE webhook_events (
    id           BIGSERIAL PRIMARY KEY,
    gateway      VARCHAR(50) NOT NULL,
    event_id     TEXT NOT NULL UNIQUE,
    event_type   TEXT NOT NULL,
    payload      JSONB NOT NULL,
    processed_at TIMESTAMPTZ,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_webhook_unprocessed
    ON webhook_events(created_at)
    WHERE processed_at IS NULL;

-- +goose Down

DROP INDEX IF EXISTS idx_webhook_unprocessed;
DROP TABLE IF EXISTS webhook_events;
DROP INDEX IF EXISTS idx_payments_order_paid;
DROP TABLE IF EXISTS payments;
DROP TYPE IF EXISTS payment_status;
