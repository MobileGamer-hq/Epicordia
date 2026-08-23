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
            var windowLabel = "August 2026"
            val dayLevels = IntArray(28) { i -> if (i % 3 == 0) (i % 4) else 0 }

            if (rawJson != null) {
                try {
                    val json = JSONObject(rawJson)
                    focusRate = json.optInt("focus_rate", 82)
                    windowLabel = json.optString("window", "August 2026")
                    val activityArray = json.optJSONArray("activity_28_days")
                    if (activityArray != null && activityArray.length() >= 28) {
                        for (i in 0 until 28) {
                            dayLevels[i] = activityArray.optInt(i, 0)
                        }
                    }
                } catch (e: Exception) {
                    e.printStackTrace()
                }
            }

            val views = RemoteViews(context.packageName, R.layout.widget_calendar_heatmap).apply {
                setTextViewText(R.id.widget_title, "$focusRate% Focus Rate")
                setTextViewText(R.id.widget_subtitle, "Visual Workflow • $windowLabel")

                val dayIds = arrayOf(
                    R.id.day_0, R.id.day_1, R.id.day_2, R.id.day_3, R.id.day_4, R.id.day_5, R.id.day_6,
                    R.id.day_7, R.id.day_8, R.id.day_9, R.id.day_10, R.id.day_11, R.id.day_12, R.id.day_13,
                    R.id.day_14, R.id.day_15, R.id.day_16, R.id.day_17, R.id.day_18, R.id.day_19, R.id.day_20,
                    R.id.day_21, R.id.day_22, R.id.day_23, R.id.day_24, R.id.day_25, R.id.day_26, R.id.day_27
                )

                for (i in 0 until 28) {
                    val resId = when (dayLevels[i]) {
                        1 -> R.drawable.widget_day_square_1
                        2 -> R.drawable.widget_day_square_2
                        3 -> R.drawable.widget_day_square_3
                        else -> R.drawable.widget_day_square_0
                    }
                    setImageViewResource(dayIds[i], resId)
                }

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
