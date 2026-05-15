plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.vpnsc.client"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    flavorDimensions += "platform"

    productFlavors {
        create("mobile") {
            dimension = "platform"
            applicationId = "com.vpnsc.client"
            resValue("string", "app_name", "VPN-SC")
        }
        create("tv") {
            dimension = "platform"
            applicationId = "com.vpnsc.client.tv"
            resValue("string", "app_name", "VPN-SC TV")
        }
    }

    defaultConfig {
        minSdk = flutter.minSdkVersion
        targetSdk = 35
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
