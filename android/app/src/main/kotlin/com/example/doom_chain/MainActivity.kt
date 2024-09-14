package com.example.doom_chain

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.util.Log
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import android.app.NotificationChannel
import android.app.NotificationManager

class MainActivity: FlutterActivity() {
    companion object {
        const val CHANNEL = "com.example.doom_chain/channel"
        private var flutterEngineInstance : FlutterEngine? = null
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        flutterEngineInstance = flutterEngine

        val serviceIntent = Intent(this, ServiceIntent::class.java)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->

            // val args = call.arguments as? Map<String, Any>

            // args?.let{
            //     serviceIntent.putExtra("userId", it["userId"] as? String ?: "root")
            // }

            when(call.method){
                "startNotif" -> {
                    startForegroundService(serviceIntent)
                    result.success(null)
                }

                "stopNotif" -> {
                    ServiceIntent.stopNotif()
                    result.success(null);
                }

                "pushNotif" -> {

                    ServiceIntent.pushNotif(this, " ")

                    // val methodArgs = call.arguments as? Map<String, Any>

                    // methodArgs?.let{
                    //     ServiceIntent.pushNotif(this, " ")
                    // }
                }

                else -> {
                    result.notImplemented();
                }
            }
        }
    }
}
