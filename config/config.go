package config

import (
	"fmt"
	"time"

	"github.com/ilyakaznacheev/cleanenv"
)

type Config struct {
	Project  ProjectConfig
	Postgres PostgresConfig
	Redis    RedisConfig
	JWT      JWTConfig
	Telegram TelegramConfig
	ApiPay   ApiPayConfig
}

type ProjectConfig struct {
	Env     string `env:"PROJECT_ENV"     env-default:"development"`
	Port    int    `env:"PROJECT_PORT"    env-default:"8080"`
	BaseURL string `env:"PROJECT_BASE_URL" env-default:"http://localhost:8080"`
}

type PostgresConfig struct {
	Host     string `env:"POSTGRES_HOST"     env-default:"localhost"`
	Port     int    `env:"POSTGRES_PORT"     env-default:"5432"`
	User     string `env:"POSTGRES_USER"`
	Password string `env:"POSTGRES_PASSWORD"`
	Database string `env:"POSTGRES_DB"`
	DSN      string `env:"POSTGRES_DSN"`
}

func (c PostgresConfig) FormatDSN() string {
	if c.DSN != "" {
		return c.DSN
	}
	return fmt.Sprintf(
		"postgres://%s:%s@%s:%d/%s?sslmode=disable",
		c.User, c.Password, c.Host, c.Port, c.Database,
	)
}

type RedisConfig struct {
	Host     string `env:"REDIS_HOST"     env-default:"localhost"`
	Port     int    `env:"REDIS_PORT"     env-default:"6379"`
	Password string `env:"REDIS_PASSWORD"`
	Database int    `env:"REDIS_DATABASE" env-default:"0"`
	DSN      string `env:"REDIS_DSN"`
}

func (c RedisConfig) Addr() string {
	return fmt.Sprintf("%s:%d", c.Host, c.Port)
}

type JWTConfig struct {
	Secret     string        `env:"JWT_SECRET" env-default:"secret"`
	AccessTTL  time.Duration `env:"JWT_ACCESS_TTL" env-default:"10m"`
	RefreshTTL time.Duration `env:"JWT_REFRESH_TTL" env-default:"720h"`
}

type TelegramConfig struct {
	BotToken  string `env:"TELEGRAM_BOT_TOKEN"  env-required:"true"`
	BotSecret string `env:"TELEGRAM_BOT_SECRET" env-default:""`
}

type ApiPayConfig struct {
	APIKey        string `env:"APIPAY_API_KEY"        env-required:"true"`
	BaseURL       string `env:"APIPAY_BASE_URL"       env-default:"https://bpapi.bazarbay.site/api/v1"`
	WebhookSecret string `env:"APIPAY_WEBHOOK_SECRET" env-required:"true"`
}

func Load(path string) (*Config, error) {
	cfg := &Config{}
	if err := cleanenv.ReadConfig(path, cfg); err != nil {
		return nil, fmt.Errorf("read config: %w", err)
	}
	return cfg, nil
}

func (c *ProjectConfig) IsDevelopment() bool {
	return c.Env == "development"
}
