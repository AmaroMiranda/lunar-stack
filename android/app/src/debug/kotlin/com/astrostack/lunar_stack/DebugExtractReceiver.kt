package com.astrostack.lunar_stack

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import java.io.File

/**
 * Debug-only entry point so frame extraction can be driven from `adb shell am
 * broadcast` for local algorithm testing, without going through the file
 * picker / Flutter UI each time. Always writes under the app's own cache dir
 * (no storage permission needed) — read results back with:
 *   adb shell run-as com.astrostack.lunar_stack cat cache/dbg_frames/result.txt
 *
 * adb shell am broadcast -a com.astrostack.lunar_stack.DEBUG_EXTRACT \
 *   -n com.astrostack.lunar_stack/.DebugExtractReceiver \
 *   --es videoPath /sdcard/DCIM/Camera/moon_test.mp4 \
 *   --ei targetFrameCount 40
 */
class DebugExtractReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val videoPath = intent.getStringExtra("videoPath") ?: return
        val targetFrameCount = intent.getIntExtra("targetFrameCount", 40)
        val outputDir = File(context.cacheDir, "dbg_frames")
        val pending = goAsync()

        Thread {
            try {
                val result = FrameExtractor.extract(videoPath, outputDir.absolutePath, targetFrameCount) { _, _ -> }
                File(outputDir, "result.txt").writeText(
                    "durationMs=${result.durationMs}\n" +
                        "width=${result.width}\n" +
                        "height=${result.height}\n" +
                        "nativeFrameCount=${result.nativeFrameCount}\n" +
                        "fps=${result.fps}\n" +
                        result.framePaths.joinToString("\n"),
                )
            } catch (e: Exception) {
                outputDir.mkdirs()
                File(outputDir, "error.txt").writeText(e.stackTraceToString())
            } finally {
                pending.finish()
            }
        }.start()
    }
}
