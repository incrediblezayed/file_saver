package com.one.file_saver

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.provider.OpenableColumns
import android.util.Log
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.File

private const val LOG_TAG = "FileDialog"

private const val REQUEST_CODE_SAVE_FILE = 19112

class FileDialog(
        private val activity: Activity
) : PluginRegistry.ActivityResultListener {

    private var flutterResult: MethodChannel.Result? = null
    private var fileExtensionsFilter: Array<String>? = null

    // file to be saved
    private var sourceFile: File? = null
    private var isSourceFileTemp: Boolean = false

    fun pickFile(result: MethodChannel.Result,
                 fileExtensionsFilter: Array<String>?,
                 mimeTypesFilter: Array<String>?,
                 localOnly: Boolean
    ) {
        Log.d(LOG_TAG, "pickFile - IN, fileExtensionsFilter=$fileExtensionsFilter, mimeTypesFilter=$mimeTypesFilter, localOnly=$localOnly")

        this.flutterResult = result
        this.fileExtensionsFilter = fileExtensionsFilter

        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT)
        intent.addCategory(Intent.CATEGORY_OPENABLE)
        if (localOnly) {
            intent.putExtra(Intent.EXTRA_LOCAL_ONLY, true)
        }
        applyMimeTypesFilterToIntent(mimeTypesFilter, intent)

        activity.startActivityForResult(intent, REQUEST_CODE_PICK_FILE)

        Log.d(LOG_TAG, "pickFile - OUT")
    }

    fun saveFile(result: MethodChannel.Result,
                 sourceFilePath: String?,
                 data: ByteArray?,
                 fileName: String?,
                 mimeTypesFilter: Array<String>?,
                 localOnly: Boolean
    ) {
        Log.d(LOG_TAG, "saveFile - IN, sourceFilePath=$sourceFilePath, " +
                "data=${data?.size} bytes, fileName=$fileName, " +
                "mimeTypesFilter=$mimeTypesFilter, localOnly=$localOnly")

        this.flutterResult = result

        if (sourceFilePath != null) {
            isSourceFileTemp = false
            // get source file
            sourceFile = File(sourceFilePath)
            if (!sourceFile!!.exists()) {
                flutterResult?.error(
                        "file_not_found",
                        "Source file is missing",
                        sourceFilePath)
                return
            }
        } else {
            // write data to a temporary file
            isSourceFileTemp = true
            sourceFile = File.createTempFile(fileName, "")
            sourceFile!!.writeBytes(data!!)
        }

        val intent = Intent(Intent.ACTION_CREATE_DOCUMENT)
        intent.addCategory(Intent.CATEGORY_OPENABLE)
        intent.putExtra(Intent.EXTRA_TITLE, fileName ?: sourceFile!!.name)
        if (localOnly) {
            intent.putExtra(Intent.EXTRA_LOCAL_ONLY, true)
        }
        applyMimeTypesFilterToIntent(mimeTypesFilter, intent)

        activity.startActivityForResult(intent, REQUEST_CODE_SAVE_FILE)

        Log.d(LOG_TAG, "saveFile - OUT")
    }

    private fun applyMimeTypesFilterToIntent(mimeTypesFilter: Array<String>?, intent: Intent) {
        if (mimeTypesFilter != null) {
            if (mimeTypesFilter.size == 1) {
                intent.type = mimeTypesFilter.first()
            } else {
                intent.type = "*/*"
                intent.putExtra(Intent.EXTRA_MIME_TYPES, mimeTypesFilter)
            }
        } else {
            intent.type = "*/*"
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        when (requestCode) {
            REQUEST_CODE_PICK_FILE -> {
                if (resultCode == Activity.RESULT_OK && data?.data != null) {
                    val sourceFileUri = data.data
                    val destinationFileName = getFileNameFromPickedDocumentUri(sourceFileUri)
                    if (destinationFileName != null && validateFileExtension(destinationFileName)) {
                        copyFileToCacheDirOnBackground(
                                context = activity,
                                sourceFileUri = sourceFileUri!!,
                                destinationFileName = destinationFileName)
                    } else {
                        flutterResult?.error(
                                "invalid_file_extension",
                                "Invalid file type was picked",
                                getFileExtension(destinationFileName))
                    }
                } else {
                    Log.d(LOG_TAG, "Cancelled")
                    flutterResult?.success(null)
                }
                return true
            }
            REQUEST_CODE_SAVE_FILE -> {
                if (resultCode == Activity.RESULT_OK && data?.data != null) {
                    val destinationFileUri = data.data
                    saveFileOnBackground(this.sourceFile!!, destinationFileUri!!)
                } else {
                    Log.d(LOG_TAG, "Cancelled")
                    if (isSourceFileTemp) {
                        Log.d(LOG_TAG, "Deleting source file: ${sourceFile?.path}")
                        sourceFile?.delete()
                    }
                    flutterResult?.success(null)
                }
                return true
            }
            else -> return false
        }
    }

    private fun copyFileToCacheDirOnBackground(
            context: Context,
            sourceFileUri: Uri,
            destinationFileName: String) {
        val uiScope = CoroutineScope(Dispatchers.Main)
        uiScope.launch {
            try {
                Log.d(LOG_TAG, "Launch...")
                Log.d(LOG_TAG, "Copy on background...")
                val filePath = withContext(Dispatchers.IO) {
                    copyFileToCacheDir(context, sourceFileUri, destinationFileName)
                }
                Log.d(LOG_TAG, "...copied on background, result: $filePath")
                flutterResult?.success(filePath)
                Log.d(LOG_TAG, "...launch")
            } catch (e: Exception) {
                Log.e(LOG_TAG, "copyFileToCacheDirOnBackground failed", e)
                flutterResult?.error("file_copy_failed", e.localizedMessage, e.toString())
            }
        }
    }

    private fun copyFileToCacheDir(
            context: Context,
            sourceFileUri: Uri,
            destinationFileName: String): String {
        // get destination file on cache dir
        val destinationFile = File(context.cacheDir.path, destinationFileName)

        // delete existing destination file
        if (destinationFile.exists()) {
            Log.d(LOG_TAG, "Deleting existing destination file '${destinationFile.path}'")
            destinationFile.delete()
        }

        // copy file to cache dir
        Log.d(LOG_TAG, "Copying '$sourceFileUri' to '${destinationFile.path}'")
        var copiedBytes: Long = 0
        context.contentResolver.openInputStream(sourceFileUri).use { inputStream ->
            destinationFile.outputStream().use { outputStream ->
                copiedBytes = inputStream!!.copyTo(outputStream)
            }
        }

        Log.d(LOG_TAG, "Successfully copied file to '${destinationFile.absolutePath}, bytes=$copiedBytes'")

        return destinationFile.absolutePath
    }

    private fun getFileNameFromPickedDocumentUri(uri: Uri?): String? {
        if (uri == null) {
            return null
        }
        var fileName: String? = null
        activity.contentResolver.query(uri, null, null, null, null, null)?.use { cursor ->
            if (cursor.moveToFirst()) {
                fileName = cursor.getString(cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME))
            }
        }
        return cleanupFileName(fileName)
    }

    private fun cleanupFileName(fileName: String?): String? {
        // https://stackoverflow.com/questions/2679699/what-characters-allowed-in-file-names-on-android
        return fileName?.replace(Regex("[\\\\/:*?\"<>|\\[\\]]"), "_")
    }

    private fun getFileExtension(fileName: String?): String? {
        return fileName?.substringAfterLast('.', "")
    }

    private fun validateFileExtension(filePath: String): Boolean {
        val validFileExtensions = fileExtensionsFilter
        if (validFileExtensions == null || validFileExtensions.isEmpty()) {
            return true
        }
        val fileExtension = getFileExtension(filePath) ?: return false
        for (extension in validFileExtensions) {
            if (fileExtension.equals(extension, true)) {
                return true
            }
        }
        return false
    }

    private fun saveFileOnBackground(
            sourceFile: File,
            destinationFileUri: Uri
    ) {
        val uiScope = CoroutineScope(Dispatchers.Main)
        uiScope.launch {
            try {
                Log.d(LOG_TAG, "Saving file on background...")
                val filePath = withContext(Dispatchers.IO) {
                    saveFile(sourceFile, destinationFileUri)
                }
                Log.d(LOG_TAG, "...saved file on background, result: $filePath")
                flutterResult?.success(filePath)
            } catch (e: SecurityException) {
                Log.e(LOG_TAG, "saveFileOnBackground", e)
                flutterResult?.error("security_exception", e.localizedMessage, e.toString())
            } catch (e: Exception) {
                Log.e(LOG_TAG, "saveFileOnBackground failed", e)
                flutterResult?.error("save_file_failed", e.localizedMessage, e.toString())
            } finally {
                if (isSourceFileTemp) {
                    Log.d(LOG_TAG, "Deleting source file: ${sourceFile.path}")
                    sourceFile.delete()
                }
            }
        }
    }

    private fun saveFile(
            sourceFile: File,
            destinationFileUri: Uri
    ): String {
        Log.d(LOG_TAG, "Saving file '${sourceFile.path}' to '${destinationFileUri.path}'")
        sourceFile.inputStream().use { inputStream ->
            activity.contentResolver.openOutputStream(destinationFileUri).use { outputStream ->
                inputStream.copyTo(outputStream!!)
            }
        }
        Log.d(LOG_TAG, "Saved file to '${destinationFileUri.path}'")
        return destinationFileUri.path!!
    }
}
