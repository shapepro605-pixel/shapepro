import java.util.Properties
import java.io.FileInputStream
import java.io.File
plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.shapepro.fitness"
    compileSdk = 36 // Required for latest CameraX
    ndkVersion = "28.2.13676358"

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    // Migrated from deprecated kotlinOptions to modern compilerOptions DSL
    // Configuration moved to the bottom of the file to ensure task availability

    defaultConfig {
        applicationId = "com.shapepro.fitness"
        minSdk = 26
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Explicitly defining ABIs to ensure universal compatibility (32-bit and 64-bit)
        ndk {
            abiFilters += listOf("armeabi-v7a", "arm64-v8a", "x86_64")
        }
    }

    lint {
        checkReleaseBuilds = false
        abortOnError = false
        quiet = true
        ignoreWarnings = true
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
            // Essential for Android 15 (16KB page size) on S25
            useLegacyPackaging = true
        }
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
    compilerOptions {
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
        freeCompilerArgs.addAll("-Xlint:all", "-Xlint:deprecation", "-Xlint:unchecked")
    }
}

// Enable Xlint for Java compilation as well
tasks.withType<JavaCompile>().configureEach {
    options.compilerArgs.addAll(listOf("-Xlint:all", "-Xlint:deprecation", "-Xlint:unchecked"))
}
