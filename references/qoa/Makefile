CC ?= gcc
QOA_URL ?= https://raw.githubusercontent.com/phoboslab/qoa/master/qoa.h

.PHONY: bench_file bench_mem clean all fetch_qoa

# Fetch QOA reference header if not present
qoa.h:
	@echo "Fetching QOA reference header..."
	@curl -s -o qoa.h $(QOA_URL)

fetch_qoa: qoa.h

bench_file: reference_decode_file
reference_decode_file: reference_decode_file.c qoa.h
	$(CC) -std=c99 -O3 -DQOA_IMPLEMENTATION reference_decode_file.c -o reference_decode_file -lm

QOA_EMBED ?= ../../examples/bench/jungle_dash__pogo.qoa
embedded_qoa.h: $(QOA_EMBED)
	xxd -i -n embedded_qoa_bytes $(QOA_EMBED) > $@

bench_mem: reference_decode_mem
reference_decode_mem: reference_decode_mem.c qoa.h embedded_qoa.h
	$(CC) -std=c99 -O3 reference_decode_mem.c -o reference_decode_mem -lm

all: bench_file bench_mem

clean:
	$(RM) reference_decode_file reference_decode_mem embedded_qoa.h qoa.h
