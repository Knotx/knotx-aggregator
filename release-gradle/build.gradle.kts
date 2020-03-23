plugins {
    `knotx-release-notes-plugin`
}

val VERSION = project.findProperty("releaseVersion")?.toString() ?: "2.2.0-RC1"
val NEXT_VERSION = project.findProperty("nextVersion")?.toString() ?: "2.2.1-SNAPSHOT"
val RELEASE_BRANCH = project.findProject("branch")?.toString() ?: "master"
val DRY_RUN = project.findProperty("dryRun")?.toString()?.toBoolean() ?: false

val WEBSITE = "Knotx/knotx-website"
val TO_RELEASE = setOf(
        "Knotx/knotx-dependencies",
        "Knotx/knotx-commons",
        "Knotx/knotx-launcher",
        "Knotx/knotx-junit5",
        "Knotx/knotx-server-http",
        "Knotx/knotx-repository-connector",
        "Knotx/knotx-fragments",
        "Knotx/knotx-template-engine",
        "Knotx/knotx-stack",
        "Knotx/knotx-docker",
        "Knotx/knotx-starter-kit"
)

tasks {

    /**
     * PREPARE
     */

    register("setup") {
        group = "prepare"
        doFirst {
            justLog("INFO", "root", "Cleaning $buildDir")
            delete(buildDir)
            mkdir(buildDir)
        }
    }

    register("cloneProjects") {
        group = "prepare"
        dependsOn("setup")
        doLast {
            TO_RELEASE.forEach { repo ->
                justLog("INFO", project.buildDir.path, "cloning $repo")
                exec {
                    workingDir = project.buildDir
                    commandLine = "git clone git@github.com:$repo.git".split(" ")
                }
                if (RELEASE_BRANCH != "master") {
                    justLog("INFO", project.buildDir.path, "switching to $RELEASE_BRANCH")
                    exec {
                        workingDir = repositoryWorkingDir(repo)
                        commandLine = "git checkout $RELEASE_BRANCH".split(" ")
                    }
                }
            }
        }
    }

    register("prepareProjects") {
        group = "prepare"
        dependsOn("cloneProjects")
        doLast {
            TO_RELEASE.forEach { repo ->
                execOnRepo(repo, "sh gradlew prepare -Pversion=${VERSION} -Pknotx.version=${VERSION} --rerun-tasks")
            }
        }
    }

    register("savePreparation") {
        group = "prepare"
        dependsOn("prepareProjects")

        doLast {
            TO_RELEASE.forEach { repo ->
                execOnRepo(repo, "git add -A")
                execOnRepo(repo, listOf("git", "commit", "-m", "Releasing ${VERSION}"))
                execOnRepo(repo, "git tag ${VERSION}")
            }
        }
    }

    /**
     * CLOSE
     */

    register("setNextDevVersion") {
        group = "close release"
        doLast {
            TO_RELEASE.forEach { repo ->
                execOnRepo(repo, "sh gradlew setVersion -Pversion=${NEXT_VERSION} -Pknotx.version=${NEXT_VERSION}")
                execOnRepo(repo, "git add -A")
                execOnRepo(repo, listOf("git", "commit", "-m", "Setting next development version to ${NEXT_VERSION}"))
            }
        }
    }

    register("pushChanges") {
        group = "close release"
        dependsOn("setNextDevVersion")
        doLast {
            TO_RELEASE.forEach { repo ->
                execOnRepo(repo, "git push origin $VERSION")
                execOnRepo(repo, "git push")
            }
        }
    }

    register("githubRelease") {
        group = "close release"
        dependsOn("pushChanges")
        mustRunAfter("publish")
        doLast {
            TO_RELEASE.forEach { repo ->
                justLog("TODO", repo, "releasing on GitHub")
            }
        }
    }

    // Website Release Notes
    register("cloneWebsiteRepo") {
        group = "release notes"
        doLast {
            exec {
                workingDir = project.buildDir
                commandLine = "git clone git@github.com:${WEBSITE}.git".split(" ")
            }
        }
    }

    register<io.knotx.AggregateChangelogsTask>("aggregateChanges") {
        group = "release notes"
        repositories = TO_RELEASE.map { s -> s.substringAfter("/") }
        version = VERSION
        dependsOn("cloneWebsiteRepo")
    }

    register("websiteReleaseNotes") {
        group = "release notes"
        dependsOn("aggregateChanges")
        mustRunAfter("publish")
        doLast {
            val repo = "knotx-website"
            execOnRepo(repo, "git checkout -b release/${VERSION}")
            execOnRepo(repo, "git add -A")
            execOnRepo(repo, listOf("git", "commit", "-m", "Release notes for release ${VERSION}"))
            execOnRepo(repo, "git push -u origin release/${VERSION}")
        }
    }

    /**
     * RELEASE TASKS
     */

    register("info") {
        group = "release"
        doFirst {
            logger.lifecycle("Starting release!")
            logger.lifecycle("VERSION='$VERSION'\nNEXT_VERSION='$NEXT_VERSION'\nDRY_RUN=$DRY_RUN\n")
            logger.lifecycle("Repositories: \nWebsite='$WEBSITE'\nTo release:\n${TO_RELEASE.joinToString("\n", transform = { s -> "  - $s" })}")

        }
    }

    register("prepare") {
        group = "release"
        dependsOn("info", "savePreparation")
    }

    register("publish") {
        group = "release"
        dependsOn("prepare")
        doLast {
            TO_RELEASE.forEach { repo ->
                execOnRepo(repo, "sh gradlew publishArtifacts -Pversion=${VERSION}")
            }
        }
    }

    register("close") {
        group = "release"
        dependsOn("publish", "githubRelease", "websiteReleaseNotes")
    }

    register("release") {
        group = "release"
        dependsOn("close")
    }
}

fun repositoryWorkingDir(repo: String) =
        File("${project.buildDir.absolutePath}/${repo.substringAfter("/")}")

fun execOnRepo(repo: String, command: String) {
    execOnRepo(repo, command.split(" "))
}

fun execOnRepo(repo: String, command: List<String>) {
    if (DRY_RUN && isPersistingCommand(command)) {
        justLog("DRY RUN: ", repo, command.joinToString(" "))
    } else {
        justLog("EXEC: ", repo, command.joinToString(" "))
        exec {
            workingDir = repositoryWorkingDir(repo)
            commandLine = command
        }
    }
}

fun justLog(type: String, repo: String, message: String) {
    logger.lifecycle("[$type] $repo $> $message")
}

fun isPersistingCommand(command: List<String>) = command.contains("push")