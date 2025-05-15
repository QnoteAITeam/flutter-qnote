import java.util.Properties
import java.io.FileInputStream

val dotenv = Properties().apply {
    val envFile = File(rootProject.projectDir.parentFile, ".env") // flutter_qnote/.env
    println("🔍 Loading .env from: ${envFile.absolutePath}")
    load(FileInputStream(envFile))
}

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = dotenv["PAGE"] as String;
    compileSdk = flutter.compileSdkVersion
    // ndkVersion = flutter.ndkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = dotenv["PAGE"] as String
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        manifestPlaceholders.put("KAKAO_NATIVE_APP_KEY", dotenv["KAKAO_NATIVE_APP_KEY"] as String)
        manifestPlaceholders.put("PAGE", dotenv["PAGE"] as String)
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
