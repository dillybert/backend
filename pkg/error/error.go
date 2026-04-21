package error

import "fmt"

// Code соответствует enum кодов ошибок в openapi.yaml
type Code string

const (
	CodeInvalidInitData    Code = "INVALID_INIT_DATA"
	CodeInvalidCredentials Code = "INVALID_CREDENTIALS"
	CodeTokenExpired       Code = "TOKEN_EXPIRED"
	CodeTokenInvalid       Code = "TOKEN_INVALID"
	CodeUnauthorized       Code = "UNAUTHORIZED"
	CodeForbidden          Code = "FORBIDDEN"
	CodeNotFound           Code = "NOT_FOUND"
	CodeOrderNotFound      Code = "ORDER_NOT_FOUND"
	CodeInternalError      Code = "INTERNAL_ERROR"
)

// Error — типизированная ошибка приложения.
// Handler слой преобразует её в HTTP ответ с нужным статусом.
type Error struct {
	Code    Code
	Message string
	Err     error // оригинальная ошибка для логирования
}

func (e *Error) Error() string {
	if e.Err != nil {
		return fmt.Sprintf("%s: %s: %v", e.Code, e.Message, e.Err)
	}
	return fmt.Sprintf("%s: %s", e.Code, e.Message)
}

func (e *Error) Unwrap() error {
	return e.Err
}

// Конструкторы для типичных ошибок

func Unauthorized(msg string) *Error {
	return &Error{Code: CodeUnauthorized, Message: msg}
}

func Forbidden(msg string) *Error {
	return &Error{Code: CodeForbidden, Message: msg}
}

func NotFound(msg string) *Error {
	return &Error{Code: CodeNotFound, Message: msg}
}

func InvalidCredentials() *Error {
	return &Error{Code: CodeInvalidCredentials, Message: "invalid username or password"}
}

func InvalidInitData(err error) *Error {
	return &Error{Code: CodeInvalidInitData, Message: "invalid telegram init data", Err: err}
}

func Internal(err error) *Error {
	return &Error{Code: CodeInternalError, Message: "internal server error", Err: err}
}
