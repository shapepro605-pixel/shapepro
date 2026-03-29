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
