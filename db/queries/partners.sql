-- name: GetPartnerByCode :one
SELECT
    p.*,
    u.role,
    u.is_active
FROM partners p
JOIN users u ON u.id = p.user_id
WHERE p.partner_code = $1;

-- name: GetPartnerByUserID :one
SELECT * FROM partners
WHERE user_id = $1;

-- name: CreatePartner :one
INSERT INTO partners (
    user_id, partner_code, password_hash
) VALUES (
    $1, $2, $3
)
RETURNING *;

-- name: UpdatePartnerLastLogin :exec
UPDATE partners
SET last_login_at = now()
WHERE id = $1;

-- name: UpdatePartnerPassword :exec
UPDATE partners
SET
    password_hash   = $2,
    must_change_pwd = false
WHERE id = $1;
