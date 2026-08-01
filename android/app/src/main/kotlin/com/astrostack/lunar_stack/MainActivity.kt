package com.astrostack.lunar_stack

import android.content.ContentValues
import android.os.Build
import android.os.Environment
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val methodChannelName = "com.astrostack.lunar_stack/frame_extractor"
    private val progressChannelName = "com.astrostack.lunar_stack/frame_extractor_progress"
    private val mainHandler = Handler(Looper.getMainLooper())

    companion object {
        @Volatile
        private var progressSink: EventChannel.EventSink? = null
        @Volatile
        private var methodChannel: MethodChannel? = null
        private val uiHandler = Handler(Looper.getMainLooper())

        fun setProgressSink(sink: EventChannel.EventSink?) {
            progressSink = sink
        }

        fun setMethodChannel(channel: MethodChannel?) {
            methodChannel = channel
        }

        /** Kotlin -> Dart push on the progress EventChannel (same process). */
        fun emit(phase: String, current: Int, total: Int) {
            uiHandler.post {
                progressSink?.success(mapOf("phase" to phase, "current" to current, "total" to total))
            }
        }

        /** The notification's "Cancelar" action reaches here via ProcessingService.
         *  Only Dart can cancel the FFI stacking, so we call back into Dart on the
         *  (bidirectional) method channel; Dart runs the real cancel. */
        fun postCancelRequested() {
            uiHandler.post { methodChannel?.invokeMethod("onCancelRequested", null) }
        }
    }

    private fun postProgress(phase: String, current: Int, total: Int) = emit(phase, current, total)

    private fun ensureNotificationPermission() {
        if (Build.VERSION.SDK_INT >= 33 &&
            checkSelfPermission(android.Manifest.permission.POST_NOTIFICATIONS) !=
            android.content.pm.PackageManager.PERMISSION_GRANTED
        ) {
            requestPermissions(arrayOf(android.Manifest.permission.POST_NOTIFICATIONS), 1001)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, progressChannelName)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    setProgressSink(events)
                }

                override fun onCancel(arguments: Any?) {
                    setProgressSink(null)
                }
            })

        val methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, methodChannelName)
        setMethodChannel(methodChannel)
        methodChannel
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    // Pass 1: sequential decode of the whole clip, returning the
                    // real frame count + a sharpness score per frame.
                    "analyzeVideo" -> {
                        val videoPath = call.argument<String>("videoPath")
                        if (videoPath == null) {
                            result.error("INVALID_ARGS", "videoPath is required", null)
                            return@setMethodCallHandler
                        }
                        Thread {
                            try {
                                val (info, scores) = SequentialFrameExtractor.analyzeAll(videoPath) { c, t ->
                                    postProgress("analyze", c, t)
                                }
                                mainHandler.post {
                                    result.success(
                                        mapOf(
                                            "durationMs" to info.durationMs,
                                            "width" to info.width,
                                            "height" to info.height,
                                            "frameCount" to info.frameCount,
                                            "fps" to info.fps,
                                            "scores" to scores.toList(),
                                        ),
                                    )
                                }
                            } catch (e: Exception) {
                                mainHandler.post { result.error("ANALYZE_FAILED", e.message, null) }
                            }
                        }.start()
                    }

                    // Pass 2: sequential decode again, saving only the selected
                    // frame indices as lossless PNG.
                    "extractSelected" -> {
                        val videoPath = call.argument<String>("videoPath")
                        val outputDir = call.argument<String>("outputDir")
                        val indices = call.argument<List<Int>>("indices")
                        if (videoPath == null || outputDir == null || indices == null) {
                            result.error("INVALID_ARGS", "videoPath, outputDir, indices required", null)
                            return@setMethodCallHandler
                        }
                        val centerMoon = call.argument<Boolean>("centerMoon") ?: false
                        Thread {
                            try {
                                val paths = SequentialFrameExtractor.extractSelected(
                                    videoPath, outputDir, indices.toIntArray(), centerMoon,
                                ) { c, t -> postProgress("extract", c, t) }
                                mainHandler.post { result.success(paths) }
                            } catch (e: Exception) {
                                android.util.Log.e("LunarStab", "extractSelected failed", e)
                                mainHandler.post { result.error("EXTRACTION_FAILED", e.message, null) }
                            }
                        }.start()
                    }

                    // Fast metadata probe (no decode). Lets the import flow
                    // accept a clip whose ExoPlayer preview failed to init.
                    "probeVideo" -> {
                        val videoPath = call.argument<String>("videoPath")
                        if (videoPath == null) {
                            result.error("INVALID_ARGS", "videoPath is required", null)
                            return@setMethodCallHandler
                        }
                        Thread {
                            val info = FrameExtractor.probe(videoPath)
                            mainHandler.post {
                                if (info == null) {
                                    result.error("PROBE_FAILED", "not a readable video", null)
                                } else {
                                    result.success(info)
                                }
                            }
                        }.start()
                    }

                    "cancelExtraction" -> {
                        SequentialFrameExtractor.cancelRequested = true
                        VideoStabilizer.cancelRequested = true
                        result.success(null)
                    }

                    // Empilhamento em segundo plano: inicia/atualiza/encerra o
                    // foreground service que segura o processo e mostra o
                    // progresso na barra de notificacoes (ver ProcessingService).
                    "startProcessing" -> {
                        ensureNotificationPermission()
                        ProcessingService.start(this, call.argument<String>("title") ?: "LunarStack")
                        result.success(null)
                    }

                    "updateProcessing" -> {
                        ProcessingService.instance?.update(
                            call.argument<Int>("progress") ?: 0,
                            call.argument<String>("stage") ?: "",
                        )
                        result.success(null)
                    }

                    "stopProcessing" -> {
                        ProcessingService.stop(this, call.argument<String>("status") ?: "done")
                        result.success(null)
                    }

                    // "Apenas estabilizar": center-lock the Moon and re-encode
                    // the clip as H.264/MP4.
                    "stabilizeVideo" -> {
                        val videoPath = call.argument<String>("videoPath")
                        val outPath = call.argument<String>("outPath")
                        if (videoPath == null || outPath == null) {
                            result.error("INVALID_ARGS", "videoPath and outPath required", null)
                            return@setMethodCallHandler
                        }
                        Thread {
                            try {
                                val r = VideoStabilizer.stabilize(videoPath, outPath) { c, t ->
                                    postProgress("stabilize", c, t)
                                }
                                mainHandler.post {
                                    result.success(
                                        mapOf(
                                            "path" to outPath,
                                            "width" to r.width,
                                            "height" to r.height,
                                            "frames" to r.frames,
                                            "durationMs" to r.durationMs,
                                        ),
                                    )
                                }
                            } catch (e: InterruptedException) {
                                mainHandler.post { result.error("CANCELLED", e.message, null) }
                            } catch (e: Exception) {
                                android.util.Log.e("LunarStab", "stabilize failed", e)
                                mainHandler.post { result.error("STABILIZE_FAILED", e.message, null) }
                            }
                        }.start()
                    }

                    // Copies a produced file (e.g. the 16-bit TIFF the gallery
                    // can't host) into the public Downloads/LunarStack folder
                    // via MediaStore — no storage permission needed on API 29+.
                    "saveToDownloads" -> {
                        val path = call.argument<String>("path")
                        val mime = call.argument<String>("mime") ?: "application/octet-stream"
                        if (path == null) {
                            result.error("INVALID_ARGS", "path is required", null)
                            return@setMethodCallHandler
                        }
                        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
                            result.error("UNSUPPORTED", "Requer Android 10 ou superior.", null)
                            return@setMethodCallHandler
                        }
                        Thread {
                            try {
                                val src = File(path)
                                val values = ContentValues().apply {
                                    put(MediaStore.MediaColumns.DISPLAY_NAME, src.name)
                                    put(MediaStore.MediaColumns.MIME_TYPE, mime)
                                    put(
                                        MediaStore.MediaColumns.RELATIVE_PATH,
                                        Environment.DIRECTORY_DOWNLOADS + "/LunarStack",
                                    )
                                }
                                val uri = contentResolver.insert(
                                    MediaStore.Downloads.EXTERNAL_CONTENT_URI, values,
                                ) ?: throw IllegalStateException("MediaStore insert failed")
                                contentResolver.openOutputStream(uri).use { out ->
                                    src.inputStream().use { it.copyTo(out!!) }
                                }
                                mainHandler.post { result.success("Downloads/LunarStack/${src.name}") }
                            } catch (e: Exception) {
                                mainHandler.post { result.error("SAVE_FAILED", e.message, null) }
                            }
                        }.start()
                    }

                    // Legacy fallback: MediaMetadataRetriever-based sampling.
                    // Kept for devices where the MediaCodec path fails.
                    "extractFrames" -> {
                        val videoPath = call.argument<String>("videoPath")
                        val outputDir = call.argument<String>("outputDir")
                        val targetFrameCount = call.argument<Int>("targetFrameCount") ?: 180

                        if (videoPath == null || outputDir == null) {
                            result.error("INVALID_ARGS", "videoPath and outputDir are required", null)
                            return@setMethodCallHandler
                        }

                        Thread {
                            try {
                                val extraction = FrameExtractor.extract(
                                    videoPath,
                                    outputDir,
                                    targetFrameCount,
                                ) { current, total -> postProgress("extract", current, total) }
                                mainHandler.post {
                                    result.success(
                                        mapOf(
                                            "durationMs" to extraction.durationMs,
                                            "width" to extraction.width,
                                            "height" to extraction.height,
                                            "nativeFrameCount" to extraction.nativeFrameCount,
                                            "fps" to extraction.fps,
                                            "framePaths" to extraction.framePaths,
                                        ),
                                    )
                                }
                            } catch (e: Exception) {
                                mainHandler.post {
                                    result.error("EXTRACTION_FAILED", e.message, null)
                                }
                            }
                        }.start()
                    }

                    else -> result.notImplemented()
                }
            }
    }
}
