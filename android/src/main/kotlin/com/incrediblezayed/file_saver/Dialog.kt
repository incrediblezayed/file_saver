package com.incrediblezayed.file_saver

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Environment
import android.provider.DocumentsContract
import android.util.Log
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import java.io.FileInputStream
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext


private const val SAVE_FILE = 886325063

class Dialog(private val activity: Activity) : PluginRegistry.ActivityResultListener {
    private var result: MethodChannel.Result? = null
    private var bytes: ByteArray? = null
    private var sourcePath: String? = null
    private var fileName: String? = null
    private val TAG = "Dialog Activity"

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != SAVE_FILE) {
            return false
        }

        if (resultCode == Activity.RESULT_OK && data?.data != null) {
            Log.d(TAG, "Starting file operation")
            completeFileOperation(data.data!!)
        } else {
            Log.d(TAG, "Activity result was null")
            result?.success(null)
            result = null
        }

        return true
    }

    fun openFileManager(
        fileName: String?,
        fileExtension: String?,
        bytes: ByteArray?,
        sourcePath: String?,
        type: String?,
        includeExtension: Boolean?,
        result: MethodChannel.Result
    ) {
        Log.d(TAG, "Opening File Manager")
        var fileNameWithExtension = sanitizeFileName(fileName)
        if (includeExtension == true) {
            val safeExtension = sanitizeExtension(fileExtension)
            if (safeExtension.isNotEmpty()) {
                fileNameWithExtension += safeExtension
            }
        }
        this.result = result
        this.bytes = bytes
        this.sourcePath = sourcePath
        this.fileName = fileName
        val intent =
            Intent(Intent.ACTION_CREATE_DOCUMENT)
        intent.addCategory(Intent.CATEGORY_OPENABLE)
        intent.putExtra(Intent.EXTRA_TITLE, "$fileNameWithExtension")
        intent.putExtra(
            DocumentsContract.EXTRA_INITIAL_URI,
            Environment.getExternalStorageDirectory().path
        )
        intent.type = type
        activity.startActivityForResult(intent, SAVE_FILE)
    }

    private fun completeFileOperation(uri: Uri) {
        CoroutineScope(Dispatchers.IO).launch {
            try {
                saveFile(uri)
                withContext(Dispatchers.Main) {
                    result?.success(uri.toString())
                    result = null
                }
            } catch (e: SecurityException) {
                Log.d(TAG, "Security Exception while saving file" + e.message)
                withContext(Dispatchers.Main) {
                    result?.error("Security Exception", e.localizedMessage, e)
                    result = null
                }
            } catch (e: Exception) {
                Log.d(TAG, "Exception while saving file" + e.message)
                withContext(Dispatchers.Main) {
                    result?.error("Error", e.localizedMessage, e)
                    result = null
                }
            }
        }
    }

    private fun saveFile(uri: Uri) {
        Log.d(TAG, "Saving file")

        activity.contentResolver.openOutputStream(uri)?.use { outputStream ->
            if (sourcePath != null) {
                FileInputStream(sourcePath!!).use { inputStream ->
                    inputStream.copyTo(outputStream)
                }
            } else {
                val data = bytes ?: throw IllegalArgumentException("bytes is null")
                outputStream.write(data)
            }
        } ?: throw IllegalStateException("Unable to open output stream")
    }

    private fun sanitizeFileName(fileName: String?): String {
        val safeName = java.io.File(fileName ?: "file").name
            .replace(Regex("[\\\\/:*?\"<>|\\p{Cntrl}]"), "_")
            .trim()
        return if (safeName.isBlank() || safeName == "." || safeName == "..") {
            "file"
        } else {
            safeName
        }
    }

    private fun sanitizeExtension(extension: String?): String {
        val safeExtension = extension.orEmpty()
            .trim()
            .trimStart('.')
            .replace(Regex("[\\\\/:*?\"<>|\\p{Cntrl}]"), "_")
        return if (safeExtension.isEmpty()) "" else ".$safeExtension"
    }
}
