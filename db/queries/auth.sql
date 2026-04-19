-- name: GetUserByID :one
SELECT * FROM users
WHERE id = $1;

-- name: CreateUser :one
INSERT INTO users (role)
VALUES ($1)
RETURNING *;

-- name: DeactivateUser :exec
UPDATE users
SET is_active = false, updated_at = now()
WHERE id = $1;

-- Sessions

-- name: CreateSession :one
INSERT INTO sessions (user_id, user_agent, ip_address, expires_at)
VALUES ($1, $2, $3, $4)
RETURNING *;

-- name: GetSession :one
SELECT * FROM sessions
WHERE id = $1
  AND revoked_at IS NULL
  AND expires_at > now();

-- name: GetActiveSessionsByUser :many
SELECT * FROM sessions
WHERE user_id = $1
  AND revoked_at IS NULL
  AND expires_at > now()
ORDER BY created_at DESC;

-- name: RevokeSession :exec
UPDATE sessions
SET revoked_at = now()
WHERE id = $1;

-- name: RevokeAllUserSessions :exec
UPDATE sessions
SET revoked_at = now()
WHERE user_id = $1
  AND revoked_at IS NULL;
