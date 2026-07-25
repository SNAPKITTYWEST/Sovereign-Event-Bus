.PHONY: build test check fmt lint clean release run daemon help verify

help:
	@echo "🔐 Human-Touch Gateway — Makefile Commands"
	@echo ""
	@echo "Build & Test:"
	@echo "  make build        - Build in debug mode"
	@echo "  make release      - Build optimized release binary"
	@echo "  make test         - Run all tests"
	@echo "  make check        - Run cargo check"
	@echo ""
	@echo "Development:"
	@echo "  make fmt          - Format code (cargo fmt)"
	@echo "  make lint         - Run clippy linter"
	@echo "  make verify       - Run check + fmt + lint"
	@echo ""
	@echo "Running:"
	@echo "  make run          - Run interactive mode"
	@echo "  make daemon       - Run daemon mode (webhook)"
	@echo ""
	@echo "Maintenance:"
	@echo "  make clean        - Remove build artifacts"
	@echo "  make help         - Show this message"

build:
	@echo "🔨 Building human-touch gateway..."
	cargo build --verbose

release:
	@echo "🚀 Building release binary..."
	cargo build --release --verbose

test:
	@echo "🧪 Running tests..."
	cargo test --verbose -- --nocapture --test-threads=1

check:
	@echo "✓ Checking code..."
	cargo check --verbose

fmt:
	@echo "📝 Formatting code..."
	cargo fmt --all

lint:
	@echo "🔍 Running clippy..."
	cargo clippy --all-targets --all-features -- -D warnings

verify: check fmt lint test
	@echo "✅ All checks passed!"

run:
	@echo "🏃 Running interactive mode..."
	cargo run -- --verbose --repo-path .

daemon:
	@echo "🌙 Running daemon mode..."
	cargo run -- --daemon --webhook-port 8080 --verbose --repo-path .

clean:
	@echo "🧹 Cleaning build artifacts..."
	cargo clean
	rm -rf target/
	find . -name "*.wasm" -delete

install:
	@echo "📦 Installing binary..."
	cargo install --path .

doc:
	@echo "📚 Building documentation..."
	cargo doc --no-deps --open

update:
	@echo "🔄 Updating dependencies..."
	cargo update

audit:
	@echo "🔐 Security audit..."
	cargo audit

# Development workflow
dev: fmt lint test build
	@echo "✅ Development build complete"

# Full CI workflow
ci: verify build release
	@echo "✅ CI pipeline complete"
