package net.errorx.vpn.services

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.os.Binder
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import net.errorx.vpn.MainActivity

class ErrorXService : Service(), BaseServiceInterface {
    private val binder = LocalBinder()

    inner class LocalBinder : Binder() {
        fun getService(): ErrorXService = this@ErrorXService
    }

    override fun onBind(intent: Intent?): IBinder {
        return binder
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        return START_NOT_STICKY
    }

    private val CHANNEL = "ErrorX"

    private val notificationId: Int = 1

    override fun onCreate() {
        super.onCreate()
        startForeground()
    }

    private fun startForeground() {
        try {
            val intent = Intent(
                this@ErrorXService, MainActivity::class.java
            )

            val pendingIntent = if (Build.VERSION.SDK_INT >= 31) {
                PendingIntent.getActivity(
                    this@ErrorXService,
                    0,
                    intent,
                    PendingIntent.FLAG_IMMUTABLE
                )
            } else {
                PendingIntent.getActivity(
                    this@ErrorXService,
                    0,
                    intent,
                    PendingIntent.FLAG_UPDATE_CURRENT
                )
            }

            with(NotificationCompat.Builder(this@ErrorXService, CHANNEL)) {
                setSmallIcon(net.errorx.vpn.R.drawable.ic_stat_name)
                setContentTitle("ErrorX")
                setContentIntent(pendingIntent)
                setCategory(NotificationCompat.CATEGORY_SERVICE)
                setOngoing(true)
                val manager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager?
                var channel = manager?.getNotificationChannel(CHANNEL)
                if (channel == null) {
                    channel =
                        NotificationChannel(CHANNEL, "ErrorX", NotificationManager.IMPORTANCE_LOW)
                    manager?.createNotificationChannel(channel)
                }
                startForeground(notificationId, build())
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        stopForeground(STOP_FOREGROUND_REMOVE)
    }
} 