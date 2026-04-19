-- name: CreateOrder :one
INSERT INTO orders (
    customer_id, restaurant_id, delivery_address,
    subtotal, delivery_fee, total_amount,
    commission_rate, commission_amt, partner_amount,
    customer_note
) VALUES (
    $1, $2, $3, $4, $5, $6, $7, $8, $9, $10
)
RETURNING *;

-- name: GetOrderByID :one
SELECT * FROM orders WHERE id = $1;

-- name: GetOrdersByCustomer :many
SELECT * FROM orders
WHERE customer_id = $1
ORDER BY created_at DESC
LIMIT $2 OFFSET $3;

-- name: GetOrdersByRestaurant :many
SELECT * FROM orders
WHERE restaurant_id = $1
  AND status = ANY(sqlc.slice('statuses')::order_status[])
ORDER BY created_at DESC
LIMIT $2 OFFSET $3;

-- name: UpdateOrderStatus :one
UPDATE orders
SET status = $2, updated_at = now()
WHERE id = $1
RETURNING *;

-- name: LogOrderStatus :exec
INSERT INTO order_status_log (
    order_id, from_status, to_status, actor_id, actor_role, note
) VALUES (
    $1, $2, $3, $4, $5, $6
);

-- name: GetOrderItems :many
SELECT * FROM order_items
WHERE order_id = $1;

-- name: CreateOrderItems :copyfrom
INSERT INTO order_items (
    order_id, menu_item_id, name, price, quantity, total
) VALUES (
    $1, $2, $3, $4, $5, $6
);
