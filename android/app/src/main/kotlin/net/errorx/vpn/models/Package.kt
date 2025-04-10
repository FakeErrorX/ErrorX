package net.errorx.vpn.models

data class Package(
    val packageName: String,
    val label: String,
    val isSystem: Boolean,
    val lastUpdateTime: Long,
)
