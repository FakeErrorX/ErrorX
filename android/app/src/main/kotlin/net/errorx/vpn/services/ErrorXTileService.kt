package net.errorx.vpn.services

import android.content.Intent
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService
import net.errorx.vpn.GlobalState
import net.errorx.vpn.RunState
import net.errorx.vpn.TempActivity

class ErrorXTileService : TileService() {
    override fun onClick() {
        super.onClick()
        val intent = Intent(this, TempActivity::class.java)
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        intent.action = when (GlobalState.runState) {
            RunState.RUNNING -> "${packageName}.action.STOP"
            else -> "${packageName}.action.START"
        }
        startActivityAndCollapse(intent)
    }

    override fun onStartListening() {
        super.onStartListening()
        qsTile?.state = when (GlobalState.runState) {
            RunState.RUNNING -> Tile.STATE_ACTIVE
            else -> Tile.STATE_INACTIVE
        }
        qsTile?.updateTile()
    }
} 