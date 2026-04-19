ifneq (,$(wildcard ./.env))
    include .env
    export
endif


# ==============================================================================
# Project Configuration
# ==============================================================================
PROJECT_NAME := order-platform
BINARY_NAME := server
BUILD_DIR := ./bin
SRC_DIR := ./cmd/server

# Database (adjust values or use .env file)
MIGRATIONS_DIR := ./db/migrations

# Go parameters
GOCMD := go
GOBUILD := $(GOCMD) build
GOCLEAN := $(GOCMD) clean
GOTEST := $(GOCMD) test
GOGENERATE := $(GOCMD) generate ./...

# Build flags for static binary (suitable for VPS deployment)
CGO_ENABLED := 0
GOOS := linux
GOARCH := amd64
BUILD_FLAGS := -a -ldflags "-extldflags=-static" -tags netgo

# ==============================================================================
# Phony Targets
# ==============================================================================
.PHONY: all build clean run test generate migrate-up migrate-down migrate-create

# ------------------------------------------------------------------------------
# Build
# ------------------------------------------------------------------------------
all: generate build

build:
	@echo "🔨 Building $(BINARY_NAME)..."
	@mkdir -p $(BUILD_DIR)
	CGO_ENABLED=$(CGO_ENABLED) GOOS=$(GOOS) GOARCH=$(GOARCH) \
		$(GOBUILD) $(BUILD_FLAGS) -o $(BUILD_DIR)/$(BINARY_NAME) $(SRC_DIR)
	@echo "✅ Build complete: $(BUILD_DIR)/$(BINARY_NAME)"

# Build for local OS (for quick testing)
build-local:
	@echo "🔨 Building $(BINARY_NAME) for local OS..."
	@mkdir -p $(BUILD_DIR)
	$(GOBUILD) -o $(BUILD_DIR)/$(BINARY_NAME) $(SRC_DIR)
	@echo "✅ Local build complete."

# ------------------------------------------------------------------------------
# Code Generation (OpenAPI + SQLC)
# ------------------------------------------------------------------------------
generate:
	@echo "📦 Generating OpenAPI server code (ogen)..."
	go run github.com/ogen-go/ogen/cmd/ogen@latest --target ./internal/generated/api --package api --clean ./openapi.yml
	@echo "📦 Generating database code (sqlc)..."
	sqlc generate
	@echo "✅ Code generation complete."

# ------------------------------------------------------------------------------
# Development
# ------------------------------------------------------------------------------
run: build-local
	@echo "🚀 Starting server..."
	$(BUILD_DIR)/$(BINARY_NAME)

test:
	@echo "🧪 Running tests..."
	$(GOTEST) ./... -v -cover

clean:
	@echo "🧹 Cleaning build artifacts..."
	$(GOCLEAN)
	rm -rf $(BUILD_DIR)
	@echo "✅ Clean complete."

# Linting (requires golangci-lint installed)
lint:
	@echo "🔍 Linting code..."
	golangci-lint run

# Format code
fmt:
	@echo "🎨 Formatting code..."
	$(GOCMD) fmt ./...

# Tidy dependencies
tidy:
	@echo "🧹 Tidying go.mod..."
	$(GOCMD) mod tidy



## Применить все миграции
migrate-up:
	docker compose exec app goose -dir db/migrations postgres "$(DATABASE_URL)" up
 
## Откатить последнюю миграцию
migrate-down:
	docker compose exec app goose -dir db/migrations postgres "$(DATABASE_URL)" down
 
## Статус миграций
migrate-status:
	docker compose exec app goose -dir db/migrations postgres "$(DATABASE_URL)" status
 
## Создать новую миграцию: make migrate-create name=add_reviews
migrate-create:
	docker compose exec app goose -dir db/migrations create $(name) sql

# ─────────────────────────────────────────
# Docker
# ─────────────────────────────────────────
 
## Запустить postgres + redis + app
up:
	docker compose up -d
 
## Запустить с UI инструментами (adminer, redis-commander, mailpit)
tools:
	docker compose --profile tools up -d
 
## Остановить всё
down:
	docker compose down
 
## Пересобрать и запустить
dev:
	docker compose up -d --build
 
## Логи app
logs:
	docker compose logs -f app
 
## Статус контейнеров
ps:
	docker compose ps



# ------------------------------------------------------------------------------
# Docker (optional, for containerised deployment)
# ------------------------------------------------------------------------------
docker-build:
	docker build -t $(PROJECT_NAME):latest .

docker-run:
	docker run -p 8080:8080 --env-file .env $(PROJECT_NAME):latest

# ------------------------------------------------------------------------------
# Help
# ------------------------------------------------------------------------------
help:
	@echo "Available targets:"
	@echo "  all           - Generate code and build"
	@echo "  build         - Build static binary for Linux"
	@echo "  build-local   - Build binary for local OS"
	@echo "  run           - Build and run locally"
	@echo "  test          - Run all tests"
	@echo "  clean         - Remove build artifacts"
	@echo "  generate      - Run ogen and sqlc code generation"
	@echo "  lint          - Run linter (golangci-lint)"
	@echo "  fmt           - Format code"
	@echo "  tidy          - Tidy go.mod"
	@echo "  migrate-up    - Apply all pending migrations"
	@echo "  migrate-down  - Rollback last migration"
	@echo "  migrate-create- Create new migration files"
	@echo "  migrate-status- Show current migration version"
	@echo "  docker-build  - Build Docker image"
	@echo "  docker-run    - Run Docker container"
