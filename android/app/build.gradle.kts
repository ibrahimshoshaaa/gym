plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.shosha.gym_manager"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    val releaseKey = file("release.jks")
    val hasReleaseKey = releaseKey.exists() && System.getenv("ANDROID_STORE_PASSWORD") != null
    signingConfigs {
        if (hasReleaseKey) {
            create("privateRelease") {
                storeFile = releaseKey
                storePassword = System.getenv("ANDROID_STORE_PASSWORD")
                keyAlias = System.getenv("ANDROID_KEY_ALIAS")
                keyPassword = System.getenv("ANDROID_KEY_PASSWORD")
            }
        }
    }
    if (gradle.startParameter.taskNames.any { it.contains("Release", ignoreCase = true) }) {
        require(hasReleaseKey || System.getenv("ALLOW_UNSIGNED_RELEASE") == "1") { "Release builds require a private key, or explicit ALLOW_UNSIGNED_RELEASE=1 for offline signing" }
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.shosha.gym_manager"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // mobile_scanner 7.x (CameraX الحديثة) محتاج minSdk 23 على الأقل -
        // بنحددها صراحة بدل ما نسيبها على قيمة فلاتر الافتراضية اللي ممكن
        // تكون أقل من كده
        minSdk = 23
        multiDexEnabled = true
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            if (hasReleaseKey) signingConfig = signingConfigs.getByName("privateRelease")

            // ✅ تصغير الكود وحذف اللي مش محتاجه
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}


dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
