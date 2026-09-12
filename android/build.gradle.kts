allprojects {
    repositories {
        google()
        mavenCentral()
        maven("https://storage.googleapis.com/download.flutter.io")
    }
    configurations.all {
        resolutionStrategy.eachDependency {
            if (requested.group == "io.flutter" && requested.name.endsWith("_debug")) {
                if (requested.version == "1.0.0-315ff242617023c1c5549878bf17fad51ffec6f3") {
                    useVersion("1.0.0-a804b261645ef8c13eb3d5c44a5c2fb0340c5539")
                }
            }
        }
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
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
