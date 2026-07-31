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

#include <libraw/libraw.h>

#ifdef __ANDROID__
#include <android/log.h>
#define AS_LOG(...) \
  __android_log_print(ANDROID_LOG_INFO, "astro_engine", __VA_ARGS__)
#else
#define AS_LOG(...) ((void)0)
#endif

#include <algorithm>
#include <atomic>
#include <cctype>
#include <cmath>
#include <cstdio>
#include <cstring>
#include <mutex>
#include <set>
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

std::string lower_ext(const std::string& path) {
  const size_t dot = path.find_last_of('.');
  if (dot == std::string::npos) return "";
  std::string ext = path.substr(dot + 1);
  for (auto& c : ext) c = static_cast<char>(std::tolower(static_cast<unsigned char>(c)));
  return ext;
}

// Camera RAW containers LibRaw handles and OpenCV's imgcodecs does not
// (CR2/CR3/NEF/ARW/DNG…). DNG is included: OpenCV would "read" some DNGs as a
// plain TIFF (or fail) without demosaicing the Bayer data.
bool is_raw(const std::string& path) {
  static const std::set<std::string> kRawExts = {
      "cr2", "cr3", "crw", "nef", "nrw", "arw", "srf", "sr2", "dng",
      "raf", "orf", "rw2", "pef", "raw", "3fr", "iiq", "erf", "mos",
      "mrw", "kdc", "dcr", "x3f", "srw", "rwl"};
  return kRawExts.count(lower_ext(path)) > 0;
}

// Decode a camera RAW to a 16-bit BGR Mat via LibRaw. Same decode policy as
// AstroStitch (the app STACKS, it does not reinterpret): the RAW comes out
// looking like the camera's own render, matching a TIFF/JPEG of the same shot.
//   • sRGB gamma — the standard rendering every viewer/converter applies.
//   • use_camera_wb — the shot's OWN white balance (auto WB would drift
//     between frames).
//   • no_auto_bright — auto-exposure is a per-frame EDIT; a different scale on
//     each frame would break the stack's photometric consistency.
//   • AHD demosaic, 16-bit, sRGB primaries.
Mat imread_raw16(const std::string& path) {
  LibRaw raw;
  raw.imgdata.params.output_bps = 16;
  raw.imgdata.params.no_auto_bright = 1;
  raw.imgdata.params.use_camera_wb = 1;
  raw.imgdata.params.use_auto_wb = 0;
  raw.imgdata.params.user_qual = 3;         // AHD
  raw.imgdata.params.gamm[0] = 1.0 / 2.4;   // sRGB curve
  raw.imgdata.params.gamm[1] = 12.92;
  raw.imgdata.params.output_color = 1;      // sRGB primaries

  if (raw.open_file(path.c_str()) != LIBRAW_SUCCESS) return Mat();
  if (raw.unpack() != LIBRAW_SUCCESS) return Mat();
  if (raw.dcraw_process() != LIBRAW_SUCCESS) return Mat();

  int err = 0;
  libraw_processed_image_t* out = raw.dcraw_make_mem_image(&err);
  if (out == nullptr) return Mat();
  Mat img;
  if (out->type == LIBRAW_IMAGE_BITMAP && out->colors == 3 && out->bits == 16) {
    Mat rgb(out->height, out->width, CV_16UC3, static_cast<void*>(out->data));
    cvtColor(rgb, img, COLOR_RGB2BGR);  // clones out of LibRaw's buffer
  }
  LibRaw::dcraw_clear_mem(out);
  raw.recycle();
  return img;
}

