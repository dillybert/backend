-- name: ListActiveRestaurants :many
SELECT * FROM restaurants
WHERE deleted_at IS NULL
  AND is_active = true
ORDER BY name;

-- name: GetRestaurantByID :one
SELECT * FROM restaurants
WHERE id = $1
  AND deleted_at IS NULL;

-- name: GetRestaurantByPartnerID :many
SELECT * FROM restaurants
WHERE partner_id = $1
  AND deleted_at IS NULL;

-- name: CreateRestaurant :one
INSERT INTO restaurants (
    partner_id, name, description, address, phone,
    commission_tier, commission_rate, onboarding_ends_at
) VALUES (
    $1, $2, $3, $4, $5, $6, $7, $8
)
RETURNING *;

-- name: UpdateRestaurantStatus :one
UPDATE restaurants
SET
    is_active  = coalesce(sqlc.narg('is_active'), is_active),
    is_open    = coalesce(sqlc.narg('is_open'),   is_open),
    updated_at = now()
WHERE id = $1
RETURNING *;

-- name: UpdateRestaurantTier :exec
UPDATE restaurants
SET
    commission_tier = $2,
    commission_rate = $3,
    updated_at      = now()
WHERE id = $1;

-- name: SoftDeleteRestaurant :exec
UPDATE restaurants
SET deleted_at = now(), updated_at = now()
WHERE id = $1;

-- name: GetRestaurantHours :many
SELECT * FROM restaurant_hours
WHERE restaurant_id = $1
ORDER BY day_of_week;

-- name: UpsertRestaurantHours :one
INSERT INTO restaurant_hours (
    restaurant_id, day_of_week, opens_at, closes_at, is_closed
) VALUES (
    $1, $2, $3, $4, $5
)
ON CONFLICT (restaurant_id, day_of_week)
DO UPDATE SET
    opens_at  = EXCLUDED.opens_at,
    closes_at = EXCLUDED.closes_at,
    is_closed = EXCLUDED.is_closed
RETURNING *;
