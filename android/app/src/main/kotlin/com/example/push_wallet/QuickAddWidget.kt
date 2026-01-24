package com.example.push_wallet

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetProvider

class QuickAddWidget : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }
}

internal fun updateAppWidget(
    context: Context,
    appWidgetManager: AppWidgetManager,
    appWidgetId: Int
) {
    // 1. Retrieve Current Amount from SharedPrefs (synced via HomeWidget)
    val widgetData = HomeWidgetProvider.getData(context)
    val currentAmount = widgetData.getString("widget_amount", "0")

    val views = RemoteViews(context.packageName, R.layout.widget_layout)
    
    // 2. Update Display
    views.setTextViewText(R.id.amount_display, currentAmount)

    // 3. Attach Click Listeners
    
    // Numbers 0-9
    views.setOnClickPendingIntent(R.id.btn_0, HomeWidgetBackgroundIntent.getBroadcast(context, android.net.Uri.parse("quickadd://num/0")))
    views.setOnClickPendingIntent(R.id.btn_1, HomeWidgetBackgroundIntent.getBroadcast(context, android.net.Uri.parse("quickadd://num/1")))
    views.setOnClickPendingIntent(R.id.btn_2, HomeWidgetBackgroundIntent.getBroadcast(context, android.net.Uri.parse("quickadd://num/2")))
    views.setOnClickPendingIntent(R.id.btn_3, HomeWidgetBackgroundIntent.getBroadcast(context, android.net.Uri.parse("quickadd://num/3")))
    views.setOnClickPendingIntent(R.id.btn_4, HomeWidgetBackgroundIntent.getBroadcast(context, android.net.Uri.parse("quickadd://num/4")))
    views.setOnClickPendingIntent(R.id.btn_5, HomeWidgetBackgroundIntent.getBroadcast(context, android.net.Uri.parse("quickadd://num/5")))
    views.setOnClickPendingIntent(R.id.btn_6, HomeWidgetBackgroundIntent.getBroadcast(context, android.net.Uri.parse("quickadd://num/6")))
    views.setOnClickPendingIntent(R.id.btn_7, HomeWidgetBackgroundIntent.getBroadcast(context, android.net.Uri.parse("quickadd://num/7")))
    views.setOnClickPendingIntent(R.id.btn_8, HomeWidgetBackgroundIntent.getBroadcast(context, android.net.Uri.parse("quickadd://num/8")))
    views.setOnClickPendingIntent(R.id.btn_9, HomeWidgetBackgroundIntent.getBroadcast(context, android.net.Uri.parse("quickadd://num/9")))
    views.setOnClickPendingIntent(R.id.btn_dot, HomeWidgetBackgroundIntent.getBroadcast(context, android.net.Uri.parse("quickadd://num/.")))

    // Actions
    views.setOnClickPendingIntent(R.id.btn_clear, HomeWidgetBackgroundIntent.getBroadcast(context, android.net.Uri.parse("quickadd://clear")))
    views.setOnClickPendingIntent(R.id.btn_save, HomeWidgetBackgroundIntent.getBroadcast(context, android.net.Uri.parse("quickadd://save")))

    appWidgetManager.updateAppWidget(appWidgetId, views)
}
