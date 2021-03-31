package com.one.file_saver

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.util.Log
import androidx.annotation.RequiresApi
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import kotlinx.coroutines.*
import java.io.File
import java.io.FileDescriptor
import java.io.OutputStream
import java.lang.Exception

private const val REQUEST_CODE_SAVE_FILE = 101

class FileDialog(private val activity: Activity) : PluginRegistry.ActivityResultListener {
    private var result: MethodChannel.Result? = null
    private var bytes: ByteArray? = null
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (resultCode == Activity.RESULT_OK && data?.data != null) {
            initialFile(data.data!!)
        } else {
            result!!.success(null)
        }
        return true
    }

    fun openFileManager(fileName: String?, bytes: ByteArray?, type: String?, result: MethodChannel.Result) {
        this.result = result
        this.bytes = bytes
        val intent =
                Intent(Intent.ACTION_CREATE_DOCUMENT).addCategory(Intent.CATEGORY_OPENABLE).setType(type).putExtra(Intent.EXTRA_TITLE, fileName).putExtra(Intent.EXTRA_MIME_TYPES, type).putExtra(Intent.EXTRA_LOCAL_ONLY, true)
        activity.startActivityForResult(intent, REQUEST_CODE_SAVE_FILE)
    }

    private fun initialFile(uri: Uri) {
        val uiScope = CoroutineScope(Dispatchers.Main)
        uiScope.launch {
            withContext(Dispatchers.IO) {
                try {
                    val filePath: String? = saveFile(uri)
                    result?.success(filePath)
                } catch (e: SecurityException) {
                    result?.error("Security Exception", e.localizedMessage, e)
                } catch (e: Exception) {
                    result?.error("Error", e.localizedMessage, e)
                } finally {
                    print("Something went wrong")
                }
            }
        }
    }

    private fun saveFile(uri: Uri): String? {
        activity.contentResolver.openOutputStream(uri)?.write(bytes)
        return uri.path
    }
}