# Security Policy for Sovereign Forge

## Threat Model

Sovereign Forge is a deterministic proof verification system designed to provide cryptographic assurance of exact linear algebra computations. This document outlines the security properties we provide and the boundaries of our guarantees.

### What We Prove

1. **Deterministic Computation Integrity**
   - Proof certificates cryptographically bind inputs, algorithms, and outputs
   - Blake3/Ed25519 signatures prevent tampering with computation traces
   - WORM (Write-Once Read-Many) ledger architecture ensures immutability

2. **Type Safety**
   - Typed execution prevents category errors in linear algebra operations
   - Lean 4 formal refinement proofs establish correctness of type rules
   - Typecheck phase enforces preconditions before computation begins

3. **Memory Safety**
   - ASan/UBSan clean: no buffer overflows, use-after-free, signed integer overflows
   - Stack machine architecture eliminates arbitrary pointer manipulation
   - All memory allocations are statically bounded

4. **Serialization Fidelity**
   - Canonical JSON representation prevents encoding attacks
   - Deterministic sorting of certificate fields
   - Serialization proofs formally verified in Lean 4

5. **Exact Arithmetic**
   - All linear algebra uses rational/algebraic numbers (no floating-point)
   - Rational arithmetic library proven correct via Lean 4 refinement
   - Rounding errors are impossible by design

### What We Don't Prove

1. **Availability**
   - Sovereign Forge does not guarantee liveness or DoS resistance
   - Proof verification may be computationally expensive for large matrices
   - No guarantees about wall-clock time or resource consumption

2. **Privacy**
   - All computation traces are deterministic and reproducible
   - Proof certificates contain full data flow information
   - Sensitive data should be encrypted before being embedded in proofs

3. **Hardware Security**
   - Vulnerable to physical attacks (fault injection, side-channel)
   - Assumes honest execution environment; no TEE/SEV integration
   - Side-channel timing attacks are not mitigated

4. **Key Management**
   - Sovereign Forge assumes signing keys are protected by external systems
   - Key rotation, distribution, and revocation are out of scope
   - Compromised keys lead to forged proofs (this is not a key escrow system)

5. **Consensus/Replication**
   - Single-machine proof verification
   - Multi-node agreement is handled by external consensus layers
   - No Byzantine fault tolerance built in

## Security Boundaries

### In-Scope Threats

- **Computation Tampering**: Attacker modifies certificate to claim different result
- **Input Substitution**: Attacker claims proof verifies different input matrix
- **Serialization Attacks**: Attacker exploits non-canonical encoding
- **Type Confusion**: Attacker violates preconditions for operations

### Out-of-Scope Threats

- **Insider Threats**: System operator with signing key access
- **Hardware Faults**: Bit flips, speculative execution attacks
- **Denial of Service**: Malicious workloads designed to exhaust CPU/memory
- **Supply Chain**: Compromised build tools, malicious dependencies
- **Cryptographic Breaks**: Future advances in hash/signature algorithm attacks

## Responsible Disclosure

If you discover a security vulnerability:

1. **Do not open a public GitHub issue**
2. **Email privately**: Send details to the maintainers with subject line `[SECURITY]`
3. **Allow 90 days**: For researchers and vendors to implement fixes
4. **Coordinated disclosure**: We will work with you on a timeline

### Vulnerability Response SLA

- **Critical (RCE, signature bypass)**: Response within 48 hours, patch within 72 hours
- **High (DoS, memory corruption)**: Response within 1 week, patch within 2 weeks
- **Medium (information disclosure)**: Response within 2 weeks, patch within 1 month

## Attestation & Verification

### Build Reproducibility

All builds are reproducible. To verify:

```bash
git clone https://github.com/SNAPKITTYWEST/bobs-control-repo.git
cd bobs-control-repo
make -f netlister/Makefile.sov clean all
sha256sum build/sov_verifier > /tmp/my.sha256
# Compare against release binary
```

### Proof Certificate Structure

Each certificate is a JSON object with:
- `version`: Protocol version (immutable)
- `algorithm`: Linear algebra operation (immutable)
- `input_hash`: Blake3 hash of input matrix
- `output_hash`: Blake3 hash of output matrix
- `trace`: Execution trace with intermediate values
- `signature`: Ed25519 signature over all of above

### Signature Verification

```bash
cd certificates
jq -S . < example.json | sha256sum  # Deterministic ordering
# Verify Ed25519 signature against issuer's public key
```

## Testing & Fuzzing

- **Phase 1 Fuzzing**: 1M+ libFuzzer iterations, 42 conformance tests
- **Phase 2 Typecheck**: 12 tests covering type rule violations
- **Phase 3 Certificate**: 10 tests covering tampering scenarios
- **Phase 4 Receipts**: 8 tests covering provenance tracking
- **Phase 5 Refinement**: 15 Lean 4 formal proofs

All tests pass with ASan and UBSan enabled in CI/CD.

## Cryptographic Details

### Hash Function
- **Algorithm**: Blake3
- **Output size**: 256 bits
- **Justification**: Cryptographically secure, deterministic, resistant to length-extension attacks

### Signing Algorithm
- **Algorithm**: Ed25519
- **Key size**: 256 bits (32 bytes)
- **Verification**: RFC 8032 compliant
- **Justification**: Post-quantum resistant signature scheme with low overhead

### Serialization
- **Format**: JSON (RFC 8259)
- **Canonicalization**: RFC 7159 style (no whitespace, sorted keys)
- **Character encoding**: UTF-8

## Known Limitations

1. **Floating-point Integration**: If you need to integrate with floating-point systems, you must convert to exact rationals before verification.

2. **Large Matrices**: Proof size grows with matrix dimensions. 10,000x10,000 matrices will produce megabyte-scale certificates.

3. **Network Attacks**: Proofs are vulnerable to man-in-the-middle attacks if transmitted over unencrypted channels. Use TLS/mTLS for network transmission.

4. **Timestamp Attacks**: Proof certificates do not include timestamps. Add external timestamping if ordering is required.

## Compliance & Standards

- **Code Quality**: MISRA C guidelines (where applicable)
- **Testing**: MCDC coverage > 90% on critical paths
- **Documentation**: NIST SP 800-53 security-relevant documentation
- **Formal Methods**: Lean 4 proofs for refinement layer

## Contributors & Acknowledgments

- **Ahmad Ali Parr**: Architectural design, threat modeling
- **Jessica Westerhoff**: Coordination, testing framework
- **Claude Haiku 4.5**: Formal verification, implementation

## Further Reading

- OWASP Top 10 for Cryptographic Implementations: https://owasp.org/www-project-top-ten/
- NIST SP 800-38 (Cryptographic Modes): https://nvlpubs.nist.gov/nistpubs/Legacy/SP/nistspecialpublication800-38d.pdf
- RFC 8032 (Edwards-Curve Signatures): https://tools.ietf.org/html/rfc8032

---

**Last Updated**: July 29, 2026
**Version**: 1.0.0
**Status**: Production
