package com.epicordia.live.widgets

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.view.View
import android.widget.RemoteViews
import com.epicordia.live.R
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONObject

class TopPriorityAppWidget : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val rawJson = widgetData.getString("top_priority_data", null)
            var count = 0
            val tasksList = mutableListOf<Triple<String, String, Int>>()

            if (rawJson != null) {
                try {
                    val json = JSONObject(rawJson)
                    count = json.optInt("count", 0)
                    val array = json.optJSONArray("tasks")
                    if (array != null) {
                        for (i in 0 until array.length()) {
                            val item = array.getJSONObject(i)
                            val title = item.optString("title", "")
                            val timeStr = item.optString("time", "")
                            val priority = item.optInt("priority", 0)
                            tasksList.add(Triple(title, timeStr, priority))
                        }
                    }
                } catch (e: Exception) {
                    e.printStackTrace()
                }
            }

            val views = RemoteViews(context.packageName, R.layout.widget_top_priority).apply {
                setTextViewText(R.id.widget_priority_count, "• $count active")

                if (tasksList.isEmpty()) {
                    setTextViewText(R.id.widget_top_task_title, "No pending tasks")
                } else {
                    setTextViewText(R.id.widget_top_task_title, tasksList[0].first)
                }

                val taskItemIds = arrayOf(R.id.task_item_0, R.id.task_item_1, R.id.task_item_2, R.id.task_item_3)
                for (i in 0 until 4) {
                    if (i < tasksList.size) {
                        val (title, timeStr, priority) = tasksList[i]
                        val icon = when {
                            priority >= 2 -> "🔴 "
                            priority == 1 -> "🟠 "
                            else -> "⚪ "
                        }
                        val timeSuffix = if (timeStr.isNotEmpty()) " ($timeStr)" else ""
                        setTextViewText(taskItemIds[i], "$icon$title$timeSuffix")
                        setViewVisibility(taskItemIds[i], View.VISIBLE)
                    } else {
                        setViewVisibility(taskItemIds[i], View.GONE)
                    }
                }

                val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    com.epicordia.live.MainActivity::class.java,
                    android.net.Uri.parse("epicordia://tasks")
                )
                setOnClickPendingIntent(R.id.widget_top_priority_container, pendingIntent)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
