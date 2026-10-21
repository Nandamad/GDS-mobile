    plugins {
        id("com.android.application")
        id("kotlin-android")
        id("dev.flutter.flutter-gradle-plugin")
    }

    val releaseStoreFilePath = providers.gradleProperty("RELEASE_STORE_FILE")
        .orElse(providers.environmentVariable("RELEASE_STORE_FILE"))
        .orNull
    val releaseStorePassword = providers.gradleProperty("RELEASE_STORE_PASSWORD")
        .orElse(providers.environmentVariable("RELEASE_STORE_PASSWORD"))
        .orNull
    val releaseKeyAlias = providers.gradleProperty("RELEASE_KEY_ALIAS")
        .orElse(providers.environmentVariable("RELEASE_KEY_ALIAS"))
        .orNull
    val releaseKeyPassword = providers.gradleProperty("RELEASE_KEY_PASSWORD")
        .orElse(providers.environmentVariable("RELEASE_KEY_PASSWORD"))
        .orNull
    val releaseSigningValues = mapOf(
        "RELEASE_STORE_FILE" to releaseStoreFilePath,
        "RELEASE_STORE_PASSWORD" to releaseStorePassword,
        "RELEASE_KEY_ALIAS" to releaseKeyAlias,
        "RELEASE_KEY_PASSWORD" to releaseKeyPassword,
    )
    val hasReleaseSigningValues = releaseSigningValues.values.any { !it.isNullOrBlank() }
    val hasCompleteReleaseSigning = releaseSigningValues.values.all { !it.isNullOrBlank() }

    val validateReleaseSigning = tasks.register("validateReleaseSigning") {
        doLast {
            val missingValues = releaseSigningValues
                .filterValues { it.isNullOrBlank() }
                .keys

            check(!hasReleaseSigningValues || missingValues.isEmpty()) {
                "Release signing is not configured. Provide: ${missingValues.joinToString()}"
            }
            check(!hasCompleteReleaseSigning || file(requireNotNull(releaseStoreFilePath)).isFile) {
                "Release keystore file does not exist: $releaseStoreFilePath"
            }
        }
    }

    android {
        namespace = "com.example.mobile"
        compileSdk = 36

        ndkVersion = "28.2.13676358"

        compileOptions {
            isCoreLibraryDesugaringEnabled = true
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
            versionCode = flutter.versionCode
            versionName = flutter.versionName
        }

        signingConfigs {
            create("release") {
                if (releaseStoreFilePath != null) {
                    storeFile = file(releaseStoreFilePath)
                }
                if (releaseStorePassword != null) {
                    storePassword = releaseStorePassword
                }
                if (releaseKeyAlias != null) {
                    keyAlias = releaseKeyAlias
                }
                if (releaseKeyPassword != null) {
                    keyPassword = releaseKeyPassword
                }
            }
        }

        buildTypes {
            release {
                signingConfig = signingConfigs.getByName(
                    if (hasCompleteReleaseSigning) "release" else "debug",
                )
            }
        }

        applicationVariants.all {
            outputs.all {
                (this as com.android.build.gradle.internal.api.BaseVariantOutputImpl).outputFileName = "PresensiPlus_v${versionName}.apk"
            }
        }
        // ----------------------------------
    }

    tasks.matching {
        it.name == "assembleRelease" ||
            it.name == "bundleRelease" ||
            it.name == "packageRelease"
    }.configureEach {
        dependsOn(validateReleaseSigning)
    }

    tasks.withType<JavaCompile>().configureEach {
        options.compilerArgs.add("-Xlint:-options")
    }

    flutter {
        source = "../.."
    }

    dependencies {
        coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    }