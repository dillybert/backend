-- name: CreatePayment :one
INSERT INTO payments (
    order_id, idempotency_key, gateway, amount
) VALUES (
    $1, $2, $3, $4
)
RETURNING *;

-- name: GetPaymentByOrderID :one
SELECT * FROM payments
WHERE order_id = $1
ORDER BY created_at DESC
LIMIT 1;

-- name: GetPaymentByIdempotencyKey :one
SELECT * FROM payments
WHERE idempotency_key = $1;

-- name: UpdatePaymentStatus :one
UPDATE payments
SET
    status             = $2,
    gateway_invoice_id = coalesce($3, gateway_invoice_id),
    paid_at            = CASE WHEN $2 = 'paid' THEN now() ELSE paid_at END,
    updated_at         = now()
WHERE id = $1
RETURNING *;

-- name: CreateWebhookEvent :one
INSERT INTO webhook_events (gateway, event_id, event_type, payload)
VALUES ($1, $2, $3, $4)
RETURNING *;

-- name: MarkWebhookProcessed :exec
UPDATE webhook_events
SET processed_at = now()
WHERE event_id = $1;

-- name: GetUnprocessedWebhooks :many
SELECT * FROM webhook_events
WHERE processed_at IS NULL
ORDER BY created_at
LIMIT 50;
