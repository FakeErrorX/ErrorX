package net.errorx.vpn.services

import android.content.Context
import android.util.Log
import androidx.work.Worker
import androidx.work.WorkerParameters
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.atomic.AtomicReference

/**
 * WorkManager worker that keeps the WebSocket connection alive by triggering
 * a ping operation through Flutter's MethodChannel every 20 seconds
 */
class WebSocketWorker(
    context: Context,
    workerParams: WorkerParameters
) : Worker(context, workerParams) {

    companion object {
        private const val TAG = "WebSocketWorker"
        // Reference to Flutter's MethodChannel
        private val methodChannel = AtomicReference<MethodChannel?>(null)

        // Set the MethodChannel instance
        fun setMethodChannel(channel: MethodChannel?) {
            methodChannel.set(channel)
        }
    }

    override fun doWork(): Result {
        try {
            Log.d(TAG, "WebSocketWorker running - sending ping")
            val channel = methodChannel.get()
            
            if (channel != null) {
                // Call the Flutter method to keep WebSocket alive
                channel.invokeMethod("keepWebSocketAlive", null)
                Log.d(TAG, "Successfully invoked keepWebSocketAlive method")
            } else {
                Log.e(TAG, "MethodChannel is null - cannot send ping")
            }
            
            // Always return success, even if channel is null
            // This allows the worker to continue running
            return Result.success()
        } catch (e: Exception) {
            Log.e(TAG, "Error in WebSocketWorker", e)
            // Return retry to attempt again later
            return Result.retry()
        }
    }
} 