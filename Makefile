# Go parameters
GOCMD := go
GOBUILD := $(GOCMD) build
GOCLEAN := $(GOCMD) clean
BUILD_DIR := ./bin
BINARY_NAME := server
SRC := ./cmd/server

# Build flags for static binary
BUILD_FLAGS := -a -ldflags "-extldflags=-static" -tags netgo
CGO_ENABLED := 0
GOOS := linux
GOARCH := amd64

.PHONY: all build clean run test

# Default target
all: build

# Build ntund binary
build:
	@echo "Building $(BINARY_NAME)..."
	mkdir -p $(BUILD_DIR)
	CGO_ENABLED=$(CGO_ENABLED) GOOS=$(GOOS) GOARCH=$(GOARCH) \
		$(GOBUILD) $(BUILD_FLAGS) -o $(BUILD_DIR)/$(BINARY_NAME) $(SRC)
	@echo "Build complete: ./bin/$(BINARY_NAME)"

# Clean build artifacts
clean:
	@echo "Cleaning..."
	$(GOCLEAN)
	rm -rf $(BUILD_DIR)
	@echo "Clean complete."

# Run the binary (for local testing)
run: build
	@echo "Running $(BINARY_NAME)..."
	$(BUILD_DIR)/$(BINARY_NAME)

# Run tests
test:
	@echo "Running tests..."
	$(GOCMD) test ./... -v
