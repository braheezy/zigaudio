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

### Basic Usage

```zig
const std = @import("std");
const zigaudio = @import("zigaudio");

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    // Load audio from file
    var audio = try zigaudio.fromPath(allocator, "song.qoa");
    defer audio.deinit();

    std.debug.print("Sample rate: {}\n", .{audio.params.sample_rate});
    std.debug.print("Channels: {}\n", .{audio.params.channels});
    std.debug.print("Duration: {:.2}s\n", .{audio.durationSeconds()});
}
```

### Streaming Playback

```zig
const std = @import("std");
const zigaudio = @import("zigaudio");

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    // Create streaming audio source
    var stream = try zigaudio.fromPath(allocator, "song.qoa");
    defer stream.deinit();

    // Use with audio playback library
    // stream.readerInterface() provides std.Io.Reader for PCM data
    // stream.info contains AudioInfo for setup
}
```

### Memory-Based Audio

```zig
const std = @import("std");
const zigaudio = @import("zigaudio");

const embedded_audio = @embedFile("song.qoa");

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    // Load from embedded data
    var audio = try zigaudio.fromMemory(allocator, embedded_audio);
    defer audio.deinit();

    // Access PCM data
    const pcm_data = audio.data;
    const frame_count = audio.frameCount();
}
```

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
