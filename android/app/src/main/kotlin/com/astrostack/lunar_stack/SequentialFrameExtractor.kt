package com.astrostack.lunar_stack

import android.graphics.Bitmap
import android.graphics.Matrix
import android.media.Image
import android.media.MediaCodec
import android.media.MediaCodecInfo
import android.media.MediaExtractor
import android.media.MediaFormat
import java.io.File
import java.io.FileOutputStream

/**
 * Sequential video decoding via MediaExtractor+MediaCodec (hardware), the
 * architecture the product spec calls for (section 12.2 / 16.2):
 *
 *   Pass 1 [analyzeAll]  — decode EVERY frame once, in order, computing a
 *     cheap sharpness score per frame on a subsampled grayscale. No frames
 *     are kept in memory or on disk.
 *   Pass 2 [extractSelected] — decode again sequentially, saving only the
 *     selected frame indices as lossless PNG.
 *
 * This replaces MediaMetadataRetriever.getFrameAtTime(OPTION_CLOSEST), whose
 * every call re-decodes from the previous keyframe (~O(frames × GOP)) and
 * capped the app at ~60 sampled frames. Sequential decode touches each frame
 * exactly once per pass, so the whole clip (~hundreds of frames) is usable.
 */
object SequentialFrameExtractor {

    @Volatile
    var cancelRequested = false

    /**
     * Color range of the last decoded stream (set at FORMAT_CHANGED, which
     * always precedes the first frame). Camera H.264/HEVC is usually
     * LIMITED range (Y 16-235): converting it as full range turns black sky
     * into RGB(16,16,16) — the "gray background" complaint.
     */
    @Volatile
    var lastRangeLimited = false

    data class VideoInfo(
        val durationMs: Long,
        val width: Int,       // display (rotation-applied) dimensions
        val height: Int,
        val rotation: Int,
        val frameCount: Int,  // actual decoded count (analyze) or estimate (probe)
        val fps: Double,
    )

    private fun selectVideoTrack(extractor: MediaExtractor): Int {
        for (i in 0 until extractor.trackCount) {
            val mime = extractor.getTrackFormat(i).getString(MediaFormat.KEY_MIME) ?: continue
            if (mime.startsWith("video/")) return i
        }
        return -1
    }

    fun probe(videoPath: String): VideoInfo {
        val extractor = MediaExtractor()
        try {
            extractor.setDataSource(videoPath)
            val track = selectVideoTrack(extractor)
            require(track >= 0) { "no video track in $videoPath" }
            val f = extractor.getTrackFormat(track)
            val w = f.getInteger(MediaFormat.KEY_WIDTH)
            val h = f.getInteger(MediaFormat.KEY_HEIGHT)
            val rotation = if (f.containsKey(MediaFormat.KEY_ROTATION)) {
                f.getInteger(MediaFormat.KEY_ROTATION)
            } else 0
            val durationMs = if (f.containsKey(MediaFormat.KEY_DURATION)) {
                f.getLong(MediaFormat.KEY_DURATION) / 1000
            } else 0L
            val fps = if (f.containsKey(MediaFormat.KEY_FRAME_RATE)) {
                f.getInteger(MediaFormat.KEY_FRAME_RATE).toDouble()
            } else 30.0
            val swap = rotation == 90 || rotation == 270
            return VideoInfo(
                durationMs = durationMs,
                width = if (swap) h else w,
                height = if (swap) w else h,
                rotation = rotation,
                frameCount = ((durationMs / 1000.0) * fps).toInt(),
                fps = fps,
            )
        } finally {
            extractor.release()
        }
    }

    /** Pass 1: sharpness (Laplacian variance on a subsampled grayscale) per frame. */
    fun analyzeAll(videoPath: String, onProgress: (Int, Int) -> Unit): Pair<VideoInfo, DoubleArray> {
        val info = probe(videoPath)
        val estimate = info.frameCount.coerceAtLeast(1)
        val scores = ArrayList<Double>(estimate)
        decodeSequentially(videoPath) { index, image ->
            scores.add(sharpnessOf(image))
            // The container's fps metadata often under-reports (e.g. 30 vs the
            // real ~58), so the decoded count can exceed the estimate — never
            // show "641/640"; grow the total alongside.
            onProgress(index + 1, maxOf(estimate, index + 1))
            true
        }
        return Pair(
            info.copy(frameCount = scores.size),
            scores.toDoubleArray(),
        )
    }

