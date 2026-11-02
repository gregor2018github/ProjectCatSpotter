import java.util.Base64
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // Flutter Gradle Plugin must be applied after Android and Kotlin plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing: keystore.properties (local) or env vars (CI).
// Local: android/keystore.properties with storeFile, storePassword, keyAlias, keyPassword.
// CI: KEYSTORE_BASE64 (decoded to a temp file), KEYSTORE_PASSWORD, KEY_ALIAS, KEY_PASSWORD.
val keystorePropertiesFile = rootProject.file("keystore.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) keystorePropertiesFile.inputStream().use { load(it) }
}
val releaseStoreFile: File? = when {
    keystoreProperties.getProperty("storeFile") != null ->
        file(keystoreProperties.getProperty("storeFile"))
    System.getenv("KEYSTORE_BASE64") != null ->
        layout.buildDirectory.file("release.jks").get().asFile.apply {
            parentFile.mkdirs()
            writeBytes(Base64.getMimeDecoder().decode(System.getenv("KEYSTORE_BASE64")))
        }
    else -> null
}
fun signingValue(propKey: String, envKey: String): String? =
    keystoreProperties.getProperty(propKey) ?: System.getenv(envKey)

// Version: CI passes VERSION_NAME / VERSION_CODE (derived from the git tag);
// locally falls back to the version in pubspec.yaml.
val appVersionName = System.getenv("VERSION_NAME") ?: flutter.versionName
val appVersionCode = System.getenv("VERSION_CODE")?.toInt() ?: flutter.versionCode

android {
    namespace = "com.example.cat_spotter"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.example.cat_spotter"
        // Pixel 6 (Android 12) and Galaxy A56 (Android 15) both meet this minimum.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = appVersionCode
        versionName = appVersionName
    }

    signingConfigs {
        if (releaseStoreFile != null) {
            create("release") {
                storeFile = releaseStoreFile
                storePassword = signingValue("storePassword", "KEYSTORE_PASSWORD")
                keyAlias = signingValue("keyAlias", "KEY_ALIAS")
                keyPassword = signingValue("keyPassword", "KEY_PASSWORD")
            }
        }
    }

    buildTypes {
        release {
            // No minify / R8 shrinking.
            isMinifyEnabled = false
            isShrinkResources = false
            signingConfig = when {
                releaseStoreFile != null -> signingConfigs.getByName("release")
                System.getenv("CI") != null ->
                    throw GradleException("Release keystore missing: set KEYSTORE_BASE64 etc. in CI")
                // No keystore locally: fall back to debug signing so `flutter run --release` still works.
                else -> signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}
