package com.epicordia.live.widgets

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import com.epicordia.live.R
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class QuickCaptureAppWidget : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_quick_capture).apply {
                val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    com.epicordia.live.MainActivity::class.java,
                    android.net.Uri.parse("epicordia://capture")
                )
                setOnClickPendingIntent(R.id.widget_quick_capture_container, pendingIntent)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
