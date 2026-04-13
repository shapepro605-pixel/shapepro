# ProGuard Rules for ShapePro
# Protect logic and obfuscate class names for Google Play

# General Flutter rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Protect ShapePro models/business logic but allow obfuscation
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Remove Log calls in production for security and performance
-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int v(...);
    public static int i(...);
    public static int d(...);
    public static int w(...);
    public static int e(...);
}

# Prevent scraping of string constants if possible
# (Basic obfuscation covers this, but we can be more aggressive)
-repackageclasses ''
-allowaccessmodification
-optimizations !code/simplification/arithmetic,!field/*,!class/merging/*

# In-App Purchase rules
-keep class com.android.billingclient.** { *; }

# Google Play Core rules
-keep class com.google.android.play.core.common.IntentSenderForResultStarter { *; }
-keep class com.google.android.play.core.release_notes.** { *; }
-keep class com.google.android.play.core.review.** { *; }
-keep class com.google.android.play.core.appupdate.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }

# Local Auth rules
-keep class androidx.biometric.** { *; }
-keep class io.flutter.plugins.localauth.** { *; }
-keep class androidx.fragment.app.FragmentActivity { *; }
-keep class androidx.fragment.app.Fragment { *; }

# Suppress warnings that don't affect runtime
-dontwarn com.google.android.gms.**
-dontwarn com.google.android.play.core.**
-dontwarn com.google.firebase.**

# ML Kit Pose Detection
-keep class com.google.mlkit.vision.pose.** { *; }
-keep class com.google.android.gms.vision.** { *; }
-keep class com.google.mlkit.common.** { *; }
