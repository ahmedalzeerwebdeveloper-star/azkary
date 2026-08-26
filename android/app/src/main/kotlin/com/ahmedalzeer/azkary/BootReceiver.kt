package com.ahmedalzeer.azkary

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import es.antonborri.home_widget.HomeWidgetPlugin

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_BOOT_COMPLETED &&
            intent.action != Intent.ACTION_MY_PACKAGE_REPLACED
        ) return

        val widgetData = HomeWidgetPlugin.getData(context)
        WidgetUpdateScheduler.scheduleAll(context, widgetData)
        WidgetUpdateScheduler.triggerUpdate(context)
    }
}
