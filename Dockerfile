# ─────────────────────────────────────────
# Stage 1: base — общие зависимости
# ─────────────────────────────────────────
FROM golang:1.26-alpine AS base

WORKDIR /app

RUN apk add --no-cache \
    git \
    curl \
    wget \
    ca-certificates

COPY go.mod go.sum ./
RUN go mod download

# ─────────────────────────────────────────
# Stage 2: development — с hot reload
# ─────────────────────────────────────────
FROM base AS development

# Air — hot reload для Go
RUN go install github.com/air-verse/air@latest

RUN go install github.com/pressly/goose/v3/cmd/goose@latest

COPY . .

EXPOSE 8080

CMD ["air", "-c", ".air.toml"]

# ─────────────────────────────────────────
# Stage 3: builder — компилируем бинарь
# ─────────────────────────────────────────
FROM base AS builder

COPY . .

RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build \
    -ldflags="-w -s" \
    -o /app/bin/server \
    ./cmd/server

# ─────────────────────────────────────────
# Stage 4: production — минимальный образ
# ─────────────────────────────────────────
FROM scratch AS production

COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /app/bin/server /server

EXPOSE 8080

ENTRYPOINT ["/server"]
