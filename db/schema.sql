-- ============================================
-- IDENTITY LAYER
-- ============================================

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

-- ============================================
-- CUSTOMER PROFILE
-- ============================================

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

-- ============================================
-- PARTNER PROFILE
-- ============================================

CREATE TABLE partners (
    id              BIGSERIAL PRIMARY KEY,
    user_id         BIGINT NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    partner_code    VARCHAR(50) NOT NULL UNIQUE,
    password_hash   TEXT NOT NULL,
    must_change_pwd BOOLEAN NOT NULL DEFAULT true,
    last_login_at   TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================
-- ADMIN PROFILE
-- ============================================

CREATE TABLE admins (
    id            BIGSERIAL PRIMARY KEY,
    user_id       BIGINT NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    username      VARCHAR(100) NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================
-- CATALOG LAYER
-- ============================================

CREATE TABLE restaurants (
    id               BIGSERIAL PRIMARY KEY,
    -- UNIQUE убран: один партнёр может иметь несколько заведений
    partner_id       BIGINT NOT NULL REFERENCES partners(id),
    name             TEXT NOT NULL,
    description      TEXT,
    address          TEXT,
    phone            VARCHAR(20),
    logo_url         TEXT,
    cover_url        TEXT,
    commission_tier  VARCHAR(20) NOT NULL DEFAULT 'onboarding'
                         CHECK (commission_tier IN (
                             'onboarding',
                             'basic',
                             'standard',
                             'partner'
                         )),
    commission_rate  NUMERIC(4,2) NOT NULL DEFAULT 0.00,
    is_active        BOOLEAN NOT NULL DEFAULT false,
    is_open          BOOLEAN NOT NULL DEFAULT false,
    onboarding_ends_at TIMESTAMPTZ,
    -- Soft delete: история заказов не ломается при уходе партнёра
    deleted_at       TIMESTAMPTZ,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_restaurants_partner
    ON restaurants(partner_id);

CREATE INDEX idx_restaurants_active
    ON restaurants(id)
    WHERE deleted_at IS NULL;

-- Часы работы ресторана
CREATE TABLE restaurant_hours (
    id            BIGSERIAL PRIMARY KEY,
    restaurant_id BIGINT NOT NULL REFERENCES restaurants(id) ON DELETE CASCADE,
    day_of_week   SMALLINT NOT NULL CHECK (day_of_week BETWEEN 0 AND 6),
    opens_at      TIME NOT NULL,
    closes_at     TIME NOT NULL,
    is_closed     BOOLEAN NOT NULL DEFAULT false,
    UNIQUE (restaurant_id, day_of_week)
);

CREATE TABLE restaurant_categories (
    id            BIGSERIAL PRIMARY KEY,
    restaurant_id BIGINT NOT NULL REFERENCES restaurants(id) ON DELETE CASCADE,
    name          TEXT NOT NULL,
    sort_order    INT NOT NULL DEFAULT 0,
    is_active     BOOLEAN NOT NULL DEFAULT true
);

CREATE TABLE menu_items (
    id            BIGSERIAL PRIMARY KEY,
    restaurant_id BIGINT NOT NULL REFERENCES restaurants(id) ON DELETE CASCADE,
    category_id   BIGINT REFERENCES restaurant_categories(id) ON DELETE SET NULL,
    name          TEXT NOT NULL,
    description   TEXT,
    price         NUMERIC(10,2) NOT NULL CHECK (price >= 0),
    image_url     TEXT,
    is_available  BOOLEAN NOT NULL DEFAULT true,
    sort_order    INT NOT NULL DEFAULT 0,
    deleted_at    TIMESTAMPTZ,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_menu_items_restaurant
    ON menu_items(restaurant_id)
    WHERE deleted_at IS NULL;

-- ============================================
-- ORDERS LAYER
-- ============================================

CREATE TYPE order_status AS ENUM (
    'pending',
    'paid',
    'confirmed',
    'preparing',
    'delivering',
    'completed',
    'cancelled'
);

CREATE TABLE orders (
    id               BIGSERIAL PRIMARY KEY,
    customer_id      BIGINT NOT NULL REFERENCES customers(id),
    restaurant_id    BIGINT NOT NULL REFERENCES restaurants(id),
    status           order_status NOT NULL DEFAULT 'pending',
    delivery_address TEXT NOT NULL,
    -- Финансовый снапшот момента заказа
    subtotal         NUMERIC(10,2) NOT NULL CHECK (subtotal >= 0),
    delivery_fee     NUMERIC(10,2) NOT NULL DEFAULT 0 CHECK (delivery_fee >= 0),
    total_amount     NUMERIC(10,2) NOT NULL CHECK (total_amount >= 0),
    -- Гарантия консистентности сумм на уровне БД
    CONSTRAINT chk_order_total CHECK (total_amount = subtotal + delivery_fee),
    -- Снапшот комиссии момента заказа
    commission_rate  NUMERIC(4,2) NOT NULL,
    commission_amt   NUMERIC(10,2) NOT NULL CHECK (commission_amt >= 0),
    partner_amount   NUMERIC(10,2) NOT NULL CHECK (partner_amount >= 0),
    customer_note    TEXT,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_orders_customer    ON orders(customer_id);
CREATE INDEX idx_orders_restaurant  ON orders(restaurant_id);
CREATE INDEX idx_orders_status      ON orders(status);
CREATE INDEX idx_orders_created     ON orders(created_at DESC);

CREATE TABLE order_items (
    id           BIGSERIAL PRIMARY KEY,
    order_id     BIGINT NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    -- SET NULL: даже если блюдо удалили, строка заказа остаётся
    menu_item_id BIGINT REFERENCES menu_items(id) ON DELETE SET NULL,
    -- Снапшот названия и цены на момент заказа
    name         TEXT NOT NULL,
    price        NUMERIC(10,2) NOT NULL CHECK (price >= 0),
    quantity     INT NOT NULL CHECK (quantity > 0),
    total        NUMERIC(10,2) NOT NULL CHECK (total >= 0),
    CONSTRAINT chk_item_total CHECK (total = price * quantity)
);

CREATE TABLE order_status_log (
    id          BIGSERIAL PRIMARY KEY,
    order_id    BIGINT NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    from_status order_status,
    to_status   order_status NOT NULL,
    actor_id    BIGINT REFERENCES users(id) ON DELETE SET NULL,
    actor_role  VARCHAR(20),
    note        TEXT,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_status_log_order ON order_status_log(order_id);

-- ============================================
-- PAYMENTS LAYER
-- ============================================

CREATE TYPE payment_status AS ENUM (
    'pending',
    'paid',
    'failed',
    'cancelled',
    'refunded'
);

CREATE TABLE payments (
    id                BIGSERIAL PRIMARY KEY,
    order_id          BIGINT NOT NULL REFERENCES orders(id),
    idempotency_key   VARCHAR(255) NOT NULL UNIQUE,
    gateway           VARCHAR(50) NOT NULL DEFAULT 'apipay',
    gateway_invoice_id TEXT,
    amount            NUMERIC(10,2) NOT NULL CHECK (amount > 0),
    status            payment_status NOT NULL DEFAULT 'pending',
    paid_at           TIMESTAMPTZ,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Частичный UNIQUE: только один успешный платёж на заказ.
-- Обычный UNIQUE(order_id) запрещал бы retry после failed.
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

-- ============================================
-- SETTLEMENTS LAYER
-- ============================================

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
    status        VARCHAR(20) NOT NULL DEFAULT 'pending'
                      CHECK (status IN ('pending', 'paid', 'failed')),
    paid_at       TIMESTAMPTZ,
    note          TEXT,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT chk_payout_period CHECK (period_to >= period_from)
);

ALTER TABLE ledger_entries
    ADD CONSTRAINT fk_ledger_payout
    FOREIGN KEY (payout_id) REFERENCES payouts(id) ON DELETE SET NULL;

-- ============================================
-- JOBS LAYER
-- ============================================

CREATE TABLE job_queue (
    id           BIGSERIAL PRIMARY KEY,
    job_type     VARCHAR(100) NOT NULL,
    payload      JSONB NOT NULL,
    status       VARCHAR(20) NOT NULL DEFAULT 'pending'
                     CHECK (status IN ('pending', 'processing', 'done', 'failed')),
    attempts     INT NOT NULL DEFAULT 0,
    max_attempts INT NOT NULL DEFAULT 3,
    run_after    TIMESTAMPTZ NOT NULL DEFAULT now(),
    last_error   TEXT,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_jobs_pending
    ON job_queue(run_after)
    WHERE status = 'pending';
