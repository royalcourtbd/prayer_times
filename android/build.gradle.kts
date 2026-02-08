allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
buildscript {
    extra.apply {
        val androidSdkPath = System.getenv("ANDROID_HOME") ?: System.getenv("ANDROID_SDK_ROOT") ?: ""
        val ndkDir = File("$androidSdkPath/ndk")
        
        set(
            "ndkVersion",
            if (ndkDir.exists() && ndkDir.isDirectory) {
                ndkDir.listFiles()
                    ?.filter { dir -> dir.name.matches(Regex("\\d+\\.\\d+\\.\\d+.*")) }
                    ?.map { dir -> 
                        val parts = dir.name.split(".")
                        Triple(
                            parts.getOrNull(0)?.toIntOrNull() ?: 0,
                            parts.getOrNull(1)?.toIntOrNull() ?: 0,
                            dir.name
                        )
                    }
                    ?.maxByOrNull { (major, minor, _) -> major * 1000 + minor }
                    ?.third ?: "27.0.12077973"
            } else {
                "27.0.12077973"
            }
        )
    }
}