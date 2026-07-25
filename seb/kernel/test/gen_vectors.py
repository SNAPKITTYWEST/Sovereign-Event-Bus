#!/usr/bin/env python3
"""
Generate deterministic test vectors for SEB kernel verification.

Wire layout:
  Event = 68-byte Header || variable Payload || 128-byte Footer
  Header: event_type_id(8) || timestamp_ns(8) || agent_id(8) || payload_size(4) ||
          partition_id(4) || prev_offset(8) || sequence_no(8) || reserved(12) = 68 bytes
  Footer: prev_hash(32) || event_hash(32) || signature(64) = 128 bytes
"""

import struct
import hashlib
import os
import sys

def blake3_hash(data):
    """Simulate BLAKE3 (using SHA256 for determinism in test)."""
    return hashlib.sha256(data).digest()

def ed25519_sign(message, secret_key):
    """Simulate Ed25519 signature (using HMAC-SHA256 for determinism)."""
    import hmac
    sig = hmac.new(secret_key, message, hashlib.sha256).digest()
    # Pad to 64 bytes
    return (sig + b"\x00" * 64)[:64]

def ed25519_verify(message, signature, public_key):
    """Verify simulated Ed25519 signature."""
    expected = ed25519_sign(message, public_key)
    return signature == expected[:64]

# Test Vector 1: Valid event with correct signature and hash
def gen_vector_append_valid():
    """Generate: append_valid.bin (valid event)"""

    # Fixed seed for determinism
    seed = b"test_vector_1_seed_12345678901234"

    # Event header (68 bytes)
    event_type_id = 1  # snapkitty.intent.verify_proof
    timestamp_ns = 1719292980000000000  # 2026-07-25
    agent_id = 42
    payload_size = 256
    partition_id = 0
    prev_offset = 0
    sequence_no = 1
    reserved1 = 0
    reserved2 = 0
    reserved3 = 0

    header = struct.pack(
        "<QQQQIIQQQI",
        event_type_id, timestamp_ns, agent_id, payload_size,
        partition_id, prev_offset, sequence_no, reserved1,
        reserved2, reserved3
    )

    assert len(header) == 68, f"Header size wrong: {len(header)}"

    # Payload (256 bytes of deterministic data)
    payload = seed * (payload_size // len(seed) + 1)
    payload = payload[:payload_size]

    # Event hash = blake3(header || payload)
    event_hash = blake3_hash(header + payload)
    assert len(event_hash) == 32

    # Signature = ed25519_sign(event_hash, secret_key)
    secret_key = hashlib.sha256(b"secret_key_seed_1").digest()
    signature = ed25519_sign(event_hash, secret_key)
    assert len(signature) == 64

    # Prior hash (genesis, all zeros)
    prev_hash = b"\x00" * 32

    # Event footer (128 bytes)
    footer = prev_hash + event_hash + signature
    assert len(footer) == 128

    # Write vector
    vector = header + payload + footer
    with open("/c/Users/jessi/Desktop/bobs control repo/seb/kernel/test/vectors/append_valid.bin", "wb") as f:
        f.write(vector)

    print(f"✓ append_valid.bin: {len(vector)} bytes")
    print(f"  Header: event_type={event_type_id}, payload_size={payload_size}")
    print(f"  Payload: {len(payload)} bytes")
    print(f"  Footer: hash={event_hash.hex()[:16]}..., sig={signature.hex()[:16]}...")

# Test Vector 2: Invalid signature (should be rejected)
def gen_vector_apply_invalid_sig():
    """Generate: apply_invalid_sig.bin (tampered signature)"""

    seed = b"test_vector_2_seed_12345678901234"

    # Same structure as Vector 1
    event_type_id = 1
    timestamp_ns = 1719292980000000000
    agent_id = 42
    payload_size = 256
    partition_id = 0
    prev_offset = 0
    sequence_no = 2
    reserved1 = 0
    reserved2 = 0
    reserved3 = 0

    header = struct.pack(
        "<QQQQIIQQQI",
        event_type_id, timestamp_ns, agent_id, payload_size,
        partition_id, prev_offset, sequence_no, reserved1,
        reserved2, reserved3
    )

    payload = seed * (payload_size // len(seed) + 1)
    payload = payload[:payload_size]

    event_hash = blake3_hash(header + payload)

    # Create WRONG signature (tampered)
    wrong_signature = b"\xff" * 64

    prev_hash = b"\x00" * 32
    footer = prev_hash + event_hash + wrong_signature

    vector = header + payload + footer
    with open("/c/Users/jessi/Desktop/bobs control repo/seb/kernel/test/vectors/apply_invalid_sig.bin", "wb") as f:
        f.write(vector)

    print(f"✓ apply_invalid_sig.bin: {len(vector)} bytes (tampered signature)")

# Test Vector 3: Segment rotation
def gen_vector_rotate_segment():
    """Generate: rotate_segment.bin (segment rotation test)"""

    # Segment header (64 bytes)
    segment_id = 1
    segment_sequence = 1
    prev_seg_hash = b"\x00" * 32
    segment_size = 1024

    seg_header = struct.pack(
        "<QQQI",
        segment_id, segment_sequence, segment_size
    ) + prev_seg_hash

    # Pad to 64 bytes
    seg_header = seg_header + b"\x00" * (64 - len(seg_header))

    assert len(seg_header) == 64

    # Followed by a single event
    seed = b"segment_rotation_seed_1234567890"
    event_type_id = 1
    timestamp_ns = 1719292980000000000
    agent_id = 99
    payload_size = 128
    partition_id = 0
    prev_offset = 0
    sequence_no = 1

    header = struct.pack(
        "<QQQQIIQQQI",
        event_type_id, timestamp_ns, agent_id, payload_size,
        partition_id, prev_offset, sequence_no, 0, 0, 0
    )

    payload = seed * (payload_size // len(seed) + 1)
    payload = payload[:payload_size]

    event_hash = blake3_hash(header + payload)
    prev_hash = b"\x00" * 32
    signature = ed25519_sign(event_hash, hashlib.sha256(b"secret_key_seed_2").digest())

    footer = prev_hash + event_hash + signature

    vector = seg_header + header + payload + footer
    with open("/c/Users/jessi/Desktop/bobs control repo/seb/kernel/test/vectors/rotate_segment.bin", "wb") as f:
        f.write(vector)

    print(f"✓ rotate_segment.bin: {len(vector)} bytes (segment rotation)")

if __name__ == "__main__":
    os.makedirs("/c/Users/jessi/Desktop/bobs control repo/seb/kernel/test/vectors", exist_ok=True)
    gen_vector_append_valid()
    gen_vector_apply_invalid_sig()
    gen_vector_rotate_segment()
    print("\n✓ All test vectors generated successfully")