// Drop-in replacement for cv::imread that also decodes camera RAW. For RAW the
// 16-bit LibRaw output is adapted to the requested flag so the rest of the
// pipeline (which assumes 8-bit BGR from imread) is unchanged:
//   IMREAD_COLOR      -> 8-bit BGR   (RAW downscaled 16->8, i.e. the sRGB render)
//   IMREAD_GRAYSCALE  -> 8-bit gray
//   IMREAD_UNCHANGED  -> 16-bit BGR  (kept at depth, for master re-encode paths)
Mat imread_any(const std::string& path, int flags) {
  if (!is_raw(path)) return imread(path, flags);
  Mat bgr16 = imread_raw16(path);
  if (bgr16.empty()) return Mat();
  if (flags == IMREAD_UNCHANGED) return bgr16;
  Mat bgr8;
  bgr16.convertTo(bgr8, CV_8UC3, 1.0 / 257.0);  // 0..65535 -> 0..255
  if (flags == IMREAD_GRAYSCALE) {
    Mat gray;
    cvtColor(bgr8, gray, COLOR_BGR2GRAY);
    return gray;
  }
  return bgr8;
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
// `reference_gray32` and `hann` depend only on the reference proxy and its
// size — both constant across all frames in a stack — so the caller computes
// them once and passes them in, instead of this rebuilding a float copy of the
// reference and a full Hanning window on every frame (pure per-frame overhead,
// output-identical either way).
bool estimate_shift(const Mat& reference_gray, const Mat& reference_gray32, const Mat& hann,
                    const Mat& target_gray, Point2d* out_shift) {
  Mat tgt32;
  target_gray.convertTo(tgt32, CV_32F);

  double response = 0.0;
  const Point2d raw = phaseCorrelate(reference_gray32, tgt32, hann, &response);
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
// Minimum enhanced correlation coefficient (findTransformECC's own convergence
// score, range ~[-1,1] for real images) to trust an affine refinement. Below
// this, ECC ran to completion without throwing but converged to a poor local
// optimum — silently accepting it was the P0 bug: no exception, no signal.
// This threshold is a conservative first cut (not calibrated against a video
// corpus — the project doesn't have one committed yet); it only widens the
// set of frames that fall back to the coarse phase-correlation translation,
// which was already the exception-path behavior, so it cannot make alignment
// worse than before, only more consistently honest about when ECC actually
// helped.
constexpr double kMinEccScore = 0.30;

bool refine_affine(const Mat& reference_gray, const Mat& target_gray, Point2d coarse_shift,
                    Mat* out_warp) {
  Mat warp = (Mat_<float>(2, 3) << 1, 0, static_cast<float>(coarse_shift.x), 0, 1,
              static_cast<float>(coarse_shift.y));
  TermCriteria criteria(TermCriteria::COUNT + TermCriteria::EPS, 150, 1e-6);
  double ecc = 0.0;
  try {
    ecc = findTransformECC(reference_gray, target_gray, warp, MOTION_AFFINE, criteria);
  } catch (const cv::Exception&) {
    return false;  // did not converge: caller keeps the coarse translation
  }
  if (ecc < kMinEccScore) {
    return false;  // converged, but to a poor fit: don't trust the refinement
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

  // Single streaming pass instead of decomposing into a `details[scales]`
  // vector and reconstructing in a second loop: at 4K, 5 float32 full-res
  // layers is ~166 MB held simultaneously for no reason other than the two
  // loops being written separately. The two loops fold into one via the
  // telescoping identity of the à trous decomposition:
  //   c_prev(final) = lum - sum_j raw_detail[j]
  //   recon = c_prev(final) + sum_j gains[j] * w[j]
  //         = lum + sum_j (gains[j] * w[j] - raw_detail[j])
  // where w[j] is the (possibly denoised) detail layer used for
  // reconstruction and raw_detail[j] is the undenoised layer that actually
  // drives the decomposition (c_prev -> c_next). Denoising only touches w[j],
  // never the recursion itself, so raw_detail must stay separate from w — this
  // is not a plain "(gains[j]-1)*detail" simplification, which would be wrong
  // whenever j<=1 (denoised).
  Mat c_prev = lum.clone();
  Mat recon = lum.clone();
  for (int j = 0; j < scales; ++j) {
    Mat k = build_atrous_kernel_1d(j);
    Mat c_next;
    sepFilter2D(c_prev, c_next, CV_32F, k, k, Point(-1, -1), 0, BORDER_REFLECT);
    Mat raw_detail = c_prev - c_next;

    Mat w = raw_detail;
    // Denoise the two finest layers (where sensor grain lives) via soft
    // thresholding, so the gain doesn't amplify noise into the result.
    if (denoise > 0.f && j <= 1) {
      const float t = denoise * (j == 0 ? 1.0f : 0.5f);
      Mat mag = abs(raw_detail);
      threshold(mag, mag, t, 0, THRESH_TOZERO);  // |w|<t -> 0
      // rebuild signed, shrinking by t (soft threshold)
      Mat shrunk = mag - t;
      threshold(shrunk, shrunk, 0, 0, THRESH_TOZERO);
      // apply sign of raw_detail to shrunk magnitude
      Mat pos = (raw_detail >= 0);
      pos.convertTo(pos, CV_32F, 1.0 / 255.0);
      w = shrunk.mul(2 * pos - 1);
    }
    recon += gains[j] * w - raw_detail;
    c_prev = c_next;
  }

  // Apply as a luminance ratio to preserve color.
  Mat ratio;
  divide(recon, lum + 1e-3f, ratio);
  for (auto& ch : bgr) ch = ch.mul(ratio);
  merge(bgr, img_f);
}


// ===== Lua Mineral (portado do AstroStitch) =====

Mat lunar_content_mask(const Mat& bgr, bool phase_aware = false) {
  Mat gray;
  if (bgr.channels() == 3) {
    cvtColor(bgr, gray, COLOR_BGR2GRAY);
  } else {
    gray = bgr;
  }
  if (gray.depth() == CV_16U) gray.convertTo(gray, CV_8U, 1.0 / 257.0);
  // Contrast-normalize first so the threshold works on faint linear-stacked
  // frames too (a fixed cut wiped out a disk compressed into the low 12% of
  // the range). Otsu then finds the sky/disk valley automatically; cap it low
  // so real dark maria are never masked out of a high-contrast frame.
  Mat norm;
  normalize(gray, norm, 0, 255, NORM_MINMAX, CV_8U);
  Mat tmp;
  const double otsu =
      threshold(norm, tmp, 0, 255, THRESH_BINARY | THRESH_OTSU);
  Mat mask;
  threshold(norm, mask, std::min(otsu, 25.0), 255, THRESH_BINARY);
  if (phase_aware) {
    // Partial phases (crescent/gibbous): the terminator fades gradually, and
    // the capped threshold bites ragged chunks out of that dim sunlit terrain
    // — tiles then leave those regions uncovered and the mosaic shows black
    // holes along the terminator. Recover them by keeping every low-threshold
    // component CONNECTED to the bright disk; sky noise stays out because it
    // is disconnected. (Not used for the solar disk: its limb is a hard edge
    // and the low threshold would only pull in glow.)
    Mat weak;
    threshold(norm, weak, 5.0, 255, THRESH_BINARY);
    Mat k5 = getStructuringElement(MORPH_ELLIPSE, Size(5, 5));
    morphologyEx(weak, weak, MORPH_CLOSE, k5);
    Mat labels;
    const int ncomp = connectedComponents(weak, labels, 8, CV_32S);
    std::vector<uint8_t> keep(static_cast<size_t>(std::max(ncomp, 1)), 0);
    for (int y = 0; y < labels.rows; ++y) {
      const int* lr = labels.ptr<int>(y);
      const uchar* sr = mask.ptr<uchar>(y);
      for (int x = 0; x < labels.cols; ++x) {
        if (sr[x] && lr[x] > 0) keep[static_cast<size_t>(lr[x])] = 1;
      }
    }
    for (int y = 0; y < labels.rows; ++y) {
      const int* lr = labels.ptr<int>(y);
      uchar* mr = mask.ptr<uchar>(y);
      for (int x = 0; x < labels.cols; ++x) {
        mr[x] = (lr[x] > 0 && keep[static_cast<size_t>(lr[x])]) ? 255 : 0;
      }
    }
  }
  Mat k = getStructuringElement(MORPH_ELLIPSE, Size(9, 9));
  morphologyEx(mask, mask, MORPH_CLOSE, k);
  // Speckle removal that PRESERVES the true disc boundary. A morphological OPEN
  // here (erode→dilate) removed sky speckle but also ate a ~4px band off the
  // dim OUTER LIMB — real edge craters vanished from the mosaic (a good stitcher
  // feathers overlaps but never erodes the subject's outer edge). Drop small
  // isolated components instead: the Moon/Sun disc is by far the largest, so
  // sky speckle that passed the threshold is removed while the disc keeps its
  // exact edge. Threshold scales with the disc so it is resolution-independent.
  {
    Mat labels, stats, centroids;
    const int nlab =
        connectedComponentsWithStats(mask, labels, stats, centroids, 8, CV_32S);
    int best_area = 0;
    for (int i = 1; i < nlab; ++i) {
      best_area = std::max(best_area, stats.at<int>(i, CC_STAT_AREA));
    }
    if (best_area > 0) {
      const int min_keep = std::max(64, best_area / 500);
      Mat clean = Mat::zeros(mask.size(), CV_8U);
      for (int i = 1; i < nlab; ++i) {
        if (stats.at<int>(i, CC_STAT_AREA) >= min_keep) {
          clean.setTo(255, labels == i);
        }
      }
      mask = clean;
    }
  }
  return mask;
}

void apply_mineral_moon(Mat& bgr, double saturation, double vibrance,
                        double colorNoise, double falseColor, double rGain = 1.0,
                        double gGain = 1.0, double bGain = 1.0,
                        double intensity = 0.6, bool fullDisc = false,
                        double warmth = 0.0, bool discMask = true) {
  if (bgr.empty() || bgr.channels() != 3) return;  // mono: nothing to tint
  const int depth = bgr.depth();
  const double maxv = (depth == CV_16U) ? 65535.0 : 255.0;
  Mat f;
  bgr.convertTo(f, CV_32F, 1.0 / maxv);

  // Máscara do DISCO lunar: o grade de cor deve valer só no disco, não no céu/
  // fundo (o usuário reportou a cor sendo aplicada na imagem toda). Guardamos o
  // original e, no fim, restauramos tudo fora do disco. `orig_f` é a referência
  // do "fora"; `disc_alpha` (0..1, borda suavizada) é o peso de mistura. Se a
  // detecção falhar ou o disco cobrir o quadro todo, `disc_alpha` fica vazio e
  // o grade vale para tudo (comportamento antigo) — fallback seguro.
  //
  // No modo CLOSE-UP (crateras / região ampliada) não há disco nem céu — o
  // quadro inteiro é superfície lunar. `discMask=false` desliga a máscara e
  // grada tudo, senão a detecção confinaria a cor a uma mancha brilhante à toa.
  const Mat orig_f = f.clone();
  Mat disc_alpha;
  if (discMask) {
    Mat disc = lunar_content_mask(bgr, /*phase_aware=*/true);
    const double area = disc.empty() ? 0.0 : countNonZero(disc);
    const double total = static_cast<double>(disc.total());
    if (area > 0.02 * total && area < 0.995 * total) {
      // Dilata um filete (a cor chega até o limbo real) e suaviza a transição
      // para o céu, evitando uma emenda dura na borda.
      const double fsig = std::max(1.0, 0.0012 * std::min(bgr.rows, bgr.cols));
      disc.convertTo(disc_alpha, CV_32F, 1.0 / 255.0);
      dilate(disc_alpha, disc_alpha, getStructuringElement(MORPH_ELLIPSE, Size(5, 5)));
      GaussianBlur(disc_alpha, disc_alpha, Size(0, 0), fsig);
      min(disc_alpha, 1.0f, disc_alpha);
    }
  }

  // 1. Gray-world neutralization over the WELL-lit surface. The threshold is
  //    deliberately above the limb fade (0.06, not 0.02) so the dim terminator
  //    edge — where colour is mostly noise — can't bias the balance and later
  //    surface as a coloured rim.
  {
    std::vector<Mat> ch;
    split(f, ch);
    Mat luma = 0.114f * ch[0] + 0.587f * ch[1] + 0.299f * ch[2];
    Mat lit = luma > 0.06f;
    if (countNonZero(lit) > 100) {
      const Scalar mb = mean(f, lit);
      const double gray = (mb[0] + mb[1] + mb[2]) / 3.0;
      for (int c = 0; c < 3; ++c) {
        if (mb[c] > 1e-6) ch[c] *= static_cast<float>(gray / mb[c]);
      }
      merge(ch, f);
    }
  }
  max(f, 0.0f, f);
  min(f, 1.0f, f);

  Mat ycc;
  cvtColor(f, ycc, COLOR_BGR2YCrCb);  // Y,Cr,Cb in 0..1 (chroma centered 0.5)
  std::vector<Mat> yc;
  split(ycc, yc);
  Mat& Y = yc[0];
  Mat cr = yc[1] - 0.5f;
  Mat cb = yc[2] - 0.5f;

  // 2. Chroma-only noise reduction: blur Cr/Cb (Y untouched → detail stays
  //    sharp). Deliberately GENTLE — the Moon's real mineral colour is itself
  //    fairly fine-scale, so a strong chroma blur greys the disk (measured:
  //    sigma≈1.9 cut real blue↔orange chroma to ~23%). This removes only the
  //    worst speckle; raising the slider trades colour for smoothness and is
  //    the user's call (default is low). sigma tops out ~1.5px at full.
  if (colorNoise > 0.0) {
    const double sigma = colorNoise * 1.5;
    GaussianBlur(cr, cr, Size(0, 0), sigma);
    GaussianBlur(cb, cb, Size(0, 0), sigma);
  }

  // 3. False-colour suppression: remove the diagonal (green+magenta) component
  //    (Cr+Cb)/2, leaving only the real blue↔orange axis.
  if (falseColor > 0.0) {
    Mat off = (cr + cb) * 0.5f;
    cr = cr - off * static_cast<float>(falseColor);
    cb = cb - off * static_cast<float>(falseColor);
  }

  // 4. Saturation + vibrance, gated by a shadow-protection weight so the dim
  //    limb is not amplified (the source of the blue edge band). Vibrance adds
  //    extra gain to weakly-coloured pixels, tapering off as chroma grows.
  Mat chroma;
  magnitude(cr, cb, chroma);
  Mat vibGain = chroma * 4.0f;
  min(vibGain, 1.0f, vibGain);
  vibGain = (1.0f - vibGain) * static_cast<float>(vibrance);
  // Shadow + LIMB protection. The weight comes from the LOCAL-MIN luma (Y
  // eroded), not Y itself: a pixel is attenuated when it is dim OR when a very
  // dark sky pixel lies within `lr` of it — i.e. the thin band just inside the
  // limb. Without this, strong saturation turns the limb's real chromatic-
  // aberration fringe (blue on one edge, orange on the opposite) into a vivid
  // coloured HALO ringing the whole disk. The interior surface, whose whole
  // neighbourhood is lit, keeps w=1 and full colour. `lr` scales with size.
  Mat w;
  // No close-up (sem máscara de disco) não há limbo nem céu — e as sombras de
  // cratera têm cor real, então a proteção por luma-mínima (que atenuaria essas
  // sombras) é indesejada. Grade uniforme (w=1), como no "disco inteiro".
  if (fullDisc || !discMask) {
    // "Aplicar no disco inteiro" (escolha do usuário): sem atenuação de limbo,
    // a cor mineral chega até a borda do disco — nada de faixa incolor. O custo
    // é que a franja de aberração cromática do limbo pode aparecer levemente
    // colorida; é uma troca que o usuário optou por fazer explicitamente.
    w = Mat::ones(Y.size(), CV_32F);
  } else {
    // Banda de proteção do limbo: só o FILETE da franja de CA (2-4px na borda),
    // não uma margem larga. 1.2% comia ~36px, 0.5% ainda deixava ~15px sem cor;
    // 0.25% (~7px num disco de 3000) cobre a franja e deixa a cor chegar à borda,
    // como na referência (que tem mineral até o limbo).
    const int lr = std::max(
        2, static_cast<int>(std::round(0.0025 * std::min(bgr.rows, bgr.cols))));
    // Local-min of luma to find the near-limb band, computed on a 1/4-scale copy
    // so the erode is cheap regardless of resolution — a full-res erode with a
    // large kernel froze the live preview and the save on full-res masters
    // (v0.34.1 regression). The weight is smooth (a band along the limb), so the
    // downscale/upscale is invisible. MORPH_RECT (separable) on top.
    Mat Ymin;
    {
      const double s = 0.25;
      Mat small;
      resize(Y, small, Size(), s, s, INTER_AREA);
      const int lrs = std::max(1, static_cast<int>(std::round(lr * s)));
      erode(small, small,
            getStructuringElement(MORPH_RECT, Size(2 * lrs + 1, 2 * lrs + 1)));
      resize(small, Ymin, Y.size(), 0, 0, INTER_LINEAR);
    }
    w = (Ymin - 0.05f) * (1.0f / 0.15f);  // 0 at Ymin≤0.05, 1 at Ymin≥0.20
    max(w, 0.0f, w);
    min(w, 1.0f, w);
  }

  // Pass 1: the user's normal saturation+vibrance gain (unchanged formula).
  Mat gain = 1.0f + w.mul(vibGain + static_cast<float>(saturation));
  cr = cr.mul(gain);
  cb = cb.mul(gain);

  // Pass 2: adaptive auto-stretch. Real per-shot chroma signal varies hugely
  // — a well-exposed dedicated astro capture and a bright, JPEG-compressed
  // phone photo can differ 5x+ in raw mineral-colour signal. A fixed
  // saturation multiplier alone either does nothing on a weak source or is
  // overkill on a strong one. So MEASURE what pass 1 actually achieved (90th
  // percentile chroma over the lit disk, ground truth — not a prediction)
  // and, only if it still falls short of a fixed target, multiply the
  // REMAINING gap on top. An already-vivid source (real dedicated astro
  // data, or a weak source pass 1 already lifted enough) measures at/above
  // target and gets autoMul≈1 — no double-counting on top of the user's
  // saturation slider.
  {
    magnitude(cr, cb, chroma);
    Mat litMask = Y > 0.06f;
    const int lit_n = countNonZero(litMask);
    double autoMul = 1.0;
    if (lit_n > 100) {
      std::vector<float> vals;
      vals.reserve(static_cast<size_t>(lit_n));
      for (int y = 0; y < chroma.rows; ++y) {
        const float* cp = chroma.ptr<float>(y);
        const uchar* lp = litMask.ptr<uchar>(y);
        for (int x = 0; x < chroma.cols; ++x) {
          if (lp[x]) vals.push_back(cp[x]);
        }
      }
      const size_t idx = static_cast<size_t>(vals.size() * 0.90);
      std::nth_element(vals.begin(), vals.begin() + idx, vals.end());
      const double p90 = vals[idx];
      // Source-variance FLOOR (boost-only): a weak/compressed source whose
      // pass-1 chroma is well below a baseline gets lifted up to it, so it is
      // not colourless. A source that already reached the baseline — or whose
      // Saturation/Vibration pushed past it — is LEFT ALONE (autoMul≈1). This is
      // the fix for "saturation/vibration doing nothing": the old code RE-
      // NORMALISED to a target and divided their effect back out; a boost-only
      // floor never caps, so the sliders stay effective above it. The master
      // Intensity (applied after this block) does the dialling UP and DOWN.
      // Reference mineral moons (5 measured: Lucca, astropix, etc.) sit at
      // chroma p90 ≈ 0.045–0.061 — so kFloorP90 = 0.05 is the validated target.
      // The cap was 4×, which left a very weak phone source (measured output
      // p90 ≈ 0.015) short of the target; 8× lets even a faint source reach the
      // reference level. Boost-only: a strong source is never pushed down here.
      // O piso antigo (levantar TODA fonte com p90<0.05 ATÉ 0.05) mascarava
      // Saturação/Vibração: uma fonte fraca a sat=2.5 e a mesma a sat=6 caíam
      // as duas em 0.05 — os sliders "não funcionavam" (3ª reclamação disso).
      // Agora o piso é uma rede de segurança GENTIL, que só dispara em fontes
      // QUASE SEM COR (p90 < gatilho) e levanta de leve (raiz, teto baixo). Para
      // qualquer fonte com cor de verdade (a esmagadora maioria) autoMul≈1, e o
      // nível fica 100% nas mãos do usuário (sat/vib + Intensidade).
      constexpr double kFloorTrigger = 0.028;  // só fontes bem fracas
      constexpr double kFloorTarget = 0.045;
      if (p90 > 1e-4 && p90 < kFloorTrigger) {
        autoMul = std::clamp(std::sqrt(kFloorTarget / p90), 1.0, 2.5);
      }
      AS_LOG("mineral floor: p90=%.5f mul=%.3f intensity=%.2f",
             p90, autoMul, intensity);
    }
    // A weak source's chroma p90 is dominated by JPEG block noise, not real
    // mineral colour (measured: multiplying a real phone photo's post-gain
    // chroma further painted visible orange/blue 8x8-block speckle across
    // smooth mare — not the smooth colour a stronger source shows at the
    // same gain). Real lunar colour varies over tens/hundreds of pixels
    // (whole maria); block noise varies pixel-to-pixel. So when autoMul is
    // doing real work, smooth cr/cb FIRST — proportional to how much extra
    // push is needed — so we stretch the real large-scale structure, not the
    // noise floor. A source that already met target (autoMul≈1) gets no
    // extra blur, same as before this feature existed.
    if (autoMul > 1.05) {
      const double extraSigma = std::min(2.5, 0.9 * (autoMul - 1.0));
      GaussianBlur(cr, cr, Size(0, 0), extraSigma);
      GaussianBlur(cb, cb, Size(0, 0), extraSigma);
    }
    if (autoMul > 1.001) {
      cr = cr * static_cast<float>(autoMul);
      cb = cb * static_cast<float>(autoMul);
    }
  }

  // Master INTENSITY: a final scale on the whole graded chroma. 1.0 = the base
  // look; below 1 dials toward neutral (the user can ALWAYS reduce the colour,
  // instead of it being forced); above 1 pushes stronger. Because it multiplies
  // the already-graded cr/cb, the Saturation/Vibration work stays visible and
  // Intensity rides on top of it.
  if (std::abs(intensity - 1.0) > 1e-3) {
    cr = cr * static_cast<float>(intensity);
    cb = cb * static_cast<float>(intensity);
  }

  // Tom (quente↔frio): o eixo estético em que as boas luas minerais de fato
  // variam (medido: da Lucca mais azul à astropix mais quente). Em YCrCb o
  // ocre/laranja das terras altas pesa no +Cr e o azul dos mares no +Cb;
  // warmth>0 realça o lado quente e recua o frio, warmth<0 o inverso.
  // 0 = neutro (no-op). Faixa útil -1..+1.
  if (std::abs(warmth) > 1e-3) {
    const float wf = static_cast<float>(std::clamp(warmth, -1.0, 1.0));
    cr = cr * (1.0f + 0.5f * wf);
    cb = cb * (1.0f - 0.5f * wf);
  }

  // Redução de ruído de cor NA IMAGEM FINAL. O blur de croma do passo 2 acontece
  // ANTES dos ganhos (saturação/vibração/autoMul/intensidade), que re-amplificam
  // o croma — então o speckle de cor que o usuário realmente vê é pós-ganho e o
  // blur inicial não o alcança (era o "parece não estar sendo aplicada"). Aqui,
  // no croma já graduado e com o Y intacto (detalhe preservado), o blur age
  // exatamente sobre o ruído visível. A cor mineral real é de larga escala
  // (dezenas de px), então sobrevive; o slider controla o quanto (é a escolha do
  // usuário trocar cor por suavidade).
  if (colorNoise > 0.0) {
    const double finalSigma = colorNoise * 4.0;  // slider 1.0 -> ~4px (forte)
    GaussianBlur(cr, cr, Size(0, 0), finalSigma);
    GaussianBlur(cb, cb, Size(0, 0), finalSigma);
  }

  yc[1] = cr + 0.5f;
  yc[2] = cb + 0.5f;
  max(yc[1], 0.0f, yc[1]);
  min(yc[1], 1.0f, yc[1]);
  max(yc[2], 0.0f, yc[2]);
  min(yc[2], 1.0f, yc[2]);
  merge(yc, ycc);
  cvtColor(ycc, f, COLOR_YCrCb2BGR);

  // 5. Per-channel RGB balance (studio fine-tuning). Applied to the final BGR,
  //    AFTER the luma-preserving chroma grade, as a white-balance-style tint the
  //    user dials in on top: warm the highlands, cool the maria, or correct a
  //    residual cast. Neutral (1,1,1) leaves the image byte-identical. f is BGR,
  //    so index 0=B, 1=G, 2=R.
  if (rGain != 1.0 || gGain != 1.0 || bGain != 1.0) {
    std::vector<Mat> bch;
    split(f, bch);
    bch[0] *= static_cast<float>(bGain);
    bch[1] *= static_cast<float>(gGain);
    bch[2] *= static_cast<float>(rGain);
    merge(bch, f);
  }

  max(f, 0.0f, f);
  min(f, 1.0f, f);

  // Confina o grade ao DISCO lunar: fora do disco, restaura o pixel original
  // (o céu/fundo não é tingido). Mistura por alpha suavizado no limbo:
  //   out = orig·(1-a) + graded·a.  Vazio => grade vale para tudo (fallback).
  if (!disc_alpha.empty()) {
    std::vector<Mat> gch, och;
    split(f, gch);
    split(orig_f, och);
    for (int c = 0; c < 3; ++c) {
      gch[c] = och[c].mul(1.0f - disc_alpha) + gch[c].mul(disc_alpha);
    }
    merge(gch, f);
  }

  f.convertTo(bgr, depth, maxv);
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
    Mat img = imread_any(utf8_paths[i], IMREAD_GRAYSCALE);
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
    //
    // Streaming by design: only `sharpness[]` (one double per frame, ~16 KB
    // even at 2000 frames) survives this loop. Earlier revisions kept every
    // frame's proxy in a `std::vector<Mat> proxies(n)` for reuse in pass 2 —
    // at the UI's 2000-frame ceiling and a 4K source (2600px-longest-edge
    // proxy, ~3.8 MB each), that alone reached ~7.6 GB, well past what an
    // Android app can hold before the accumulator/ECC/wavelet buffers even
    // exist. Pass 2 below regenerates each proxy on demand instead of
    // caching it.
    std::vector<double> sharpness(n, 0.0);
    Size full_size;

    for (size_t i = 0; i < n; ++i) {
      if (cancelled()) return AS_ERR_CANCELLED;
      Mat img = imread_any(paths[i], IMREAD_COLOR);
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
      set_progress(AS_STAGE_ANALYZING, static_cast<int32_t>(i) + 1,
                   static_cast<int32_t>(n), 0.25f * (i + 1) / n);
    }

    size_t ref_idx = 0;
    for (size_t i = 1; i < n; ++i) {
      if (sharpness[i] > sharpness[ref_idx]) ref_idx = i;
    }
    const double proxy_scale = resize_scale_for_max_dim(full_size.width, full_size.height, 2600);

    // The one proxy pass 2 actually needs resident throughout: the anchor's,
    // regenerated once here (cheap relative to the O(n) alternative above)
    // and reused as the alignment target for every other frame below.
    Mat ref_proxy;
    {
      Mat ref_img = imread_any(paths[ref_idx], IMREAD_COLOR);
      if (ref_img.empty()) {
        fail_msg(err_buf, err_len, "failed to decode: " + paths[ref_idx]);
        return AS_ERR_DECODE;
      }
      Mat ref_gray = to_gray8(ref_img);
      ref_img.release();
      if (proxy_scale < 1.0) {
        resize(ref_gray, ref_proxy, Size(), proxy_scale, proxy_scale, INTER_AREA);
      } else {
        ref_proxy = ref_gray;
      }
    }

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
    // Reference-derived inputs for phase correlation: constant for the whole
    // stack, so build them once here rather than per frame inside the loop.
    Mat ref_proxy32, hann;
    ref_proxy.convertTo(ref_proxy32, CV_32F);
    createHanningWindow(hann, ref_proxy.size(), CV_32F);

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

      // Full-resolution decode moved ahead of alignment (was after it): the
      // alignment proxy is now regenerated from this same in-memory frame
      // instead of a pass-1 cache, so it has to exist first. Frames that end
      // up rejected below now cost one extra decode versus the old
      // cache-then-skip order — an acceptable trade for not holding an O(n)
      // proxy array (see the streaming-memory note above).
      Mat frame = imread_any(paths[i], IMREAD_COLOR);
      if (frame.empty()) continue;
      if (frame.size() != full_size) resize(frame, frame, full_size, 0, 0, INTER_LINEAR);

      Mat warp_full;  // 2x3 CV_32F, aligned(x) = frame(warp_full(x))
      if (i != ref_idx) {
        Mat gray = to_gray8(frame);
        Mat proxy;
        const double scale = resize_scale_for_max_dim(gray.cols, gray.rows, 2600);
        if (scale < 1.0) {
          resize(gray, proxy, Size(), scale, scale, INTER_AREA);
        } else {
          proxy = gray;
        }

        Point2d shift(0.0, 0.0);
        if (!estimate_shift(ref_proxy, ref_proxy32, hann, proxy, &shift)) {
          continue;  // could not align this frame: skip it
        }

        Mat warp_proxy;
        const bool ecc_ok = refine_affine(ref_proxy, proxy, shift, &warp_proxy);
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
        // acc += aligned * w without materializing a full-resolution
        // CV_32FC3 temporary for `aligned * w` each frame (at 4K that temp is
        // ~100 MB of alloc/free churn per frame). scaleAdd fuses the multiply
        // and add in place — same float result.
        scaleAdd(aligned, w, acc, acc);
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
    // IMREAD_UNCHANGED keeps 16-bit TIFF masters at full depth; imread_any also
    // lets this decode a camera RAW (used to render the "before" preview).
    Mat img = imread_any(in_path, IMREAD_UNCHANGED);
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

int32_t as_wavelet_sharpen(const char* in_path, const float* layer_gains, int32_t n_layers,
                            float denoise, int32_t max_dim, const char* out_path,
                            char* err_buf, int32_t err_len) {
  if (in_path == nullptr || out_path == nullptr || layer_gains == nullptr || n_layers <= 0) {
    fail_msg(err_buf, err_len, "in_path, out_path and layer_gains are required");
    return AS_ERR_INVALID_ARGS;
  }
  try {
    // IMREAD_UNCHANGED so a 16-bit TIFF master keeps its depth through the
    // adjustment; the wavelet math runs in float either way.
    Mat img = imread(in_path, IMREAD_UNCHANGED);
    if (img.empty()) {
      fail_msg(err_buf, err_len, std::string("could not decode ") + in_path);
      return AS_ERR_DECODE;
    }
    if (img.channels() == 4) cvtColor(img, img, COLOR_BGRA2BGR);
    if (img.channels() == 1) cvtColor(img, img, COLOR_GRAY2BGR);
    const int src_depth = img.depth();

    // Live preview: shrink first so each slider drag re-renders in a few ms.
    if (max_dim > 0) {
      const double s = resize_scale_for_max_dim(img.cols, img.rows, max_dim);
      if (s < 1.0) resize(img, img, Size(), s, s, INTER_AREA);
    }

    // wavelet_sharpen_bgr works in a 0..255 float space regardless of source
    // bit depth.
    Mat img_f;
    const double to_f = (src_depth == CV_16U) ? (255.0 / 65535.0) : 1.0;
    img.convertTo(img_f, CV_32FC3, to_f);

    std::vector<float> gains(layer_gains, layer_gains + n_layers);
    wavelet_sharpen_bgr(img_f, gains, denoise);

    cv::max(img_f, 0.0, img_f);
    cv::min(img_f, 255.0, img_f);

    const std::string out_str(out_path);
    const auto ends_with = [&out_str](const char* suf) {
      const size_t n = std::strlen(suf);
      return out_str.size() >= n && out_str.compare(out_str.size() - n, n, suf) == 0;
    };
    const bool want_tiff = ends_with(".tif") || ends_with(".tiff");
    const bool want_jpeg = ends_with(".jpg") || ends_with(".jpeg");

    Mat out;
    std::vector<int> params;
    if (want_tiff) {
      img_f.convertTo(out, CV_16UC3, 257.0);  // 0..255 float -> 0..65535
      params = {IMWRITE_TIFF_PREDICTOR, IMWRITE_TIFF_PREDICTOR_NONE};
    } else {
      img_f.convertTo(out, CV_8UC3);
      if (want_jpeg) params = {IMWRITE_JPEG_QUALITY, 95};
    }
    if (!imwrite(out_path, out, params)) {
      fail_msg(err_buf, err_len, std::string("failed to write ") + out_path);
      return AS_ERR_ENCODE;
    }
    return AS_OK;
  } catch (const std::exception& e) {
    fail_msg(err_buf, err_len, std::string("internal error: ") + e.what());
    return AS_ERR_INTERNAL;
  }
}

// "Lua Mineral": realça a cor mineral REAL da Lua (titânio→azul, ferro→laranja)
// sobre uma imagem salva (um stack pronto ou uma foto única), sem mexer no
// brilho/detalhe. Portado do AstroStitch. max_dim>0 processa uma cópia reduzida
// para a prévia ao vivo; 0 = resolução cheia ao salvar. Formato pela extensão.
int32_t as_mineral_adjust(const char* in_path, double saturation, double vibrance,
                          double color_noise, double false_color, double r_gain,
                          double g_gain, double b_gain, double intensity,
                          int32_t full_disc, double warmth, int32_t disc_mask,
                          int32_t max_dim, const char* out_path, char* err_buf,
                          int32_t err_len) {
  if (in_path == nullptr || out_path == nullptr) {
    fail_msg(err_buf, err_len, "in_path and out_path are required");
    return AS_ERR_INVALID_ARGS;
  }
  try {
    Mat img = imread_any(in_path, IMREAD_UNCHANGED);
    if (img.empty()) {
      fail_msg(err_buf, err_len, std::string("could not decode ") + in_path);
      return AS_ERR_DECODE;
    }
    if (img.channels() == 4) cvtColor(img, img, COLOR_BGRA2BGR);
    if (img.channels() == 1) cvtColor(img, img, COLOR_GRAY2BGR);  // mono: no-op grade
    if (max_dim > 0) {
      const double s = resize_scale_for_max_dim(img.cols, img.rows, max_dim);
      if (s < 1.0) resize(img, img, Size(), s, s, INTER_AREA);
    }
    apply_mineral_moon(img, saturation, vibrance, color_noise, false_color,
                       r_gain, g_gain, b_gain, intensity, full_disc != 0, warmth,
                       disc_mask != 0);

    const std::string out_str(out_path);
    const auto ends_with = [&out_str](const char* suf) {
      const size_t n = std::strlen(suf);
      return out_str.size() >= n && out_str.compare(out_str.size() - n, n, suf) == 0;
    };
    const bool want_tiff = ends_with(".tif") || ends_with(".tiff");
    const bool want_jpeg = ends_with(".jpg") || ends_with(".jpeg");
    Mat out = img;
    std::vector<int> params;
    if (want_tiff) {
      if (img.depth() != CV_16U) img.convertTo(out, CV_16UC3, 257.0);
      params = {IMWRITE_TIFF_PREDICTOR, IMWRITE_TIFF_PREDICTOR_NONE};
    } else {
      if (img.depth() == CV_16U) img.convertTo(out, CV_8UC3, 1.0 / 257.0);
      if (want_jpeg) params = {IMWRITE_JPEG_QUALITY, 95};
    }
    if (!imwrite(out_path, out, params)) {
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
