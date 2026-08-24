# zigaudio

A Zig library for reading and writing audio files with a streaming-capable, format-agnostic API.

## Audio Format Support

| Format | Read | Write | Notes                  |
| ------ | ---- | ----- | ---------------------- |
| QOA    | ✅   | ✅    | Full support           |
| WAV    | ✅   | ✅    | Write: i16 PCM only    |
| MP3    | ✅   | ❌    |                        |
| AAC    | ✅   | ❌    | Not pure Zig (`faad2`) |
| FLAC   | ✅   | ❌    |                        |
| OGG    | ✅   | ❌    | Vorbis streams         |

**Note:** All formats decode to i16 PCM. WAV encoding supports i16 PCM output only.

### WAV Format Support

WAV decoding supports a wide range of sub-formats:

- **PCM**: 8, 16, 24, 32-bit (including WAVE_FORMAT_EXTENSIBLE)
- **IEEE Float**: 32-bit (single) and 64-bit (double)
- **G.711**: mu-Law and a-Law
- **ADPCM**: IMA ADPCM and MS ADPCM

All the files from [this site](https://mauvecloud.net/sounds/).

## Usage

Add to your `build.zig.zon`:

```bash
zig fetch --save git+https://github.com/braheezy/zig-audio#0.1.0
```

And in your `build.zig`:

```zig
const target = b.standardTargetOptions(.{});
const optimize = b.standardOptimizeOption(.{});
const zigaudio = b.dependency("zigaudio", .{
    // default build options
    .optimize = optimize,
    .target = target,
    .aac = true,
});
root_module.addImport("zigaudio", zigaudio.module("zigaudio"));
```

## Quick Start

```zig
const std = @import("std");
const zigaudio = @import("zigaudio");

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;

    // Simple: decode entire file (good for small files)
    var audio = try zigaudio.decodeFile(allocator, init.io, "song.mp3");
    defer audio.deinit(allocator);

    std.debug.print("Sample rate: {d} Hz\n", .{audio.params.sample_rate});
    std.debug.print("Channels: {d}\n", .{audio.params.channels});
    std.debug.print("Duration: {d:.2}s\n", .{audio.durationSeconds()});

    // Work with PCM samples (interleaved i16: [L, R, L, R, ...])
    const pcm_samples = audio.samples();
    for (pcm_samples[0..@min(10, pcm_samples.len)]) |sample| {
        std.debug.print("Sample: {d}\n", .{sample});
    }

    // For large files: stream and process incrementally
    const stream = try zigaudio.fromPath(allocator, init.io, "large-song.mp3");
    defer stream.deinit(allocator);

    var buffer: [4096]i16 = undefined;
    while (true) {
        const samples_read = try stream.read(&buffer);
        if (samples_read == 0) break;
        // Process samples in chunks (send to audio output, DSP, etc.)
    }
}
```

### Format Conversion

```zig
var audio = try zigaudio.decodeFile(allocator, io, "input.mp3");
defer audio.deinit(allocator);

// Encode to QOA or WAV
try zigaudio.encodeToPath(.qoa, io, "output.qoa", &audio);
try zigaudio.encodeToPath(.wav, io, "output.wav", &audio);
```

### Embedded Audio

```zig
const embedded_audio = @embedFile("sound.qoa");

// Decode from embedded bytes
var audio = try zigaudio.decodeMemory(allocator, embedded_audio);
defer audio.deinit(allocator);
```

## Examples

The `examples/` directory contains:

- **`player/`**: Audio playback using the `zoto` library
- **`bench/`**: Performance benchmarking tools
- **`convert/`**: Decode one format, write another.

## Building and Running

```bash
# Build the library (compiles but doesn't install examples)
zig build

# Run tests
zig build test

# See help for all
zig build --help
```

## Contributing

Please do! Open an Issue, PR, new audio format, all is welcome!
