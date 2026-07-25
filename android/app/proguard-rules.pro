# Add project specific ProGuard rules here.
# By default, the flags in this file are appended to flags specified
# in /usr/local/Cellar/android-sdk/24.3.3/tools/proguard/proguard-android.txt

# Flutter specific rules
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep all model classes (drift, riverpod, etc.)
-keep class com.epicordia.app.** { *; }

# SQLite / Drift
-keep class org.sqlite.** { *; }
-keep class org.sqlite.database.** { *; }

# Notifications
-keep class com.dexterous.** { *; }

# Google Fonts
-keep class com.google.android.gms.** { *; }

# General rules
-dontwarn kotlin.**
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.engine.deferredcomponents.**
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
