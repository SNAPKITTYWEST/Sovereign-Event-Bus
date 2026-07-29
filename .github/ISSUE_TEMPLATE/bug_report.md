---
name: Bug Report
about: Report a security, correctness, or performance issue
title: "[BUG] "
labels: bug
assignees: ''

---

## Bug Category

- [ ] Security (authentication, authorization, cryptography, DoS)
- [ ] Correctness (wrong computation result, algorithm error)
- [ ] Performance (excessive CPU/memory, timeouts)
- [ ] Memory Safety (crash, undefined behavior)
- [ ] Other (describe below)

## Severity

- [ ] Critical (immediate exploitation, data loss, complete failure)
- [ ] High (significant impact, partial failure, workaround exists)
- [ ] Medium (limited impact, workaround available)
- [ ] Low (cosmetic, edge case, minimal impact)

## Description

Clearly describe the bug. What did you expect to happen? What actually happened?

## Minimal Reproducible Example

Provide the smallest code snippet that reproduces the issue:

```c
// Your minimal example here
// Include matrix dimensions, inputs, and expected vs actual output
```

## Steps to Reproduce

1. (First step)
2. (Second step)
3. (etc.)

## Expected Behavior

What should have happened?

## Actual Behavior

What actually happened?

## Environment

- **OS**: (e.g., Ubuntu 22.04 x86_64)
- **Compiler**: (e.g., gcc-11, clang-14)
- **Version**: (commit hash or version number)
- **Build Configuration**: (Debug, Release, with/without ASan/UBSan)

## Certificate & Trace

If applicable, attach the proof certificate that triggered the bug:

```json
{
  "version": "1.0.0",
  "algorithm": "...",
  "...": "..."
}
```

Or the execution trace:

```
Step 0: ...
Step 1: ...
```

## Error Output

Include full error messages, stack traces, or assertion failures:

```
[Error message here]
```

## Additional Context

Any other context about the problem?

---

## Security Considerations

**If this is a security issue:**
- Do NOT include sensitive data or cryptographic keys
- Do NOT open a public issue; email maintainers privately
- Provide sufficient detail for reproduction without endangering systems

See [SECURITY.md](../../SECURITY.md) for responsible disclosure guidelines.
