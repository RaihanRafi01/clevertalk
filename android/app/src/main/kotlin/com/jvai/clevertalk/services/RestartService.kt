package com.jvai.clevertalk.services

import android.app.Service
import android.content.Intent
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import android.app.NotificationManager
import android.app.NotificationChannel
import android.os.Build
import android.os.Handler
import android.os.Looper

class RestartService : Service() {
    private val TAG = "RestartService"
    private val NOTIFICATION_CHANNEL_ID = "clevertalk_restart_channel"
    private val NOTIFICATION_ID = 1

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "RestartService onCreate called")
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "RestartService started")

        // Create a notification for the foreground service
        createNotificationChannel()
        val notification = NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
            .setContentTitle("CleverTalk Restart")
            .setContentText("Restarting the app...")
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()

        // Start the service in the foreground
        startForeground(NOTIFICATION_ID, notification)

        // Stop the service after a delay to dismiss notification
        Handler(Looper.getMainLooper()).postDelayed({
            Log.d(TAG, "Stopping RestartService")
            stopSelf()
        }, 1000)

        return START_NOT_STICKY
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                NOTIFICATION_CHANNEL_ID,
                "CleverTalk Restart Service",
                NotificationManager.IMPORTANCE_LOW
            )
            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "RestartService destroyed")
    }

    override fun onBind(intent: Intent?): IBinder? = null
}