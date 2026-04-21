-- name: GetCustomerTelegramIDByOrderID :one
-- Используется для отправки Telegram Bot push уведомления клиенту.
-- telegram_id == chat_id в Bot API для приватных сообщений.
SELECT
    c.telegram_id,
    c.first_name,
    o.id         AS order_id,
    o.status     AS order_status,
    o.total_amount
FROM orders o
JOIN customers c ON c.id = o.customer_id
WHERE o.id = $1;

-- name: GetCustomerTelegramIDByCustomerID :one
-- Используется при первом контакте — проверить что пользователь
-- не заблокировал бота перед отправкой.
SELECT telegram_id, first_name
FROM customers
WHERE id = $1;
