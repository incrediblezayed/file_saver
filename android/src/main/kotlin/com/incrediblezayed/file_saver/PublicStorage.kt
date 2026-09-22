package com.incrediblezayed.file_saver

import android.Manifest
import android.content.ContentValues
import android.content.Context
import android.content.pm.PackageManager
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import androidx.annotation.RequiresApi
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import java.io.InputStream

/** Writes into the shared collections: the gallery (Pictures/Movies) and Downloads. */
class PublicStorage(private val context: Context) {

    private enum class Target(val directory: String) {
        IMAGES(Environment.DIRECTORY_PICTURES),
        VIDEOS(Environment.DIRECTORY_MOVIES),
        DOWNLOADS(Environment.DIRECTORY_DOWNLOADS);

        @RequiresApi(Build.VERSION_CODES.Q)
        fun collection(): Uri = when (this) {
            IMAGES -> MediaStore.Images.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
            VIDEOS -> MediaStore.Video.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
            DOWNLOADS -> MediaStore.Downloads.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
        }
    }

    /** Images go to Pictures/, videos to Movies/, optionally inside an album. */
    fun saveToGallery(request: SaveRequest): String {
        val type = request.mimeType
        val target = when {
            type.startsWith("image/") -> Target.IMAGES
            type.startsWith("video/") -> Target.VIDEOS
            else -> throw IllegalArgumentException(
                "saveToGallery only accepts image/* or video/* mime types, got '$type'"
            )
        }
        return save(request, target)
    }

    /** Any file into Downloads/, optionally inside a subfolder. */
    fun saveToDownloads(request: SaveRequest): String = save(request, Target.DOWNLOADS)

    /** Returns the MediaStore URI (API 29+) or the file path (older) of the saved item. */
    private fun save(request: SaveRequest, target: Target): String {
        val name = FileNames.withExtension(request)
        val type = request.mimeType.ifBlank { "application/octet-stream" }
        val folder = request.folder?.trim()?.takeIf { it.isNotEmpty() }
            ?.let(FileNames::sanitizeFileName)
        val sourcePath = request.sourcePath
        val bytes = request.bytes
        val open: () -> InputStream = {
            if (sourcePath != null) {
                FileInputStream(sourcePath)
            } else {
                (bytes ?: throw IllegalArgumentException("bytes is null")).inputStream()
            }
        }

        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            insertWithMediaStore(name, type, target, folder, open)
        } else {
            writeToPublicDirectory(name, type, target.directory, folder, open)
        }
    }

    @RequiresApi(Build.VERSION_CODES.Q)
    private fun insertWithMediaStore(
        name: String,
        type: String,
        target: Target,
        folder: String?,
        open: () -> InputStream
    ): String {
        val resolver = context.contentResolver
        val values = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, name)
            put(MediaStore.MediaColumns.MIME_TYPE, type)
            put(
                MediaStore.MediaColumns.RELATIVE_PATH,
                if (folder == null) target.directory else "${target.directory}/$folder"
            )
            put(MediaStore.MediaColumns.IS_PENDING, 1)
        }
        val uri = resolver.insert(target.collection(), values)
            ?: throw IllegalStateException("MediaStore insert failed")
        try {
            resolver.openOutputStream(uri)?.use { output ->
                open().use { input -> input.copyTo(output) }
            } ?: throw IllegalStateException("Unable to open output stream")
        } catch (e: Exception) {
            resolver.delete(uri, null, null)
            throw e
        }
        values.clear()
        values.put(MediaStore.MediaColumns.IS_PENDING, 0)
        resolver.update(uri, values, null, null)
        return uri.toString()
    }

    private fun writeToPublicDirectory(
        name: String,
        type: String,
        directory: String,
        folder: String?,
        open: () -> InputStream
    ): String {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M &&
            context.checkSelfPermission(Manifest.permission.WRITE_EXTERNAL_STORAGE) !=
            PackageManager.PERMISSION_GRANTED
        ) {
            throw SecurityException(
                "WRITE_EXTERNAL_STORAGE must be granted to write to shared storage on Android 9 and below"
            )
        }
        var target = Environment.getExternalStoragePublicDirectory(directory)
        if (folder != null) {
            target = FileNames.safeChild(target, folder)
        }
        if (!target.exists() && !target.mkdirs()) {
            throw IllegalStateException("Unable to create ${target.path}")
        }
        val file = uniqueChild(target, name)
        FileOutputStream(file).use { output ->
            open().use { input -> input.copyTo(output) }
        }
        MediaScannerConnection.scanFile(context, arrayOf(file.absolutePath), arrayOf(type), null)
        return file.absolutePath
    }

    /** Mirrors MediaStore's "name (1).ext" behaviour so a second save never overwrites. */
    private fun uniqueChild(directory: File, name: String): File {
        var candidate = FileNames.safeChild(directory, name)
        if (!candidate.exists()) return candidate
        val dot = name.lastIndexOf('.')
        val base = if (dot > 0) name.substring(0, dot) else name
        val extension = if (dot > 0) name.substring(dot) else ""
        var counter = 1
        while (candidate.exists()) {
            candidate = FileNames.safeChild(directory, "$base ($counter)$extension")
            counter++
        }
        return candidate
    }
}
