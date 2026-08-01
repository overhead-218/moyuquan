pluginManagement {
    val flutterSdkPath: String = (System.getenv("FLUTTER_ROOT")
        ?: run {
            // 兼容本地 Windows：使用当前 settings.gradle.kts 所在项目向上回退到 flutter SDK
            // 本项目假定 flutter checkout 与当前仓库同级，即 ../flutter
            val candidate = file("../flutter/packages/flutter_tools/gradle").absolutePath
            if (java.io.File(candidate).exists()) candidate
            else "C:\\Dev\\flutter"
        })

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "9.0.1" apply false
    id("org.jetbrains.kotlin.android") version "2.3.20" apply false
}

include(":app")