package com.epicordia.live.widgets

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
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

            val views = RemoteViews(context.packageName, android.R.layout.simple_list_item_2).apply {
                setTextViewText(android.R.id.text1, "$focusRate% Focus Rate")
                setTextViewText(android.R.id.text2, "Visual Workflow • $windowLabel")
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
