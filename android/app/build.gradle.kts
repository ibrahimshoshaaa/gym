plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.shosha.gym_manager"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    // مفتاح توقيع ثابت (debug.keystore) محفوظ جوه المشروع نفسه - عشان كل
    // build يطلع من GitHub Actions يتوقع بنفس المفتاح بالظبط. قبل كده كل
    // build كان بيستخدم مفتاح debug افتراضي بيتولد جديد على كل CI runner
    // (لأنه مؤقت ومش موجود على القرص أصلاً)، فكل نسخة APK كانت بتوقيعها
    // مختلف عن اللي قبلها - يعني أندرويد كان بيشوفها "برنامج مختلف"، فلو
    // ثبتّها فوق نسخة قديمة كان بيمسح كل بيانات التطبيق (بما فيها جلسة
    // تسجيل الدخول المحفوظة)، وده كان سبب "بيطلب دخول من جديد كل مرة".
    // دلوقتي بما إن المفتاح ثابت، أي تحديث APK هيتعامل معاه أندرويد
    // كـ"ترقية" عادية ويحافظ على بيانات التطبيق وجلسة الدخول.
    signingConfigs {
        create("debugFixed") {
            storeFile = file("debug.keystore")
            storePassword = "android"
            keyAlias = "androiddebugkey"
            keyPassword = "android"
        }
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
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // بنستخدم المفتاح الثابت اللي عرفناه فوق (debugFixed) بدل
            // debug العادي - عشان التوقيع يفضل ثابت بين كل الـ builds
            signingConfig = signingConfigs.getByName("debugFixed")
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
