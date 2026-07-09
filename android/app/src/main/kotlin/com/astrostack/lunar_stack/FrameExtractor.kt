package com.astrostack.lunar_stack

import android.graphics.Bitmap
import android.media.MediaMetadataRetriever
import java.io.File
import java.io.FileOutputStream

data class ExtractionResult(
    val durationMs: Long,
    val width: Int,
    val height: Int,
    val nativeFrameCount: Int,
    val fps: Double,
    val framePaths: List<String>,
)

/**
 * Pulls a representative, evenly-spaced sample of real frames out of a video
 * via [MediaMetadataRetriever]. The vendored OpenCV Android build has no
 * video I/O backend (no FFmpeg, no MediaNDK backend compiled in), so frame
 * decoding has to happen here, not in the native engine.
 *
 * Extracting every single native frame of a multi-hundred-frame clip via
 * repeated seek+decode would be slow (each seek can redecode back to the
 * previous keyframe), so we cap how many frames we actually pull and spread
 * them evenly across the clip's real duration.
 */
object FrameExtractor {

    fun extract(
        videoPath: String,
        outputDir: String,
        targetFrameCount: Int,
        onProgress: (current: Int, total: Int) -> Unit,
    ): ExtractionResult {
        val retriever = MediaMetadataRetriever()
        try {
            retriever.setDataSource(videoPath)

            val durationMs =
                retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)
                    ?.toLongOrNull() ?: 0L
            val width =
                retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_WIDTH)
                    ?.toIntOrNull() ?: 0
            val height =
                retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_HEIGHT)
                    ?.toIntOrNull() ?: 0
            val nativeFrameCount =
                retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_FRAME_COUNT)
                    ?.toIntOrNull() ?: 0

            val fps = if (nativeFrameCount > 0 && durationMs > 0) {
                nativeFrameCount * 1000.0 / durationMs
            } else {
                30.0
            }

            val outDir = File(outputDir)
            if (!outDir.exists()) outDir.mkdirs()

            val effectiveNativeCount = if (nativeFrameCount > 0) {
                nativeFrameCount
            } else {
                ((durationMs / 1000.0) * fps).toInt().coerceAtLeast(1)
            }
            val count = minOf(targetFrameCount, effectiveNativeCount).coerceAtLeast(1)
            val durationUs = durationMs * 1000L
            val paths = ArrayList<String>(count)

            for (i in 0 until count) {
                val timeUs = if (count == 1) 0L else (i.toLong() * durationUs) / count
                val bitmap: Bitmap? = retriever.getFrameAtTime(
                    timeUs,
                    MediaMetadataRetriever.OPTION_CLOSEST,
                )
                if (bitmap != null) {
                    // PNG (lossless): JPEG's DCT ringing around the Moon's
                    // high-contrast limb differs frame to frame and blurred
                    // that edge when stacked.
                    val file = File(outDir, "frame_%04d.png".format(i))
                    FileOutputStream(file).use { out ->
                        bitmap.compress(Bitmap.CompressFormat.PNG, 100, out)
                    }
                    paths.add(file.absolutePath)
                    bitmap.recycle()
                }
                onProgress(i + 1, count)
            }

            return ExtractionResult(
                durationMs = durationMs,
                width = width,
                height = height,
                nativeFrameCount = effectiveNativeCount,
                fps = fps,
                framePaths = paths,
            )
        } finally {
            retriever.release()
        }
    }
}
