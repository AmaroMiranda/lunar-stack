#ifndef ASTRO_ENGINE_H
#define ASTRO_ENGINE_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

#if defined(_WIN32)
#define AS_EXPORT __declspec(dllexport)
#else
#define AS_EXPORT __attribute__((visibility("default")))
#endif

// ---------------------------------------------------------------------------
// LunarStack native engine — flat C API consumed via dart:ffi.
//
// Frames are pre-extracted to image files by the Android side (Kotlin,
// MediaMetadataRetriever) since the vendored OpenCV Android build has no
// video I/O backend (no FFmpeg, no Android MediaNDK backend compiled in).
// This engine only ever sees still images.
//
// Threading contract: every as_* call is blocking and must be issued from a
// background isolate. Progress is delivered through as_poll_progress (pull
// model). Cancellation is cooperative via as_cancel.
// ---------------------------------------------------------------------------

typedef enum AsStatus {
  AS_OK = 0,
  AS_ERR_INVALID_ARGS = 1,
  AS_ERR_DECODE = 2,
  AS_ERR_NOT_ENOUGH_FRAMES = 3,
  AS_ERR_ENCODE = 4,
  AS_ERR_CANCELLED = 5,
  AS_ERR_INTERNAL = 6,
} AsStatus;

typedef enum AsStage {
  AS_STAGE_IDLE = 0,
  AS_STAGE_ANALYZING = 1,
  AS_STAGE_ALIGNING = 2,
  AS_STAGE_STACKING = 3,
  AS_STAGE_ENCODING = 4,
  AS_STAGE_DONE = 5,
} AsStage;

typedef enum AsStackingMethod {
  AS_STACK_SIMPLE_AVERAGE = 0,
  AS_STACK_WEIGHTED_AVERAGE = 1,
} AsStackingMethod;

typedef struct AsStackOptions {
  int32_t stacking_method;   // AsStackingMethod
  int32_t auto_crop;         // 1 = trim border invalidated by alignment shift
  int32_t sharpen;           // 1 = light unsharp mask on the final result
  int32_t preview_max_dim;   // if >0, also write a downscaled preview
} AsStackOptions;

typedef struct AsProgress {
  int32_t stage;    // AsStage
  int32_t current;
  int32_t total;
  float fraction;   // overall 0..1
} AsProgress;

typedef struct AsStackResult {
  int32_t width;
  int32_t height;
  int32_t frames_analyzed;
  int32_t frames_stacked;    // how many were actually aligned+averaged in
  int32_t reference_index;   // index (into the paths passed to as_stack) used as anchor
} AsStackResult;

// Version string, e.g. "astro-engine 0.1.0 / OpenCV 4.13.0". Returns length.
AS_EXPORT int32_t as_version(char* buf, int32_t buf_len);

// Laplacian-variance sharpness per frame, normalized to 0..1 against the
// batch's own max. out_scores must have room for `count` doubles, written in
// the same order as `paths`. Reports progress via as_poll_progress.
AS_EXPORT int32_t as_analyze_frames(const char** utf8_paths,
                                     int32_t count,
                                     double* out_scores,
                                     char* err_buf,
                                     int32_t err_len);

// Aligns every frame in `paths` onto its sharpest member (by phase
// correlation, sub-pixel, sign resolved by NCC) and stacks them (simple or
// sharpness-weighted average) into `out_path` (.png/.jpg decides encoder).
// `paths` should already be the selected subset (top N% by quality) — the
// caller does that filtering.
AS_EXPORT int32_t as_stack(const char** utf8_paths,
                            int32_t count,
                            const AsStackOptions* options,
                            const char* out_path,
                            const char* preview_path,
                            char* err_buf,
                            int32_t err_len);

// Re-encodes a saved image into another format decided by out_path's
// extension (.png/.jpg/.tif). Bit depth is adapted: 16-bit sources are
// scaled down for 8-bit outputs, 8-bit sources scaled up for 16-bit TIFF.
// jpeg_quality applies only to .jpg outputs (use 95 as default).
AS_EXPORT int32_t as_convert_image(const char* in_path,
                                    const char* out_path,
                                    int32_t jpeg_quality,
                                    char* err_buf,
                                    int32_t err_len);

// Pull the latest progress snapshot (thread-safe, non-blocking).
AS_EXPORT void as_poll_progress(AsProgress* out);

// Info about the last successful as_stack (thread-safe snapshot).
AS_EXPORT void as_get_stack_result(AsStackResult* out);

// Request cooperative cancellation of the in-flight as_stack/as_analyze_frames.
AS_EXPORT void as_cancel(void);

#ifdef __cplusplus
}  // extern "C"
#endif

#endif  // ASTRO_ENGINE_H
