package net.errorx.vpn.services

import android.content.Context
import android.util.Log
import androidx.work.*
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.TimeUnit

/**
 * Service to manage background WebSocket connection using WorkManager
 */
class WebSocketService(private val context: Context) {
    companion object {
        private const val TAG = "WebSocketService"
        private const val WEBSOCKET_WORKER_NAME = "websocket_ping_worker"
    }

    /**
     * Start the WebSocket ping worker to keep the connection alive
     * @param methodChannel The Flutter MethodChannel to communicate with
     */
    fun startWebSocketKeepAliveWorker(methodChannel: MethodChannel) {
        try {
            Log.d(TAG, "Starting WebSocket keep-alive worker")
            
            // Set the method channel reference in the worker
            WebSocketWorker.setMethodChannel(methodChannel)
            
            // Configure worker constraints - require network connectivity
            val constraints = Constraints.Builder()
                .setRequiredNetworkType(NetworkType.CONNECTED)
                .build()
            
            // Create a periodic work request that runs every 20 seconds
            // (minimum interval is 15 minutes for standard periodic work,
            // but we use a workaround with exponential backoff)
            val pingWorkRequest = OneTimeWorkRequestBuilder<WebSocketWorker>()
                .setConstraints(constraints)
                .setBackoffCriteria(
                    BackoffPolicy.LINEAR,
                    20, // Retry after 20 seconds
                    TimeUnit.SECONDS
                )
                .addTag("websocket_ping")
                .build()
            
            // Enqueue the work request
            WorkManager.getInstance(context)
                .enqueueUniqueWork(
                    WEBSOCKET_WORKER_NAME,
                    ExistingWorkPolicy.REPLACE,
                    pingWorkRequest
                )
            
            Log.d(TAG, "WebSocket keep-alive worker started successfully")
        } catch (e: Exception) {
            Log.e(TAG, "Error starting WebSocket keep-alive worker", e)
        }
    }
    
    /**
     * Schedule the next ping worker to run in 20 seconds
     */
    fun scheduleNextPing() {
        try {
            // Create a one-time work request that runs after 20 seconds
            val pingWorkRequest = OneTimeWorkRequestBuilder<WebSocketWorker>()
                .setInitialDelay(20, TimeUnit.SECONDS)
                .addTag("websocket_ping")
                .build()
            
            // Enqueue the work request
            WorkManager.getInstance(context)
                .enqueueUniqueWork(
                    WEBSOCKET_WORKER_NAME,
                    ExistingWorkPolicy.REPLACE,
                    pingWorkRequest
                )
        } catch (e: Exception) {
            Log.e(TAG, "Error scheduling next ping", e)
        }
    }
    
    /**
     * Stop the WebSocket keep-alive worker
     */
    fun stopWebSocketKeepAliveWorker() {
        try {
            Log.d(TAG, "Stopping WebSocket keep-alive worker")
            
            // Cancel all websocket_ping workers
            WorkManager.getInstance(context)
                .cancelUniqueWork(WEBSOCKET_WORKER_NAME)
            
            // Clear the method channel reference
            WebSocketWorker.setMethodChannel(null)
            
            Log.d(TAG, "WebSocket keep-alive worker stopped successfully")
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping WebSocket keep-alive worker", e)
        }
    }
} 