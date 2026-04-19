-- name: GetCustomerByTelegramID :one
SELECT
    c.*,
    u.role,
    u.is_active
FROM customers c
JOIN users u ON u.id = c.user_id
WHERE c.telegram_id = $1;

-- name: GetCustomerByUserID :one
SELECT * FROM customers
WHERE user_id = $1;

-- name: CreateCustomer :one
INSERT INTO customers (
    user_id, telegram_id, first_name, last_name, username
) VALUES (
    $1, $2, $3, $4, $5
)
RETURNING *;

-- name: UpdateCustomer :one
UPDATE customers
SET
    first_name = coalesce(sqlc.narg('first_name'), first_name),
    last_name  = coalesce(sqlc.narg('last_name'),  last_name),
    username   = coalesce(sqlc.narg('username'),   username),
    phone      = coalesce(sqlc.narg('phone'),      phone)
WHERE user_id = $1
RETURNING *;
