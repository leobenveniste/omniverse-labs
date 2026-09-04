package com.omniverselabs.ritmo

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

class RitmoPulseWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val widgetData = HomeWidgetPlugin.getData(context)

        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_mindful_pulse)

            val streak = widgetData.getInt("pulse_streak", 0)
            val doneCount = widgetData.getInt("pulse_done_count", 0)
            val totalCount = widgetData.getInt("pulse_total_count", 0)
            val percent = if (totalCount > 0) (doneCount * 100) / totalCount else 0
            val phase = widgetData.getString("circadian_phase", "morning") ?: "morning"

            views.setTextViewText(R.id.pulse_streak_count, streak.toString())
            views.setTextViewText(R.id.pulse_percent_text, "%")
            views.setTextViewText(R.id.pulse_fraction_text, " de  completados")
            views.setProgressBar(R.id.pulse_progress_bar, 100, percent, false)

            // Circadian Palette Adjustment
            when (phase) {
                "afternoon" -> {
                    views.setTextViewText(R.id.pulse_time_greeting, "Ritmo • Tarde solar")
                    views.setTextColor(R.id.pulse_time_greeting, Color.parseColor("#C85A3B"))
                }
                "night" -> {
                    views.setTextViewText(R.id.pulse_time_greeting, "Ritmo • Serenidad nocturna")
                    views.setTextColor(R.id.pulse_time_greeting, Color.parseColor("#5C6BC0"))
                }
                else -> {
                    views.setTextViewText(R.id.pulse_time_greeting, "Ritmo • Mañana zen")
                    views.setTextColor(R.id.pulse_time_greeting, Color.parseColor("#2D4A2B"))
                }
            }

            // Clicking widget launches app
            val intent = context.packageManager.getLaunchIntentForPackage(context.packageName)
            val pendingIntent = PendingIntent.getActivity(
                context,
                0,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_pulse_root, pendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}

class RitmoBentoWidgetProvider : AppWidgetProvider() {
    companion object {
        const val ACTION_TOGGLE_HABIT = "com.omniverselabs.ritmo.ACTION_TOGGLE_HABIT"
        const val EXTRA_HABIT_ID = "extra_habit_id"
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == ACTION_TOGGLE_HABIT) {
            val habitId = intent.getStringExtra(EXTRA_HABIT_ID)
            if (habitId != null) {
                // Record toggle request in shared data so Flutter processes it on resume or launches
                val widgetData = HomeWidgetPlugin.getData(context)
                widgetData.edit().putString("pending_toggle_habit_id", habitId).apply()

                // Launch or bring app forward
                val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
                launchIntent?.putExtra("toggle_habit_id", habitId)
                launchIntent?.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                context.startActivity(launchIntent)
            }
        }
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val widgetData = HomeWidgetPlugin.getData(context)
        val isPro = widgetData.getBoolean("is_pro", false)

        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_bento_matrix)

            if (!isPro) {
                views.setViewVisibility(R.id.bento_pro_overlay, View.VISIBLE)
                val intent = context.packageManager.getLaunchIntentForPackage(context.packageName)
                val pendingIntent = PendingIntent.getActivity(
                    context, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.bento_pro_overlay, pendingIntent)
                appWidgetManager.updateAppWidget(appWidgetId, views)
                continue
            }

            views.setViewVisibility(R.id.bento_pro_overlay, View.GONE)

            val streak = widgetData.getInt("pulse_streak", 0)
            val doneCount = widgetData.getInt("pulse_done_count", 0)
            val totalCount = widgetData.getInt("pulse_total_count", 0)
            val phase = widgetData.getString("circadian_phase", "morning") ?: "morning"

            views.setTextViewText(R.id.bento_streak_text, " días")
            views.setTextViewText(R.id.bento_status_summary, " de  hábitos cumplidos")

            when (phase) {
                "afternoon" -> views.setTextViewText(R.id.bento_circadian_tag, "RITMO • TARDE")
                "night" -> views.setTextViewText(R.id.bento_circadian_tag, "RITMO • NOCHE")
                else -> views.setTextViewText(R.id.bento_circadian_tag, "RITMO • MAÑANA")
            }

            // Habit slots
            val habit1Title = widgetData.getString("bento_habit_1_title", "")
            val habit1Done = widgetData.getBoolean("bento_habit_1_done", false)
            val habit1Id = widgetData.getString("bento_habit_1_id", "")

            val habit2Title = widgetData.getString("bento_habit_2_title", "")
            val habit2Done = widgetData.getBoolean("bento_habit_2_done", false)
            val habit2Id = widgetData.getString("bento_habit_2_id", "")

            val habit3Title = widgetData.getString("bento_habit_3_title", "")
            val habit3Done = widgetData.getBoolean("bento_habit_3_done", false)
            val habit3Id = widgetData.getString("bento_habit_3_id", "")

            setupHabitSlot(context, views, R.id.habit_slot_1, R.id.habit_title_1, R.id.habit_check_1, habit1Title, habit1Done, habit1Id, 1)
            setupHabitSlot(context, views, R.id.habit_slot_2, R.id.habit_title_2, R.id.habit_check_2, habit2Title, habit2Done, habit2Id, 2)
            setupHabitSlot(context, views, R.id.habit_slot_3, R.id.habit_title_3, R.id.habit_check_3, habit3Title, habit3Done, habit3Id, 3)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }

    private fun setupHabitSlot(
        context: Context,
        views: RemoteViews,
        slotId: Int,
        titleId: Int,
        checkId: Int,
        title: String?,
        done: Boolean,
        habitId: String?,
        requestCode: Int
    ) {
        if (title.isNullOrEmpty()) {
            views.setViewVisibility(slotId, View.GONE)
            return
        }
        views.setViewVisibility(slotId, View.VISIBLE)
        views.setTextViewText(titleId, title)
        if (done) {
            views.setTextViewText(checkId, "✓")
            views.setTextColor(checkId, Color.parseColor("#2E7D32"))
        } else {
            views.setTextViewText(checkId, "○")
            views.setTextColor(checkId, Color.parseColor("#8A968C"))
        }

        if (!habitId.isNullOrEmpty()) {
            val intent = Intent(context, RitmoBentoWidgetProvider::class.java).apply {
                action = ACTION_TOGGLE_HABIT
                putExtra(EXTRA_HABIT_ID, habitId)
            }
            val pendingIntent = PendingIntent.getBroadcast(
                context,
                requestCode,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(slotId, pendingIntent)
        }
    }
}
