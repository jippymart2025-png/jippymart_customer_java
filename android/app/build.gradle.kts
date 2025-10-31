plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.jippymart.customer"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.jippymart.customer"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }
    signingConfigs {
        create("release") {
            storeFile = file("jippy_mart_keystore.jks")
            storePassword = "Jippy@2024"
            keyAlias = "jippy_mart"
            keyPassword = "Jippy@2024"
        }
    }
    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("release")
        }
    }
}
dependencies {
    // ✅ Core Android dependencies
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation("com.google.android.material:material:1.11.0")

//    implementation 'androidx.multidex:multidex:2.0.1'
//    implementation 'com.google.android.material:material:1.11.0'
//
//    // ✅ Firebase dependencies
//    implementation platform('com.google.firebase:firebase-bom:32.7.0')
//    implementation 'com.google.firebase:firebase-analytics'
//    implementation 'com.google.firebase:firebase-auth'
//
//    // ✅ Google Play Services
//    implementation 'com.google.android.gms:play-services-maps:18.2.0'
//    implementation 'com.google.android.gms:play-services-base:18.3.0'
//    implementation 'com.google.android.gms:play-services-auth:20.7.0'
//    implementation 'com.google.android.gms:play-services-auth-api-phone:18.0.2'
//    implementation 'com.google.android.gms:play-services-wallet:19.4.0'
//    implementation 'com.google.android.play:integrity:1.3.0'
//
//    // ✅ Payment and third-party SDKs
//    implementation 'io.card:android-sdk:5.5.1'
//    implementation 'com.tencent.mm.opensdk:wechat-sdk-android-without-mta:6.7.0'
//
//    // ✅ Explicitly exclude SafetyNet to prevent deprecation warnings
//    configurations.all {
//        exclude group: 'com.google.android.gms', module: 'play-services-safetynet'
//    }
}

flutter {
    source = "../.."
}
