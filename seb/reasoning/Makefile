.PHONY: build test clean release demo check fmt clippy doc all help

CARGO ?= cargo
RUST_BACKTRACE ?= 1
PROFILE ?= release

# Color output
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[0;33m
NC := \033[0m

help:
	@echo "$(GREEN)SEB L6 Reasoning Protocol Build Targets$(NC)"
	@echo ""
	@echo "$(YELLOW)Building:$(NC)"
	@echo "  make build         Build debug binary"
	@echo "  make release       Build release binary"
	@echo "  make clean         Clean build artifacts"
	@echo ""
	@echo "$(YELLOW)Testing:$(NC)"
	@echo "  make test          Run all tests"
	@echo "  make test-unit     Run unit tests only"
	@echo "  make test-doc      Run doc tests"
	@echo "  make coverage      Generate test coverage"
	@echo ""
	@echo "$(YELLOW)Code Quality:$(NC)"
	@echo "  make check         Check code with clippy"
	@echo "  make fmt           Format code with rustfmt"
	@echo "  make clippy        Run clippy linter"
	@echo ""
	@echo "$(YELLOW)Examples:$(NC)"
	@echo "  make demo          Run multi-agent demo"
	@echo ""
	@echo "$(YELLOW)Documentation:$(NC)"
	@echo "  make doc           Generate documentation"
	@echo "  make doc-open      Open documentation in browser"
	@echo ""
	@echo "$(YELLOW)Utilities:$(NC)"
	@echo "  make all           Build, test, check"
	@echo "  make help          Show this help message"

# Build targets
build:
	@echo "$(GREEN)Building seb_reasoning (debug)...$(NC)"
	@$(CARGO) build

release:
	@echo "$(GREEN)Building seb_reasoning (release)...$(NC)"
	@$(CARGO) build --release
	@echo "$(GREEN)✓ Release build complete$(NC)"
	@ls -lh target/release/libseb_reasoning*

# Testing
test:
	@echo "$(GREEN)Running all tests...$(NC)"
	@RUST_BACKTRACE=$(RUST_BACKTRACE) $(CARGO) test --all-targets --all-features
	@echo "$(GREEN)✓ All tests passed$(NC)"

test-unit:
	@echo "$(GREEN)Running unit tests...$(NC)"
	@$(CARGO) test --lib

test-doc:
	@echo "$(GREEN)Running doc tests...$(NC)"
	@$(CARGO) test --doc

coverage:
	@echo "$(YELLOW)Coverage report requires tarpaulin$(NC)"
	@which cargo-tarpaulin > /dev/null || cargo install cargo-tarpaulin
	@cargo tarpaulin --out Html --output-dir coverage

# Code quality
check:
	@echo "$(GREEN)Running cargo check...$(NC)"
	@$(CARGO) check --all-targets
	@echo "$(GREEN)✓ Check passed$(NC)"

fmt:
	@echo "$(GREEN)Formatting code with rustfmt...$(NC)"
	@$(CARGO) fmt --all

fmt-check:
	@echo "$(GREEN)Checking code format...$(NC)"
	@$(CARGO) fmt --all -- --check

clippy:
	@echo "$(GREEN)Running clippy linter...$(NC)"
	@$(CARGO) clippy --all-targets --all-features -- -D warnings
	@echo "$(GREEN)✓ Clippy passed$(NC)"

# Examples
demo:
	@echo "$(GREEN)Running multi-agent reasoning demo...$(NC)"
	@$(CARGO) run --example demo --release

# Documentation
doc:
	@echo "$(GREEN)Generating documentation...$(NC)"
	@$(CARGO) doc --no-deps --open

doc-open:
	@$(CARGO) doc --no-deps --open

# Composite targets
all: check fmt test
	@echo "$(GREEN)✓ All checks passed$(NC)"

verify: fmt-check check test
	@echo "$(GREEN)✓ Verification complete$(NC)"

# Cleaning
clean:
	@echo "$(YELLOW)Cleaning build artifacts...$(NC)"
	@$(CARGO) clean
	@rm -rf coverage/
	@echo "$(GREEN)✓ Clean complete$(NC)"

# CI/CD target
ci: verify release
	@echo "$(GREEN)✓ CI pipeline complete$(NC)"

# Development watch (requires cargo-watch)
watch:
	@which cargo-watch > /dev/null || (echo "$(YELLOW)Installing cargo-watch...$(NC)" && cargo install cargo-watch)
	@cargo watch -x test

# Bench target (future)
bench:
	@echo "$(YELLOW)Benchmarks not yet configured$(NC)"
	@$(CARGO) bench 2>/dev/null || echo "Use --bench to run"

.DEFAULT_GOAL := help
