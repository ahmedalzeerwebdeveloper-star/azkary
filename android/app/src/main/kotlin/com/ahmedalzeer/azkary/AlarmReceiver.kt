package com.ahmedalzeer.azkary

import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.media.AudioManager
import android.net.Uri
import android.os.Build
import androidx.core.app.NotificationCompat

class AlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val prayerName = intent.getStringExtra(EXTRA_PRAYER_NAME) ?: "الصلاة"
        val prayerBody = intent.getStringExtra(EXTRA_PRAYER_BODY) ?: "حان الآن موعد الصلاة"
        val notificationId = intent.getIntExtra(EXTRA_NOTIFICATION_ID, 0)
        val playAdhan = isAdhanEnabled(context)
        val soundUri = if (playAdhan) {
            Uri.parse("android.resource://${context.packageName}/raw/adhan")
        } else {
            null
        }

        ensureChannel(context, soundUri, playAdhan)

        val builder = NotificationCompat.Builder(context, channelId(playAdhan))
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentTitle("نداء الصلاة - $prayerName")
            .setContentText(prayerBody)
            .setAutoCancel(true)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_ALARM)

        if (playAdhan && soundUri != null) {
            builder.setSound(soundUri)
        } else {
            builder.setSilent(true)
        }

        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.notify(notificationId, builder.build())

        if (playAdhan) {
            playAdhanSound(context)
        }

        WidgetUpdateScheduler.triggerUpdate(context)
    }

    private fun isAdhanEnabled(context: Context): Boolean {
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        return prefs.getBoolean("flutter.play_adhan", true)
    }

    private fun channelId(playAdhan: Boolean): String {
        return if (playAdhan) CHANNEL_ID_ADHAN else CHANNEL_ID_SILENT
    }

    private fun ensureChannel(context: Context, soundUri: Uri?, playAdhan: Boolean) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val id = channelId(playAdhan)
            val name = if (playAdhan) CHANNEL_NAME_ADHAN else CHANNEL_NAME_SILENT
            val channel = NotificationChannel(id, name, NotificationManager.IMPORTANCE_HIGH).apply {
                description = CHANNEL_DESC
                enableVibration(true)
                setShowBadge(true)
                if (playAdhan && soundUri != null) {
                    setSound(soundUri, AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build())
                } else {
                    setSound(null, null)
                }
            }
            val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun playAdhanSound(context: Context) {
        try {
            MediaPlayer().apply {
                setDataSource(context, Uri.parse("android.resource://${context.packageName}/raw/adhan"))
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                    setAudioAttributes(AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build())
                } else {
                    @Suppress("DEPRECATION")
                    setAudioStreamType(AudioManager.STREAM_ALARM)
                }
                setVolume(1.0f, 1.0f)
                setOnCompletionListener { release() }
                setOnErrorListener { _, _, _ ->
                    try { release() } catch (_: Exception) {}
                    true
                }
                prepare()
                start()
            }
        } catch (_: Exception) {
        }
    }

    companion object {
        private const val CHANNEL_ID_ADHAN = "prayer_channel_v2"
        private const val CHANNEL_ID_SILENT = "prayer_channel_silent"
        private const val CHANNEL_NAME_ADHAN = "مواقيت الصلاة - أذان"
        private const val CHANNEL_NAME_SILENT = "مواقيت الصلاة - إشعار"
        private const val CHANNEL_DESC = "تنبيهات الأذان ومواقيت الصلاة"
        private const val EXTRA_PRAYER_NAME = "prayer_name"
        private const val EXTRA_PRAYER_BODY = "prayer_body"
        private const val EXTRA_NOTIFICATION_ID = "notification_id"

        fun schedule(
            context: Context,
            id: Int,
            prayerName: String,
            prayerBody: String,
            triggerAtMillis: Long
        ) {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val intent = Intent(context, AlarmReceiver::class.java).apply {
                putExtra(EXTRA_PRAYER_NAME, prayerName)
                putExtra(EXTRA_PRAYER_BODY, prayerBody)
                putExtra(EXTRA_NOTIFICATION_ID, id)
            }
            val pendingIntent = PendingIntent.getBroadcast(
                context, id, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    if (alarmManager.canScheduleExactAlarms()) {
                        alarmManager.setExactAndAllowWhileIdle(
                            AlarmManager.RTC_WAKEUP, triggerAtMillis, pendingIntent
                        )
                    } else {
                        alarmManager.set(AlarmManager.RTC_WAKEUP, triggerAtMillis, pendingIntent)
                    }
                } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    alarmManager.setExactAndAllowWhileIdle(
                        AlarmManager.RTC_WAKEUP, triggerAtMillis, pendingIntent
                    )
                } else {
                    alarmManager.setExact(AlarmManager.RTC_WAKEUP, triggerAtMillis, pendingIntent)
                }
            } catch (_: SecurityException) {
                alarmManager.set(AlarmManager.RTC_WAKEUP, triggerAtMillis, pendingIntent)
            }
        }

        fun cancel(context: Context, id: Int) {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val intent = Intent(context, AlarmReceiver::class.java)
            val pendingIntent = PendingIntent.getBroadcast(
                context, id, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            alarmManager.cancel(pendingIntent)
            pendingIntent.cancel()
        }
    }
}
