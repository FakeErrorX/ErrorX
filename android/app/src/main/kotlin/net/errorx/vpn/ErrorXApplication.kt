package net.errorx.vpn

import android.app.Application
import android.content.Context
import androidx.work.Configuration
import androidx.work.WorkManager

class ErrorXApplication : Application(), Configuration.Provider {
    companion object {
        private lateinit var instance: ErrorXApplication

        fun getAppContext(): Context {
            return instance
        }
    }

    override fun onCreate() {
        super.onCreate()
        instance = this
        // Initialize WorkManager
        WorkManager.initialize(this, workManagerConfiguration)
    }
    
    override val workManagerConfiguration: Configuration
        get() = Configuration.Builder()
            .setMinimumLoggingLevel(android.util.Log.INFO)
            .build()
} 