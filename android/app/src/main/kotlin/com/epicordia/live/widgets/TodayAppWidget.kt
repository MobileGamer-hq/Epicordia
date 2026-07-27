package com.epicordia.live.widgets

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import com.epicordia.live.R
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONObject

class TodayAppWidget : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val rawJson = widgetData.getString("today_data", null)
            var dueCount = 0
            var topTaskTitle = "No tasks due"

            if (rawJson != null) {
                try {
                    val json = JSONObject(rawJson)
                    dueCount = json.optInt("due_count", 0)
                    val tasks = json.optJSONArray("tasks")
                    if (tasks != null && tasks.length() > 0) {
                        val firstTask = tasks.getJSONObject(0)
                        topTaskTitle = firstTask.optString("title", "No tasks due")
                    }
                } catch (e: Exception) {
                    e.printStackTrace()
                }
            }

            // Simple RemoteViews representation or custom Glance view
            // Here we render layout for standard HomeWidgetReceiver
            val views = RemoteViews(context.packageName, android.R.layout.simple_list_item_2).apply {
                setTextViewText(android.R.id.text1, "$dueCount due today")
                setTextViewText(android.R.id.text2, "◯ $topTaskTitle")
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