    /**
     * Pass 2: save only `indices` (sorted ascending) as PNG into outputDir.
     *
     * The YUV→RGB conversion + PNG encode (~0.5-1s per 8 MP frame) run on a
     * small worker pool while the decoder keeps producing frames — inline
     * they stall the decoder and dominate the extraction wall time. Each
     * queued job holds one tight YUV copy (~12 MB at 4K); the semaphore
     * bounds that to 3 frames in flight.
     *
     * [centerMoon] is the "Estabilizar + empilhar" pre-alignment: each saved
     * frame is shifted (integer pixels, no resampling, no re-encode) so the
     * Moon's luminance centroid sits at the frame center. This absorbs
     * arbitrarily large shake that the stacker's global registration would
     * reject as implausible; its sub-pixel fine alignment then runs on
     * pre-centered frames.
     */
    fun extractSelected(
        videoPath: String,
        outputDir: String,
        indices: IntArray,
        centerMoon: Boolean = false,
        onProgress: (Int, Int) -> Unit,
    ): List<String> {
        val startMs = System.currentTimeMillis()
        val info = probe(videoPath)
        val outDir = File(outputDir).apply { mkdirs() }
        val wanted = indices.toSortedSet()
        val last = if (wanted.isEmpty()) -1 else wanted.last()
        val paths = java.util.concurrent.ConcurrentSkipListMap<Int, String>()
        val saved = java.util.concurrent.atomic.AtomicInteger(0)
        val firstError = java.util.concurrent.atomic.AtomicReference<Exception?>(null)

        // Each in-flight job holds a tight YUV copy (~12 MB at 4K) plus, while
        // running, an IntArray + ARGB_8888 Bitmap for the PNG encode
        // (~66 MB at 4K). A flat "3 in flight" budget regardless of
        // resolution could peak past 250-350 MB on a 4K clip; scale the
        // budget down as frames get larger instead.
        val megapixels = (info.width.toLong() * info.height.toLong()) / 1_000_000.0
        val maxInFlight = when {
            megapixels >= 7.5 -> 1 // ~4K (3840x2160 = 8.3 MP) and above
            megapixels >= 1.8 -> 2 // ~1080p (2.1 MP) and above
            else -> 3
        }
        val cores = Runtime.getRuntime().availableProcessors()
        val poolSize = (cores - 1).coerceIn(1, 4).coerceAtMost(maxInFlight)
        val pool = java.util.concurrent.Executors.newFixedThreadPool(poolSize)
        val inFlight = java.util.concurrent.Semaphore(maxInFlight)
        val futures = ArrayList<java.util.concurrent.Future<*>>()

        var cancelledMidway = false
        try {
            decodeSequentially(videoPath) { index, image ->
                if (firstError.get() != null) return@decodeSequentially false
                if (index in wanted) {
                    val w = image.width
                    val h = image.height
                    // Acquired BEFORE allocating the YUV copies below (was
                    // after): otherwise the decoder could race ahead and
                    // allocate one more set of buffers than the budget while
                    // every worker was still busy, silently exceeding the
                    // limit the semaphore exists to enforce.
                    inFlight.acquire()
                    val y = ByteArray(w * h)
                    val u = ByteArray(w / 2 * (h / 2))
                    val v = ByteArray(w / 2 * (h / 2))
                    copyPlaneTight(image.planes[0], w, h, y)
                    copyPlaneTight(image.planes[1], w / 2, h / 2, u)
                    copyPlaneTight(image.planes[2], w / 2, h / 2, v)
                    futures.add(
                        pool.submit {
                            try {
                                var dx = 0
                                var dy = 0
                                if (centerMoon) {
                                    val c = moonCentroidTight(y, w, h)
                                    if (c != null) {
                                        dx = (w / 2.0 - c.first).toInt().coerceIn(-w / 3, w / 3)
                                        dy = (h / 2.0 - c.second).toInt().coerceIn(-h / 3, h / 3)
                                    }
                                }
                                val file = File(outDir, "frame_%04d.png".format(index))
                                savePlanesAsPng(y, u, v, w, h, info.rotation, file, dx, dy, lastRangeLimited)
                                paths[index] = file.absolutePath
                                onProgress(saved.incrementAndGet(), wanted.size)
                            } catch (e: Exception) {
                                firstError.compareAndSet(null, e)
                            } finally {
                                inFlight.release()
                            }
                        },
                    )
                }
                index < last // stop decoding once every wanted frame is saved
            }
        } catch (e: InterruptedException) {
            cancelledMidway = true
            throw e
        } finally {
            pool.shutdown()
            if (cancelledMidway || cancelRequested) {
                // Cancelled: don't wait for pending encodes, their output
                // would just be discarded. shutdownNow() interrupts whatever
                // is still running.
                pool.shutdownNow()
            } else {
                // Wait for every submitted job to actually finish — no more
                // silent "gave up after 120s and returned whatever PNGs
                // happened to exist by then". There is no network call on
                // this path to justify a timeout; a job that truly never
                // returns would hang here, same as any other unbounded disk
                // I/O elsewhere in this codebase.
                for (f in futures) {
                    try {
                        f.get()
                    } catch (e: java.util.concurrent.ExecutionException) {
                        firstError.compareAndSet(null, e.cause as? Exception ?: e)
                    } catch (e: InterruptedException) {
                        Thread.currentThread().interrupt()
                        firstError.compareAndSet(null, e)
                        break
                    }
                }
            }
        }
        firstError.get()?.let { throw it }
        android.util.Log.i(
            "LunarPerf",
            "extractSelected: ${paths.size} frames in ${System.currentTimeMillis() - startMs}ms",
        )
        return ArrayList(paths.values)
    }

