package net.errorx.vpn.services

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.net.VpnService
import android.os.Binder
import android.os.Build
import android.os.IBinder
import android.os.ParcelFileDescriptor
import androidx.core.app.NotificationCompat
import net.errorx.vpn.MainActivity
import net.errorx.vpn.models.VpnOptions

class ErrorXVpnService : VpnService(), BaseServiceInterface {
    private val binder = LocalBinder()

    inner class LocalBinder : Binder() {
        fun getService(): ErrorXVpnService = this@ErrorXVpnService
    }

    override fun onBind(intent: Intent?): IBinder {
        return binder
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        return START_NOT_STICKY
    }

    private var vpnInterface: ParcelFileDescriptor? = null

    private var options: VpnOptions? = null

    fun start(options: VpnOptions): Int {
        this.options = options
        val builder = Builder()
            .setMtu(options.mtu)
            .setSession("ErrorX")
            .setBlocking(false)

        if (options.ipv6) {
            builder.addAddress("fdfe:dcba:9876::1", 126)
            builder.addRoute("::", 0)
            builder.addDnsServer("fdfe:dcba:9876::2")
        }

        builder.addAddress("172.19.0.1", 30)
        builder.addDnsServer("172.19.0.2")
        builder.addRoute("0.0.0.0", 0)

        if (options.bypassPrivateNetwork) {
            for (prefix in arrayOf("10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16")) {
                val parts = prefix.split("/")
                builder.addDisallowedRoute(parts[0], parts[1].toInt())
            }
        }

        for (packageName in options.packageNames) {
            try {
                builder.addAllowedApplication(packageName)
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }

        try {
            vpnInterface = builder.establish()
            startForeground()
            return vpnInterface?.detachFd() ?: -1
        } catch (e: Exception) {
            e.printStackTrace()
            return -1
        }
    }

    private val CHANNEL = "ErrorX"

    private val notificationId: Int = 1

    private fun startForeground() {
        try {
            val intent = Intent(this@ErrorXVpnService, MainActivity::class.java)

            val pendingIntent = if (Build.VERSION.SDK_INT >= 31) {
                PendingIntent.getActivity(
                    this@ErrorXVpnService,
                    0,
                    intent,
                    PendingIntent.FLAG_IMMUTABLE
                )
            } else {
                PendingIntent.getActivity(
                    this@ErrorXVpnService,
                    0,
                    intent,
                    PendingIntent.FLAG_UPDATE_CURRENT
                )
            }

            with(NotificationCompat.Builder(this@ErrorXVpnService, CHANNEL)) {
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
        vpnInterface?.close()
        vpnInterface = null
    }
} 