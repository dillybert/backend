package main

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/dillybert/backend/config"
	"github.com/dillybert/backend/internal/auth"
	"github.com/dillybert/backend/internal/generated/api"
	"github.com/dillybert/backend/internal/generated/db"
	"github.com/dillybert/backend/pkg/handlers"
	"github.com/dillybert/backend/pkg/jwt"
	"github.com/dillybert/backend/pkg/middleware"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/redis/go-redis/v9"
)

func main() {
	cfg, err := config.Load(".env")
	if err != nil {
		fmt.Printf("failed to load config: %s\n", err.Error())
		os.Exit(1)
	}

	logger := setupLogger(cfg.Project.Env)
	slog.SetDefault(logger)

	pool, err := pgxpool.New(context.Background(), cfg.Postgres.FormatDSN())
	if err != nil {
		slog.Error("failed to connect to database", "error", err)
		os.Exit(1)
	}
	defer pool.Close()

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	if err := pool.Ping(ctx); err != nil {
		slog.Error("failed to ping database", "error", err)
		os.Exit(1)
	}

	queries := db.New(pool)
	slog.Info("database connected", "queries", queries)

	redis := redis.NewClient(&redis.Options{
		Addr:     cfg.Redis.Addr(),
		Password: cfg.Redis.Password,
		DB:       cfg.Redis.Database,
	})
	defer redis.Close()

	ctx, cancel = context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	if err := redis.Ping(ctx).Err(); err != nil {
		slog.Error("failed to ping redis", "error", err)
		os.Exit(1)
	}

	jwtManager := jwt.NewManager(
		cfg.JWT.Secret,
		cfg.JWT.AccessTTL,
		cfg.JWT.RefreshTTL,
	)

	authService := auth.NewService(queries, redis, jwtManager, cfg.Telegram.BotToken)
	authHandler := auth.NewHandler(authService)

	handler := &handlers.Handler{
		AuthHandler: authHandler,
	}

	securityHandler := &handlers.SecurityHandler{
		JwtManager: jwtManager,
	}

	server, err := api.NewServer(
		handler,
		securityHandler,
		api.WithMiddleware(
			middleware.Logger(logger),
			middleware.Recovery(logger),
		),
	)
	if err != nil {
		slog.Error("failed to create server", "error", err)
		os.Exit(1)
	}

	mux := http.NewServeMux()
	mux.HandleFunc("GET /health", healthHandler)
	mux.Handle("/", server)

	httpServer := &http.Server{
		Addr:         fmt.Sprintf(":%d", cfg.Project.Port),
		Handler:      mux,
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 30 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	serverErr := make(chan error, 1)

	go func() {
		slog.Info("server starting", "addr", httpServer.Addr, "env", cfg.Project.Env)
		if err := httpServer.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
			serverErr <- err
		}
	}()

	// Ждём сигнала завершения или ошибки сервера
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)

	select {
	case err := <-serverErr:
		slog.Error("server error", "error", err)
	case sig := <-quit:
		slog.Info("shutdown signal received", "signal", sig)
	}

	// Даём 30 секунд на завершение текущих запросов
	shutdownCtx, shutdownCancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer shutdownCancel()

	slog.Info("shutting down server...")
	if err := httpServer.Shutdown(shutdownCtx); err != nil {
		slog.Error("server forced to shutdown", "error", err)
	}

	slog.Info("server stopped")
}

// ─────────────────────────────────────────
// healthHandler — простой endpoint для docker healthcheck.
// Не требует авторизации, отвечает 200 OK если сервер жив.
// ─────────────────────────────────────────
func healthHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	_, _ = w.Write([]byte(`{"status":"ok"}`))
}

// Убеждаемся что handler имплементирует интерфейс ogen на этапе компиляции.
// Эта строка упадёт с ошибкой компилятора если что-то не реализовано.
var _ api.Handler = (*handlers.Handler)(nil)

func setupLogger(env string) *slog.Logger {
	var handler slog.Handler
	if env == "production" {
		handler = slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{
			Level: slog.LevelInfo,
		})
	} else {
		handler = slog.NewTextHandler(os.Stdout, &slog.HandlerOptions{
			Level:     slog.LevelDebug,
			AddSource: true,
		})
	}

	return slog.New(handler)
}
