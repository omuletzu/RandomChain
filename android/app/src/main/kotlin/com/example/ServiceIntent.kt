package com.example.doom_chain

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import com.google.firebase.firestore.FirebaseFirestoreException
import com.google.firebase.firestore.ListenerRegistration
import com.google.firebase.firestore.QuerySnapshot
import com.google.firebase.firestore.ktx.firestore
import com.google.firebase.ktx.Firebase

class ServiceIntent : Service() {
    private var firestore = Firebase.firestore
    private val notifId = "ForegroundServiceChannel"
    private var firstTimeListener = false

    companion object {
        var pushNotifId = 0
        var serviceIntentContext: Context? = null
        var listener : ListenerRegistration? = null

        fun stopNotif() {
            val stopIntent = Intent(serviceIntentContext, ServiceIntent::class.java).apply {
                action = "ACTION_STOP_SERVICE"
            }
    
            serviceIntentContext?.startService(stopIntent)
        }

        fun pushNotif(context: Context, chainType: String) {
            val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            val notificationChannel = NotificationChannel(
                pushNotifId.toString(),
                "Notification Channel",
                NotificationManager.IMPORTANCE_DEFAULT
            )
            notificationManager.createNotificationChannel(notificationChannel)
    
            val notification = NotificationCompat.Builder(context, pushNotifId.toString())
                .setSmallIcon(R.mipmap.ic_launcher)
                .setContentTitle("An unchained has arrived")
                .setContentText("$chainType chain")
                .setPriority(NotificationCompat.PRIORITY_DEFAULT)
                .build()
    
            notificationManager.notify(pushNotifId, notification)
            pushNotifId++
        }
    }

    override fun onCreate() {
        super.onCreate()
        serviceIntentContext = this
        createNotificationChannel(this)
    }

    fun startListener(userId: String, context: Context) {
        val docRef = firestore.collection("UserDetails")
            .document(userId)
            .collection("PendingPersonalChains")

        listener = docRef.addSnapshotListener { snapshot: QuerySnapshot?, e: FirebaseFirestoreException? ->
            if (e != null) {
                Log.e("ServiceIntent", "Error listening to Firestore changes", e)
                return@addSnapshotListener
            }

            if(firstTimeListener == true){
                if (snapshot != null && !snapshot.isEmpty) {

                    for (change in snapshot.documentChanges) {
                        if (change.type == com.google.firebase.firestore.DocumentChange.Type.ADDED) {
                            val categoryName = change.document.getString("categoryName") ?: " "
                            pushNotif(context, categoryName)
                            break
                        }
                    }
                }
            }
            else{
                firstTimeListener = true
            }
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {

        if(firestore == null){
            firestore = Firebase.firestore
        }

        if(intent?.action == null){
            intent?.getStringExtra("userId")?.let { userId ->
                startListener(userId, this)
            }
        }

        intent?.action?.let { action ->
            if (action == "ACTION_STOP_SERVICE") {
                stopForeground(true)
                stopSelf()
                return START_NOT_STICKY
            }
        }

        return START_STICKY
    }

    private fun createNotificationChannel(context: Context) {
        val channel = NotificationChannel(
            notifId,
            "Foreground Service Channel",
            NotificationManager.IMPORTANCE_DEFAULT
        )

        val notifManager = getSystemService(NotificationManager::class.java)
        notifManager.createNotificationChannel(channel)

        val notification = NotificationCompat.Builder(context, notifId)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle("DoomChain")
            .setContentText("DoomChain")
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()

        startForeground(1, notification)
    }

    override fun onDestroy() {
        listener?.remove()
        listener = null
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }
}
