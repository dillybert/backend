package middleware

import (
	"fmt"
	"log/slog"
	"runtime/debug"

	"github.com/ogen-go/ogen/middleware"
)

func Recovery(logger *slog.Logger) middleware.Middleware {
	return func(
		req middleware.Request,
		next func(req middleware.Request) (middleware.Response, error),
	) (resp middleware.Response, err error) {
		defer func() {
			if r := recover(); r != nil {

				logger.Error("panic recovered",
					"panic", r,
					"method", req.Raw.Method,
					"path", req.Raw.URL.Path,
					"stack", string(debug.Stack()),
				)

				err = fmt.Errorf("internal server error")
			}
		}()

		return next(req)
	}
}
