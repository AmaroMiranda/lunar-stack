cmake_minimum_required(VERSION 3.22)
project(astro_engine LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# OpenCV_DIR must point at <OpenCV-android-sdk>/sdk/native/jni and is passed
# from gradle (externalNativeBuild.cmake.arguments) or -D on the CLI.
find_package(OpenCV REQUIRED COMPONENTS core imgproc imgcodecs video)

add_library(astro_engine SHARED
  engine/src/engine.cpp)

target_include_directories(astro_engine PRIVATE
  engine/include)

target_compile_options(astro_engine PRIVATE
  -O3 -fvisibility=hidden -Wall)

target_link_libraries(astro_engine PRIVATE ${OpenCV_LIBS})

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
  target_compile_options(astro_stack_cli PRIVATE -O3 -Wall)
  target_compile_definitions(astro_stack_cli PRIVATE ASTRO_DEBUG_LOG)
  target_link_libraries(astro_stack_cli PRIVATE ${OpenCV_LIBS})
  if(ANDROID)
    target_link_libraries(astro_stack_cli PRIVATE log android z)
  endif()
endif()
