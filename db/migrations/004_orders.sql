-- +goose Up

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
    subtotal         NUMERIC(10,2) NOT NULL CHECK (subtotal >= 0),
    delivery_fee     NUMERIC(10,2) NOT NULL DEFAULT 0 CHECK (delivery_fee >= 0),
    total_amount     NUMERIC(10,2) NOT NULL CHECK (total_amount >= 0),
    CONSTRAINT chk_order_total CHECK (total_amount = subtotal + delivery_fee),
    commission_rate  NUMERIC(4,2) NOT NULL,
    commission_amt   NUMERIC(10,2) NOT NULL CHECK (commission_amt >= 0),
    partner_amount   NUMERIC(10,2) NOT NULL CHECK (partner_amount >= 0),
    customer_note    TEXT,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_orders_customer   ON orders(customer_id);
CREATE INDEX idx_orders_restaurant ON orders(restaurant_id);
CREATE INDEX idx_orders_status     ON orders(status);
CREATE INDEX idx_orders_created    ON orders(created_at DESC);

CREATE TABLE order_items (
    id           BIGSERIAL PRIMARY KEY,
    order_id     BIGINT NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    menu_item_id BIGINT REFERENCES menu_items(id) ON DELETE SET NULL,
    name         TEXT NOT NULL,
    price        NUMERIC(10,2) NOT NULL CHECK (price >= 0),
    quantity     INT NOT NULL CHECK (quantity > 0),
    total        NUMERIC(10,2) NOT NULL CHECK (total >= 0),
    CONSTRAINT chk_item_total CHECK (total = price * quantity)
);

CREATE INDEX idx_order_items_order ON order_items(order_id);

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

-- +goose Down

DROP INDEX IF EXISTS idx_status_log_order;
DROP TABLE IF EXISTS order_status_log;
DROP INDEX IF EXISTS idx_order_items_order;
DROP TABLE IF EXISTS order_items;
DROP INDEX IF EXISTS idx_orders_created;
DROP INDEX IF EXISTS idx_orders_status;
DROP INDEX IF EXISTS idx_orders_restaurant;
DROP INDEX IF EXISTS idx_orders_customer;
DROP TABLE IF EXISTS orders;
DROP TYPE IF EXISTS order_status;
