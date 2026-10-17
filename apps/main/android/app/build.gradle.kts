import java.util.Properties

// Load signing properties from key.properties if it exists.
// Do NOT commit key.properties or the keystore file to version control.
val keyPropsFile = rootProject.file("key.properties")
val keyProps = Properties().apply {
    if (keyPropsFile.exists()) keyPropsFile.inputStream().use { load(it) }
}

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    // The Flutter Gradle Plugin must be applied after the Android Gradle plugin.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "id.rmq.app_main"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    signingConfigs {
        create("release") {
            keyAlias = keyProps["keyAlias"] as String? ?: ""
            keyPassword = keyProps["keyPassword"] as String? ?: ""
            storeFile = (keyProps["storeFile"] as String?)?.let { file(it) }
            storePassword = keyProps["storePassword"] as String? ?: ""
        }
    }

    defaultConfig {
        // TODO: Replace with your project's application ID before publishing.
        applicationId = "id.rmq.main"
        minSdk = 24
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Uses release signing when key.properties is present;
            // falls back to debug signing for local dev convenience.
            signingConfig = if (keyPropsFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

kotlin {
    compilerOptions {
        // Samakan dengan compileOptions (17). Tanpa ini Kotlin mengikuti JDK yang
        // menjalankan Gradle (mis. JBR 21 Android Studio) → "Inconsistent JVM Target".
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
    }
}

flutter {
    source = "../.."
}
