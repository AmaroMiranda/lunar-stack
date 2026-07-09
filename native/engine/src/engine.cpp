// LunarStack native engine.
//
// Frames arrive as still images (already extracted from the source video by
// the Android/Kotlin side). Pipeline: per-frame sharpness (Laplacian
// variance) -> pick sharpest frame as anchor -> align every other frame onto
// it by sub-pixel phase correlation (sign resolved by NCC, no calibration
// step needed) -> sharpness-weighted (or simple) average -> auto-crop the
// border invalidated by the max alignment shift -> encode.
//
// Frames are decoded and released one at a time (never all held in memory at
// once), matching the streaming-memory principle from the product spec.

#include "astro_engine.h"

#include <opencv2/core.hpp>
#include <opencv2/imgcodecs.hpp>
#include <opencv2/imgproc.hpp>
#include <opencv2/video/tracking.hpp>

#ifdef __ANDROID__
#include <android/log.h>
#define AS_LOG(...) \
  __android_log_print(ANDROID_LOG_INFO, "astro_engine", __VA_ARGS__)
#else
#define AS_LOG(...) ((void)0)
#endif

#include <algorithm>
#include <atomic>
#include <cmath>
#include <cstdio>
#include <cstring>
#include <mutex>
#include <string>
#include <vector>

using namespace cv;

