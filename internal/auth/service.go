package auth

import (
	"github.com/dillybert/backend/internal/generated/db"
	"github.com/dillybert/backend/pkg/jwt"
	"github.com/redis/go-redis/v9"
)

// Service содержит всю бизнес-логику аутентификации.
// Знает про: БД (через sqlc queries), Redis (refresh токены), JWT.
// Не знает про: HTTP, Telegram Bot API.
type Service struct {
	queries  *db.Queries
	redis    *redis.Client
	jwt      *jwt.Manager
	botToken string // нужен для валидации initData HMAC
}

// NewService создаёт auth сервис.
func NewService(
	queries *db.Queries,
	rdb *redis.Client,
	jwtManager *jwt.Manager,
	botToken string,
) *Service {
	return &Service{
		queries:  queries,
		redis:    rdb,
		jwt:      jwtManager,
		botToken: botToken,
	}
}

// TODO: методы реализуются при написании auth handler-ов:
//
// AuthenticateClient(ctx, initData string) (*AuthResult, error)
//   - валидация HMAC initData
//   - upsert customer в БД
//   - выдача access JWT (без refresh)
//
// AuthenticatePartner(ctx, code, password string) (*AuthResult, error)
//   - проверка bcrypt хэша
//   - создание session в БД + Redis
//   - выдача access JWT + refresh cookie
//
// AuthenticateAdmin(ctx, username, password string) (*AuthResult, error)
//   - аналогично партнёру
//
// RefreshToken(ctx, refreshToken string) (*AuthResult, error)
//   - проверка refresh токена в Redis
//   - rotation: удаляем старый, создаём новый
//
// Logout(ctx, sessionID string) error
//   - revoke session в БД
//   - удаление refresh токена из Redis
