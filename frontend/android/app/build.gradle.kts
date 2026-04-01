import java.util.Properties
import java.io.FileInputStream
import java.io.File
plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.shapepro.fitness"
    compileSdk = 36
    ndkVersion = "27.0.12077973"

    allprojects {
        tasks.withType<JavaCompile> {
            options.compilerArgs.add("-Xlint:all")
            options.compilerArgs.add("-Xlint:-serial")
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.shapepro.fitness"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 24
        targetSdk = 34 // Targeting Android 14 (Stable from yesterday)
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    lint {
        checkReleaseBuilds = false
        abortOnError = false
    }

    signingConfigs {
        create("release") {
            val keystorePropertiesFile = rootProject.file("key.properties")
            val keystoreProperties = Properties()
            if (keystorePropertiesFile.exists()) {
                keystoreProperties.load(FileInputStream(keystorePropertiesFile))
            }

            val keyAliasStr = keystoreProperties["keyAlias"]?.toString()
            val keyPasswordStr = keystoreProperties["keyPassword"]?.toString()
            val storePasswordStr = keystoreProperties["storePassword"]?.toString()
            val storeFileStr = keystoreProperties["storeFile"]?.toString()

            if (keyAliasStr != null) keyAlias = keyAliasStr
            if (keyPasswordStr != null) keyPassword = keyPasswordStr
            if (storePasswordStr != null) storePassword = storePasswordStr
            if (storeFileStr != null) storeFile = rootProject.file(storeFileStr)
        }
    }

    packaging {
        jniLibs {
            useLegacyPackaging = true
        }
    }

    buildTypes {
        release {
            // Signing with the release keys for the official App Store version.
            signingConfig = signingConfigs.getByName("release")
            
            // Optimization for production
            isMinifyEnabled = false
            isShrinkResources = false
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
            
            ndk {
                debugSymbolLevel = "SYMBOL_TABLE"
            }
        }
    }
}

flutter {
    source = "../.."
}
