/*
Reference C file decode bench using qoa_read from a filepath.
Build via Makefile: make bench_file
Usage: ./reference_decode_file <input.qoa>
*/

#include <stdio.h>
#include <stdlib.h>

#include "qoa.h"

int main(int argc, char **argv) {
    if (argc < 2) {
        fprintf(stderr, "usage: %s <input.qoa>\n", argv[0]);
        return 2;
    }
    qoa_desc desc;
    short *sample_data = qoa_read(argv[1], &desc);
    if (!sample_data) {
        fprintf(stderr, "decode failed: %s\n", argv[1]);
        return 1;
    }
    size_t pcm_bytes = (size_t)desc.samples * (size_t)desc.channels * sizeof(short);
    free(sample_data);
    printf("bytes=%zu\n", pcm_bytes);
    return 0;
}
