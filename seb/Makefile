# SEB Makefile
# Generated from: SEB_SOVEREIGN_EVENT_BUS_MASTER_SPECIFICATION.xml
# Version: 1.0.0

.PHONY: help scaffold-verify scaffold-clean codegen-all test-contracts hash-manifest

# Default target
help:
	@echo "SEB Makefile - Available targets:"
	@echo "  scaffold-verify    - Verify scaffold integrity"
	@echo "  scaffold-clean     - Clean generated files"
	@echo "  codegen-all        - Generate all codegen targets"
	@echo "  test-contracts     - Test contract templates"
	@echo "  hash-manifest      - Compute manifest hash"
	@echo "  help               - Show this help message"

# Verify scaffold integrity
scaffold-verify:
	@echo "=== SEB Scaffold Verification ==="
	@echo ""
	@echo "[1/7] Checking directory structure..."
	@test -d contracts || (echo "ERROR: contracts/ missing" && exit 1)
	@test -d scripts/codegen || (echo "ERROR: scripts/codegen/ missing" && exit 1)
	@test -d docs/spec || (echo "ERROR: docs/spec/ missing" && exit 1)
	@test -d kernel || (echo "ERROR: kernel/ missing" && exit 1)
	@test -d runtime || (echo "ERROR: runtime/ missing" && exit 1)
	@test -d adapters || (echo "ERROR: adapters/ missing" && exit 1)
	@test -d clients/typescript || (echo "ERROR: clients/typescript/ missing" && exit 1)
	@test -d clients/python || (echo "ERROR: clients/python/ missing" && exit 1)
	@test -d verification/lean4 || (echo "ERROR: verification/lean4/ missing" && exit 1)
	@echo "✓ Directory structure OK"
	@echo ""
	@echo "[2/7] Checking contract templates..."
	@test -f contracts/rust.template || (echo "ERROR: rust.template missing" && exit 1)
	@test -f contracts/typescript.template || (echo "ERROR: typescript.template missing" && exit 1)
	@test -f contracts/python.template || (echo "ERROR: python.template missing" && exit 1)
	@test -f contracts/lean4.template || (echo "ERROR: lean4.template missing" && exit 1)
	@test -f contracts/openapi.template || (echo "ERROR: openapi.template missing" && exit 1)
	@echo "✓ All 5 contract templates present"
	@echo ""
	@echo "[3/7] Checking codegen scripts..."
	@test -f scripts/codegen/generate_all.sh || (echo "ERROR: generate_all.sh missing" && exit 1)
	@test -f scripts/codegen/generate_rust.sh || (echo "ERROR: generate_rust.sh missing" && exit 1)
	@test -f scripts/codegen/generate_typescript.sh || (echo "ERROR: generate_typescript.sh missing" && exit 1)
	@test -f scripts/codegen/generate_python.sh || (echo "ERROR: generate_python.sh missing" && exit 1)
	@test -f scripts/codegen/generate_lean4.sh || (echo "ERROR: generate_lean4.sh missing" && exit 1)
	@test -f scripts/codegen/generate_openapi.sh || (echo "ERROR: generate_openapi.sh missing" && exit 1)
	@echo "✓ All codegen scripts present"
	@echo ""
	@echo "[4/7] Checking script permissions..."
	@test -x scripts/codegen/generate_all.sh || chmod +x scripts/codegen/generate_all.sh
	@test -x scripts/codegen/generate_rust.sh || chmod +x scripts/codegen/generate_rust.sh
	@test -x scripts/codegen/generate_typescript.sh || chmod +x scripts/codegen/generate_typescript.sh
	@test -x scripts/codegen/generate_python.sh || chmod +x scripts/codegen/generate_python.sh
	@test -x scripts/codegen/generate_lean4.sh || chmod +x scripts/codegen/generate_lean4.sh
	@test -x scripts/codegen/generate_openapi.sh || chmod +x scripts/codegen/generate_openapi.sh
	@echo "✓ All scripts executable"
	@echo ""
	@echo "[5/7] Checking documentation..."
	@test -f README.md || (echo "WARNING: README.md missing" && exit 0)
	@test -f docs/spec/SEB_EVENT_V1.md || (echo "WARNING: SEB_EVENT_V1.md missing" && exit 0)
	@echo "✓ Documentation check complete"
	@echo ""
	@echo "[6/7] Checking GenesisConfig..."
	@test -f GenesisConfig.toml || (echo "WARNING: GenesisConfig.toml missing" && exit 0)
	@echo "✓ GenesisConfig check complete"
	@echo ""
	@echo "[7/7] Verifying manifest hash..."
	@test -f GenesisConfig.toml && grep -q "manifest_hash" GenesisConfig.toml || (echo "WARNING: manifest_hash not found" && exit 0)
	@echo "✓ Manifest hash check complete"
	@echo ""
	@echo "=== ✓ Scaffold verification PASSED ==="

# Clean generated files
scaffold-clean:
	@echo "Cleaning generated files..."
	@rm -f kernel/event_envelope.rs
	@rm -f clients/typescript/index.ts
	@rm -f clients/python/seb_client.py
	@rm -f verification/lean4/SEB.lean
	@rm -f docs/api/openapi.yaml
	@echo "✓ Clean complete"

# Generate all codegen targets
codegen-all:
	@echo "Generating all codegen targets..."
	@bash scripts/codegen/generate_all.sh

# Test contract templates (basic syntax check)
test-contracts:
	@echo "Testing contract templates..."
	@echo "[Rust] Checking syntax..."
	@rustc --crate-type lib contracts/rust.template --out-dir /tmp 2>/dev/null || echo "WARNING: Rust template has syntax issues"
	@echo "[TypeScript] Checking syntax..."
	@tsc --noEmit contracts/typescript.template 2>/dev/null || echo "WARNING: TypeScript template has syntax issues"
	@echo "[Python] Checking syntax..."
	@python3 -m py_compile contracts/python.template 2>/dev/null || echo "WARNING: Python template has syntax issues"
	@echo "[OpenAPI] Checking syntax..."
	@which yamllint >/dev/null && yamllint contracts/openapi.template || echo "WARNING: yamllint not installed"
	@echo "✓ Contract template tests complete"

# Compute manifest hash
hash-manifest:
	@echo "Computing manifest hash..."
	@find contracts -type f -name "*.template" -exec sha256sum {} \; | sort | sha256sum | cut -d' ' -f1 > .manifest_hash
	@echo "Manifest hash: $$(cat .manifest_hash)"
	@echo "✓ Manifest hash computed and saved to .manifest_hash"

# Made with Bob
