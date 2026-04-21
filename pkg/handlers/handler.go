package handlers

import (
	"context"
	"errors"

	"github.com/dillybert/backend/internal/auth"
	"github.com/dillybert/backend/internal/generated/api"
)

type Handler struct {
	AuthHandler *auth.Handler
}

func (h *Handler) AuthenticateCustomer(ctx context.Context) (api.AuthenticateCustomerRes, error) {
	return h.AuthHandler.AuthenticateCustomer(ctx)
}

func (h *Handler) AuthenticatePartner(ctx context.Context, req *api.PartnerLoginRequest) (api.AuthenticatePartnerRes, error) {
	return h.AuthHandler.AuthenticatePartner(ctx, req)
}

func (h *Handler) AuthenticateAdmin(ctx context.Context, req *api.AdminLoginRequest) (api.AuthenticateAdminRes, error) {
	return h.AuthHandler.AuthenticateAdmin(ctx, req)
}

func (h *Handler) RefreshToken(ctx context.Context) (api.RefreshTokenRes, error) {
	return h.AuthHandler.RefreshToken(ctx)
}

func (h *Handler) Logout(ctx context.Context) (api.LogoutRes, error) {
	return h.AuthHandler.Logout(ctx)
}

func (h *Handler) NewError(ctx context.Context, err error) *api.UnexpectedErrorStatusCode {
	code := 500
	msg := err.Error()

	switch {
	case errors.Is(err, auth.ErrUnauthorized):
		code = 401

	case errors.Is(err, auth.ErrForbidden):
		code = 403

	case errors.Is(err, auth.ErrNotFound):
		code = 404
	}

	return &api.UnexpectedErrorStatusCode{
		StatusCode: code,
		Response: api.Error{
			Code:    api.ErrorCode(code),
			Message: msg,
		},
	}
}