namespace {

std::atomic<bool> g_cancel{false};
std::mutex g_progress_mutex;
AsProgress g_progress{AS_STAGE_IDLE, 0, 0, 0.0f};
AsStackResult g_result{0, 0, 0, 0, 0};

bool cancelled() { return g_cancel.load(); }

void set_progress(int32_t stage, int32_t current, int32_t total, float fraction) {
  std::lock_guard<std::mutex> lock(g_progress_mutex);
  g_progress = AsProgress{stage, current, total, fraction};
}

void fail_msg(char* err_buf, int32_t err_len, const std::string& msg) {
  if (err_buf == nullptr || err_len <= 0) return;
  const size_t n = std::min(static_cast<size_t>(err_len - 1), msg.size());
  std::memcpy(err_buf, msg.data(), n);
  err_buf[n] = '\0';
}

Mat to_gray8(const Mat& img) {
  Mat gray;
  if (img.channels() == 4) {
    cvtColor(img, gray, COLOR_BGRA2GRAY);
  } else if (img.channels() == 3) {
    cvtColor(img, gray, COLOR_BGR2GRAY);
  } else {
    gray = img;
  }
  if (gray.depth() != CV_8U) {
    Mat gray8;
    gray.convertTo(gray8, CV_8U, 255.0 / 65535.0);
    return gray8;
  }
  return gray;
}

double resize_scale_for_max_dim(int cols, int rows, int max_dim) {
  const int longest = std::max(cols, rows);
  if (longest <= max_dim) return 1.0;
  return static_cast<double>(max_dim) / static_cast<double>(longest);
}

double laplacian_sharpness(const Mat& gray) {
  Mat lap;
  Laplacian(gray, lap, CV_64F);
  Scalar mu, sigma;
  meanStdDev(lap, mu, sigma);
  return sigma[0] * sigma[0];
}

// Sub-pixel translation of `target` relative to `reference` (both same-size
// 8-bit gray proxies). Sign resolved empirically via NCC on shifted patches,
// so no separate runtime calibration pass is needed. Returns false if the
// correlation is too weak/ambiguous to trust.
bool estimate_shift(const Mat& reference_gray, const Mat& target_gray, Point2d* out_shift) {
  Mat ref32, tgt32;
  reference_gray.convertTo(ref32, CV_32F);
  target_gray.convertTo(tgt32, CV_32F);

  Mat win;
  createHanningWindow(win, ref32.size(), CV_32F);

  double response = 0.0;
  const Point2d raw = phaseCorrelate(ref32, tgt32, win, &response);
  if (response < 0.03) return false;  // textureless or failed correlation

  const Point2f center(reference_gray.cols * 0.5f, reference_gray.rows * 0.5f);
  const Size patch(std::min(256, reference_gray.cols / 2),
                    std::min(256, reference_gray.rows / 2));
  if (patch.width < 16 || patch.height < 16) return false;

  Mat pa, pb1, pb2;
  getRectSubPix(reference_gray, patch, center, pa);
  getRectSubPix(target_gray, patch,
                Point2f(center.x + static_cast<float>(raw.x), center.y + static_cast<float>(raw.y)),
                pb1);
  getRectSubPix(target_gray, patch,
                Point2f(center.x - static_cast<float>(raw.x), center.y - static_cast<float>(raw.y)),
                pb2);

  const auto ncc = [](const Mat& x, const Mat& y) {
    Mat r;
    matchTemplate(x, y, r, TM_CCOEFF_NORMED);
    return static_cast<double>(r.at<float>(0, 0));
  };
  const double n1 = ncc(pa, pb1);
  const double n2 = ncc(pa, pb2);
  if (std::max(n1, n2) < 0.5) return false;  // content disagrees with either sign

  *out_shift = (n1 >= n2) ? raw : Point2d(-raw.x, -raw.y);
  return true;
}

// Hand-held footage doesn't just translate — measured on a real clip,
// rotation turned out to be negligible (<0.04°), but the apparent scale of
// the Moon drifts slightly frame to frame (focus breathing / OIS), which a
// rotation+translation-only model can't correct. A scale mismatch is exact
// at the center of the warp and grows radially, which is exactly the
// "sharp center, smeared limb" symptom. Refines the phase-correlation
// translation into a full affine warp (rotation+scale+shear+translation)
// via ECC. `warp` follows findTransformECC's convention: aligned(x) =
// target(warp(x)), seeded here with the coarse translation and identity
// rotation/scale. Returns false if ECC fails to converge (caller falls back
// to the coarse translation-only estimate).
bool refine_affine(const Mat& reference_gray, const Mat& target_gray, Point2d coarse_shift,
                    Mat* out_warp) {
  Mat warp = (Mat_<float>(2, 3) << 1, 0, static_cast<float>(coarse_shift.x), 0, 1,
              static_cast<float>(coarse_shift.y));
  TermCriteria criteria(TermCriteria::COUNT + TermCriteria::EPS, 150, 1e-6);
  try {
    findTransformECC(reference_gray, target_gray, warp, MOTION_AFFINE, criteria);
  } catch (const cv::Exception&) {
    return false;  // did not converge: caller keeps the coarse translation
  }
  *out_warp = warp;
  return true;
}

// NOTE: multi-point local alignment (AutoStakkert-style APs) was prototyped
// here and removed. On low-seeing footage (phone/short focal length) the
// per-AP phase correlations mostly measure noise, not real atmospheric warp,
// and remapping by that noise measurably DEGRADED fine detail (limb sharpness
// 37.6 -> 34.0 on the test clip). It only helps footage with genuine local
// seeing (long-focal telescope), which we have nothing to validate against —
// so it stays future work (spec section 7, "alinhamento por múltiplos
// pontos"), not shipped unvalidated. The global affine registration below is
// what actually helps this footage.

// NOTE: full-resolution sub-pixel residual refinement (re-measuring leftover
// translation after the proxy-based warp via phase correlation on a centered
// full-res crop, then folding it into the warp) was prototyped and measured
// to make the limb WORSE, not better: A/B on the test clip, same 15 frames,
// only variable changed — edge width 7.0px (without it) vs 20.0px (with it).
// The measured "residual" on this footage is mostly phase-correlation noise
// rather than genuine leftover misalignment (the same failure mode as the
// reverted multi-point local alignment above), and folding noise into the
// warp adds error instead of removing it. Reverted; the proxy-resolution ECC
// affine registration is what actually helps this footage.

// À trous (starlet) wavelet sharpening — the technique RegiStax/AstroSurface
// made standard for lunar/planetary detail. Instead of one unsharp mask at a
// single blur radius, it decomposes the image into several spatial-frequency
// bands (detail layers) and boosts each independently, with per-layer
// denoising so amplifying fine detail doesn't amplify grain. Sharpens the
// luminance only and reapplies as a ratio, so hue/limb-glow isn't shifted.
//
// gains[j] is the multiplier for detail layer j (j=0 finest). gain 1.0 = no
// change; >1 sharpens that band. Kept moderate by default to avoid the
// "plastic"/halo over-sharpened look the product spec warns against.
Mat build_atrous_kernel_1d(int scale) {
  // B3-spline base kernel, dilated with 2^scale - 1 holes between taps.
  const float base[5] = {1.f / 16, 4.f / 16, 6.f / 16, 4.f / 16, 1.f / 16};
  const int holes = (1 << scale) - 1;  // scale 0 -> 0 holes, scale1 ->1, ...
  const int len = 4 * (holes + 1) + 1;
  Mat k = Mat::zeros(1, len, CV_32F);
  for (int i = 0; i < 5; ++i) {
    k.at<float>(0, i * (holes + 1)) = base[i];
  }
  return k;
}

void wavelet_sharpen_bgr(Mat& img_f /* CV_32FC3, 0..255 */, const std::vector<float>& gains,
                          float denoise) {
  const int scales = static_cast<int>(gains.size());
  if (scales == 0) return;

  std::vector<Mat> bgr;
  split(img_f, bgr);
  // Luminance (Rec.601). Moon is near-gray but this keeps color neutral.
  Mat lum = 0.114f * bgr[0] + 0.587f * bgr[1] + 0.299f * bgr[2];

  Mat c_prev = lum.clone();
  Mat recon;  // starts as the coarsest residual, detail added back below
  std::vector<Mat> details;
  details.reserve(scales);
  for (int j = 0; j < scales; ++j) {
    Mat k = build_atrous_kernel_1d(j);
    Mat c_next;
    sepFilter2D(c_prev, c_next, CV_32F, k, k, Point(-1, -1), 0, BORDER_REFLECT);
    details.push_back(c_prev - c_next);  // detail layer j
    c_prev = c_next;
  }
  recon = c_prev.clone();  // residual (coarsest smooth)

  for (int j = 0; j < scales; ++j) {
    Mat w = details[j];
    // Denoise the two finest layers (where sensor grain lives) via soft
    // thresholding, so the gain doesn't amplify noise into the result.
    if (denoise > 0.f && j <= 1) {
      const float t = denoise * (j == 0 ? 1.0f : 0.5f);
      Mat sign, mag;
      mag = abs(w);
      threshold(mag, mag, t, 0, THRESH_TOZERO);  // |w|<t -> 0
      // rebuild signed, shrinking by t (soft threshold)
      Mat shrunk = mag - t;
      threshold(shrunk, shrunk, 0, 0, THRESH_TOZERO);
      Mat wsign;
      w.copyTo(wsign);
      // apply sign of w to shrunk magnitude
      Mat pos = (w >= 0);
      pos.convertTo(pos, CV_32F, 1.0 / 255.0);
      w = shrunk.mul(2 * pos - 1);
    }
    recon += gains[j] * w;
  }

  // Apply as a luminance ratio to preserve color.
  Mat ratio;
  divide(recon, lum + 1e-3f, ratio);
  for (auto& ch : bgr) ch = ch.mul(ratio);
  merge(bgr, img_f);
}

}  // namespace

