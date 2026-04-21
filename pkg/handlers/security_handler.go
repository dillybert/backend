package handlers

import (
	"context"

	"github.com/dillybert/backend/internal/generated/api"
	"github.com/dillybert/backend/pkg/jwt"
)

type SecurityHandler struct {
	JwtManager *jwt.Manager
}

func (h *SecurityHandler) HandleBearerAuth(ctx context.Context, operationName api.OperationName, t api.BearerAuth) (context.Context, error) {
	return nil, nil
}

func (h *SecurityHandler) HandleInitData(ctx context.Context, operationName api.OperationName, t api.InitData) (context.Context, error) {
	return nil, nil
}
