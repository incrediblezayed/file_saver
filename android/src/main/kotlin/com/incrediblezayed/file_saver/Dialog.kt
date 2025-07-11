package com.incrediblezayed.file_saver

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Environment
import android.provider.DocumentsContract
import android.util.Log
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch


private const val SAVE_FILE = 886325063

class Dialog(private val activity: Activity) : PluginRegistry.ActivityResultListener {
    private var result: MethodChannel.Result? = null
    private var bytes: ByteArray? = null
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
        type: String?,
        includeExtension: Boolean?,
        result: MethodChannel.Result
    ) {
        Log.d(TAG, "Opening File Manager")
        val nonNullExtension = fileExtension ?: "";
        var fileNameWithExtension = fileName
        if (includeExtension == true) {
            fileNameWithExtension += if (nonNullExtension.startsWith('.')) {
                nonNullExtension;
            } else {
                ".$nonNullExtension"
            }
        }
        this.result = result
        this.bytes = bytes
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
        CoroutineScope(Dispatchers.Main).launch {
            try {
                saveFile(uri)
                val fileUtils = FileUtils(activity)
                result?.success(fileUtils.getPath(uri));
                result = null
                //result?.success(getRealPathFromUri(activity, uri))
            } catch (e: SecurityException) {
                Log.d(TAG, "Security Exception while saving file" + e.message)

                result?.error("Security Exception", e.localizedMessage, e)
                result = null
            } catch (e: Exception) {
                Log.d(TAG, "Exception while saving file" + e.message)
                result?.error("Error", e.localizedMessage, e)
                result = null
            }
        }
    }

    private fun saveFile(uri: Uri) {
        try {
            Log.d(TAG, "Saving file")

            val opStream = activity.contentResolver.openOutputStream(uri)
            opStream?.write(bytes)

        } catch (e: Exception) {
            Log.d(TAG, "Error while writing file" + e.message)
        }
    }
}