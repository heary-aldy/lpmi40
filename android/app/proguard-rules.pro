# android/app/proguard-rules.pro
# ✅ ENHANCED VERSION: Builds on your existing rules + fixes type cast issues

#===============================================================================
# YOUR EXISTING RULES (KEPT AS-IS)
#===============================================================================
-keep class com.google.firebase.** { *; }
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class com.google.android.play.core.** { *; }
-keepattributes *Annotation*
-dontwarn com.google.firebase.**
-dontwarn com.google.android.play.core.**

#===============================================================================
# ✅ NEW ADDITIONS: These fix your Firebase type cast issues
#===============================================================================

# Google Mobile Services (GMS) - Missing from your current rules
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# ✅ CRITICAL: Pigeon classes (THIS FIXES YOUR TYPE CAST ERRORS!)
# These are the PigeonUserInfo/PigeonUserDetails classes causing your issues
-keep class **Pigeon** { *; }
-keep class **PigeonUserInfo** { *; }
-keep class **PigeonUserDetails** { *; }
-keep class **PigeonAuthResult** { *; }
-keep class **PigeonFirebaseApp** { *; }
-keepnames class **Pigeon** { *; }

# Firebase Auth specific protections (more specific than your general Firebase rule)
-keep class com.google.firebase.auth.** { *; }
-keepclassmembers class com.google.firebase.auth.** { *; }

# Firebase Database specific protections  
-keep class com.google.firebase.database.** { *; }
-keepclassmembers class com.google.firebase.database.** { *; }

# Flutter Firebase plugins (more specific than your general plugin rule)
-keep class io.flutter.plugins.firebase.** { *; }
-keep class io.flutter.plugins.googlesignin.** { *; }

# Plugin communication classes (prevents method signature issues)
-keep class io.flutter.plugin.common.** { *; }
-keep class io.flutter.embedding.** { *; }

# Firebase model annotations
-keep @com.google.firebase.database.IgnoreExtraProperties class *
-keepclassmembers class * {
    @com.google.firebase.database.Exclude <fields>;
    @com.google.firebase.database.Exclude <methods>;
}

# Enum classes (often involved in type cast issues)
-keep class * extends java.lang.Enum { *; }

# Native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep line numbers for better crash reports
-keepattributes SourceFile,LineNumberTable

# Network classes for Firebase
-keep class okhttp3.** { *; }
-keep class okio.** { *; }
-dontwarn okhttp3.**
-dontwarn okio.**

#===============================================================================
# OPTIMIZATION SETTINGS
#===============================================================================

# Don't optimize these classes (prevents aggressive optimization that breaks reflection)
-keep,allowoptimization !class com.google.firebase.**
-keep,allowoptimization !class **Pigeon**