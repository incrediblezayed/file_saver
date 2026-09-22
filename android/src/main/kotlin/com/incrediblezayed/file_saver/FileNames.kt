package com.incrediblezayed.file_saver

import java.io.File

/** File name sanitising shared by the save, save-as and gallery flows. */
internal object FileNames {
    private val invalidCharacters = Regex("[\\\\/:*?\"<>|\\p{Cntrl}]")

    fun sanitizeFileName(fileName: String?): String {
        val safeName = File(fileName ?: "file").name
            .replace(invalidCharacters, "_")
            .trim()
        return if (safeName.isBlank() || safeName == "." || safeName == "..") {
            "file"
        } else {
            safeName
        }
    }

    fun sanitizeExtension(extension: String?): String {
        val safeExtension = extension.orEmpty()
            .trim()
            .trimStart('.')
            .replace(invalidCharacters, "_")
        return if (safeExtension.isEmpty()) "" else ".$safeExtension"
    }

    /** `name.ext` for a request, or just the sanitised name when the extension is off. */
    fun withExtension(request: SaveRequest): String {
        var name = sanitizeFileName(request.name)
        if (request.includeExtension) {
            name += sanitizeExtension(request.fileExtension)
        }
        return name
    }

    /** Resolves [fileName] under [parent] and refuses anything that escapes it. */
    fun safeChild(parent: File, fileName: String): File {
        val file = File(parent, fileName)
        val parentPath = parent.canonicalPath + File.separator
        if (!file.canonicalPath.startsWith(parentPath)) {
            throw SecurityException("Invalid file name")
        }
        return file
    }
}
