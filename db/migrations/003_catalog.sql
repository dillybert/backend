-- +goose Up

CREATE TABLE restaurants (
    id                 BIGSERIAL PRIMARY KEY,
    partner_id         BIGINT NOT NULL REFERENCES partners(id),
    name               TEXT NOT NULL,
    description        TEXT,
    address            TEXT,
    phone              VARCHAR(20),
    logo_url           TEXT,
    cover_url          TEXT,
    commission_tier    VARCHAR(20) NOT NULL DEFAULT 'onboarding'
                           CHECK (commission_tier IN (
                               'onboarding',
                               'basic',
                               'standard',
                               'partner'
                           )),
    commission_rate    NUMERIC(4,2) NOT NULL DEFAULT 0.00,
    is_active          BOOLEAN NOT NULL DEFAULT false,
    is_open            BOOLEAN NOT NULL DEFAULT false,
    onboarding_ends_at TIMESTAMPTZ,
    deleted_at         TIMESTAMPTZ,
    created_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at         TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_restaurants_partner
    ON restaurants(partner_id);

CREATE INDEX idx_restaurants_active
    ON restaurants(id)
    WHERE deleted_at IS NULL;

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

CREATE INDEX idx_menu_items_category
    ON menu_items(category_id)
    WHERE deleted_at IS NULL;

-- +goose Down

DROP INDEX IF EXISTS idx_menu_items_category;
DROP INDEX IF EXISTS idx_menu_items_restaurant;
DROP TABLE IF EXISTS menu_items;
DROP TABLE IF EXISTS restaurant_categories;
DROP TABLE IF EXISTS restaurant_hours;
DROP INDEX IF EXISTS idx_restaurants_active;
DROP INDEX IF EXISTS idx_restaurants_partner;
DROP TABLE IF EXISTS restaurants;
