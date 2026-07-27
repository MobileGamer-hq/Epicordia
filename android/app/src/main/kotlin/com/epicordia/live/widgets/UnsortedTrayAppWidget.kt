package com.epicordia.live.widgets

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
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
            val views = RemoteViews(context.packageName, android.R.layout.simple_list_item_2).apply {
                setTextViewText(android.R.id.text1, "$count unsorted")
                setTextViewText(android.R.id.text2, "Unsorted Tray")
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
