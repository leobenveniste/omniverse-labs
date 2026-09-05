package com.omniverselabs.ritmo

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.res.Configuration
import android.graphics.Color
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import java.util.Calendar

data class RitmoWidgetTheme(
    val phase: String,
    val isDark: Boolean,
    val bgCardRes: Int,
    val itemBgRes: Int,
    val itemDoneBgRes: Int,
    val circleAccentRes: Int,
    val greetingText: String,
    val greetingTag: String,
    val accentColor: Int,
    val textPrimaryColor: Int,
    val textSecondaryColor: Int,
    val streakColor: Int,
    val checkDoneColor: Int,
    val checkUndoneColor: Int
)

object RitmoWidgetThemeHelper {
    fun getCircadianPhase(): String {
        val hour = Calendar.getInstance().get(Calendar.HOUR_OF_DAY)
        return when (hour) {
            in 5..11 -> "morning"
            in 12..17 -> "afternoon"
            else -> "night"
        }
    }

    fun isDarkMode(context: Context): Boolean {
        val widgetData = HomeWidgetPlugin.getData(context)
        val prefThemeMode = widgetData.getString("theme_mode", "system")
        return when (prefThemeMode) {
            "dark" -> true
            "light" -> false
            else -> {
                val nightMode = context.resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK
                nightMode == Configuration.UI_MODE_NIGHT_YES
            }
        }
    }

    fun getTheme(context: Context): RitmoWidgetTheme {
        val phase = getCircadianPhase()
        val isDark = isDarkMode(context)

        return when (phase) {
            "afternoon" -> {
                if (isDark) {
                    RitmoWidgetTheme(
                        phase = phase,
                        isDark = true,
                        bgCardRes = R.drawable.widget_bg_afternoon_dark,
                        itemBgRes = R.drawable.widget_item_afternoon_dark,
                        itemDoneBgRes = R.drawable.widget_item_done_afternoon_dark,
                        circleAccentRes = R.drawable.widget_circle_afternoon_dark,
                        greetingText = "Ritmo • Tarde",
                        greetingTag = "RITMO • TARDE",
                        accentColor = Color.parseColor("#FFA07A"),
                        textPrimaryColor = Color.parseColor("#FFF5F0"),
                        textSecondaryColor = Color.parseColor("#BCA49A"),
                        streakColor = Color.parseColor("#F59E0B"),
                        checkDoneColor = Color.parseColor("#34D399"),
                        checkUndoneColor = Color.parseColor("#78665E")
                    )
                } else {
                    RitmoWidgetTheme(
                        phase = phase,
                        isDark = false,
                        bgCardRes = R.drawable.widget_bg_afternoon_light,
                        itemBgRes = R.drawable.widget_item_afternoon_light,
                        itemDoneBgRes = R.drawable.widget_item_done_afternoon_light,
                        circleAccentRes = R.drawable.widget_circle_afternoon_light,
                        greetingText = "Ritmo • Tarde",
                        greetingTag = "RITMO • TARDE",
                        accentColor = Color.parseColor("#C85A3B"),
                        textPrimaryColor = Color.parseColor("#251814"),
                        textSecondaryColor = Color.parseColor("#6D5A53"),
                        streakColor = Color.parseColor("#D35400"),
                        checkDoneColor = Color.parseColor("#2E7D32"),
                        checkUndoneColor = Color.parseColor("#9A8780")
                    )
                }
            }
            "night" -> {
                if (isDark) {
                    RitmoWidgetTheme(
                        phase = phase,
                        isDark = true,
                        bgCardRes = R.drawable.widget_bg_night_dark,
                        itemBgRes = R.drawable.widget_item_night_dark,
                        itemDoneBgRes = R.drawable.widget_item_done_night_dark,
                        circleAccentRes = R.drawable.widget_circle_night_dark,
                        greetingText = "Ritmo • Noche",
                        greetingTag = "RITMO • NOCHE",
                        accentColor = Color.parseColor("#818CF8"),
                        textPrimaryColor = Color.parseColor("#F6F8FD"),
                        textSecondaryColor = Color.parseColor("#94A3B8"),
                        streakColor = Color.parseColor("#F59E0B"),
                        checkDoneColor = Color.parseColor("#38BDF8"),
                        checkUndoneColor = Color.parseColor("#60708D")
                    )
                } else {
                    RitmoWidgetTheme(
                        phase = phase,
                        isDark = false,
                        bgCardRes = R.drawable.widget_bg_night_light,
                        itemBgRes = R.drawable.widget_item_night_light,
                        itemDoneBgRes = R.drawable.widget_item_done_night_light,
                        circleAccentRes = R.drawable.widget_circle_night_light,
                        greetingText = "Ritmo • Noche",
                        greetingTag = "RITMO • NOCHE",
                        accentColor = Color.parseColor("#4F46E5"),
                        textPrimaryColor = Color.parseColor("#101828"),
                        textSecondaryColor = Color.parseColor("#4B5874"),
                        streakColor = Color.parseColor("#D97706"),
                        checkDoneColor = Color.parseColor("#2E7D32"),
                        checkUndoneColor = Color.parseColor("#8290AD")
                    )
                }
            }
            else -> { // morning
                if (isDark) {
                    RitmoWidgetTheme(
                        phase = phase,
                        isDark = true,
                        bgCardRes = R.drawable.widget_bg_morning_dark,
                        itemBgRes = R.drawable.widget_item_morning_dark,
                        itemDoneBgRes = R.drawable.widget_item_done_morning_dark,
                        circleAccentRes = R.drawable.widget_circle_morning_dark,
                        greetingText = "Ritmo • Mañana",
                        greetingTag = "RITMO • MAÑANA",
                        accentColor = Color.parseColor("#72D572"),
                        textPrimaryColor = Color.parseColor("#F2F7F2"),
                        textSecondaryColor = Color.parseColor("#9EB2A1"),
                        streakColor = Color.parseColor("#FF8A65"),
                        checkDoneColor = Color.parseColor("#4ADE80"),
                        checkUndoneColor = Color.parseColor("#667A69")
                    )
                } else {
                    RitmoWidgetTheme(
                        phase = phase,
                        isDark = false,
                        bgCardRes = R.drawable.widget_bg_morning_light,
                        itemBgRes = R.drawable.widget_item_morning_light,
                        itemDoneBgRes = R.drawable.widget_item_done_morning_light,
                        circleAccentRes = R.drawable.widget_circle_morning_light,
                        greetingText = "Ritmo • Mañana",
                        greetingTag = "RITMO • MAÑANA",
                        accentColor = Color.parseColor("#2D4A2B"),
                        textPrimaryColor = Color.parseColor("#182219"),
                        textSecondaryColor = Color.parseColor("#526354"),
                        streakColor = Color.parseColor("#C85A3B"),
                        checkDoneColor = Color.parseColor("#2E7D32"),
                        checkUndoneColor = Color.parseColor("#859687")
                    )
                }
            }
        }
    }
}

