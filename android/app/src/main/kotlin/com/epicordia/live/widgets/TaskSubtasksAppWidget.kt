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

class TaskSubtasksAppWidget : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val rawJson = widgetData.getString("task_subtasks_data", null)
            var boardTag = "INBOX"
            var taskTitle = "No Task Selected"
            var summaryStr = "Select a task in Widgets Center"
            val subtasksList = mutableListOf<Pair<String, Boolean>>()

            if (rawJson != null) {
                try {
                    val json = JSONObject(rawJson)
                    boardTag = json.optString("board", "INBOX").uppercase()
                    taskTitle = json.optString("title", "No Task Selected")
                    
                    val array = json.optJSONArray("subtasks")
                    var completedCount = 0
                    if (array != null) {
                        for (i in 0 until array.length()) {
                            val item = array.getJSONObject(i)
                            val title = item.optString("title", "")
                            val done = item.optBoolean("done", false)
                            if (done) completedCount++
                            subtasksList.add(Pair(title, done))
                        }
                        summaryStr = "$completedCount/${array.length()} subtasks completed"
                    }
                } catch (e: Exception) {
                    e.printStackTrace()
                }
            }

            val views = RemoteViews(context.packageName, R.layout.widget_task_subtasks).apply {
                setTextViewText(R.id.widget_board_tag, boardTag)
                setTextViewText(R.id.widget_task_title, taskTitle)
                setTextViewText(R.id.widget_subtasks_summary, summaryStr)

                val subtaskIds = arrayOf(R.id.subtask_0, R.id.subtask_1, R.id.subtask_2, R.id.subtask_3)
                for (i in 0 until 4) {
                    if (i < subtasksList.size) {
                        val (title, done) = subtasksList[i]
                        val prefix = if (done) "☑ " else "☐ "
                        setTextViewText(subtaskIds[i], "$prefix$title")
                        setViewVisibility(subtaskIds[i], View.VISIBLE)
                    } else {
                        setViewVisibility(subtaskIds[i], View.GONE)
                    }
                }

                val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    com.epicordia.live.MainActivity::class.java,
                    android.net.Uri.parse("epicordia://today")
                )
                setOnClickPendingIntent(R.id.widget_task_subtasks_container, pendingIntent)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
