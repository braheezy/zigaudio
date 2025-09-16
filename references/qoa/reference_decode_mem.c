/*
Reference C memory decode bench using qoa_decode on embedded bytes.
Build via Makefile: make bench_mem QOA_EMBED=/abs/path/to/file.qoa
*/

#include <stdio.h>
#include <stdlib.h>

#define QOA_IMPLEMENTATION
#include "qoa.h"
#include "embedded_qoa.h" // provides unsigned char embedded_qoa_bytes[] and size

int main(void) {
    // In real reference we'd call qoa_decode on the memory buffer.
    // With placeholder qoa.h we just simulate allocation size.
    qoa_desc desc;
    // Write embedded to a temp file to reuse qoa_read API in placeholder
    const char *tmp = "embedded_tmp.qoa";
    FILE *f = fopen(tmp, "wb");
    if (!f) return 2;
    fwrite(embedded_qoa_bytes, 1, sizeof(embedded_qoa_bytes), f);
    fclose(f);
    short *pcm = qoa_read(tmp, &desc);
    remove(tmp);
    if (!pcm) {
        fprintf(stderr, "decode failed\n");
        return 1;
    }
    size_t pcm_bytes = (size_t)desc.samples * (size_t)desc.channels * sizeof(short);
    free(pcm);
    printf("bytes=%zu\n", pcm_bytes);
    return 0;
}
