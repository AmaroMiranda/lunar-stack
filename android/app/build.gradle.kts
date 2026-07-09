plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Path to the OpenCV Android SDK cmake config (<OpenCV-android-sdk>/sdk/native/jni).
// Configure per machine via the `lunarstack.opencvDir` Gradle property
// (~/.gradle/gradle.properties or -P) or the OPENCV_ANDROID_SDK env var
// pointing at the SDK root. See README.md > Building.
val opencvDir: String =
    (project.findProperty("lunarstack.opencvDir") as String?)
        ?: System.getenv("OPENCV_ANDROID_SDK")?.let { "$it/sdk/native/jni" }
        ?: error(
            "OpenCV Android SDK not configured. Download it from " +
                "https://opencv.org/releases/ and either set " +
                "lunarstack.opencvDir=<path-to-sdk>/sdk/native/jni in " +
                "~/.gradle/gradle.properties or export OPENCV_ANDROID_SDK=<path-to-sdk>.",
        )

android {
    namespace = "com.astrostack.lunar_stack"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.astrostack.lunar_stack"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // ABIs are governed by Flutter (--split-per-abi / target-platform);
        // ndk.abiFilters would conflict with split builds.
        externalNativeBuild {
            cmake {
                arguments += listOf(
                    "-DOpenCV_DIR=$opencvDir",
                    "-DANDROID_STL=c++_shared",
                    // Builds a small CLI (astro_stack_cli) alongside the .so, for
                    // testing the alignment/stacking algorithm via `adb shell`
                    // without going through the Flutter app. Not packaged in the APK.
                    "-DASTRO_BUILD_CLI=ON",
                )
                cppFlags += "-std=c++17"
            }
        }
    }

    externalNativeBuild {
        cmake {
            path = file("../../native/CMakeLists.txt")
            version = "3.22.1"
        }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
