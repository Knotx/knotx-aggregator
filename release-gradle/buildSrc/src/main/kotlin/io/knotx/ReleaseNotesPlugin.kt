package io.knotx

import org.gradle.api.Plugin
import org.gradle.api.Project
import org.gradle.kotlin.dsl.invoke
import org.gradle.kotlin.dsl.register

class ReleaseNotesPlugin : Plugin<Project> {

    override fun apply(project: Project) {
        with(project) {
            tasks {
//                register<AggregateChangelogsTask>("aggregateChanges") {
//                    group = "release prepare"
//                }
            }
        }
    }

}