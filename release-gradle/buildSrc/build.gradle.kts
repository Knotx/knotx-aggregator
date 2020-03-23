plugins {
    `kotlin-dsl`
}

repositories {
    jcenter()
}

dependencies {
    implementation("io.pebbletemplates:pebble:3.1.2")
}

gradlePlugin {
    plugins {
        register("knotx-release-notes-plugin") {
            id = "knotx-release-notes-plugin"
            implementationClass = "io.knotx.ReleaseNotesPlugin"
        }
    }
}

