# BOB Quick Start Guide
## From Zero to Enterprise Automation in 5 Minutes

**Version:** 1.0.0  
**Status:** Production Ready  
**For:** First-time users, developers, operations teams

---

## ⚡ 5-Minute Setup

### Step 1: Clone Repository (30 seconds)
```bash
git clone https://github.com/SNAPKITTYWEST/bobs-sovereign-automation
cd bobs-sovereign-automation
```

### Step 2: Install Tools (1 minute)
```bash
# Make SovereignShell commands executable
chmod +x bob-shell/*.sh

# Add to PATH (permanent)
echo 'export PATH="$PATH:$(pwd)/bob-shell"' >> ~/.bashrc
source ~/.bashrc

# Verify installation
bob-build --help
```

### Step 3: Run Your First Build (2 minutes)
```bash
# Compile with formal verification
bob-build compiler --verify --profile=prod

# Watch the build
# Output goes to: ./build/compiler-build-report-*.txt
```

### Step 4: Run Tests (1 minute)
```bash
# Deterministic testing (reproducible)
bob-test --deterministic --coverage

# View results
# Output goes to: ./test-report-*.txt
```

### Step 5: Generate Audit Trail (30 seconds)
```bash
# Cryptographically sealed audit
bob-audit compiler --format=json

# View audit records
# Output goes to: ./.audit/
```

---

## 🎯 Common Tasks

### Deploy to Production
```bash
# 1. Verify policy compliance
bob-policy query "verify_deed(deploy_production, Verdict)" --explain

# 2. Build with verification
bob-build runtime --verify --profile=prod

# 3. Run tests deterministically
bob-test --deterministic

# 4. Generate deployment seal
bob-deploy production --validate --seal

# 5. Check deployment manifest
cat .deploy/DEPLOYMENT_MANIFEST.json
```

### Verify Formal Guarantees
```bash
# Lean 4 proofs
bob-proof protocol_correctness --backend=lean4

# Ada/SPARK contracts
bob-proof state_transition_valid --backend=ada

# Coq proofs (advanced)
bob-proof compiler_correctness --backend=coq
```

### Query Policy Rules
```bash
# Simple policy query
bob-policy query "agent_class(oracle, X)"

# With reasoning trace
bob-policy query "route_task(compile, Agent, Priority)" --explain

# Fiscal governance check
bob-policy query "authorize_settlement(Amount, Agent)" --explain
```

### Generate Audit Records
```bash
# JSON format (machine-readable)
bob-audit compiler --format=json

# Text format (human-readable)
bob-audit runtime --format=text

# All components
for comp in compiler runtime adapters; do
    bob-audit $comp --format=json
done
```

---

## 📁 Understanding the Layout

```
bobs-sovereign-automation/
├── bob-shell/                    # SovereignShell commands (6 tools)
│   ├── bob-build.sh             # Build with verification
│   ├── bob-test.sh              # Deterministic testing
│   ├── bob-audit.sh             # Audit trail generation
│   ├── bob-policy.sh            # Policy queries
│   ├── bob-deploy.sh            # Sealed deployment
│   ├── bob-proof.sh             # Formal verification
│   └── README.md                # Command reference
│
├── seb/                          # Core 7 layers
│   ├── kernel/                  # L1 Ada/SPARK (verified)
│   ├── runtime/                 # L2 Erlang/OTP
│   ├── adapters/                # L4 RPG/PL-I
│   ├── reasoning/               # L6 Rust reasoning
│   ├── universe/                # L7 Rust universe
│   ├── verification/            # L0 proofs
│   └── README.md                # SEB architecture
│
├── ENTERPRISE_EDITION.md         # Pricing + services
├── BOB_TRUST_DEED_V1.md         # Governance framework
├── BOB_OPERATIONAL_CONTRACT.md  # Interaction protocols
├── RELEASE_NOTES_v1.0.0.md      # What's new
└── QUICK_START_GUIDE.md         # This file
```

---

## ✅ Verification Checklist

After setup, verify everything works:

