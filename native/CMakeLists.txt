cmake_minimum_required(VERSION 3.22)
project(astro_engine LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# OpenCV_DIR must point at <OpenCV-android-sdk>/sdk/native/jni and is passed
# from gradle (externalNativeBuild.cmake.arguments) or -D on the CLI.
find_package(OpenCV REQUIRED COMPONENTS core imgproc imgcodecs video)

# LibRaw (vendored, LGPL-2.1/CDDL — see native/third_party/libraw/COPYRIGHT).
# OpenCV's imgcodecs cannot read camera RAW (CR2/CR3/NEF/ARW/DNG…), so the
# engine decodes those through LibRaw. Same vendored tree as AstroStitch;
# `src/integration/` (Adobe DNG SDK / RawSpeed glue) is inert without external
# SDKs and not compiled.
file(GLOB_RECURSE LIBRAW_SOURCES third_party/libraw/src/*.cpp)
# LibRaw ships placeholder stubs (*_ph.cpp) that define the SAME symbols as the
# real files; compiling both duplicates symbols. Exclude the placeholders.
list(FILTER LIBRAW_SOURCES EXCLUDE REGEX "_ph\\.cpp$")
add_library(libraw_static STATIC ${LIBRAW_SOURCES})
target_include_directories(libraw_static PUBLIC third_party/libraw)
target_compile_definitions(libraw_static PUBLIC LIBRAW_NODLL)
# dcraw-derived code is warning-noisy and not ours to clean up.
if(MSVC)
  target_compile_options(libraw_static PRIVATE /w)
else()
  target_compile_options(libraw_static PRIVATE -O3 -w)
endif()
# zlib enables deflate-compressed DNG; available on the Android build (links z).
if(ANDROID)
  target_compile_definitions(libraw_static PUBLIC USE_ZLIB)
  target_link_libraries(libraw_static PRIVATE z)
endif()

add_library(astro_engine SHARED
  engine/src/engine.cpp)

target_include_directories(astro_engine PRIVATE
  engine/include)

if(MSVC)
  target_compile_definitions(astro_engine PRIVATE
    NOMINMAX WIN32_LEAN_AND_MEAN _USE_MATH_DEFINES)
else()
  target_compile_options(astro_engine PRIVATE
    -O3 -fvisibility=hidden -Wall)
endif()

target_link_libraries(astro_engine PRIVATE ${OpenCV_LIBS} libraw_static)

if(ANDROID)
  target_link_libraries(astro_engine PRIVATE log android z)
endif()

# CLI for fast local iteration on the alignment/stacking algorithm — calls
# the same engine.cpp functions directly, no Flutter/APK/UI round-trip.
if(ASTRO_BUILD_CLI)
  add_executable(astro_stack_cli
    engine/src/engine.cpp
    tools/test_stack.cpp)
  target_include_directories(astro_stack_cli PRIVATE engine/include)
  if(MSVC)
    target_compile_definitions(astro_stack_cli PRIVATE
      ASTRO_DEBUG_LOG NOMINMAX WIN32_LEAN_AND_MEAN _USE_MATH_DEFINES)
  else()
    target_compile_options(astro_stack_cli PRIVATE -O3 -Wall)
    target_compile_definitions(astro_stack_cli PRIVATE ASTRO_DEBUG_LOG)
  endif()
  target_link_libraries(astro_stack_cli PRIVATE ${OpenCV_LIBS} libraw_static)
  if(ANDROID)
    target_link_libraries(astro_stack_cli PRIVATE log android z)
  endif()
endif()
