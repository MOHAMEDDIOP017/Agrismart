plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services") 
}

android {
    namespace = "com.agritech.agritech"
    compileSdk = 36
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.agritech.agritech"
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // 🔥 Firebase BoM (gestion des versions automatique)
    implementation(platform("com.google.firebase:firebase-bom:34.12.0"))

    // 🔑 Authentification Firebase
    implementation("com.google.firebase:firebase-auth")

    // ☁️ Firestore (si tu l’utilises)
    implementation("com.google.firebase:firebase-firestore")

    // 🔔 Notifications (optionnel)
    implementation("com.google.firebase:firebase-messaging")
}