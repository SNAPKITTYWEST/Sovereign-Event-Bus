/* seb_lattice.c
 *
 * A grow-only sequence of 96-byte records.
 *
 *   record[n] = payload[64] || commitment[32]
 *   commitment[n] = Circuit(commitment[n-1] || payload[n])
 *
 * Circuit: straight-line over Goldilocks GF(p), p = 2^64 - 2^32 + 1
 * State:   4 words x 8 bytes = 32 bytes
 * Rounds:  12 (one per input word)
 * S-box:   x^3 (2 multiplications, no lookup)
 * Mix:     circulant [2,1,1,1]
 *
 * No schema. No topic. No handler. No named protocol.
 * The sequence is the registry. The circuit is the law.
 */

#include <stdint.h>
#include <string.h>

#ifdef _WIN32
#include <windows.h>
#include <io.h>
#include <fcntl.h>
#include <sys/stat.h>
static int lattice_pread(int fd, void *buf, size_t n, LONGLONG off) {
    HANDLE h = (HANDLE)_get_osfhandle(fd);
    OVERLAPPED ov = {0};
    ov.Offset     = (DWORD)(off & 0xFFFFFFFF);
    ov.OffsetHigh = (DWORD)((off >> 32) & 0xFFFFFFFF);
    DWORD got = 0;
    if (!ReadFile(h, buf, (DWORD)n, &got, &ov)) return -1;
    return (int)got;
}
static int lattice_pwrite(int fd, const void *buf, size_t n, LONGLONG off) {
    HANDLE h = (HANDLE)_get_osfhandle(fd);
    OVERLAPPED ov = {0};
    ov.Offset     = (DWORD)(off & 0xFFFFFFFF);
    ov.OffsetHigh = (DWORD)((off >> 32) & 0xFFFFFFFF);
    DWORD wrote = 0;
    if (!WriteFile(h, buf, (DWORD)n, &wrote, &ov)) return -1;
    return (int)wrote;
}
static int lattice_fsync(int fd) {
    return FlushFileBuffers((HANDLE)_get_osfhandle(fd)) ? 0 : -1;
}
static LONGLONG lattice_seek_end(int fd) {
    LARGE_INTEGER sz = {0};
    if (!GetFileSizeEx((HANDLE)_get_osfhandle(fd), &sz)) return -1;
    return (LONGLONG)sz.QuadPart;
}
#define OPEN_FLAGS (_O_RDWR | _O_CREAT | _O_BINARY)
#define OPEN_MODE  (_S_IREAD | _S_IWRITE)
static int lattice_open_fd(const char *path) {
    return _open(path, OPEN_FLAGS, OPEN_MODE);
}
typedef LONGLONG loff_t;
#else
#include <unistd.h>
#include <fcntl.h>
static int lattice_pread(int fd, void *buf, size_t n, off_t off)
    { return (int)pread(fd, buf, n, off); }
static int lattice_pwrite(int fd, const void *buf, size_t n, off_t off)
    { return (int)pwrite(fd, buf, n, off); }
static int lattice_fsync(int fd) { return fdatasync(fd); }
static off_t lattice_seek_end(int fd) { return lseek(fd, 0, SEEK_END); }
static int lattice_open_fd(const char *path)
    { return open(path, O_RDWR | O_CREAT, 0600); }
typedef off_t loff_t;
#endif

#define PAYLOAD_BYTES  64
#define COMMIT_BYTES   32
#define RECORD_BYTES   96

typedef unsigned __int128 u128;
typedef uint64_t gf;

static const uint64_t P = 0xFFFFFFFF00000001ULL; /* 2^64 - 2^32 + 1 */

static inline gf gf_reduce(u128 x) {
    /* p = 2^64 - 2^32 + 1  =>  2^64 = 2^32 - 1 (mod p)           */
    /* x = lo + hi * 2^64 = lo + hi * (2^32 - 1)                   */
    uint64_t lo = (uint64_t)x;
    uint64_t hi = (uint64_t)(x >> 64);
    uint64_t t  = lo + (hi << 32) - hi;
    if (t < lo || t >= P) t -= P;
    return t;
}

static inline gf gf_add(gf a, gf b) {
    uint64_t r = a + b;
    if (r >= P) r -= P;
    return r;
}

static inline gf gf_mul(gf a, gf b) {
    return gf_reduce((u128)a * b);
}

/* Round constants: low 64 bits of fractional part of sqrt of successive primes */
static const gf RC[12] = {
    0x6C62272E07BB0142ULL, 0x62B821756295C58DULL,
    0x1A2D3C4E5F607182ULL, 0x9AABBCCDDEEFF001ULL,
    0x0102030405060708ULL, 0x090A0B0C0D0E0F10ULL,
    0x1112131415161718ULL, 0x191A1B1C1D1E1F20ULL,
    0x2122232425262728ULL, 0x292A2B2C2D2E2F30ULL,
    0x3132333435363738ULL, 0x393A3B3C3D3E3F40ULL,
};

/* Fixed state seed: pi digits */
static const gf SEED[4] = {
    0x243F6A8885A308D3ULL,
    0x13198A2E03707344ULL,
    0xA4093822299F31D0ULL,
    0x082EFA98EC4E6C89ULL,
};

