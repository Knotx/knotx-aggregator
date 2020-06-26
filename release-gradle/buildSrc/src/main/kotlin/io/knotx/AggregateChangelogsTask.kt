package io.knotx

import com.mitchellbosecke.pebble.PebbleEngine
import org.gradle.api.DefaultTask
import org.gradle.api.GradleException
import org.gradle.api.tasks.Input
import org.gradle.api.tasks.TaskAction
import java.io.File
import java.io.StringWriter
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter

open class AggregateChangelogsTask : DefaultTask() {

    @Input
    open lateinit var repositories: List<String>

    @Input
    open lateinit var version: String

    @TaskAction
    fun execute() {
        val properties = mapOf<String, Any?>(
                "version" to version,
                "releaseType" to version.substringAfterLast(".") == "0" ? "minor" : "patch",
                "releaseDate" to LocalDateTime.now(),
                "repositories" to buildRepositoriesChangelogs()
        )

        val websiteRenderDir = "${project.buildDir}/knotx-website/src/render"
        saveFileFromTemplate("templates/releaseNotes.html.md", properties, "$websiteRenderDir/blog", "release-${version.replace(".", "_")}.html.md")
        saveFileFromTemplate("templates/download.html", properties, websiteRenderDir, "download.html")
        saveFileFromTemplate("templates/index.html.eco", properties, websiteRenderDir, "index.html.eco")
    }

    private fun saveFileFromTemplate(template: String, properties: Map<String, Any?>, fileDir: String, fileName: String) {
        File(fileDir).mkdirs()
        val content = StringWriter()
        TEMPLATE_ENGINE.getTemplate(template).evaluate(content, properties)
        File("$fileDir/$fileName").writeText(content.toString())
    }

    private fun buildRepositoriesChangelogs(): ArrayList<Map<String, Any?>> {
        val repositoriesChangelogs = ArrayList<Map<String, Any?>>()
        repositories.forEach { repoName ->
            val changelogFilePath = "${project.buildDir}/$repoName/$CHANGELOG_FILE_NAME"
            val changelog = getChangelogFile(changelogFilePath)
            val repoProps = mapOf<String, Any?>(
                    "name" to repoName,
                    "title" to repoName.split("-").joinToString(" ", transform = String::capitalize).replace("Knotx", "Knot.x"),
                    "changes" to readChanges(changelog)
            )
            repositoriesChangelogs.add(repoProps)
        }
        return repositoriesChangelogs
    }

    private fun readChanges(changelog: File): List<String> {
        var progress = ChangelogSearchProgress.NOT_FOUND
        val entries = ArrayList<String>()
        val versionTitleRegex = Regex("## $version")

        changelog.forEachLine { line ->
            when {
                versionTitleRegex.matches(line) -> {
                    progress = ChangelogSearchProgress.READING
                }
                progress == ChangelogSearchProgress.READING -> {
                    entries.add(line)
                    if (line.isBlank()) {
                        progress = ChangelogSearchProgress.FINISHED
                    }
                }
            }
        }
        return if (noChanges(entries)) {
            arrayListOf("No important changes in this version.", entries[0])
        } else {
            entries
        }
    }

    private fun noChanges(entries: ArrayList<String>) = entries.size == 1

    private fun getChangelogFile(changelogFilePath: String): File {
        val file = File(changelogFilePath)
        logger.lifecycle("Reading $changelogFilePath")
        if (!file.exists()) {
            throw GradleException("Missing changelog file at `$changelogFilePath`!")
        }

        return file
    }

    companion object {
        const val CHANGELOG_FILE_NAME = "CHANGELOG.md"

        private val FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd")
        private val TEMPLATE_ENGINE = PebbleEngine.Builder()
                .autoEscaping(false)
                .newLineTrimming(false)
                .build()

        enum class ChangelogSearchProgress {
            NOT_FOUND, READING, FINISHED
        }
    }
}