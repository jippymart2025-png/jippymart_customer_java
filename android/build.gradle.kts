allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
    
    // Fix for facebook_app_events plugin compilation error
    configurations.all {
        resolutionStrategy {
            force("com.facebook.android:facebook-android-sdk:16.3.0")
            
            // 🔑 CRITICAL: Resolve Razorpay SDK version conflicts
            // This ensures all Razorpay dependencies use a compatible version
            // that includes the logFunctionEntry method (available in 1.6.20+)
            // ✅ UPDATED: Using latest version 1.6.36+ which may have Android 14+ fixes
            eachDependency {
                if (requested.group == "com.razorpay" && requested.name == "checkout") {
                    // Try latest version that might have Android 14+ broadcast receiver fix
                    // Version 1.6.36+ may include fixes for RECEIVER_EXPORTED issue
                    useVersion("1.6.36")
                    because("Fix Android 14+ RECEIVER_EXPORTED SecurityException and NoSuchMethodError")
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