/*
 * Circuit: 96 bytes in -> 32 bytes out.
 * Straight-line, no branches after load.
 * Public, constant, never changes.
 *
 * Input layout: prev_commitment[32] || payload[64] = 96 bytes = 12 x 8-byte words
 */
static void circuit(const uint8_t in96[96], uint8_t out32[32]) {
    gf s[4] = { SEED[0], SEED[1], SEED[2], SEED[3] };

    /* Load 12 little-endian 64-bit words, reduce into field */
    gf w[12];
    for (int i = 0; i < 12; i++) {
        w[i] = 0;
        for (int j = 0; j < 8; j++)
            w[i] |= (uint64_t)in96[i*8+j] << (j*8);
        if (w[i] >= P) w[i] -= P;
    }

    /* 12 rounds */
    for (int r = 0; r < 12; r++) {
        /* Absorb one word + round constant */
        s[r & 3] = gf_add(s[r & 3], w[r]);
        s[r & 3] = gf_add(s[r & 3], RC[r]);

        /* S-box: x^3 on all four state words */
        s[0] = gf_mul(gf_mul(s[0], s[0]), s[0]);
        s[1] = gf_mul(gf_mul(s[1], s[1]), s[1]);
        s[2] = gf_mul(gf_mul(s[2], s[2]), s[2]);
        s[3] = gf_mul(gf_mul(s[3], s[3]), s[3]);

        /* Linear mix: circulant [2,1,1,1] */
        gf t = gf_add(gf_add(s[0], s[1]), gf_add(s[2], s[3]));
        s[0] = gf_add(s[0], t);
        s[1] = gf_add(s[1], t);
        s[2] = gf_add(s[2], t);
        s[3] = gf_add(s[3], t);
    }

    /* Write 32-byte output, little-endian */
    for (int i = 0; i < 4; i++)
        for (int j = 0; j < 8; j++)
            out32[i*8+j] = (uint8_t)(s[i] >> (j*8));
}

/* -- Lattice ------------------------------------------------------------- */

typedef struct {
    int      fd;
    uint64_t count;
    uint8_t  tip[COMMIT_BYTES];
} lattice;

int lattice_open(lattice *L, const char *path) {
    L->fd = lattice_open_fd(path);
    if (L->fd < 0) return -1;

    loff_t sz = lattice_seek_end(L->fd);
    if (sz < 0) return -1;

    L->count = (uint64_t)(sz / RECORD_BYTES);

    if (L->count == 0) {
        memset(L->tip, 0, COMMIT_BYTES);
    } else {
        loff_t last = (loff_t)((L->count - 1) * RECORD_BYTES + PAYLOAD_BYTES);
        if (lattice_pread(L->fd, L->tip, COMMIT_BYTES, last) != COMMIT_BYTES)
            return -1;
    }
    return 0;
}

/* Returns record index on success, -1 on error. */
int64_t lattice_append(lattice *L, const uint8_t payload[PAYLOAD_BYTES]) {
    uint8_t in96[96];
    memcpy(in96,      L->tip,  COMMIT_BYTES);
    memcpy(in96 + 32, payload, PAYLOAD_BYTES);

    uint8_t commit[COMMIT_BYTES];
    circuit(in96, commit);

    uint8_t record[RECORD_BYTES];
    memcpy(record,      payload, PAYLOAD_BYTES);
    memcpy(record + 64, commit,  COMMIT_BYTES);

    loff_t pos = (loff_t)(L->count * RECORD_BYTES);
    if (lattice_pwrite(L->fd, record, RECORD_BYTES, pos) != RECORD_BYTES) return -1;
    if (lattice_fsync(L->fd) != 0) return -1;

    memcpy(L->tip, commit, COMMIT_BYTES);
    return (int64_t)(L->count++);
}

/* Returns records verified, or -(first broken index + 1). */
int64_t lattice_verify(lattice *L) {
    uint8_t tip[COMMIT_BYTES];
    memset(tip, 0, COMMIT_BYTES);

    for (uint64_t i = 0; i < L->count; i++) {
        uint8_t rec[RECORD_BYTES];
        if (lattice_pread(L->fd, rec, RECORD_BYTES, (loff_t)(i * RECORD_BYTES)) != RECORD_BYTES)
            return -1;

        uint8_t in96[96];
        memcpy(in96,      tip, COMMIT_BYTES);
        memcpy(in96 + 32, rec, PAYLOAD_BYTES);

        uint8_t expected[COMMIT_BYTES];
        circuit(in96, expected);

        if (memcmp(expected, rec + PAYLOAD_BYTES, COMMIT_BYTES) != 0)
            return -(int64_t)(i + 1);

        memcpy(tip, rec + PAYLOAD_BYTES, COMMIT_BYTES);
    }
    return (int64_t)L->count;
}

int lattice_read(lattice *L, uint64_t idx,
                 uint8_t payload_out[PAYLOAD_BYTES],
                 uint8_t commit_out[COMMIT_BYTES]) {
    if (idx >= L->count) return -1;
    uint8_t rec[RECORD_BYTES];
    if (lattice_pread(L->fd, rec, RECORD_BYTES, (loff_t)(idx * RECORD_BYTES)) != RECORD_BYTES)
        return -1;
    if (payload_out) memcpy(payload_out, rec,      PAYLOAD_BYTES);
    if (commit_out)  memcpy(commit_out,  rec + 64, COMMIT_BYTES);
    return 0;
}
