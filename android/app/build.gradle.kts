plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    // Namespace matches your application ID for consistency
    namespace = "com.vishal.doc_app"
    
    // 🔥 "Universal" approach: Flutter settings use karein, 
    // par plugins ki wajah se 36 se kam nahi hona chahiye.
    compileSdk = 36 
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.vishal.doc_app"
        
        // 🔥 Local Auth aur Google Drive sync ke liye 23 (Android 6.0) base stable version hai
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // Enabled for compatibility with many dependencies
        multiDexEnabled = true
    }

    buildTypes {
        getByName("debug") {
            isMinifyEnabled = false
            isShrinkResources = false
        }
        
        getByName("release") {
            // Debug key usage for local testing
            signingConfig = signingConfigs.getByName("debug")
            
            // App size optimization (Universal standard)
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

dependencies {
    // Multidex for older Android compatibility
    implementation("androidx.multidex:multidex:2.0.1")
    
    // Stable Core-KTX for modern plugin support
    implementation("androidx.core:core-ktx:1.13.1")
}

flutter {
    source = "../.."
}
