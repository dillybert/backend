package middleware

import (
	"log/slog"
	"time"

	"github.com/ogen-go/ogen/middleware"
)

func Logger(logger *slog.Logger) middleware.Middleware {
	return func(
		req middleware.Request,
		next func(req middleware.Request) (middleware.Response, error),
	) (resp middleware.Response, err error) {
		start := time.Now()

		resp, err = next(req)

		duration := time.Since(start)

		attrs := []any{
			"method", req.Raw.Method,
			"path", req.Raw.URL.Path,
			"duration_ms", duration.Milliseconds(),
		}

		if err != nil {
			logger.Error("request failed",
				append(attrs, "error", err)...,
			)
			return resp, err
		}

		logger.Info("request",
			attrs...,
		)

		return resp, nil
	}
}
