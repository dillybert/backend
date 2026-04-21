package auth

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/dillybert/backend/internal/generated/api"
)

var (
	ErrUnauthorized = errors.New("unauthorized")
	ErrForbidden    = errors.New("forbidden")
	ErrInvalidData  = errors.New("invalid credentials")
	ErrNotFound     = errors.New("not found")
)

type Handler struct {
	service *Service
}

func NewHandler(service *Service) *Handler {
	return &Handler{
		service: service,
	}
}

func (h *Handler) AuthenticateCustomer(ctx context.Context) (api.AuthenticateCustomerRes, error) {
	return &api.AuthResponse{
		AccessToken: "token",
		ExpiresAt:   time.Now().Add(time.Hour),
		Role:        "customer",
	}, nil
}

func (h *Handler) AuthenticatePartner(ctx context.Context, req *api.PartnerLoginRequest) (api.AuthenticatePartnerRes, error) {
	return &api.AuthResponseHeaders{
		SetCookie: api.OptString{
			Value: fmt.Sprintf(
				"refresh_token=%s; HttpOnly; Secure; SameSite=Strict; Path=/auth/token/refresh",
				"refresh_token",
			),
			Set: true,
		},
		Response: api.AuthResponse{
			AccessToken: "token",
			ExpiresAt:   time.Now().Add(time.Hour),
			Role:        "partner",
		},
	}, nil
}

func (h *Handler) AuthenticateAdmin(context.Context, *api.AdminLoginRequest) (api.AuthenticateAdminRes, error) {
	return nil, nil
}

func (h *Handler) RefreshToken(ctx context.Context) (api.RefreshTokenRes, error) {
	return nil, nil
}

func (h *Handler) Logout(ctx context.Context) (api.LogoutRes, error) {
	return nil, nil
}
