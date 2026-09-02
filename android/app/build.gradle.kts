    plugins {
        id("com.android.application")
        id("kotlin-android")
        id("dev.flutter.flutter-gradle-plugin")
    }

    android {
        namespace = "com.example.mobile"
        compileSdk = 36

        ndkVersion = "28.2.13676358"

        compileOptions {
            sourceCompatibility = JavaVersion.VERSION_17
            targetCompatibility = JavaVersion.VERSION_17
        }

        kotlinOptions {
            jvmTarget = "17"
        }

        defaultConfig {
            applicationId = "com.example.mobile"
            minSdk = flutter.minSdkVersion
            targetSdk = 36
            versionCode = 1
            versionName = "1.0"
        }

        buildTypes {
            release {
                signingConfig = signingConfigs.getByName("debug")
            }
        }

        applicationVariants.all {
            outputs.all {
                (this as com.android.build.gradle.internal.api.BaseVariantOutputImpl).outputFileName = "PresensiPlus.apk"
            }
        }
        // ----------------------------------
    }

    tasks.withType<JavaCompile>().configureEach {
        options.compilerArgs.add("-Xlint:-options")
    }

    flutter {
        source = "../.."
    }