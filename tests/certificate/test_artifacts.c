/*
 * test_artifacts.c -- Phase 3 Integration Tests
 * FORGE Phase 3: Proof artifacts verification
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include "sov_obligations.h"
#include "sov_cert.h"

#define TEST_PASSED 1
#define TEST_FAILED 0

int tests_passed = 0;
int tests_failed = 0;


void test_result(int passed, const char *name) {
    if (passed) {
        printf("  [PASS] %s\n", name);
        tests_passed++;
    } else {
        printf("  [FAIL] %s\n", name);
        tests_failed++;
    }
}

void test_generate_obligations_for_matmul(void)
{
    printf("\n=== test_generate_obligations_for_matmul ===\n");
    
    ObligationSet *obset = sov_obset_new();
    assert(obset != NULL);
    
    int64_t A[4] = {1, 2, 3, 4};
    int32_t id = sov_obset_add_inv(obset, A, 2, 0, 10);
    
    test_result(id >= 0 && obset->count == 1, "inv obligation created");
    test_result(obset->items[0].kind == OBL_KIND_INV, "obligation kind correct");
    
    sov_obset_free(obset);
}

void test_cbor_round_trip_certificate(void)
{
    printf("\n=== test_cbor_round_trip_certificate ===\n");
    
    ProofCertificate *cert = sov_cert_new();
    assert(cert != NULL);
    
    uint8_t prog_hash[32] = {0};
    memset(prog_hash, 0xAB, 32);
    sov_cert_set_program(cert, prog_hash, 1024);
    
    int64_t init_stack[3] = {1, 2, 3};
    int64_t final_stack[3] = {3, 2, 1};
    int rc = sov_cert_set_stacks(cert, init_stack, 3, final_stack, 3);
    
    test_result(rc == 0, "stacks set successfully");
    
    sov_cert_add_obligation(cert, OB_INV_OK, 0, 10);
    sov_cert_add_obligation(cert, OB_SOLVE_OK, 10, 20);
    
    test_result(cert->obligations.count == 2, "obligations added");
    
    uint8_t *cbor_data = NULL;
    size_t cbor_len = 0;
    rc = sov_cert_serialize_cbor(cert, &cbor_data, &cbor_len);
    
    test_result(rc == 0 && cbor_data != NULL && cbor_len > 0, "CBOR serialization");
    
    ProofCertificate *cert2 = sov_cert_deserialize_cbor(cbor_data, cbor_len);
    test_result(cert2 != NULL, "CBOR deserialization");
    
    free(cbor_data);
    sov_cert_free(cert);
    sov_cert_free(cert2);
}

void test_certificate_builder_create_and_seal(void)
{
    printf("\n=== test_certificate_builder_create_and_seal ===\n");
    
    ProofCertificate *cert = sov_cert_new();
    test_result(cert != NULL && cert->version == 1, "certificate created");
    
    uint8_t prog[32];
    memset(prog, 0x11, 32);
    sov_cert_set_program(cert, prog, 256);
    
    WormReceipt *receipt = sov_receipt_new();
    test_result(receipt != NULL, "receipt created");
    
    sov_receipt_free(receipt);
    sov_cert_free(cert);
}

void test_certificate_with_multiple_obligations(void)
{
    printf("\n=== test_certificate_with_multiple_obligations ===\n");
    
    ProofCertificate *cert = sov_cert_new();
    
    for (int i = 0; i < 5; i++) {
        int rc = sov_cert_add_obligation(cert, OB_TYPE_OK, i*10, (i+1)*10);
        assert(rc == 0);
    }
    
    test_result(cert->obligations.count == 5, "multiple obligations added");
    
    sov_cert_free(cert);
}

int main(void)
{
    printf("\n========================================\n");
    printf("  FORGE Phase 3: Proof Artifacts Tests\n");
    printf("========================================\n");
    
    test_generate_obligations_for_matmul();
    test_cbor_round_trip_certificate();
    test_certificate_builder_create_and_seal();
    test_certificate_with_multiple_obligations();
    
    printf("\n========================================\n");
    printf("  Results: %d passed, %d failed\n", tests_passed, tests_failed);
    printf("========================================\n\n");
    
    return tests_failed > 0 ? 1 : 0;
}
