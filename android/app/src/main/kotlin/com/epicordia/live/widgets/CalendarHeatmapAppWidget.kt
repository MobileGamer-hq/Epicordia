package com.epicordia.live.widgets

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import com.epicordia.live.R
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONObject

class CalendarHeatmapAppWidget : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val rawJson = widgetData.getString("heatmap_data", null)
            var focusRate = 82
            var windowLabel = "July 2026"
            if (rawJson != null) {
                try {
                    val json = JSONObject(rawJson)
                    focusRate = json.optInt("focus_rate", 82)
                    windowLabel = json.optString("window", "July 2026")
                } catch (e: Exception) {
                    e.printStackTrace()
                }
            }

            val views = RemoteViews(context.packageName, R.layout.widget_calendar_heatmap).apply {
                setTextViewText(R.id.widget_title, "$focusRate% Focus Rate")
                setTextViewText(R.id.widget_subtitle, "Visual Workflow • $windowLabel")

                val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    com.epicordia.live.MainActivity::class.java,
                    android.net.Uri.parse("epicordia://calendar")
                )
                setOnClickPendingIntent(R.id.widget_heatmap_container, pendingIntent)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
