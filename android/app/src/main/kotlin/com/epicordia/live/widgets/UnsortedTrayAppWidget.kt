package com.epicordia.live.widgets

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import com.epicordia.live.R
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONObject

class UnsortedTrayAppWidget : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val rawJson = widgetData.getString("unsorted_data", null)
            var count = 0
            if (rawJson != null) {
                try {
                    val json = JSONObject(rawJson)
                    count = json.optInt("count", 0)
                } catch (e: Exception) {
                    e.printStackTrace()
                }
            }

            val views = RemoteViews(context.packageName, R.layout.widget_unsorted_tray).apply {
                setTextViewText(R.id.widget_title, "$count unsorted")
                setTextViewText(R.id.widget_subtitle, "Unsorted Tray")

                val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    com.epicordia.live.MainActivity::class.java,
                    android.net.Uri.parse("epicordia://unsorted")
                )
                setOnClickPendingIntent(R.id.widget_unsorted_container, pendingIntent)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
