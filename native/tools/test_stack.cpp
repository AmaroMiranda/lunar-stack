// Standalone CLI over the astro_engine, for fast iteration on the alignment
// algorithm without going through the Flutter app / UI automation.
//
// Usage: astro_stack_cli <out.png> <preview.jpg> <frame1> <frame2> ...
#include "astro_engine.h"

#include <algorithm>
#include <cmath>
#include <cstdio>
#include <cstring>
#include <vector>

#include <opencv2/opencv.hpp>

// Objective quality metrics for a stacked lunar frame. This is the validation
// harness the engine comments kept asking for ("not calibrated against a video
// corpus"): given the current pipeline's output and a single source frame, you
// can A/B any change on the two numbers the project already reasons in —
// Laplacian variance (overall sharpness/noise) and, crucially, the limb edge
// width in pixels (the direct "smear / arrasto" metric). It reads an image and
// does not touch the stacking path, so it can never regress the app.
namespace {

// Median 10-90% radial rise distance of the lunar limb, in pixels. Fits the
// disk (Otsu + largest contour + min-enclosing circle), then walks radial
// profiles from 0.85R to 1.15R at 720 angles; a tight limb = small width, a
// smeared/misaligned one = large. Scale-invariant when divided by R.
double limb_edge_width(const cv::Mat& bgr, double* out_R, int* out_n) {
  cv::Mat g;
  cv::cvtColor(bgr, g, cv::COLOR_BGR2GRAY);
  cv::Mat g32;
  g.convertTo(g32, CV_32F);
  cv::Mat th;
  cv::threshold(g, th, 0, 255, cv::THRESH_BINARY + cv::THRESH_OTSU);
  std::vector<std::vector<cv::Point>> cnts;
  cv::findContours(th, cnts, cv::RETR_EXTERNAL, cv::CHAIN_APPROX_NONE);
  if (cnts.empty()) {
    *out_R = 0;
    *out_n = 0;
    return 0;
  }
  int best = 0;
  double best_area = -1;
  for (size_t i = 0; i < cnts.size(); ++i) {
    const double a = cv::contourArea(cnts[i]);
    if (a > best_area) {
      best_area = a;
      best = static_cast<int>(i);
    }
  }
  cv::Point2f ctr;
  float R = 0;
  cv::minEnclosingCircle(cnts[best], ctr, R);

  // ~0.5 px radial step so the 10-90% width isn't quantized to the sample
  // spacing (a coarse step can't tell a 5 px limb from a 7 px one).
  const int kAngles = 720;
  const int kSamples = std::max(60, static_cast<int>(0.30 * R / 0.5));
  std::vector<double> widths;
  for (int i = 0; i < kAngles; ++i) {
    const double a = 2.0 * CV_PI * i / kAngles, dx = std::cos(a), dy = std::sin(a);
    std::vector<float> prof;
    std::vector<double> rr;
    for (int k = 0; k < kSamples; ++k) {
      const double r = 0.85 * R + 0.30 * R * k / (kSamples - 1);
      const double x = ctr.x + dx * r, y = ctr.y + dy * r;
      if (x < 0 || x >= g.cols - 1 || y < 0 || y >= g.rows - 1) continue;
      const int x0 = static_cast<int>(x), y0 = static_cast<int>(y);
      const double fx = x - x0, fy = y - y0;
      const float v = static_cast<float>(
          (1 - fx) * (1 - fy) * g32.at<float>(y0, x0) + fx * (1 - fy) * g32.at<float>(y0, x0 + 1) +
          (1 - fx) * fy * g32.at<float>(y0 + 1, x0) + fx * fy * g32.at<float>(y0 + 1, x0 + 1));
      prof.push_back(v);
      rr.push_back(r);
    }
    if (prof.size() < 50) continue;
    std::vector<float> s = prof;
    std::sort(s.begin(), s.end());
    const auto pct = [&](double p) { return s[static_cast<int>(p * (s.size() - 1))]; };
    const double hi = pct(0.95), lo = pct(0.05);
    if (hi - lo < 15) continue;  // weak contrast at this angle
    const double p10 = lo + 0.1 * (hi - lo), p90 = lo + 0.9 * (hi - lo);
    // Sub-sample the p90 and p10 crossings by linear interpolation between
    // adjacent radial samples (the disk falls off inside->outside).
    const auto cross = [&](double level, int from, int step, double* out_r) -> bool {
      for (int k = from; k >= 0 && k < static_cast<int>(prof.size()); k += step) {
        const int kn = k + step;
        if (kn < 0 || kn >= static_cast<int>(prof.size())) return false;
        const double a0 = prof[k], a1 = prof[kn];
        if ((a0 - level) * (a1 - level) <= 0 && a0 != a1) {
          const double t = (level - a0) / (a1 - a0);
          *out_r = rr[k] + t * (rr[kn] - rr[k]);
          return true;
        }
      }
      return false;
    };
    int i90 = -1;
    for (int k = static_cast<int>(prof.size()) - 1; k >= 0; --k) {
      if (prof[k] >= p90) { i90 = k; break; }
    }
    if (i90 < 0) continue;
    double r90 = 0, r10 = 0;
    if (!cross(p90, i90, 1, &r90)) r90 = rr[i90];
    if (!cross(p10, i90, 1, &r10)) continue;
    const double w = std::abs(r10 - r90);
    if (w > 0 && w < 0.2 * R) widths.push_back(w);
  }
  *out_R = R;
  *out_n = static_cast<int>(widths.size());
  if (widths.empty()) return 0;
  std::sort(widths.begin(), widths.end());
  return widths[widths.size() / 2];
}

}  // namespace

