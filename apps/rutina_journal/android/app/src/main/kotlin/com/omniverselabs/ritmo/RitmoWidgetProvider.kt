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
            val allCompleted = widgetData.getBoolean("all_completed", false)
            val hasHabits = widgetData.getBoolean("has_habits", totalCount > 0)
            val percent = if (totalCount > 0) (doneCount * 100) / totalCount else 0
            val phase = widgetData.getString("circadian_phase", "morning") ?: "morning"

            views.setTextViewText(R.id.pulse_streak_count, streak.toString())

            // State switching: Empty vs Completed vs In-Progress
            if (!hasHabits) {
                views.setViewVisibility(R.id.pulse_center_stats, View.GONE)
                views.setViewVisibility(R.id.pulse_completed_view, View.GONE)
                views.setViewVisibility(R.id.pulse_empty_view, View.VISIBLE)
            } else if (allCompleted || (totalCount > 0 && doneCount >= totalCount)) {
                views.setViewVisibility(R.id.pulse_center_stats, View.GONE)
                views.setViewVisibility(R.id.pulse_empty_view, View.GONE)
                views.setViewVisibility(R.id.pulse_completed_view, View.VISIBLE)
            } else {
                views.setViewVisibility(R.id.pulse_empty_view, View.GONE)
                views.setViewVisibility(R.id.pulse_completed_view, View.GONE)
                views.setViewVisibility(R.id.pulse_center_stats, View.VISIBLE)

                views.setTextViewText(R.id.pulse_percent_text, "$percent%")
                views.setTextViewText(R.id.pulse_fraction_text, "$doneCount de $totalCount completados")
                views.setProgressBar(R.id.pulse_progress_bar, 100, percent, false)
            }

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
        const val EXTRA_SLOT_INDEX = "extra_slot_index"
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == ACTION_TOGGLE_HABIT) {
            val habitId = intent.getStringExtra(EXTRA_HABIT_ID)
            val slotIndex = intent.getIntExtra(EXTRA_SLOT_INDEX, -1)

            if (!habitId.isNullOrEmpty() && slotIndex in 1..3) {
                val widgetData = HomeWidgetPlugin.getData(context)
                val currentDone = widgetData.getBoolean("bento_habit_${slotIndex}_done", false)
                val newDone = !currentDone

                // 1. Update SharedPreferences for this slot
                val editor = widgetData.edit()
                editor.putBoolean("bento_habit_${slotIndex}_done", newDone)

                // Update counts
                val prevDoneCount = widgetData.getInt("pulse_done_count", 0)
                val totalCount = widgetData.getInt("pulse_total_count", 0)
                val newDoneCount = if (newDone) prevDoneCount + 1 else maxOf(0, prevDoneCount - 1)
                editor.putInt("pulse_done_count", newDoneCount)

                val allCompleted = totalCount > 0 && newDoneCount >= totalCount
                editor.putBoolean("all_completed", allCompleted)

                // Append to pending batch toggles for Flutter to commit on next sync/resume
                val pendingBatch = widgetData.getString("pending_toggle_batch", "") ?: ""
                val updatedBatch = if (pendingBatch.isEmpty()) habitId else "$pendingBatch,$habitId"
                editor.putString("pending_toggle_batch", updatedBatch)
                editor.apply()

                // 2. Silently re-render all Bento widgets without launching the Flutter activity
                val appWidgetManager = AppWidgetManager.getInstance(context)
                val componentName = ComponentName(context, RitmoBentoWidgetProvider::class.java)
                val appWidgetIds = appWidgetManager.getAppWidgetIds(componentName)
                onUpdate(context, appWidgetManager, appWidgetIds)

                // Also refresh Mindful Pulse and Mini widgets so counts remain synchronized
                val pulseComponentName = ComponentName(context, RitmoPulseWidgetProvider::class.java)
                val pulseIds = appWidgetManager.getAppWidgetIds(pulseComponentName)
                if (pulseIds.isNotEmpty()) {
                    RitmoPulseWidgetProvider().onUpdate(context, appWidgetManager, pulseIds)
                }

                val miniComponentName = ComponentName(context, RitmoMiniPulseWidgetProvider::class.java)
                val miniIds = appWidgetManager.getAppWidgetIds(miniComponentName)
                if (miniIds.isNotEmpty()) {
                    RitmoMiniPulseWidgetProvider().onUpdate(context, appWidgetManager, miniIds)
                }
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
            val allCompleted = widgetData.getBoolean("all_completed", false)
            val hasHabits = widgetData.getBoolean("has_habits", totalCount > 0)

            views.setTextViewText(R.id.bento_streak_text, "$streak días")

            when (phase) {
                "afternoon" -> views.setTextViewText(R.id.bento_circadian_tag, "RITMO • TARDE")
                "night" -> views.setTextViewText(R.id.bento_circadian_tag, "RITMO • NOCHE")
                else -> views.setTextViewText(R.id.bento_circadian_tag, "RITMO • MAÑANA")
            }

            // Completed vs Empty vs Habits list
            if (!hasHabits) {
                views.setTextViewText(R.id.bento_status_summary, "0 hábitos hoy")
                views.setViewVisibility(R.id.bento_items_container, View.GONE)
                views.setViewVisibility(R.id.bento_completed_container, View.GONE)
                views.setViewVisibility(R.id.bento_empty_container, View.VISIBLE)

                // Tap empty state to open app
                val intent = context.packageManager.getLaunchIntentForPackage(context.packageName)
                val pendingIntent = PendingIntent.getActivity(
                    context, 10, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.bento_empty_container, pendingIntent)
            } else if (allCompleted || (totalCount > 0 && doneCount >= totalCount)) {
                views.setTextViewText(R.id.bento_status_summary, "$doneCount de $totalCount hábitos cumplidos")
                views.setViewVisibility(R.id.bento_items_container, View.GONE)
                views.setViewVisibility(R.id.bento_empty_container, View.GONE)
                views.setViewVisibility(R.id.bento_completed_container, View.VISIBLE)

                // Tap celebration to open app
                val intent = context.packageManager.getLaunchIntentForPackage(context.packageName)
                val pendingIntent = PendingIntent.getActivity(
                    context, 11, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.bento_completed_container, pendingIntent)
            } else {
                views.setTextViewText(R.id.bento_status_summary, "$doneCount de $totalCount hábitos cumplidos")
                views.setViewVisibility(R.id.bento_completed_container, View.GONE)
                views.setViewVisibility(R.id.bento_empty_container, View.GONE)
                views.setViewVisibility(R.id.bento_items_container, View.VISIBLE)

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
            }

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
        slotIndex: Int
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
                putExtra(EXTRA_SLOT_INDEX, slotIndex)
            }
            val pendingIntent = PendingIntent.getBroadcast(
                context,
                slotIndex * 100,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(slotId, pendingIntent)
        }
    }
}

class RitmoBreathingWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val widgetData = HomeWidgetPlugin.getData(context)
        val minutes = widgetData.getInt("breathing_minutes", 0)

        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_breathing_sanctuary)

            if (minutes > 0) {
                views.setTextViewText(R.id.breathing_session_minutes, "$minutes min de calma hoy • 4-4-4-4")
            } else {
                views.setTextViewText(R.id.breathing_session_minutes, "Pausa guiada • 4-4-4-4")
            }

            // Tap launches directly into Breathing Area / Focus Zone
            val intent = context.packageManager.getLaunchIntentForPackage(context.packageName)?.apply {
                putExtra("open_screen", "focus_zone")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            }
            if (intent != null) {
                val pendingIntent = PendingIntent.getActivity(
                    context,
                    200,
                    intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.widget_breathing_root, pendingIntent)
                views.setOnClickPendingIntent(R.id.breathing_center_cta, pendingIntent)
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}

class RitmoMiniPulseWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val widgetData = HomeWidgetPlugin.getData(context)

        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_mini_pulse)

            val streak = widgetData.getInt("pulse_streak", 0)
            val doneCount = widgetData.getInt("pulse_done_count", 0)
            val totalCount = widgetData.getInt("pulse_total_count", 0)
            val allCompleted = widgetData.getBoolean("all_completed", false)
            val hasHabits = widgetData.getBoolean("has_habits", totalCount > 0)

            views.setTextViewText(R.id.mini_streak_text, streak.toString())

            if (!hasHabits) {
                views.setTextViewText(R.id.mini_fraction_text, "0")
            } else if (allCompleted || (totalCount > 0 && doneCount >= totalCount)) {
                views.setTextViewText(R.id.mini_fraction_text, "✓ $doneCount")
            } else {
                views.setTextViewText(R.id.mini_fraction_text, "$doneCount/$totalCount")
            }

            val intent = context.packageManager.getLaunchIntentForPackage(context.packageName)
            val pendingIntent = PendingIntent.getActivity(
                context,
                300,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_mini_root, pendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
