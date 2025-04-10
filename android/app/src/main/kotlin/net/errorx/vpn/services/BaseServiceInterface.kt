package net.errorx.vpn.services

import net.errorx.vpn.models.VpnOptions

interface BaseServiceInterface {

    fun start(options: VpnOptions): Int

    fun stop()

    suspend fun startForeground(title: String, content: String)
}