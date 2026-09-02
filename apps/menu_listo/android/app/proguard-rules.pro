# ML Kit Text Recognition Proguard Keep Rules
-dontwarn com.google.mlkit.vision.text.**
-dontwarn com.google_mlkit_text_recognition.**
-dontwarn com.google.android.gms.**
-keep class com.google.mlkit.** { *; }
-keep class com.google_mlkit_text_recognition.** { *; }
-keep class com.google.android.gms.tasks.** { *; }

# Flutter & Sqflite Keep Rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-dontwarn io.flutter.embedding.**
-keep class com.tekartik.sqflite.** { *; }
-dontwarn com.tekartik.sqflite.**

# In-App Purchase / Google Play Billing Keep Rules
-keep class com.android.vending.billing.** { *; }
-keep class com.android.billingclient.** { *; }
-keep class io.flutter.plugins.inapppurchase.** { *; }
-dontwarn com.android.billingclient.**

