#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT_DIR"

if ! command -v hyperfine >/dev/null 2>&1; then
  echo "Error: hyperfine is not installed. Install it first (e.g., brew install hyperfine)." >&2
  exit 1
fi

if [ $# -lt 1 ]; then
  echo "Usage: $0 <input.qoa>" >&2
  exit 1
fi

INPUT="$1"
# Resolve absolute path for embedding
INPUT_DIR=$(cd "$(dirname "$INPUT")" && pwd)
INPUT_BASENAME=$(basename "$INPUT")
ABS_INPUT="$INPUT_DIR/$INPUT_BASENAME"

echo "==> Building Zig artifacts (ReleaseFast)"
zig build -Doptimize=ReleaseFast install > /dev/null

echo "==> Building C reference (qoa_decode_bench)"
make -C references/qoa bench > /dev/null

ZIG_BENCH=./zig-out/bin/bench
C_BENCH=./references/qoa/qoa_decode_bench

if [ ! -x "$ZIG_BENCH" ]; then
  echo "Error: Zig bench binary not found at $ZIG_BENCH" >&2
  exit 1
fi
if [ ! -x "$C_BENCH" ]; then
  echo "Error: C bench binary not found at $C_BENCH" >&2
  exit 1
fi

echo "==> Building C memory bench (embedded)"
make -C references/qoa QOA_EMBED="$ABS_INPUT" bench_mem > /dev/null

echo "==> Comparing memory decode Zig vs C"
hyperfine --warmup 3 --min-runs 30 \
  "$ZIG_BENCH" \
  ./references/qoa/reference_decode_mem
