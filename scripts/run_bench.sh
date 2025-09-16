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

ZIG_BIN=${ZIG_BIN:-zig}
if ! "$ZIG_BIN" version | grep -q "0.15."; then
  ALT_ZIG="/Users/michaelbraha/Library/Application Support/Cursor/User/globalStorage/ziglang.vscode-zig/zig/aarch64-macos-0.15.1/zig"
  if [ -x "$ALT_ZIG" ]; then
    ZIG_BIN="$ALT_ZIG"
  else
    echo "Warning: zig 0.15.x not found; using $($ZIG_BIN version) which may fail." >&2
  fi
fi

echo "==> Building Zig artifacts (ReleaseFast) with $ZIG_BIN"
"$ZIG_BIN" build -Doptimize=ReleaseFast install > /dev/null

echo "==> Building C reference (file)"
make -C references/qoa bench_file > /dev/null

ZIG_BENCH=./zig-out/bin/bench
C_BENCH_FILE=./references/qoa/reference_decode_file

if [ ! -x "$ZIG_BENCH" ]; then
  echo "Error: Zig bench binary not found at $ZIG_BENCH" >&2
  exit 1
fi
if [ ! -x "$C_BENCH_FILE" ]; then
  echo "Error: C bench binary not found at $C_BENCH_FILE" >&2
  exit 1
fi

echo "==> Comparing file decode Zig vs C"
hyperfine --warmup 3 --min-runs 30 \
  "./zig-out/bin/bench_file $ABS_INPUT" \
  "$C_BENCH_FILE $ABS_INPUT"