int32_t as_version(char* buf, int32_t buf_len) {
  const std::string v = std::string("astro-engine 0.1.0 / OpenCV ") + CV_VERSION;
  if (buf != nullptr && buf_len > 0) {
    const size_t n = std::min(static_cast<size_t>(buf_len - 1), v.size());
    std::memcpy(buf, v.data(), n);
    buf[n] = '\0';
  }
  return static_cast<int32_t>(v.size());
}

int32_t as_analyze_frames(const char** utf8_paths, int32_t count, double* out_scores,
                           char* err_buf, int32_t err_len) {
  if (utf8_paths == nullptr || out_scores == nullptr || count <= 0) {
    fail_msg(err_buf, err_len, "invalid arguments");
    return AS_ERR_INVALID_ARGS;
  }
  g_cancel.store(false);
  set_progress(AS_STAGE_ANALYZING, 0, count, 0.0f);

  double max_raw = 0.0;
  std::vector<double> raw(static_cast<size_t>(count), 0.0);

  for (int32_t i = 0; i < count; ++i) {
    if (cancelled()) return AS_ERR_CANCELLED;
    Mat img = imread(utf8_paths[i], IMREAD_GRAYSCALE);
    if (img.empty()) {
      fail_msg(err_buf, err_len, std::string("failed to decode: ") + utf8_paths[i]);
      return AS_ERR_DECODE;
    }
    const double scale = resize_scale_for_max_dim(img.cols, img.rows, 1024);
    if (scale < 1.0) resize(img, img, Size(), scale, scale, INTER_AREA);
    raw[static_cast<size_t>(i)] = laplacian_sharpness(img);
    max_raw = std::max(max_raw, raw[static_cast<size_t>(i)]);
    set_progress(AS_STAGE_ANALYZING, i + 1, count, static_cast<float>(i + 1) / count);
  }

  const double denom = max_raw > 1e-9 ? max_raw : 1.0;
  for (int32_t i = 0; i < count; ++i) {
    out_scores[i] = std::min(1.0, raw[static_cast<size_t>(i)] / denom);
  }
  set_progress(AS_STAGE_DONE, count, count, 1.0f);
  return AS_OK;
}

