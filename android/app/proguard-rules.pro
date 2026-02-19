# ==================== PRAYER TIMES - PROGUARD RULES ====================
# ProGuard/R8 rules for com.amatullah.prayer_times
# Flutter app with Firebase, Drift/SQLite, Hive, Dio, Location services

# ==================== FIREBASE & GOOGLE PLAY SERVICES ====================
# Firebase Core
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-keepnames class com.google.firebase.firestore.** { *; }
-keepnames class com.google.firebase.crashlytics.** { *; }
-keepnames class com.google.firebase.analytics.** { *; }
-keepnames class com.google.firebase.messaging.** { *; }

# Firestore document classes
-keep class com.google.firebase.firestore.DocumentSnapshot { *; }
-keep class com.google.firebase.firestore.QuerySnapshot { *; }
-keep interface com.google.firebase.firestore.** { *; }

# Google Services
-keep class com.google.android.gms.auth.** { *; }
-keep class com.google.android.gms.common.** { *; }
-keep class com.google.android.gms.tasks.** { *; }

# ==================== FLUTTER CORE ====================
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.app.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }

# Generated Plugin Registrant
-keep class io.flutter.plugins.GeneratedPluginRegistrant { *; }

# ==================== FIREBASE FLUTTER PLUGINS ====================
-keep class io.flutter.plugins.firebase.** { *; }
-keep class io.flutter.plugins.firebase.core.** { *; }
-keep class io.flutter.plugins.firebase.firestore.** { *; }
-keep class io.flutter.plugins.firebase.crashlytics.** { *; }
-keep class io.flutter.plugins.firebase.analytics.** { *; }
-keep class io.flutter.plugins.firebase.messaging.** { *; }

# ==================== COMMUNITY PLUGINS ====================
# device_info_plus, package_info_plus, share_plus
-keep class dev.fluttercommunity.plus.** { *; }

# flutter_native_splash
-keep class net.jonhanson.flutter_native_splash.** { *; }

# in_app_review
-keep class dev.britannio.in_app_review.** { *; }

# app_settings
-keep class com.spencerccf.app_settings.** { *; }

# url_launcher
-keep class io.flutter.plugins.urllauncher.** { *; }

# path_provider
-keep class io.flutter.plugins.pathprovider.** { *; }

# ==================== LOCATION SERVICES ====================
# Geolocator
-keep class com.baseflow.geolocator.** { *; }
-keep class com.baseflow.geolocator.location.** { *; }

# Geocoding
-keep class com.baseflow.geocoding.** { *; }

# ==================== DATABASE ====================
# SQLite / sqflite
-keep class com.tekartik.sqflite.** { *; }
-keep class org.sqlite.** { *; }

# sqlite3_flutter_libs
-keep class eu.simonbinder.sqlite3_flutter_libs.** { *; }

# ==================== NETWORKING ====================
# Dio uses OkHttp under the hood on Android
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn javax.annotation.**
-keepnames class okhttp3.internal.publicsuffix.PublicSuffixDatabase

# Google APIs Auth
-keep class com.google.api.client.** { *; }
-dontwarn com.google.api.client.**

# ==================== FLUTTER ISOLATE ====================
-keep class com.rmawatson.flutterisolate.** { *; }

# ==================== APPLICATION SPECIFIC ====================
-keep class com.amatullah.prayer_times.** { *; }
-keep class com.amatullah.prayer_times.MainActivity { *; }

# ==================== NATIVE METHODS ====================
-keepclasseswithmembernames class * {
    native <methods>;
}

# ==================== EXCEPTIONS & CRASHLYTICS ====================
# Keep source file and line numbers for crash reports
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# Keep exception classes
-keep public class * extends java.lang.Exception
-keep public class * extends java.lang.Throwable

# ==================== ANNOTATIONS ====================
-keepattributes *Annotation*
-keepattributes RuntimeVisibleAnnotations
-keepattributes RuntimeInvisibleAnnotations
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# AndroidX Keep annotation
-keep @interface androidx.annotation.Keep
-keep @androidx.annotation.Keep class *
-keepclasseswithmembers class * {
    @androidx.annotation.Keep <methods>;
}
-keepclasseswithmembers class * {
    @androidx.annotation.Keep <fields>;
}

# ==================== ENUM ====================
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# ==================== PARCELABLE ====================
-keepclassmembers class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator CREATOR;
}

# ==================== SERIALIZABLE ====================
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# ==================== R8 OPTIMIZATIONS ====================
-optimizationpasses 5
-allowaccessmodification

# ==================== REMOVE LOGGING IN RELEASE ====================
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
}

# ==================== AWESOME NOTIFICATIONS ====================
-keep class me.carda.awesome_notifications.** { *; }
-keep class me.carda.awesome_notifications_core.** { *; }

# ==================== SUPPRESS WARNINGS ====================
-dontwarn com.google.android.gms.**
-dontwarn com.google.firebase.**
-dontwarn io.flutter.**
