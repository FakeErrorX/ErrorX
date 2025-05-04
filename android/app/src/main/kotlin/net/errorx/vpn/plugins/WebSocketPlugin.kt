package net.errorx.vpn.plugins

import android.content.Context
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import net.errorx.vpn.services.WebSocketService

/**
 * Plugin to manage WebSocket connection in the background using WorkManager
 */
class WebSocketPlugin(private val context: Context) : MethodChannel.MethodCallHandler {
    companion object {
        private const val TAG = "WebSocketPlugin"
        private const val CHANNEL_NAME = "net.errorx.vpn/websocket"
        
        fun registerWith(flutterEngine: FlutterEngine, context: Context) {
            val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME)
            val plugin = WebSocketPlugin(context)
            channel.setMethodCallHandler(plugin)
            
            // Store channel reference for background worker
            plugin.setMethodChannel(channel)
        }
    }
    
    private val webSocketService = WebSocketService(context)
    private var methodChannel: MethodChannel? = null
    
    private fun setMethodChannel(channel: MethodChannel) {
        methodChannel = channel
    }
    
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "startKeepAliveService" -> {
                methodChannel?.let { channel ->
                    webSocketService.startWebSocketKeepAliveWorker(channel)
                    result.success(true)
                } ?: run {
                    Log.e(TAG, "Cannot start keep-alive service - method channel is null")
                    result.error("UNAVAILABLE", "Method channel not initialized", null)
                }
            }
            "stopKeepAliveService" -> {
                webSocketService.stopWebSocketKeepAliveWorker()
                result.success(true)
            }
            "scheduleNextPing" -> {
                webSocketService.scheduleNextPing()
                result.success(true)
            }
            "keepWebSocketAlive" -> {
                // This method will be called by the WebSocketWorker through the method channel
                // We need to inform Flutter to send a ping/pong to keep WebSocket alive
                Log.d(TAG, "WebSocketWorker requested to keep WebSocket alive")
                
                // Schedule the next ping after completing this one
                webSocketService.scheduleNextPing()
                
                result.success(true)
            }
            else -> {
                result.notImplemented()
            }
        }
    }
} 