# zigaudio

A Zig library for reading and writing audio files with a streaming-capable, format-agnostic API.

## Features

- **Streaming Support**: Decode audio without loading entire files into memory
- **Format Agnostic**: Unified API across different audio formats
- **Zero-Copy**: Efficient memory management with managed and unmanaged audio data

## Audio Format Support

| Format | Read | Write |
|--------|------|-------|
| QOA    | ✅   | ✅    |
| WAV    | ✅   | ❌    |

## Installation

Add to your `build.zig.zon`:

```bash
zig fetch --save git+https://github.com/braheezy/zig-audio
```

And in your `build.zig`:

```zig
const zigaudio = b.dependency("zigaudio", .{});
root_module.addImport("zigaudio", zigaudio.module("zigaudio"));
```

## Quick Start

### Streaming (default)

```zig
const std = @import("std");
const zigaudio = @import("zigaudio");

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    // Create streaming source using an internal buffer
    var stream = try zigaudio.fromPath(allocator, "song.qoa");
    defer stream.deinit();

    // Use with audio playback library
    // stream.readerInterface() provides std.Io.Reader for PCM data
    // stream.info contains AudioInfo for setup
    // Optionally pull a fixed amount:
    var small: [50 * 2 * @sizeOf(i16)]u8 = undefined; // 50 frames, 2ch, i16
    const frames = try stream.readFramesInto(&small);
}
```

### Unmanaged streaming (caller-provided buffers; no allocator)

```zig
const std = @import("std");
const zigaudio = @import("zigaudio");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
var in_buf: [64 * 1024]u8 = undefined;
var out_buf: [64 * 1024]u8 = undefined;
var stream = try zigaudio.fromPathUnmanaged("song.qoa", &in_buf, &out_buf);
    defer stream.deinit();
// Pull into your own buffer whenever you want
var slice: [1024]u8 = undefined;
const frames = try stream.readFramesInto(&slice);
}
```

### Full decode (all samples) from a stream

```zig
const std = @import("std");
const zigaudio = @import("zigaudio");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
var stream = try zigaudio.fromPath(allocator, "song.qoa");
defer stream.deinit();
// All samples (or use toAudioLimit on ManagedAudioStream for partial):
var audio = try stream.toAudio(allocator);
    defer audio.deinit();
    std.debug.print("frames: {} bytes: {}\n", .{ audio.frameCount(), audio.data.len });
}
```

### Encode to file

```zig
const std = @import("std");
const zigaudio = @import("zigaudio");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    var audio = try zigaudio.decodePath(allocator, "song.wav");
    defer audio.deinit();
    try zigaudio.encodeToPath(.qoa, "out.qoa", &audio);
}
```

### In-memory sources (embedded or preloaded bytes)

```zig
const std = @import("std");
const zigaudio = @import("zigaudio");

const embedded_audio = @embedFile("song.qoa");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    // Streaming from embedded bytes
    var stream = try zigaudio.fromMemory(allocator, embedded_audio);
    defer stream.deinit();

    // Full decode from embedded bytes
    var r = std.Io.Reader.fixed(embedded_audio);
    var audio = try zigaudio.decode(allocator, &r);
    defer audio.deinit();
}
```

## API cheat sheet (simple)

- Streaming (managed) — fromPath(allocator, path) -> ManagedAudioStream
  - Default for playback. Optional pulls: stream.readFramesInto(dst)
  - Get N frames: stream.toAudioLimit(allocator, max_frames)

- Streaming (unmanaged) — fromPathUnmanaged(path, file_buffer, pcm_buffer) -> AudioStream
  - You own the buffers. Pull with: stream.readFramesInto(dst)

- In-memory source — fromMemory(allocator, bytes) -> ManagedAudioStream
  - For embedded/preloaded bytes

- Full decode from a custom reader — decode(allocator, reader) -> Audio

- Encode to file — encodeToPath(format: zigaudio.Format, path, &audio)

## Examples

The `examples/` directory contains:

- **`player/`**: Audio playback using the `zoto` library
- **`bench/`**: Performance benchmarking tools
- **`bench_file/`**: File-based benchmarking

Run examples:

```bash
# Audio player
zig build run -- examples/player/main.zig -- examples/player/fanfare_heartcontainer.qoa

# Benchmarking
./scripts/run_bench.sh examples/bench/jungle_dash__pogo.qoa
```

## Performance

The Zig QOA decoder is ~34% faster than the original C reference implementation:

```
Benchmark: Popeye_audio.qoa (7.3MB)
- Zig: 351.0 ms ± 13.2 ms
- C:   471.0 ms ± 15.8 ms
- Speedup: 1.34x faster
```

## Contributing

Please do! Open an Issue, PR, new audio format, all is welcome!
