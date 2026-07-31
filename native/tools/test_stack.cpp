// Standalone CLI over the astro_engine, for fast iteration on the alignment
// algorithm without going through the Flutter app / UI automation.
//
// Usage: astro_stack_cli <out.png> <preview.jpg> <frame1> <frame2> ...
#include "astro_engine.h"

#include <cstdio>
#include <cstring>
#include <vector>

int main(int argc, char** argv) {
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
    std::fprintf(stderr, "usage: %s <out.png> <preview.jpg> <frame1> <frame2> ...\n", argv[0]);
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
