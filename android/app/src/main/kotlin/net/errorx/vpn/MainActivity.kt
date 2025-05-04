package net.errorx.vpn

import net.errorx.vpn.plugins.AppPlugin
import net.errorx.vpn.plugins.ServicePlugin
import net.errorx.vpn.plugins.TilePlugin
import net.errorx.vpn.plugins.WebSocketPlugin
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        flutterEngine.plugins.add(AppPlugin())
        flutterEngine.plugins.add(ServicePlugin)
        flutterEngine.plugins.add(TilePlugin())
        WebSocketPlugin.registerWith(flutterEngine, context)
        GlobalState.flutterEngine = flutterEngine
    }

    override fun onDestroy() {
        GlobalState.flutterEngine = null
        super.onDestroy()
    }
}