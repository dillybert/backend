-- +goose Up

CREATE TABLE ledger_entries (
    id            BIGSERIAL PRIMARY KEY,
    restaurant_id BIGINT NOT NULL REFERENCES restaurants(id),
    order_id      BIGINT REFERENCES orders(id),
    payout_id     BIGINT,
    entry_type    VARCHAR(10) NOT NULL CHECK (entry_type IN ('credit', 'debit')),
    amount        NUMERIC(10,2) NOT NULL CHECK (amount > 0),
    description   TEXT,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_ledger_restaurant ON ledger_entries(restaurant_id);
CREATE INDEX idx_ledger_order      ON ledger_entries(order_id);

CREATE TABLE payouts (
    id            BIGSERIAL PRIMARY KEY,
    restaurant_id BIGINT NOT NULL REFERENCES restaurants(id),
    amount        NUMERIC(10,2) NOT NULL CHECK (amount > 0),
    period_from   DATE NOT NULL,
    period_to     DATE NOT NULL,
    CONSTRAINT chk_payout_period CHECK (period_to >= period_from),
    status        VARCHAR(20) NOT NULL DEFAULT 'pending'
                      CHECK (status IN ('pending', 'paid', 'failed')),
    paid_at       TIMESTAMPTZ,
    note          TEXT,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE ledger_entries
    ADD CONSTRAINT fk_ledger_payout
    FOREIGN KEY (payout_id) REFERENCES payouts(id) ON DELETE SET NULL;

-- +goose Down

ALTER TABLE ledger_entries DROP CONSTRAINT IF EXISTS fk_ledger_payout;
DROP TABLE IF EXISTS payouts;
DROP INDEX IF EXISTS idx_ledger_order;
DROP INDEX IF EXISTS idx_ledger_restaurant;
DROP TABLE IF EXISTS ledger_entries;