```bash
# [ ] SovereignShell commands in PATH
which bob-build

# [ ] Build compiles cleanly
bob-build compiler --profile=dev

# [ ] Tests pass deterministically
bob-test --deterministic

# [ ] Audit seal generates
bob-audit compiler --format=json

# [ ] Policy queries work
bob-policy query "system_ready(X)"

# [ ] Deployment package creates
bob-deploy staging --no-validate

# [ ] Formal verification backend found
bob-proof dummy --backend=lean4 2>&1 | head -5
```

✅ **All passing?** You're ready for production!

---

## 🚀 Example: Complete Production Workflow

```bash
#!/bin/bash
# production-deploy.sh

echo "=== BOB Production Deployment ==="

# 1. Verify policy compliance
echo "[1/5] Verifying policy compliance..."
bob-policy query "verify_deed(deploy_production, Verdict)" --explain

# 2. Build with verification
echo "[2/5] Building runtime..."
bob-build runtime --verify --profile=prod

# 3. Run deterministic tests
echo "[3/5] Running deterministic tests..."
bob-test runtime --deterministic --coverage

# 4. Generate audit trail
echo "[4/5] Generating audit trail..."
bob-audit runtime --format=json

# 5. Deploy with seal
echo "[5/5] Deploying to production..."
bob-deploy production --validate --seal

echo ""
echo "✅ DEPLOYMENT COMPLETE"
echo "Audit records: ./.audit/"
echo "Deployment manifest: ./.deploy/DEPLOYMENT_MANIFEST.json"
echo "Deployment seal: ./.deploy/DEPLOYMENT_SEAL.txt"
```

**Run:**
```bash
chmod +x production-deploy.sh
./production-deploy.sh
```

---

## 🔍 Troubleshooting

### "Command not found: bob-build"
```bash
# Add to PATH
export PATH="$PATH:$(pwd)/bob-shell"

# Make permanent
echo 'export PATH="$PATH:$(cd "$(dirname "$0")" && pwd)/bob-shell"' >> ~/.bashrc
source ~/.bashrc
```

### "Permission denied"
```bash
# Make scripts executable
chmod +x bob-shell/*.sh
```

### "Lean 4 not found"
```bash
# Install Lean 4
curl https://raw.githubusercontent.com/leanprover/elan/master/elan-init.sh -sSf | sh

# For Ada/SPARK
sudo apt-get install gnat-community
```

### Tests failing non-deterministically
```bash
# Force deterministic mode
export RUST_TEST_THREADS=1
export RUST_TEST_SEED=42
bob-test --deterministic
```

---

## 📊 Performance Expectations

| Task | Time | Notes |
|------|------|-------|
| Build (dev) | 5–10 sec | Incremental |
| Build (prod) | 30–60 sec | Full optimization |
| Tests | 2–5 min | Deterministic, reproducible |
| Audit | <1 sec | Cryptographic seal only |
| Deploy (staging) | 1–3 min | Includes validation |
| Proof (Lean) | 30–120 sec | Depends on theorem complexity |

---

## 🎓 Next Steps

1. **Read** [ENTERPRISE_EDITION.md](./ENTERPRISE_EDITION.md) for pricing and support
2. **Review** [BOB_TRUST_DEED_V1.md](./BOB_TRUST_DEED_V1.md) for governance
3. **Study** [bob-shell/README.md](./bob-shell/README.md) for detailed command reference
4. **Explore** [seb/README.md](./seb/README.md) for architecture deep-dive

---

## 💬 Get Help

- **Issues:** GitHub Issues
- **Email:** support@snapkittywest.dev
- **Sales:** sales@snapkittywest.dev
- **Security:** security@snapkittywest.dev

---

## ✨ You're Ready!

You now have **enterprise-grade agent automation** running locally.

- ✅ 7 complete layers
- ✅ 6 verified tools
- ✅ Formal proofs
- ✅ Production ready

**Deploy with confidence.**

---

*BOB Sovereign Enterprise Automation Fabric*  
*v1.0.0 — Production Release*  
© 2026 SNAPKITTYWEST. Apache 2.0 + AGPL 3.0 licensed.