int main(int argc, char** argv) {
  // Quality metric: <exe> measure <image>  -> LapVar + limb edge width.
  if (argc >= 3 && std::strcmp(argv[1], "measure") == 0) {
    const cv::Mat img = cv::imread(argv[2], cv::IMREAD_COLOR);
    if (img.empty()) {
      std::fprintf(stderr, "measure: cannot read %s\n", argv[2]);
      return 1;
    }
    cv::Mat gray;
    cv::cvtColor(img, gray, cv::COLOR_BGR2GRAY);
    cv::Mat lap;
    cv::Laplacian(gray, lap, CV_64F);
    cv::Scalar mu, sd;
    cv::meanStdDev(lap, mu, sd);
    double R = 0;
    int ns = 0;
    const double ew = limb_edge_width(img, &R, &ns);
    std::printf("LapVar=%.1f limb_edge=%.2fpx R=%.0f edge_over_R=%.4f angles=%d\n", sd[0] * sd[0], ew,
                R, R > 0 ? ew / R : 0.0, ns);
    return 0;
  }

  // Mineral-moon smoke test: <exe> mineral <in> <out.jpg>
  if (argc >= 4 && std::strcmp(argv[1], "mineral") == 0) {
    char err[1024] = {0};
    const int32_t rc = as_mineral_adjust(
        argv[2], /*sat*/ 2.3, /*vib*/ 1.5, /*colorNoise*/ 0.15,
        /*falseColor*/ 0.5, /*r*/ 1.0, /*g*/ 1.0, /*b*/ 1.0, /*intensity*/ 1.0,
        /*full_disc*/ 0, /*warmth*/ 0.0, /*disc_mask*/ 1, /*max_dim*/ 0, argv[3],
        err, sizeof(err));
    std::printf("mineral rc=%d err=%s\n", rc, err);
    return rc == 0 ? 0 : 1;
  }
  if (argc < 5) {
    std::fprintf(stderr,
                 "usage:\n"
                 "  %s <out.png> <preview.jpg> <frame1> <frame2> ...   (stack)\n"
                 "  %s measure <image>                                 (limb/LapVar metrics)\n"
                 "  %s mineral <in> <out.jpg>                          (mineral-moon smoke test)\n",
                 argv[0], argv[0], argv[0]);
    return 1;
  }
  const char* out_path = argv[1];
  const char* preview_path = argv[2];
  std::vector<const char*> paths;
  for (int i = 3; i < argc; ++i) paths.push_back(argv[i]);

  AsStackOptions options{};
  options.stacking_method = AS_STACK_WEIGHTED_AVERAGE;
  options.auto_crop = 1;
  options.sharpen = 1;
  options.preview_max_dim = 1600;

  char err[1024] = {0};
  const int32_t rc = as_stack(paths.data(), static_cast<int32_t>(paths.size()), &options, out_path,
                               preview_path, err, sizeof(err));

  AsStackResult result{};
  as_get_stack_result(&result);

  std::printf("rc=%d err=%s\n", rc, err);
  std::printf("width=%d height=%d frames_analyzed=%d frames_stacked=%d reference_index=%d\n",
              result.width, result.height, result.frames_analyzed, result.frames_stacked,
              result.reference_index);
  return rc == AS_OK ? 0 : 1;
}
