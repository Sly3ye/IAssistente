# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.**

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**

# flutter_dotenv — keep .env asset readable at runtime
-keep class io.flutter.plugins.flutter_plugin_android_lifecycle.** { *; }

# Prevent stripping of Kotlin metadata
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes Exceptions

# Gson / JSON serialization
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# in_app_purchase / billing
-keep class com.android.billingclient.** { *; }
-dontwarn com.android.billingclient.**
