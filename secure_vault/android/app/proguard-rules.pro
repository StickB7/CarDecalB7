# Flutter wrapper
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep encryption-related classes (pointycastle / conscrypt)
-keep class org.bouncycastle.** { *; }
-keep class org.conscrypt.** { *; }

# flutter_secure_storage
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# local_auth biometric
-keep class androidx.biometric.** { *; }

# Keep app model classes
-keepclassmembers class com.securevault.app.** { *; }
