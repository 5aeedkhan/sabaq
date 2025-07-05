# Flutter
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.embedding.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Gson (only if you're using JSON parsing with Gson)
-keep class com.google.gson.** { *; }
-dontwarn com.google.gson.**

# Your app's own model/data classes (optional but recommended)
-keep class com.itartificer.sabaq.** { *; }

# Prevent R8 from removing required classes (safety net)
-dontoptimize
-dontpreverify
# Keep classes for Flutter deferred components
-keep class com.google.android.play.core.splitcompat.SplitCompatApplication { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**