class RitmoPulseWidgetProvider : AppWidgetProvider() {
    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == Intent.ACTION_CONFIGURATION_CHANGED ||
            intent.action == Intent.ACTION_TIME_CHANGED ||
            intent.action == Intent.ACTION_TIMEZONE_CHANGED) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val componentName = ComponentName(context, RitmoPulseWidgetProvider::class.java)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(componentName)
            if (appWidgetIds.isNotEmpty()) {
                onUpdate(context, appWidgetManager, appWidgetIds)
            }
        }
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val widgetData = HomeWidgetPlugin.getData(context)
        val theme = RitmoWidgetThemeHelper.getTheme(context)

        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_mindful_pulse)

            val streak = widgetData.getInt("pulse_streak", 0)
            val doneCount = widgetData.getInt("pulse_done_count", 0)
            val totalCount = widgetData.getInt("pulse_total_count", 0)
            val allCompleted = widgetData.getBoolean("all_completed", false)
            val hasHabits = widgetData.getBoolean("has_habits", totalCount > 0)
            val percent = if (totalCount > 0) (doneCount * 100) / totalCount else 0

            // Apply Dynamic Background & Header Styling
            views.setInt(R.id.widget_pulse_root, "setBackgroundResource", theme.bgCardRes)
            views.setTextViewText(R.id.pulse_time_greeting, theme.greetingText)
            views.setTextColor(R.id.pulse_time_greeting, theme.accentColor)
            views.setTextViewText(R.id.pulse_streak_count, streak.toString())
            views.setTextColor(R.id.pulse_streak_count, theme.streakColor)

            // State switching: Empty vs Completed vs In-Progress
            if (!hasHabits) {
                views.setViewVisibility(R.id.pulse_center_stats, View.GONE)
                views.setViewVisibility(R.id.pulse_completed_view, View.GONE)
                views.setViewVisibility(R.id.pulse_empty_view, View.VISIBLE)
                views.setTextColor(R.id.pulse_empty_title, theme.textPrimaryColor)
                views.setTextColor(R.id.pulse_empty_subtitle, theme.textSecondaryColor)
            } else if (allCompleted || (totalCount > 0 && doneCount >= totalCount)) {
                views.setViewVisibility(R.id.pulse_center_stats, View.GONE)
                views.setViewVisibility(R.id.pulse_empty_view, View.GONE)
                views.setViewVisibility(R.id.pulse_completed_view, View.VISIBLE)
                views.setTextColor(R.id.pulse_completed_title, theme.accentColor)
                views.setTextColor(R.id.pulse_completed_sub, theme.textSecondaryColor)
            } else {
                views.setViewVisibility(R.id.pulse_empty_view, View.GONE)
                views.setViewVisibility(R.id.pulse_completed_view, View.GONE)
                views.setViewVisibility(R.id.pulse_center_stats, View.VISIBLE)

                views.setTextViewText(R.id.pulse_percent_text, "$percent%")
                views.setTextColor(R.id.pulse_percent_text, theme.textPrimaryColor)

                views.setTextViewText(R.id.pulse_fraction_text, "$doneCount de $totalCount completados")
                views.setTextColor(R.id.pulse_fraction_text, theme.textSecondaryColor)

                views.setProgressBar(R.id.pulse_progress_bar, 100, percent, false)
            }

            views.setTextColor(R.id.pulse_zen_quote, theme.textSecondaryColor)

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
        if (intent.action == Intent.ACTION_CONFIGURATION_CHANGED ||
            intent.action == Intent.ACTION_TIME_CHANGED ||
            intent.action == Intent.ACTION_TIMEZONE_CHANGED) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val componentName = ComponentName(context, RitmoBentoWidgetProvider::class.java)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(componentName)
            if (appWidgetIds.isNotEmpty()) {
                onUpdate(context, appWidgetManager, appWidgetIds)
            }
            return
        }

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

                // Append explicit state (habitId:newDone) so Flutter sync is perfectly deterministic
                val pendingBatch = widgetData.getString("pending_toggle_batch", "") ?: ""
                val toggleEntry = "$habitId:$newDone"
                val updatedBatch = if (pendingBatch.isEmpty()) toggleEntry else "$pendingBatch,$toggleEntry"
                editor.putString("pending_toggle_batch", updatedBatch)
                editor.apply()

                // 2. Silently re-render all Bento widgets without launching Flutter activity
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

                // 3. If MainActivity is alive / in foreground, notify Flutter immediately
                MainActivity.activeInstance?.notifyWidgetAction()
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
        val theme = RitmoWidgetThemeHelper.getTheme(context)

        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_bento_matrix)

            // Dynamic Root Background
            views.setInt(R.id.widget_bento_root, "setBackgroundResource", theme.bgCardRes)

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
            val allCompleted = widgetData.getBoolean("all_completed", false)
            val hasHabits = widgetData.getBoolean("has_habits", totalCount > 0)

            val streakLabel = if (streak == 1) "1 día" else "$streak días"
            views.setTextViewText(R.id.bento_streak_text, streakLabel)
            views.setTextColor(R.id.bento_streak_text, theme.streakColor)

            views.setTextViewText(R.id.bento_circadian_tag, theme.greetingTag)
            views.setTextColor(R.id.bento_circadian_tag, theme.accentColor)

            views.setTextColor(R.id.bento_status_summary, theme.textPrimaryColor)

            // Completed vs Empty vs Habits list
            if (!hasHabits) {
                views.setTextViewText(R.id.bento_status_summary, "0 hábitos hoy")
                views.setViewVisibility(R.id.bento_items_container, View.GONE)
                views.setViewVisibility(R.id.bento_completed_container, View.GONE)
                views.setViewVisibility(R.id.bento_empty_container, View.VISIBLE)
                views.setInt(R.id.bento_empty_container, "setBackgroundResource", theme.itemBgRes)
                views.setTextColor(R.id.bento_empty_title, theme.textPrimaryColor)
                views.setTextColor(R.id.bento_empty_sub, theme.textSecondaryColor)

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
                views.setInt(R.id.bento_completed_container, "setBackgroundResource", theme.itemDoneBgRes)
                views.setTextColor(R.id.bento_completed_title, theme.accentColor)
                views.setTextColor(R.id.bento_completed_sub, theme.textSecondaryColor)

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

                setupHabitSlot(context, views, theme, R.id.habit_slot_1, R.id.habit_title_1, R.id.habit_check_1, habit1Title, habit1Done, habit1Id, 1)
                setupHabitSlot(context, views, theme, R.id.habit_slot_2, R.id.habit_title_2, R.id.habit_check_2, habit2Title, habit2Done, habit2Id, 2)
                setupHabitSlot(context, views, theme, R.id.habit_slot_3, R.id.habit_title_3, R.id.habit_check_3, habit3Title, habit3Done, habit3Id, 3)
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }

    private fun setupHabitSlot(
        context: Context,
        views: RemoteViews,
        theme: RitmoWidgetTheme,
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
        views.setInt(slotId, "setBackgroundResource", if (done) theme.itemDoneBgRes else theme.itemBgRes)
        views.setTextViewText(titleId, title)
        views.setTextColor(titleId, theme.textPrimaryColor)

        if (done) {
            views.setTextViewText(checkId, "✓")
            views.setTextColor(checkId, theme.checkDoneColor)
        } else {
            views.setTextViewText(checkId, "○")
            views.setTextColor(checkId, theme.checkUndoneColor)
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
    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == Intent.ACTION_CONFIGURATION_CHANGED ||
            intent.action == Intent.ACTION_TIME_CHANGED ||
            intent.action == Intent.ACTION_TIMEZONE_CHANGED) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val componentName = ComponentName(context, RitmoBreathingWidgetProvider::class.java)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(componentName)
            if (appWidgetIds.isNotEmpty()) {
                onUpdate(context, appWidgetManager, appWidgetIds)
            }
        }
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val widgetData = HomeWidgetPlugin.getData(context)
        val minutes = widgetData.getInt("breathing_minutes", 0)
        val theme = RitmoWidgetThemeHelper.getTheme(context)

        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_breathing_sanctuary)

            views.setInt(R.id.widget_breathing_root, "setBackgroundResource", theme.bgCardRes)
            views.setTextColor(R.id.breathing_tag, theme.accentColor)
            views.setInt(R.id.breathing_circle_btn, "setBackgroundResource", theme.circleAccentRes)
            views.setTextColor(R.id.breathing_cta_title, theme.textPrimaryColor)
            views.setTextColor(R.id.breathing_session_minutes, theme.textSecondaryColor)

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
    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == Intent.ACTION_CONFIGURATION_CHANGED ||
            intent.action == Intent.ACTION_TIME_CHANGED ||
            intent.action == Intent.ACTION_TIMEZONE_CHANGED) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val componentName = ComponentName(context, RitmoMiniPulseWidgetProvider::class.java)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(componentName)
            if (appWidgetIds.isNotEmpty()) {
                onUpdate(context, appWidgetManager, appWidgetIds)
            }
        }
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val widgetData = HomeWidgetPlugin.getData(context)
        val theme = RitmoWidgetThemeHelper.getTheme(context)

        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_mini_pulse)

            views.setInt(R.id.widget_mini_root, "setBackgroundResource", theme.bgCardRes)

            val streak = widgetData.getInt("pulse_streak", 0)
            val doneCount = widgetData.getInt("pulse_done_count", 0)
            val totalCount = widgetData.getInt("pulse_total_count", 0)
            val allCompleted = widgetData.getBoolean("all_completed", false)
            val hasHabits = widgetData.getBoolean("has_habits", totalCount > 0)

            views.setTextViewText(R.id.mini_streak_text, streak.toString())
            views.setTextColor(R.id.mini_streak_text, theme.streakColor)

            if (!hasHabits) {
                views.setTextViewText(R.id.mini_fraction_text, "0")
            } else if (allCompleted || (totalCount > 0 && doneCount >= totalCount)) {
                views.setTextViewText(R.id.mini_fraction_text, "✓ $doneCount")
            } else {
                views.setTextViewText(R.id.mini_fraction_text, "$doneCount/$totalCount")
            }
            views.setTextColor(R.id.mini_fraction_text, theme.accentColor)

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