    /** Tight (stride == width, pixel stride 1) copy of one plane. */
    private fun copyPlaneTight(p: Image.Plane, w: Int, h: Int, out: ByteArray) {
        val buf = p.buffer
        val rs = p.rowStride
        val ps = p.pixelStride
        if (ps == 1) {
            for (y in 0 until h) {
                buf.position(y * rs)
                buf.get(out, y * w, w)
            }
        } else {
            for (y in 0 until h) {
                val base = y * rs
                for (x in 0 until w) out[y * w + x] = buf.get(base + x * ps)
            }
        }
    }

    /**
     * Synchronous decode loop in ByteBuffer mode with flexible YUV output
     * (`getOutputImage`). This is the only portable way to read decoded
     * pixels: decoding into an ImageReader surface crashes on devices whose
     * hardware decoder emits proprietary tiled formats (UnsupportedOperation
     * in the reader callback — uncaught, killed the whole app on real
     * phones), while COLOR_FormatYUV420Flexible ByteBuffer output is
     * CTS-guaranteed on every device since API 21. Everything runs on the
     * calling worker thread, so failures surface as catchable exceptions.
     * `onFrame` gets each decoded frame in presentation order; return false
     * to stop early. Images are valid only during the callback.
     */
    private fun decodeSequentially(videoPath: String, onFrame: (Int, Image) -> Boolean) {
        cancelRequested = false
        val extractor = MediaExtractor()
        extractor.setDataSource(videoPath)
        val track = selectVideoTrack(extractor)
        require(track >= 0) { "no video track in $videoPath" }
        extractor.selectTrack(track)
        val format = extractor.getTrackFormat(track)
        val mime = format.getString(MediaFormat.KEY_MIME)!!
        format.setInteger(
            MediaFormat.KEY_COLOR_FORMAT,
            MediaCodecInfo.CodecCapabilities.COLOR_FormatYUV420Flexible,
        )

        val codec = MediaCodec.createDecoderByType(mime)
        try {
            codec.configure(format, null, null, 0)
            codec.start()

            val bufferInfo = MediaCodec.BufferInfo()
            var inputDone = false
            var outputDone = false
            var frameIndex = 0
            val timeoutUs = 10_000L

            while (!outputDone && !cancelRequested) {
                if (!inputDone) {
                    val inIx = codec.dequeueInputBuffer(timeoutUs)
                    if (inIx >= 0) {
                        val buf = codec.getInputBuffer(inIx)!!
                        val size = extractor.readSampleData(buf, 0)
                        if (size < 0) {
                            codec.queueInputBuffer(inIx, 0, 0, 0, MediaCodec.BUFFER_FLAG_END_OF_STREAM)
                            inputDone = true
                        } else {
                            codec.queueInputBuffer(inIx, 0, size, extractor.sampleTime, 0)
                            extractor.advance()
                        }
                    }
                }
                when (val outIx = codec.dequeueOutputBuffer(bufferInfo, timeoutUs)) {
                    MediaCodec.INFO_OUTPUT_FORMAT_CHANGED -> {
                        val f = codec.outputFormat
                        lastRangeLimited = f.containsKey(MediaFormat.KEY_COLOR_RANGE) &&
                            f.getInteger(MediaFormat.KEY_COLOR_RANGE) == MediaFormat.COLOR_RANGE_LIMITED
                    }
                    MediaCodec.INFO_TRY_AGAIN_LATER -> {}
                    else -> if (outIx >= 0) {
                        val eos = bufferInfo.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0
                        val img = if (bufferInfo.size > 0) codec.getOutputImage(outIx) else null
                        if (img != null) {
                            // Image.close() alone does NOT return the buffer
                            // to the codec — releaseOutputBuffer is mandatory
                            // or every frame leaks one output slot and the
                            // decoder goes mute after ~15-25 frames.
                            val keepGoing = try {
                                onFrame(frameIndex, img)
                            } finally {
                                img.close()
                                codec.releaseOutputBuffer(outIx, false)
                            }
                            frameIndex++
                            if (!keepGoing) outputDone = true
                        } else {
                            codec.releaseOutputBuffer(outIx, false)
                        }
                        if (eos) outputDone = true
                    }
                }
            }
        } finally {
            try { codec.stop() } catch (_: Exception) {}
            codec.release()
            extractor.release()
        }
        if (cancelRequested) throw InterruptedException("extraction cancelled")
    }

