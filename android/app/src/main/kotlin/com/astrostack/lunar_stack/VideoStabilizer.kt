package com.astrostack.lunar_stack

import android.media.Image
import android.media.MediaCodec
import android.media.MediaCodecInfo
import android.media.MediaCodecList
import android.media.MediaExtractor
import android.media.MediaFormat
import android.media.MediaMuxer
import java.io.File
import kotlin.math.max
import kotlin.math.min
import kotlin.math.roundToInt

/**
 * "Apenas estabilizar": re-encodes the clip with the Moon locked to the frame
 * center. The Moon is a bright blob on black sky, so per-frame registration
 * is a luminance centroid (robust, no feature matching needed); the shift is
 * applied as an integer translation of the YUV planes straight into the
 * encoder's input image — no RGB conversion, no Canvas, timestamps preserved.
 *
 * Output is H.264/MP4 (video track only — Moon clips have no useful audio).
 * If the device encoder can't do the source resolution, the frame is
 * decimated by 2 until it fits (encoder caps are queried, not guessed).
 */
object VideoStabilizer {

    @Volatile
    var cancelRequested = false

    data class Result(
        val width: Int,
        val height: Int,
        val frames: Int,
        val durationMs: Long,
    )

    fun stabilize(
        videoPath: String,
        outPath: String,
        onProgress: (Int, Int) -> Unit,
    ): Result {
        cancelRequested = false
        val info = SequentialFrameExtractor.probe(videoPath)
        val estimate = info.frameCount.coerceAtLeast(1)

        val extractor = MediaExtractor()
        extractor.setDataSource(videoPath)
        var track = -1
        for (i in 0 until extractor.trackCount) {
            val mime = extractor.getTrackFormat(i).getString(MediaFormat.KEY_MIME) ?: continue
            if (mime.startsWith("video/")) { track = i; break }
        }
        require(track >= 0) { "no video track in $videoPath" }
        extractor.selectTrack(track)
        val srcFormat = extractor.getTrackFormat(track)
        val srcMime = srcFormat.getString(MediaFormat.KEY_MIME)!!
        val srcW = srcFormat.getInteger(MediaFormat.KEY_WIDTH)
        val srcH = srcFormat.getInteger(MediaFormat.KEY_HEIGHT)
        val rotation = if (srcFormat.containsKey(MediaFormat.KEY_ROTATION)) {
            srcFormat.getInteger(MediaFormat.KEY_ROTATION)
        } else 0
        val fps = info.fps.roundToInt().coerceIn(1, 120)

        // -- Pick an encoder size the device supports AT THIS FRAME RATE -----
        // findEncoderForFormat must be queried without a frame rate, but a
        // size can pass that check and still exceed the codec LEVEL once the
        // real fps applies (e.g. phone AVC encoders often do 4K@30 but not
        // 4K@60): configure() accepts it and the encoder stalls after ~a
        // queue's worth of frames. areSizeAndRateSupported catches that.
        val avc = MediaFormat.MIMETYPE_VIDEO_AVC
        val codecs = MediaCodecList(MediaCodecList.REGULAR_CODECS)
        var scale = 1
        var dstW = srcW
        var dstH = srcH
        var encoderName: String? = null
        while (true) {
            dstW = (srcW / scale) and 1.inv()  // even dimensions
            dstH = (srcH / scale) and 1.inv()
            val probeFormat = MediaFormat.createVideoFormat(avc, dstW, dstH).apply {
                setInteger(
                    MediaFormat.KEY_COLOR_FORMAT,
                    MediaCodecInfo.CodecCapabilities.COLOR_FormatYUV420Flexible,
                )
            }
            val name = codecs.findEncoderForFormat(probeFormat)
            if (name != null) {
                val caps = codecs.codecInfos
                    .firstOrNull { it.name == name }
                    ?.getCapabilitiesForType(avc)
                    ?.videoCapabilities
                if (caps != null &&
                    caps.areSizeAndRateSupported(dstW, dstH, fps.toDouble())
                ) {
                    encoderName = name
                    break
                }
            }
            if (dstW <= 320 || dstH <= 320) break
            scale *= 2
        }
        requireNotNull(encoderName) { "no H.264 encoder available for ${dstW}x$dstH@${fps}fps" }
        android.util.Log.i(
            "LunarStab",
            "encoder=$encoderName ${srcW}x$srcH -> ${dstW}x$dstH@${fps}fps scale=$scale",
        )

        // Border fill and range tag must match the SOURCE range: filling
        // Y=16 into a full-range clip paints bars brighter than the sky (a
        // gray veil if the result is later stacked), and an untagged output
        // gets reinterpreted downstream.
        val srcRangeLimited = srcFormat.containsKey(MediaFormat.KEY_COLOR_RANGE) &&
            srcFormat.getInteger(MediaFormat.KEY_COLOR_RANGE) == MediaFormat.COLOR_RANGE_LIMITED
        val fillY: Byte = if (srcRangeLimited) 16 else 0

        val bitrate = (dstW.toLong() * dstH * fps / 10).coerceIn(2_000_000, 35_000_000).toInt()
        val encFormat = MediaFormat.createVideoFormat(avc, dstW, dstH).apply {
            setInteger(
                MediaFormat.KEY_COLOR_FORMAT,
                MediaCodecInfo.CodecCapabilities.COLOR_FormatYUV420Flexible,
            )
            setInteger(MediaFormat.KEY_BIT_RATE, bitrate)
            setInteger(MediaFormat.KEY_FRAME_RATE, fps)
            setInteger(MediaFormat.KEY_I_FRAME_INTERVAL, 1)
            setInteger(
                MediaFormat.KEY_COLOR_RANGE,
                if (srcRangeLimited) MediaFormat.COLOR_RANGE_LIMITED else MediaFormat.COLOR_RANGE_FULL,
            )
        }

        // ByteBuffer decode with flexible YUV (getOutputImage) — see
        // SequentialFrameExtractor.decodeSequentially for why ImageReader
        // is NOT used here (crashes on vendor tiled formats on real phones).
        srcFormat.setInteger(
            MediaFormat.KEY_COLOR_FORMAT,
            MediaCodecInfo.CodecCapabilities.COLOR_FormatYUV420Flexible,
        )
        val decoder = MediaCodec.createDecoderByType(srcMime)
        val encoder = MediaCodec.createByCodecName(encoderName)
        val muxer = MediaMuxer(outPath, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)
        if (rotation != 0) muxer.setOrientationHint(rotation)

        var muxTrack = -1
        var muxerStarted = false
        var framesEncoded = 0
        var lastPtsUs = 0L
        // EMA-smoothed Moon centroid, so 1px measurement flicker doesn't
        // wobble the output.
        var emaCx = srcW / 2.0
        var emaCy = srcH / 2.0
        var haveEma = false

        val outInfo = MediaCodec.BufferInfo()

        fun drainEncoder(untilEos: Boolean) {
            var idleTries = 0
            while (true) {
                val ix = encoder.dequeueOutputBuffer(outInfo, if (untilEos) 10_000L else 0L)
                when {
                    ix == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED -> {
                        muxTrack = muxer.addTrack(encoder.outputFormat)
                        muxer.start()
                        muxerStarted = true
                    }
                    ix >= 0 -> {
                        idleTries = 0
                        val buf = encoder.getOutputBuffer(ix)!!
                        if (outInfo.flags and MediaCodec.BUFFER_FLAG_CODEC_CONFIG == 0 &&
                            outInfo.size > 0 && muxerStarted
                        ) {
                            muxer.writeSampleData(muxTrack, buf, outInfo)
                        }
                        val eos = outInfo.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0
                        encoder.releaseOutputBuffer(ix, false)
                        if (eos) return
                    }
                    else -> {
                        if (!untilEos) return  // TRY_AGAIN while streaming: done for now
                        if (++idleTries > 800) {
                            throw IllegalStateException("encoder stalled draining EOS")
                        }
                    }
                }
                if (cancelRequested) throw InterruptedException("stabilization cancelled")
            }
        }

        // Reusable capture of one decoded frame. The decoder Image MUST be
        // copied out and closed BEFORE waiting on the encoder: Codec2
        // decoder-output and encoder-input buffers come from a shared media
        // bufferpool, so holding a decoded frame while blocking on an encoder
        // buffer deadlocks both sides once the pool runs dry (reproduced at
        // ~frame 16-25 with 4K input on device and emulator alike).
        var capW = 0
        var capH = 0
        var capY = ByteArray(0)
        var capU = ByteArray(0)
        var capV = ByteArray(0)
        var capPtsUs = 0L

        fun extractPlane(p: Image.Plane, w: Int, h: Int, out: ByteArray) {
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

        fun captureFrame(src: Image, ptsUs: Long) {
            // Coded image can differ from container WxH (e.g. 1088-aligned);
            // use the real plane dimensions for all source-side math.
            capW = src.width
            capH = src.height
            if (capY.size != capW * capH) {
                capY = ByteArray(capW * capH)
                capU = ByteArray(capW / 2 * (capH / 2))
                capV = ByteArray(capW / 2 * (capH / 2))
            }
            val c = moonCentroid(src)
            if (c != null) {
                if (haveEma) {
                    emaCx = 0.4 * c.first + 0.6 * emaCx
                    emaCy = 0.4 * c.second + 0.6 * emaCy
                } else {
                    emaCx = c.first
                    emaCy = c.second
                    haveEma = true
                }
            }
            extractPlane(src.planes[0], capW, capH, capY)
            extractPlane(src.planes[1], capW / 2, capH / 2, capU)
            extractPlane(src.planes[2], capW / 2, capH / 2, capV)
            // pts comes from dequeueOutputBuffer's BufferInfo — Image.timestamp
            // is not reliable in ByteBuffer mode, and encoders silently DROP
            // frames with non-increasing pts (input queue then fills → stall).
            capPtsUs = ptsUs
        }

        fun encodeCaptured() {
            // Shift (in DEST pixels) that puts the centroid at frame center.
            val dx = ((dstW / 2.0 - emaCx / scale).roundToInt()).coerceIn(-dstW / 3, dstW / 3)
            val dy = ((dstH / 2.0 - emaCy / scale).roundToInt()).coerceIn(-dstH / 3, dstH / 3)

            var inIx: Int
            var stallTries = 0
            while (true) {
                inIx = encoder.dequeueInputBuffer(10_000L)
                if (inIx >= 0) break
                drainEncoder(untilEos = false)
                if (cancelRequested) throw InterruptedException("stabilization cancelled")
                // A healthy encoder frees an input buffer within a few ms.
                // If none shows up for ~8s the codec has stalled — fail with
                // a real error instead of hanging the progress bar forever.
                if (++stallTries > 800) {
                    throw IllegalStateException(
                        "encoder stalled (no input buffer for 8s) at frame $framesEncoded",
                    )
                }
            }
            val dst = encoder.getInputImage(inIx)!!
            // Y at full plane res; U/V at half res with half the shift.
            copyPlaneShifted(capY, capW, capH, dst.planes[0], dstW, dstH, dx, dy, scale, fillY)
            copyPlaneShifted(
                capU, capW / 2, capH / 2, dst.planes[1], dstW / 2, dstH / 2,
                dx / 2, dy / 2, scale, 128.toByte(),
            )
            copyPlaneShifted(
                capV, capW / 2, capH / 2, dst.planes[2], dstW / 2, dstH / 2,
                dx / 2, dy / 2, scale, 128.toByte(),
            )
            lastPtsUs = capPtsUs
            encoder.queueInputBuffer(inIx, 0, dstW * dstH * 3 / 2, lastPtsUs, 0)
            if (framesEncoded < 3 || framesEncoded % 10 == 0) {
                android.util.Log.i(
                    "LunarStab",
                    "frame=$framesEncoded pts=${lastPtsUs}us dx=$dx dy=$dy muxer=$muxerStarted",
                )
            }
            drainEncoder(untilEos = false)
        }

        try {
            decoder.configure(srcFormat, null, null, 0)
            decoder.start()
            encoder.configure(encFormat, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)
            encoder.start()

            val decInfo = MediaCodec.BufferInfo()
            var inputDone = false
            var outputDone = false
            var decoderIdle = 0
            val timeoutUs = 10_000L
            while (!outputDone) {
                if (cancelRequested) throw InterruptedException("stabilization cancelled")
                if (!inputDone) {
                    val ix = decoder.dequeueInputBuffer(timeoutUs)
                    if (ix >= 0) {
                        val buf = decoder.getInputBuffer(ix)!!
                        val size = extractor.readSampleData(buf, 0)
                        if (size < 0) {
                            decoder.queueInputBuffer(ix, 0, 0, 0, MediaCodec.BUFFER_FLAG_END_OF_STREAM)
                            inputDone = true
                        } else {
                            decoder.queueInputBuffer(ix, 0, size, extractor.sampleTime, 0)
                            extractor.advance()
                        }
                    }
                }
                when (val outIx = decoder.dequeueOutputBuffer(decInfo, timeoutUs)) {
                    MediaCodec.INFO_TRY_AGAIN_LATER, MediaCodec.INFO_OUTPUT_FORMAT_CHANGED -> {
                        // The decoder loop has no other stall guard — if no
                        // frame shows up for ~10s something upstream wedged.
                        if (++decoderIdle > 1000) {
                            throw IllegalStateException(
                                "decoder stalled at frame $framesEncoded",
                            )
                        }
                    }
                    else -> if (outIx >= 0) {
                        decoderIdle = 0
                        val eos = decInfo.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0
                        val img = if (decInfo.size > 0) decoder.getOutputImage(outIx) else null
                        if (img != null) {
                            // Copy out + release BEFORE touching the encoder —
                            // holding this buffer while waiting on encoder
                            // input deadlocks the shared Codec2 bufferpool.
                            // Image.close() alone does NOT return the buffer
                            // to the codec: without releaseOutputBuffer every
                            // frame leaks one slot and the decoder goes mute
                            // after ~15-25 frames (slot count is per-device).
                            try {
                                captureFrame(img, decInfo.presentationTimeUs)
                            } finally {
                                img.close()
                                decoder.releaseOutputBuffer(outIx, false)
                            }
                            encodeCaptured()
                            framesEncoded++
                            onProgress(framesEncoded, max(estimate, framesEncoded))
                        } else {
                            decoder.releaseOutputBuffer(outIx, false)
                        }
                        if (eos) outputDone = true
                    }
                }
            }

            // Flush the encoder.
            var eosIx: Int
            var eosTries = 0
            while (true) {
                eosIx = encoder.dequeueInputBuffer(10_000L)
                if (eosIx >= 0) break
                drainEncoder(untilEos = false)
                if (++eosTries > 800) {
                    throw IllegalStateException("encoder stalled before EOS")
                }
            }
            encoder.queueInputBuffer(eosIx, 0, 0, lastPtsUs + 1, MediaCodec.BUFFER_FLAG_END_OF_STREAM)
            drainEncoder(untilEos = true)

            return Result(dstW, dstH, framesEncoded, info.durationMs)
        } catch (e: Exception) {
            File(outPath).delete()  // never leave a truncated MP4 behind
            throw e
        } finally {
            try { decoder.stop() } catch (_: Exception) {}
            decoder.release()
            try { encoder.stop() } catch (_: Exception) {}
            encoder.release()
            try { if (muxerStarted) muxer.stop() } catch (_: Exception) {}
            try { muxer.release() } catch (_: Exception) {}
            extractor.release()
        }
    }

    /** Centroid of bright (Moon) pixels on the Y plane; null if no Moon found. */
    private fun moonCentroid(img: Image): Pair<Double, Double>? {
        val p = img.planes[0]
        val buf = p.buffer
        val rowStride = p.rowStride
        val pixStride = p.pixelStride
        val w = img.width
        val h = img.height
        val step = max(1, max(w, h) / 240)
        val threshold = 48  // sky stays well below this, lit disc well above
        var count = 0L
        var sumX = 0L
        var sumY = 0L
        var y = 0
        while (y < h) {
            val rowBase = y * rowStride
            var x = 0
            while (x < w) {
                val v = buf.get(rowBase + x * pixStride).toInt() and 0xFF
                if (v > threshold) {
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
     * dst(x,y) = src((x-dx)*s, (y-dy)*s), out-of-range filled with [fill].
     * Source is a tightly-packed plane copy (stride == sw, pixel stride 1);
     * fast contiguous-row path when no decimation is needed.
     */
    private fun copyPlaneShifted(
        src: ByteArray, sw: Int, sh: Int,
        dst: Image.Plane, dw: Int, dh: Int,
        dx: Int, dy: Int, s: Int, fill: Byte,
    ) {
        val dBuf = dst.buffer
        val dRow = dst.rowStride
        val dPix = dst.pixelStride
        val row = ByteArray(dw)

        for (y in 0 until dh) {
            val sy = (y - dy) * s
            if (sy < 0 || sy >= sh) {
                java.util.Arrays.fill(row, fill)
            } else if (s == 1) {
                // Visible source span within this dest row.
                val startX = max(0, dx)                    // first dest x with source
                val endX = min(dw, sw + dx)                // one past last dest x
                if (startX > 0) java.util.Arrays.fill(row, 0, min(startX, dw), fill)
                if (endX < dw) java.util.Arrays.fill(row, max(endX, 0), dw, fill)
                if (endX > startX) {
                    System.arraycopy(src, sy * sw + (startX - dx), row, startX, endX - startX)
                }
            } else {
                // Decimation: box-average the s×s source block instead of
                // point-sampling — nearest-neighbor decimation aliases crater
                // detail into crawling moiré in the output video.
                for (x in 0 until dw) {
                    val sx = (x - dx) * s
                    if (sx < 0 || sx + s > sw || sy + s > sh) {
                        row[x] = fill
                    } else {
                        var sum = 0
                        for (by in 0 until s) {
                            val base = (sy + by) * sw + sx
                            for (bx in 0 until s) sum += src[base + bx].toInt() and 0xFF
                        }
                        row[x] = (sum / (s * s)).toByte()
                    }
                }
            }
            if (dPix == 1) {
                dBuf.position(y * dRow)
                dBuf.put(row, 0, dw)
            } else {
                for (x in 0 until dw) dBuf.put(y * dRow + x * dPix, row[x])
            }
        }
    }
}
