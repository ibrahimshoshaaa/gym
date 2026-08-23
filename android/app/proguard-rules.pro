# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Flutter Play Store Split (R8 missing classes fix)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Firestore
-keep class com.google.firestore.** { *; }
-dontwarn com.google.firestore.**

# Firebase Messaging
-keep class com.google.firebase.messaging.** { *; }

# local_auth (Biometric)
-keep class androidx.biometric.** { *; }
-dontwarn androidx.biometric.**

# mobile_scanner / CameraX
-keep class androidx.camera.** { *; }
-dontwarn androidx.camera.**

# share_plus
-keep class androidx.core.content.FileProvider { *; }

# printing / pdf
-keep class com.github.barteksc.** { *; }

# Keep model classes (Dart ↔ Java bridge)
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes Exceptions
