import java.util.Properties

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// --- Signature de release ---------------------------------------------------
// Si `android/key.properties` existe (copier key.properties.example), la release
// est signee avec VOTRE cle. Sinon on retombe sur la cle debug, ce qui permet a
// `flutter build apk --release` de fonctionner quand meme (tests / partage).
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseKeystore = keystorePropertiesFile.exists()
val keystoreProperties = Properties()
if (hasReleaseKeystore) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}

android {
    namespace = "com.mariageplus.mariageplus_app"
    // API 36 = valeur par défaut de cette version de Flutter. On évite l'API 37 :
    // le SDK local ne l'expose que comme « platforms;android-37.0 » (nouveau schéma
    // « minor version » d'Android 17) et AGP 9.0.1, en DSL hérité (android.newDsl=false),
    // cherche « android-37 » puis échoue avec :
    //   Failed to find target with hash string 'android-37' in: C:\Android\Sdk
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.mariageplus.mariageplus_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Cle de release si `android/key.properties` existe, sinon cle debug
            // (ainsi `flutter build apk --release` fonctionne dans tous les cas).
            signingConfig =
                if (hasReleaseKeystore) {
                    signingConfigs.getByName("release")
                } else {
                    signingConfigs.getByName("debug")
                }
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