int32_t as_stack(const char** utf8_paths, int32_t count, const AsStackOptions* options,
                  const char* out_path, const char* preview_path, char* err_buf, int32_t err_len) {
  if (utf8_paths == nullptr || options == nullptr || out_path == nullptr || count < 2) {
    fail_msg(err_buf, err_len, "at least two frames are required");
    return count < 2 ? AS_ERR_NOT_ENOUGH_FRAMES : AS_ERR_INVALID_ARGS;
  }
  g_cancel.store(false);
  set_progress(AS_STAGE_ANALYZING, 0, count, 0.0f);

  try {
    std::vector<std::string> paths(utf8_paths, utf8_paths + count);
    const size_t n = paths.size();

    // -- Pass 1: sharpness on a downscaled proxy, pick the anchor -----------
    std::vector<double> sharpness(n, 0.0);
    std::vector<Mat> proxies(n);
    Size full_size;

    for (size_t i = 0; i < n; ++i) {
      if (cancelled()) return AS_ERR_CANCELLED;
      Mat img = imread(paths[i], IMREAD_COLOR);
      if (img.empty()) {
        fail_msg(err_buf, err_len, "failed to decode: " + paths[i]);
        return AS_ERR_DECODE;
      }
      if (i == 0) full_size = img.size();
      Mat gray = to_gray8(img);
      img.release();
      // Larger than a typical detection proxy: ECC refines by gradient
      // descent (not discrete keypoints), but any residual sub-proxy-pixel
      // error still gets multiplied by the upscale factor when the warp is
      // applied at full resolution, so this stays as large as is still fast.
      const double scale = resize_scale_for_max_dim(gray.cols, gray.rows, 2600);
      Mat proxy;
      if (scale < 1.0) {
        resize(gray, proxy, Size(), scale, scale, INTER_AREA);
      } else {
        proxy = gray;
      }
      sharpness[i] = laplacian_sharpness(proxy);
      proxies[i] = proxy;
      set_progress(AS_STAGE_ANALYZING, static_cast<int32_t>(i) + 1,
                   static_cast<int32_t>(n), 0.25f * (i + 1) / n);
    }

    size_t ref_idx = 0;
    for (size_t i = 1; i < n; ++i) {
      if (sharpness[i] > sharpness[ref_idx]) ref_idx = i;
    }
    const double proxy_scale = resize_scale_for_max_dim(full_size.width, full_size.height, 2600);

    // NOTE: an AutoStakkert-style "double stack reference" (stage A: average
    // the sharpest 25% into a low-noise reference; stage B: register all
    // frames against it) was implemented here and MEASURED WORSE on this
    // footage class — controlled A/B, same 15 frames: limb edge width
    // 7.0px -> 9.0px, LapVar 29.1 -> 28.7. On stable phone clips the single
    // sharpest frame is already a clean reference; the averaged reference is
    // slightly soft, ECC converges looser on weak gradients, and the ref
    // frame loses its unresampled pass-through. The technique pays off when
    // the reference frame is noisy/distorted (high-mag telescope video) —
    // revisit only with that footage. Reverted, same precedent as the
    // multi-point AP experiment above.
    const bool weighted = options->stacking_method == AS_STACK_WEIGHTED_AVERAGE;
    const auto full_scale = static_cast<float>(proxy_scale > 0 ? 1.0 / proxy_scale : 1.0);

    Mat acc;      // CV_32FC3 accumulator, full resolution
    double total_w = 0.0;
    int32_t frames_stacked = 0;
    double max_abs_dx = 0.0, max_abs_dy = 0.0;

    for (size_t i = 0; i < n; ++i) {
      if (cancelled()) return AS_ERR_CANCELLED;
      set_progress(AS_STAGE_ALIGNING, static_cast<int32_t>(i) + 1,
                   static_cast<int32_t>(n), 0.25f + 0.5f * (i + 1) / n);

      Mat warp_full;  // 2x3 CV_32F, aligned(x) = frame(warp_full(x))
      if (i != ref_idx) {
        Point2d shift(0.0, 0.0);
        if (!estimate_shift(proxies[ref_idx], proxies[i], &shift)) {
          continue;  // could not align this frame: skip it
        }

        Mat warp_proxy;
        const bool ecc_ok = refine_affine(proxies[ref_idx], proxies[i], shift, &warp_proxy);
        if (!ecc_ok) {
          // ECC didn't converge: keep the coarse phase-correlation translation.
          warp_proxy = (Mat_<float>(2, 3) << 1, 0, static_cast<float>(shift.x), 0, 1,
                        static_cast<float>(shift.y));
        }
        // The affine block (rotation/scale/shear) is scale-invariant; only
        // translation scales with the proxy->full resolution ratio.
        warp_full = warp_proxy.clone();
        warp_full.at<float>(0, 2) *= full_scale;
        warp_full.at<float>(1, 2) *= full_scale;

        const double lim_x = 0.20 * full_size.width;
        const double lim_y = 0.20 * full_size.height;
        const double dx = warp_full.at<float>(0, 2), dy = warp_full.at<float>(1, 2);
        const double a = warp_full.at<float>(0, 0), b = warp_full.at<float>(0, 1);
        const double c = warp_full.at<float>(1, 0), d = warp_full.at<float>(1, 1);
        const double angle = std::atan2(c, a);
        const double scale_x = std::sqrt(a * a + c * c);
        const double scale_y = std::sqrt(b * b + d * d);
        const bool implausible = std::abs(dx) > lim_x || std::abs(dy) > lim_y ||
                                  std::abs(angle) > 0.09 || std::abs(scale_x - 1.0) > 0.06 ||
                                  std::abs(scale_y - 1.0) > 0.06;
#ifdef ASTRO_DEBUG_LOG
        std::fprintf(stderr,
                     "frame %zu: coarse=(%.2f,%.2f) ecc_ok=%d angle_deg=%.3f dx=%.2f dy=%.2f "
                     "scale=(%.4f,%.4f)%s\n",
                     i, shift.x, shift.y, ecc_ok ? 1 : 0, angle * 180.0 / CV_PI, dx, dy, scale_x,
                     scale_y, implausible ? " REJECTED" : "");
#endif
        if (implausible) {
          continue;  // implausible: likely a failed/ambiguous registration
        }
      }

      Mat frame = imread(paths[i], IMREAD_COLOR);
      if (frame.empty()) continue;
      if (frame.size() != full_size) resize(frame, frame, full_size, 0, 0, INTER_LINEAR);
      Mat frame_f;
      frame.convertTo(frame_f, CV_32FC3);
      frame.release();

      Mat aligned;
      if (i == ref_idx) {
        aligned = frame_f;
      } else {
        warpAffine(frame_f, aligned, warp_full, full_size, INTER_CUBIC + WARP_INVERSE_MAP,
                   BORDER_REFLECT);

        // Max corner displacement bounds how much border the warp could
        // have pulled from outside the frame (rotation moves corners much
        // more than the center) — that margin gets cropped away below.
        const Point2f corners[4] = {
            {0.f, 0.f},
            {static_cast<float>(full_size.width), 0.f},
            {0.f, static_cast<float>(full_size.height)},
            {static_cast<float>(full_size.width), static_cast<float>(full_size.height)},
        };
        for (const auto& c : corners) {
          const float wx = warp_full.at<float>(0, 0) * c.x + warp_full.at<float>(0, 1) * c.y +
                            warp_full.at<float>(0, 2);
          const float wy = warp_full.at<float>(1, 0) * c.x + warp_full.at<float>(1, 1) * c.y +
                            warp_full.at<float>(1, 2);
          max_abs_dx = std::max(max_abs_dx, static_cast<double>(std::abs(wx - c.x)));
          max_abs_dy = std::max(max_abs_dy, static_cast<double>(std::abs(wy - c.y)));
        }
      }

      // Sharpness weighting. A flat weight (or a shallow one with a high
      // floor) lets the softer frames drag detail out of the result — the
      // "smeared limb / no sharpness" symptom. Measured on a real clip:
      // weighting the top-N sharpest frames much harder retains ~80% of a
      // single frame's limb detail (vs ~59% with a shallow weight) while
      // still cutting noise. So raise the ratio to a power: sharp frames keep
      // full weight, softer frames contribute steeply less, but a small floor
      // keeps them denoising the flat areas.
      double w = 1.0;
      if (weighted && i != ref_idx) {
        const double ratio = sharpness[i] / sharpness[ref_idx];  // 0..1, ref is the max
        w = std::max(0.05, std::pow(std::max(0.0, ratio), 3.0));
      }

      if (acc.empty()) {
        acc = aligned * w;
      } else {
        acc += aligned * w;
      }
      total_w += w;
      ++frames_stacked;
    }

    if (acc.empty() || total_w <= 0.0) {
      fail_msg(err_buf, err_len, "no frames could be aligned");
      return AS_ERR_INTERNAL;
    }

    set_progress(AS_STAGE_STACKING, static_cast<int32_t>(n), static_cast<int32_t>(n), 0.8f);
    Mat result_f = acc / total_w;

    // -- Auto-crop the border invalidated by alignment shifts ---------------
    if (options->auto_crop != 0 && (max_abs_dx > 0.5 || max_abs_dy > 0.5)) {
      const int crop_x = static_cast<int>(std::ceil(max_abs_dx));
      const int crop_y = static_cast<int>(std::ceil(max_abs_dy));
      const int rw = result_f.cols - 2 * crop_x;
      const int rh = result_f.rows - 2 * crop_y;
      if (rw > 16 && rh > 16) {
        result_f = result_f(Rect(crop_x, crop_y, rw, rh)).clone();
      }
    }

    if (options->sharpen != 0) {
      // Multi-scale wavelet sharpening on the float result (à trous / starlet,
      // RegiStax-style). Gains peak at the fine-medium bands where lunar
      // crater detail lives and taper off for coarse structure, with light
      // denoising on the finest layers. Tuned DOWN after user feedback that
      // the first pass (1.7/1.9/1.6) looked artificial — "leve" means the
      // result should still read as a photograph, not a filter.
      static const std::vector<float> kGains = {1.30f, 1.40f, 1.25f, 1.10f, 1.0f};
      wavelet_sharpen_bgr(result_f, kGains, /*denoise=*/1.2f);
    }

    Mat result_8u;
    result_f.convertTo(result_8u, CV_8UC3);

    set_progress(AS_STAGE_ENCODING, static_cast<int32_t>(n), static_cast<int32_t>(n), 0.95f);
    // 16-bit TIFF when requested by extension: the stacking accumulator is
    // float32, so averaging N 8-bit frames genuinely creates sub-8-bit tonal
    // precision — a 16-bit master keeps it for external editing (the whole
    // point of exporting "raw"). PNG/JPEG stay 8-bit.
    const std::string out_str(out_path);
    const bool want_tiff =
        out_str.size() >= 4 && (out_str.rfind(".tif") == out_str.size() - 4 ||
                                 (out_str.size() >= 5 && out_str.rfind(".tiff") == out_str.size() - 5));
    bool wrote_ok;
    if (want_tiff) {
      Mat result_16u;
      result_f.convertTo(result_16u, CV_16UC3, 257.0);  // 0..255 float -> 0..65535
      // LZW's default horizontal-differencing predictor isn't understood by
      // many lightweight TIFF readers (e.g. mobile image-editing apps) and
      // silently corrupts the decoded pixels. Disable it explicitly; LZW
      // without a predictor is still a valid, meaningfully compressed file.
      const std::vector<int> tiff_params = {IMWRITE_TIFF_PREDICTOR, IMWRITE_TIFF_PREDICTOR_NONE};
      wrote_ok = imwrite(out_path, result_16u, tiff_params);
    } else {
      wrote_ok = imwrite(out_path, result_8u);
    }
    if (!wrote_ok) {
      fail_msg(err_buf, err_len, "failed to write output image");
      return AS_ERR_ENCODE;
    }

    if (preview_path != nullptr && options->preview_max_dim > 0) {
      const double pscale = resize_scale_for_max_dim(result_8u.cols, result_8u.rows,
                                                      options->preview_max_dim);
      Mat preview = result_8u;
      if (pscale < 1.0) resize(result_8u, preview, Size(), pscale, pscale, INTER_AREA);
      imwrite(preview_path, preview);
    }

    {
      std::lock_guard<std::mutex> lock(g_progress_mutex);
      g_result = AsStackResult{result_8u.cols, result_8u.rows, static_cast<int32_t>(n),
                                frames_stacked, static_cast<int32_t>(ref_idx)};
    }
    set_progress(AS_STAGE_DONE, static_cast<int32_t>(n), static_cast<int32_t>(n), 1.0f);
    return AS_OK;
  } catch (const std::exception& e) {
    fail_msg(err_buf, err_len, std::string("internal error: ") + e.what());
    return AS_ERR_INTERNAL;
  }
}