    /** Laplacian variance of a ~step-subsampled luminance grid (YUV Y plane). */
    private fun sharpnessOf(image: Image): Double {
        val plane = image.planes[0]  // Y plane IS luminance, no RGB conversion needed
        val buf = plane.buffer
        val rowStride = plane.rowStride
        val pixelStride = plane.pixelStride
        val w = image.width
        val h = image.height
        val step = (maxOf(w, h) / 480).coerceAtLeast(1)
        val gw = w / step
        val gh = h / step
        if (gw < 3 || gh < 3) return 0.0
        val g = FloatArray(gw * gh)
        var idx = 0
        for (gy in 0 until gh) {
            val rowBase = gy * step * rowStride
            for (gx in 0 until gw) {
                g[idx++] = (buf.get(rowBase + gx * step * pixelStride).toInt() and 0xFF).toFloat()
            }
        }
        var sum = 0.0
        var sum2 = 0.0
        var n = 0
        for (y in 1 until gh - 1) {
            for (x in 1 until gw - 1) {
                val lap = (g[(y - 1) * gw + x] + g[(y + 1) * gw + x] +
                    g[y * gw + x - 1] + g[y * gw + x + 1] - 4 * g[y * gw + x]).toDouble()
                sum += lap
                sum2 += lap * lap
                n++
            }
        }
        val mean = sum / n
        return sum2 / n - mean * mean
    }

    /** Moon centroid (bright-pixel center of mass) on a tight Y plane. */
    private fun moonCentroidTight(yArr: ByteArray, w: Int, h: Int): Pair<Double, Double>? {
        val step = kotlin.math.max(1, kotlin.math.max(w, h) / 240)
        val threshold = 48
        var count = 0L
        var sumX = 0L
        var sumY = 0L
        var y = 0
        while (y < h) {
            val rowBase = y * w
            var x = 0
            while (x < w) {
                if ((yArr[rowBase + x].toInt() and 0xFF) > threshold) {
                    count++
                    sumX += x
                    sumY += y
                }
                x += step
            }
            y += step
        }
        if (count < 50) return null
        return Pair(sumX.toDouble() / count, sumY.toDouble() / count)
    }

    /**
     * BT.601 YUV420 (tight planes) -> PNG file, applying rotation.
     * dst(x,y) = src(x-dx, y-dy); out-of-range fills black. [limited] picks
     * the studio-range matrix (Y 16-235): treating limited-range video as
     * full range renders black sky as RGB(16,16,16) — a gray veil.
     */
    private fun savePlanesAsPng(
        yArr: ByteArray, uArr: ByteArray, vArr: ByteArray,
        w: Int, h: Int, rotation: Int, file: File,
        dx: Int = 0, dy: Int = 0, limited: Boolean = false,
    ) {
        val out = IntArray(w * h)
        val cw = w / 2
        val black = (0xFF shl 24)
        for (y in 0 until h) {
            val sy = y - dy
            val dRow = y * w
            if (sy < 0 || sy >= h) {
                java.util.Arrays.fill(out, dRow, dRow + w, black)
                continue
            }
            val yRow = sy * w
            val uvRow = (sy / 2) * cw
            for (x in 0 until w) {
                val sx = x - dx
                if (sx < 0 || sx >= w) {
                    out[dRow + x] = black
                    continue
                }
                val yy = yArr[yRow + sx].toInt() and 0xFF
                val uvOff = uvRow + (sx / 2)
                val u = (uArr[uvOff].toInt() and 0xFF) - 128
                val v = (vArr[uvOff].toInt() and 0xFF) - 128
                val r: Int
                val g: Int
                val b: Int
                if (limited) {
                    val yf = 1.164f * (yy - 16)
                    r = (yf + 1.596f * v).toInt().coerceIn(0, 255)
                    g = (yf - 0.392f * u - 0.813f * v).toInt().coerceIn(0, 255)
                    b = (yf + 2.017f * u).toInt().coerceIn(0, 255)
                } else {
                    r = (yy + 1.402f * v).toInt().coerceIn(0, 255)
                    g = (yy - 0.344136f * u - 0.714136f * v).toInt().coerceIn(0, 255)
                    b = (yy + 1.772f * u).toInt().coerceIn(0, 255)
                }
                out[dRow + x] = (0xFF shl 24) or (r shl 16) or (g shl 8) or b
            }
        }
        var bitmap = Bitmap.createBitmap(out, w, h, Bitmap.Config.ARGB_8888)
        if (rotation != 0) {
            val m = Matrix().apply { postRotate(rotation.toFloat()) }
            bitmap = Bitmap.createBitmap(bitmap, 0, 0, bitmap.width, bitmap.height, m, true)
        }
        FileOutputStream(file).use { stream ->
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
        }
        bitmap.recycle()
    }
}
