package com.incrediblezayed.file_saver

import android.app.Activity
import android.content.ContentUris
import android.content.Context
import android.content.Intent
import android.database.Cursor
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.DocumentsContract
import android.provider.MediaStore
import android.text.TextUtils
import android.util.Log
import androidx.annotation.RequiresApi
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import java.io.File
import java.io.OutputStream


private const val SAVE_FILE = 19112

class Dialog(private val activity: Activity) : PluginRegistry.ActivityResultListener {
    private var result: MethodChannel.Result? = null
    private var bytes: ByteArray? = null
    private var fileName: String? = null
    private val TAG = "Dialog Activity"
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode == SAVE_FILE && resultCode == Activity.RESULT_OK && data?.data != null) {
            Log.d(TAG, "Starting file operation")
            completeFileOperation(data.data!!)
        } else {
            Log.d(TAG, "Activity result was null")
            result?.success(null)
            return false
        }
        return true
    }


    fun openFileManager(
        fileName: String?,
        ext: String?,
        bytes: ByteArray?,
        type: String?,
        result: MethodChannel.Result
    ) {
        Log.d(TAG, "Opening File Manager")
        this.result = result
        this.bytes = bytes
        this.fileName = fileName
        val intent =
            Intent(Intent.ACTION_CREATE_DOCUMENT)
        intent.putExtra(Intent.EXTRA_LOCAL_ONLY, true)
        intent.addCategory(Intent.CATEGORY_OPENABLE)
        intent.putExtra(Intent.EXTRA_TITLE, "$fileName.$ext")
        intent.putExtra(Intent.EXTRA_MIME_TYPES, type)
        intent.putExtra(
            DocumentsContract.EXTRA_INITIAL_URI,
            Environment.getExternalStorageDirectory().path
        )
        intent.type = type
        intent.flags = (Intent.FLAG_GRANT_READ_URI_PERMISSION
                or Intent.FLAG_GRANT_WRITE_URI_PERMISSION
                or Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION
                or Intent.FLAG_GRANT_PREFIX_URI_PERMISSION
                )
        activity.startActivityForResult(intent, SAVE_FILE)
    }

    private fun completeFileOperation(uri: Uri) {
        CoroutineScope(Dispatchers.Main).launch {
            try {
                saveFile(uri)
                val fileUtils = FileUtils(activity)
                result?.success(fileUtils.getPath(uri));
                //result?.success(getRealPathFromUri(activity, uri))
            } catch (e: SecurityException) {
                Log.d(TAG, "Security Exception while saving file" + e.message)

                result?.error("Security Exception", e.localizedMessage, e)
            } catch (e: Exception) {
                Log.d(TAG, "Exception while saving file" + e.message)
                result?.error("Error", e.localizedMessage, e)
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