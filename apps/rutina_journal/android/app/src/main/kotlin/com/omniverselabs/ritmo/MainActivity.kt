package com.omniverselabs.ritmo

import android.app.NotificationManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val DND_CHANNEL = "com.omniverselabs.ritmo/dnd"
    private val WIDGETS_CHANNEL = "com.omniverselabs.ritmo/widgets"
    private var previousInterruptionFilter: Int? = null
    private var pendingOpenScreen: String? = null

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        handleOpenScreenIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleOpenScreenIntent(intent)
    }

    private fun handleOpenScreenIntent(intent: Intent?) {
        val screen = intent?.getStringExtra("open_screen")
        if (!screen.isNullOrEmpty()) {
            pendingOpenScreen = screen
            // Also store in SharedPreferences so HomeWidget plugin or Flutter can read it reliably
            val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            prefs.edit().putString("flutter.pending_open_screen", screen).apply()
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DND_CHANNEL).setMethodCallHandler { call, result ->
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
            if (notificationManager == null) {
                result.error("UNAVAILABLE", "NotificationManager unavailable", null)
                return@setMethodCallHandler
            }

            when (call.method) {
                "hasDndPermission" -> {
                    result.success(notificationManager.isNotificationPolicyAccessGranted)
                }
                "openDndSettings" -> {
                    try {
                        val intent = Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS)
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("INTENT_ERROR", e.message, null)
                    }
                }
                "enableDnd" -> {
                    if (notificationManager.isNotificationPolicyAccessGranted) {
                        try {
                            if (previousInterruptionFilter == null) {
                                previousInterruptionFilter = notificationManager.currentInterruptionFilter
                            }
                            notificationManager.setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_PRIORITY)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("SET_DND_FAILED", e.message, null)
                        }
                    } else {
                        result.success(false)
                    }
                }
                "disableDnd" -> {
                    if (notificationManager.isNotificationPolicyAccessGranted) {
                        try {
                            val restoreFilter = previousInterruptionFilter ?: NotificationManager.INTERRUPTION_FILTER_ALL
                            notificationManager.setInterruptionFilter(restoreFilter)
                            previousInterruptionFilter = null
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("RESTORE_DND_FAILED", e.message, null)
                        }
                    } else {
                        result.success(false)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // Widget Pinning Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.omniverselabs.ritmo/widgets").setMethodCallHandler { call, result ->
            val appWidgetManager = getSystemService(Context.APPWIDGET_SERVICE) as? android.appwidget.AppWidgetManager
            if (appWidgetManager == null) {
                result.error("UNAVAILABLE", "AppWidgetManager unavailable", null)
                return@setMethodCallHandler
            }

            when (call.method) {
                "isPinningSupported" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        result.success(appWidgetManager.isRequestPinAppWidgetSupported)
                    } else {
                        result.success(false)
                    }
                }
                "pinWidget" -> {
                    val providerName = call.argument<String>("provider")
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && providerName != null) {
                        try {
                            val providerClass = Class.forName("com.omniverselabs.ritmo.$providerName")
                            val providerComponent = ComponentName(this, providerClass)
                            if (appWidgetManager.isRequestPinAppWidgetSupported) {
                                val success = appWidgetManager.requestPinAppWidget(providerComponent, null, null)
                                result.success(success)
                            } else {
                                result.success(false)
                            }
                        } catch (e: Exception) {
                            result.error("PIN_FAILED", e.message, null)
                        }
                    } else {
                        result.success(false)
                    }
                }
                "consumePendingOpenScreen" -> {
                    val screen = pendingOpenScreen
                    pendingOpenScreen = null
                    val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                    prefs.edit().remove("flutter.pending_open_screen").apply()
                    result.success(screen)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
