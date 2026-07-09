# LunarStack

**Lucky imaging for the Moon, entirely on your Android phone.**

LunarStack turns a shaky handheld video of the Moon into a single sharp, low-noise
photograph — the same *lucky imaging* technique used by desktop tools like
AutoStakkert and RegiStax (analyze every frame, keep only the sharpest, align them
sub-pixel and average), running fully on-device with no server and no upload.

*Empilhe e estabilize vídeos da Lua direto no Android — sem servidor, sem upload.
Interface em português.*

## Features

- **Stacking (Empilhar)** — decodes every frame of the clip, scores per-frame
  sharpness (Laplacian variance on the luma plane), selects the best N% and
  aligns them with sub-pixel phase correlation + ECC affine refinement before
  a sharpness-weighted average.
- **Stabilization (Estabilizar)** — re-encodes the clip with the Moon locked to
  the frame center (luminance-centroid tracking, integer YUV shifts, H.264/MP4
  output). No audio, no quality-destroying filtering.
- **Combined flow (Estabilizar + empilhar)** — for violently shaky clips: frames
  are saved with the Moon pre-centered (integer shift, **no re-encode
  generation loss**) so the stacker's fine registration always converges.
- **Optional multi-scale sharpening** — à trous / starlet wavelets
  (RegiStax-style), luminance-only, tuned to stay photographic.
- **Raw mode (Empilhamento cru)** — align + average only; no sharpening, no
  tonal edits.
- **Exports** — PNG / JPEG to the gallery, or 16-bit TIFF (real tonal depth
  from the float accumulator) to `Downloads/LunarStack` for external editing.
- Dark, astrophotography-friendly UI in Portuguese (pt-BR).

## How it works

| Stage | Where | What happens |
|---|---|---|
| Decode & analyze | Kotlin (`MediaExtractor` + `MediaCodec`, flexible-YUV ByteBuffer mode) | every frame decoded once, sharpness scored on the Y plane |
| Frame selection | Dart | best N% by score, capped by a max-frames setting |
| Extraction | Kotlin | only the selected frames are decoded again and saved as lossless PNG (color-range-aware BT.601), PNG encode pipelined on a worker pool |
| Registration & stacking | C++ / OpenCV via `dart:ffi` | phase correlation (NCC sign resolution) + ECC affine per frame, cubic warp, sharpness-weighted float accumulation, auto-crop |
| Post & encode | C++ | optional wavelet sharpening, PNG/JPEG/16-bit TIFF output |
| Stabilization | Kotlin | decode → centroid → integer YUV shift → H.264 encode → MP4 mux, encoder capabilities queried per device |

Design decisions worth knowing before contributing (all measured on real
footage, see comments in `native/engine/src/engine.cpp`):

- Frame **selection** is the dominant sharpness lever, not fancier alignment.
- AutoStakkert-style *double-stack reference* and multi-point alignment were
  both implemented, benchmarked and **reverted** — on stable phone footage they
  measurably soften the result. The comments document the numbers.
- MediaCodec is used in ByteBuffer + `COLOR_FormatYUV420Flexible` mode only:
  decoding into an `ImageReader` crashes on devices whose hardware decoder
  emits proprietary tiled formats.

## Building

Requirements:

- Flutter (stable channel) with Android toolchain
- Android SDK + NDK (the project uses the NDK version pinned by Flutter)
- [OpenCV Android SDK](https://opencv.org/releases/) (4.x)

Point the build at your OpenCV Android SDK, either via Gradle property in
`~/.gradle/gradle.properties`:

```properties
lunarstack.opencvDir=/path/to/OpenCV-android-sdk/sdk/native/jni
```

or via environment variable:

```bash
export OPENCV_ANDROID_SDK=/path/to/OpenCV-android-sdk
```

Then:

```bash
flutter pub get
flutter build apk --release --split-per-abi
```

Install `app-arm64-v8a-release.apk` on a real device. The native engine
(`libastro_engine.so`) is built automatically by Gradle from
`native/CMakeLists.txt`; a standalone CLI (`astro_stack_cli`) for algorithm
iteration over `adb` is built alongside it in debug (never packaged).

## Project structure

```
lib/                  Flutter app (Riverpod + go_router + freezed)
  core/native/        dart:ffi bindings + MethodChannel bridge
  features/           one folder per screen/flow
android/app/src/main/kotlin/
  SequentialFrameExtractor.kt   MediaCodec decode/analyze/extract
  VideoStabilizer.kt            centroid-lock stabilizer (decode→shift→encode)
native/
  engine/             C++ OpenCV engine (flat C API, consumed via FFI)
  tools/test_stack.cpp          adb-side CLI for controlled A/B experiments
```

## Contributing

Quality changes to the stacking pipeline must come with a controlled A/B
measurement (same input frames, one variable at a time — limb edge width and
Laplacian variance are the house metrics; `native/tools/test_stack.cpp` exists
for exactly this). PRs that make images "look better" without numbers will be
asked for numbers.

## License

Copyright 2026 Amaro Miranda

Licensed under the [Apache License 2.0](LICENSE).

OpenCV is used under its own Apache 2.0 license.
