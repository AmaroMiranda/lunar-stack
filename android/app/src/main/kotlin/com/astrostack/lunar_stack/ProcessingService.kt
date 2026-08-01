package com.astrostack.lunar_stack

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import androidx.core.app.NotificationCompat

/**
 * Foreground service that keeps the app process alive while a stack/stabilize
 * job runs, and mirrors its progress into an ongoing notification. It does NOT
 * do the work itself — the pipeline stays where it is (Kotlin extractor threads
 * + the Dart FFI isolate). This service only (1) holds the process at
 * foreground priority so Android won't kill it when backgrounded, and (2) shows
 * the progress bar + a "Cancelar" action. A partial wake lock keeps the CPU
 * running with the screen off.
 *
 * The Activity drives it directly (same process): [start] via startForegroundService,
 * then [instance] updates/finishes. The "Cancelar" action loops back to Dart —
 * only Dart can cancel the FFI stacking — via [MainActivity.postCancelRequested].
 */
class ProcessingService : Service() {

    companion object {
        const val ACTION_START = "com.astrostack.lunar_stack.PROCESSING_START"
        const val ACTION_CANCEL = "com.astrostack.lunar_stack.PROCESSING_CANCEL"
        private const val CHANNEL_ID = "processing"
        private const val ONGOING_ID = 42
        private const val DONE_ID = 43

        @Volatile
        var instance: ProcessingService? = null
            private set

        fun start(context: Context, title: String) {
            val intent = Intent(context, ProcessingService::class.java)
                .setAction(ACTION_START)
                .putExtra("title", title)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        /** Finishes any running job: shows a terminal notification when
         *  status == "done"; otherwise just clears the ongoing one. */
        fun stop(context: Context, status: String) {
            instance?.finish(status) ?: run {
                // Service not running (e.g. never started) — nothing to do.
            }
        }
    }

    private var wakeLock: PowerManager.WakeLock? = null
    private var title: String = "LunarStack"

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> {
                title = intent.getStringExtra("title") ?: "LunarStack"
                instance = this
                acquireWakeLock()
                startForegroundInternal(buildOngoing(0, "Preparando…", indeterminate = true))
            }
            ACTION_CANCEL -> {
                // The FFI stacking can only be cancelled from Dart; ask it to.
                // Dart will then call stopProcessing("cancelled") which lands in
                // finish() and tears the service down.
                MainActivity.postCancelRequested()
                update(0, "Cancelando…", indeterminate = true)
            }
        }
        return START_NOT_STICKY
    }

    /** Live progress update (0..100). Called by the Activity, same process. */
    fun update(progress: Int, stage: String, indeterminate: Boolean = false) {
        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        nm.notify(ONGOING_ID, buildOngoing(progress, stage, indeterminate))
    }

    /** Terminal state: "done" posts a tappable "concluído" notification; any
     *  other status just clears the ongoing one. Then stops the service. */
    fun finish(status: String) {
        releaseWakeLock()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
        if (status == "done") {
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            nm.notify(DONE_ID, buildDone())
        }
        instance = null
        stopSelf()
    }

    override fun onDestroy() {
        releaseWakeLock()
        instance = null
        super.onDestroy()
    }

    // -- notification building ------------------------------------------------

    private fun ensureChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (nm.getNotificationChannel(CHANNEL_ID) != null) return
        val ch = NotificationChannel(
            CHANNEL_ID,
            "Processamento",
            NotificationManager.IMPORTANCE_LOW, // silencioso, mas visível na barra
        ).apply { description = "Progresso do empilhamento/estabilização" }
        nm.createNotificationChannel(ch)
    }

    private fun contentIntent(): PendingIntent? {
        val launch = packageManager.getLaunchIntentForPackage(packageName) ?: return null
        var flags = PendingIntent.FLAG_UPDATE_CURRENT
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) flags = flags or PendingIntent.FLAG_IMMUTABLE
        return PendingIntent.getActivity(this, 0, launch, flags)
    }

    private fun cancelIntent(): PendingIntent {
        val intent = Intent(this, ProcessingService::class.java).setAction(ACTION_CANCEL)
        var flags = PendingIntent.FLAG_UPDATE_CURRENT
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) flags = flags or PendingIntent.FLAG_IMMUTABLE
        return PendingIntent.getService(this, 1, intent, flags)
    }

    private fun buildOngoing(progress: Int, stage: String, indeterminate: Boolean): Notification {
        ensureChannel()
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.stat_sys_download)
            .setContentTitle(title)
            .setContentText(stage)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setProgress(100, progress.coerceIn(0, 100), indeterminate)
            .setContentIntent(contentIntent())
            .addAction(android.R.drawable.ic_menu_close_clear_cancel, "Cancelar", cancelIntent())
            .setForegroundServiceBehavior(NotificationCompat.FOREGROUND_SERVICE_IMMEDIATE)
            .build()
    }

    private fun buildDone(): Notification {
        ensureChannel()
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.stat_sys_download_done)
            .setContentTitle("LunarStack")
            .setContentText("Concluído · toque para ver o resultado")
            .setAutoCancel(true)
            .setContentIntent(contentIntent())
            .build()
    }

    private fun startForegroundInternal(notification: Notification) {
        if (Build.VERSION.SDK_INT >= 34) {
            startForeground(ONGOING_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PROCESSING)
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(ONGOING_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC)
        } else {
            startForeground(ONGOING_ID, notification)
        }
    }

    // -- wake lock ------------------------------------------------------------

    private fun acquireWakeLock() {
        if (wakeLock != null) return
        val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = pm.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "LunarStack:processing").apply {
            setReferenceCounted(false)
            acquire(30 * 60 * 1000L) // teto de 30 min como rede de seguranca contra vazamento
        }
    }

    private fun releaseWakeLock() {
        wakeLock?.let { if (it.isHeld) it.release() }
        wakeLock = null
    }
}
