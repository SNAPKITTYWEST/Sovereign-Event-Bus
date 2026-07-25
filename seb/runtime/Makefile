.PHONY: all clean build release test dialyzer edoc help

help:
	@echo "SEB L2 Runtime Targets:"
	@echo "  make build          - Build the SEB runtime"
	@echo "  make release        - Build release tarball"
	@echo "  make test           - Run unit and integration tests"
	@echo "  make dialyzer       - Run static analysis (dialyzer)"
	@echo "  make edoc           - Generate documentation"
	@echo "  make clean          - Clean build artifacts"

all: clean build

build:
	rebar3 compile

release: build
	rebar3 release

test:
	rebar3 eunit --dir test/

dialyzer:
	rebar3 dialyzer

edoc:
	rebar3 edoc

clean:
	rebar3 clean
	rm -rf _build

## Development targets

console: build
	rebar3 shell

dev-release:
	rebar3 release
	./_build/default/rel/seb_release/bin/seb_release console

## Analysis targets

xref:
	rebar3 xref

cover:
	rebar3 do eunit, cover

docs:
	@echo "SEB L2 Runtime Documentation"
	@echo "==============================="
	@echo ""
	@echo "Architecture:"
	@echo "  - seb_sup: Supervision tree root"
	@echo "  - seb_agent_sup: Dynamic agent supervisor"
	@echo "  - seb_agent_fsm: 4-state agent lifecycle FSM"
	@echo "  - seb_partition_mgr: Deterministic partition assignment"
	@echo "  - seb_datalog_bridge: Policy engine bridge"
	@echo "  - seb_kernel_nif: Ada kernel interface"
	@echo ""
	@echo "L2 Invariants Enforced:"
	@echo "  1. Plasma Gate: Ed25519 signature valid"
	@echo "  2. Hash Chain: Prev_Hash == current tip hash"
	@echo "  3. Offset Monotonic: Event offset > prior offset"
	@echo "  4. Payload Hash: blake3(header || payload) matches footer"
	@echo "  5. Segment Chain: Prev_Seg_Hash links to prior segment"
	@echo ""
	@echo "Success Criteria:"
	@echo "  - rebar3 release builds: seb_release.tar.gz"
	@echo "  - dialyzer: zero warnings"
	@echo "  - Agent drain: < 30s timeout"
	@echo "  - NIF calls: test vectors pass"
	@echo "  - Partition assignment: deterministic (same seed → same result)"

## Integration test helpers

start-dev-node:
	rebar3 shell --sname seb@127.0.0.1

start-cluster:
	@echo "Starting 3-node cluster..."
	cd _build/default/rel/seb_release && \
	bin/seb_release -sname node1@127.0.0.1 -pa _build/default/lib/*/ebin &
	sleep 2
	cd _build/default/rel/seb_release && \
	bin/seb_release -sname node2@127.0.0.1 -pa _build/default/lib/*/ebin &
	sleep 2
	cd _build/default/rel/seb_release && \
	bin/seb_release -sname node3@127.0.0.1 -pa _build/default/lib/*/ebin &

verify-build: build dialyzer test
	@echo ""
	@echo "✓ Build completed"
	@echo "✓ Dialyzer: no type errors"
	@echo "✓ Tests passed"
	@echo ""
	@echo "Ready for Ahmad Integrity Gate review."