int32_t as_convert_image(const char* in_path, const char* out_path, int32_t jpeg_quality,
                          char* err_buf, int32_t err_len) {
  if (in_path == nullptr || out_path == nullptr) {
    fail_msg(err_buf, err_len, "in_path and out_path are required");
    return AS_ERR_INVALID_ARGS;
  }
  try {
    // IMREAD_UNCHANGED keeps 16-bit TIFF masters at full depth.
    Mat img = imread(in_path, IMREAD_UNCHANGED);
    if (img.empty()) {
      fail_msg(err_buf, err_len, std::string("could not decode ") + in_path);
      return AS_ERR_DECODE;
    }
    if (img.channels() == 4) cvtColor(img, img, COLOR_BGRA2BGR);

    const std::string out_str(out_path);
    const auto ends_with = [&out_str](const char* suf) {
      const size_t n = std::strlen(suf);
      return out_str.size() >= n && out_str.compare(out_str.size() - n, n, suf) == 0;
    };
    const bool want_tiff = ends_with(".tif") || ends_with(".tiff");
    const bool want_jpeg = ends_with(".jpg") || ends_with(".jpeg");

    std::vector<int> params;
    if (want_tiff) {
      if (img.depth() == CV_8U) img.convertTo(img, CV_16U, 257.0);
      // Same predictor caveat as as_stack: keep the TIFF readable everywhere.
      params = {IMWRITE_TIFF_PREDICTOR, IMWRITE_TIFF_PREDICTOR_NONE};
    } else {
      if (img.depth() == CV_16U) img.convertTo(img, CV_8U, 1.0 / 257.0);
      if (want_jpeg) {
        params = {IMWRITE_JPEG_QUALITY, std::max(1, std::min(100, jpeg_quality))};
      }
    }
    if (!imwrite(out_path, img, params)) {
      fail_msg(err_buf, err_len, std::string("failed to write ") + out_path);
      return AS_ERR_ENCODE;
    }
    return AS_OK;
  } catch (const std::exception& e) {
    fail_msg(err_buf, err_len, std::string("internal error: ") + e.what());
    return AS_ERR_INTERNAL;
  }
}

void as_poll_progress(AsProgress* out) {
  if (out == nullptr) return;
  std::lock_guard<std::mutex> lock(g_progress_mutex);
  *out = g_progress;
}

void as_get_stack_result(AsStackResult* out) {
  if (out == nullptr) return;
  std::lock_guard<std::mutex> lock(g_progress_mutex);
  *out = g_result;
}

void as_cancel(void) { g_cancel.store(true); }
