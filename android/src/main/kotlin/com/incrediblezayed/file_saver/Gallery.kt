package com.incrediblezayed.file_saver

import android.Manifest
import android.content.ContentValues
import android.content.Context
import android.content.pm.PackageManager
import android.media.MediaScannerConnection
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import androidx.annotation.RequiresApi
import java.io.FileInputStream
import java.io.FileOutputStream
import java.io.InputStream

/** Saves images and videos into the device gallery. */
class Gallery(private val context: Context) {

    /** Returns the MediaStore URI (API 29+) or the file path (older) of the saved item. */
    fun save(request: SaveRequest): String {
        val type = request.mimeType
        val isVideo = type.startsWith("video/")
        if (!isVideo && !type.startsWith("image/")) {
            throw IllegalArgumentException(
                "saveToGallery only accepts image/* or video/* mime types, got '$type'"
            )
        }

        val name = FileNames.withExtension(request)
        val sourcePath = request.sourcePath
        val bytes = request.bytes
        val album = request.album
        val directory = if (isVideo) Environment.DIRECTORY_MOVIES else Environment.DIRECTORY_PICTURES
        val albumName = album?.trim()?.takeIf { it.isNotEmpty() }?.let(FileNames::sanitizeFileName)
        val open: () -> InputStream = {
            if (sourcePath != null) {
                FileInputStream(sourcePath)
            } else {
                (bytes ?: throw IllegalArgumentException("bytes is null")).inputStream()
            }
        }

        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            insertWithMediaStore(name, type, isVideo, directory, albumName, open)
        } else {
            writeToPublicDirectory(name, type, directory, albumName, open)
        }
    }

    @RequiresApi(Build.VERSION_CODES.Q)
    private fun insertWithMediaStore(
        name: String,
        type: String,
        isVideo: Boolean,
        directory: String,
        album: String?,
        open: () -> InputStream
    ): String {
        val resolver = context.contentResolver
        val collection = if (isVideo) {
            MediaStore.Video.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
        } else {
            MediaStore.Images.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
        }
        val values = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, name)
            put(MediaStore.MediaColumns.MIME_TYPE, type)
            put(
                MediaStore.MediaColumns.RELATIVE_PATH,
                if (album == null) directory else "$directory/$album"
            )
            put(MediaStore.MediaColumns.IS_PENDING, 1)
        }
        val uri = resolver.insert(collection, values)
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
        album: String?,
        open: () -> InputStream
    ): String {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M &&
            context.checkSelfPermission(Manifest.permission.WRITE_EXTERNAL_STORAGE) !=
            PackageManager.PERMISSION_GRANTED
        ) {
            throw SecurityException(
                "WRITE_EXTERNAL_STORAGE must be granted to save to the gallery on Android 9 and below"
            )
        }
        var target = Environment.getExternalStoragePublicDirectory(directory)
        if (album != null) {
            target = FileNames.safeChild(target, album)
        }
        if (!target.exists() && !target.mkdirs()) {
            throw IllegalStateException("Unable to create ${target.path}")
        }
        val file = FileNames.safeChild(target, name)
        FileOutputStream(file).use { output ->
            open().use { input -> input.copyTo(output) }
        }
        MediaScannerConnection.scanFile(context, arrayOf(file.absolutePath), arrayOf(type), null)
        return file.absolutePath
    }
}
