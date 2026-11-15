pluginManagement {
    val flutterSdkPath: String = run {
        val env = System.getenv("FLUTTER_ROOT")
        if (env != null) env else "../"
    }
    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    // ⚠️ 版本必须满足 Flutter 3.44.8 的最低要求，否则构建直接失败：
    //    "Your project's Android Gradle Plugin version (9.0.1) is lower than
    //     Flutter's minimum supported version of 9.1.1"
    //    Flutter 的 maxKnownAndSupportedAgpVersion = 9.1
    id("com.android.application") version "9.1.1" apply false
    id("org.jetbrains.kotlin.android") version "2.3.20" apply false
}

include(":app")
