package com.ahmedalzeer.azkary

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import es.antonborri.home_widget.HomeWidgetPlugin

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_BOOT_COMPLETED &&
            intent.action != Intent.ACTION_MY_PACKAGE_REPLACED
        ) return

        Log.d("BootReceiver", "Boot/update received – recalculating prayer times")

        // Recalculate prayer times natively (in case data is stale)
        try {
            PrayerCalculator.recalculateAndSave(context)
        } catch (e: Exception) {
            Log.e("BootReceiver", "Error recalculating prayer times", e)
        }

        val widgetData = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        WidgetUpdateScheduler.scheduleAll(context, widgetData)
        WidgetUpdateScheduler.triggerUpdate(context)

        // Schedule the daily midnight alarm
        MidnightReceiver.scheduleMidnightAlarm(context)
    }
}
