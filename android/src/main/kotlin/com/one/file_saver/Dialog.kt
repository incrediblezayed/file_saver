package com.one.file_saver

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.util.Log
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

private const val SAVE_FILE = 19112

class Dialog(private val activity: Activity) : PluginRegistry.ActivityResultListener {
    private var result: MethodChannel.Result? = null
    private var bytes: ByteArray? = null
    private val TAG = "Dialog Activity"
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (resultCode == Activity.RESULT_OK && data?.data != null) {
            Log.d(TAG, "Starting file operation")
            completeFileOperation(data.data!!)
        } else {
            Log.d(TAG, "Activity result was null")
            return false
        }
        return true
    }

    fun openFileManager(fileName: String?, bytes: ByteArray?, type: String?, result: MethodChannel.Result) {
        Log.d(TAG, "Opening File Manager")
        this.result = result
        this.bytes = bytes
        val intent =
                Intent(Intent.ACTION_CREATE_DOCUMENT)
        intent.putExtra(Intent.EXTRA_LOCAL_ONLY, true)
        intent.addCategory(Intent.CATEGORY_OPENABLE)
        intent.putExtra(Intent.EXTRA_TITLE, fileName)
        //intent.putExtra(Intent.EXTRA_MIME_TYPES, type)
        intent.type = type
        intent.flags = (Intent.FLAG_GRANT_READ_URI_PERMISSION
                or Intent.FLAG_GRANT_WRITE_URI_PERMISSION
                or Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION)
        activity.startActivityForResult(intent, SAVE_FILE)
    }

    private fun completeFileOperation(uri: Uri) {
        CoroutineScope(Dispatchers.Main).launch {
            try {
                Log.d(TAG, "Trying to save file")
                saveFile(uri)
                result?.success("File Successfully Saved " + uri.lastPathSegment)
            } catch (e: SecurityException) {
                Log.d(TAG, "Security Exception while saving file" + e.message)

                result?.error("Security Exception", e.localizedMessage, e)
            } catch (e: Exception) {
                Log.d(TAG, "Exception while saving file" + e.message)
                result?.error("Error", e.localizedMessage, e)
            } finally {
                Log.d(TAG, "Something went wrong")
            }
        }
    }

    private fun saveFile(uri: Uri) {
        try {
            Log.d(TAG, "Saving file")
            activity.contentResolver.openOutputStream(uri)?.write(bytes)
        } catch (e: Exception) {
            print("Error while writing file" + e.message)
        }
    }
}