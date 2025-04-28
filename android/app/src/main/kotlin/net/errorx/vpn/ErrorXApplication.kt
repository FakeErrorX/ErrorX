package net.errorx.vpn

import android.app.Application
import android.content.Context

class ErrorXApplication : Application() {
    companion object {
        private lateinit var instance: ErrorXApplication

        fun getAppContext(): Context {
            return instance
        }
    }

    override fun onCreate() {
        super.onCreate()
        instance = this
    }
} 