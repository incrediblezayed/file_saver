package com.incrediblezayed.file_saver


import android.app.DownloadManager
import android.content.Context
import android.net.Uri
import android.os.Environment
import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.File
import java.lang.Exception


/** FileSaverPlugin */
class FileSaverPlugin : FlutterPlugin, ActivityAware, MethodCallHandler {
    private var dialog: Dialog? = null
    private var activity: ActivityPluginBinding? = null
    private var pluginBinding: FlutterPlugin.FlutterPluginBinding? = null
    private var methodChannel: MethodChannel? = null
    private var result: Result? = null
    private val tag: String = "FileSaver"
    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        if (pluginBinding != null) {
            Log.d(tag, "Already Initialized")
        }
        pluginBinding = flutterPluginBinding
        val messenger = pluginBinding!!.binaryMessenger
        methodChannel = MethodChannel(messenger, "file_saver")
        methodChannel?.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        Log.d(tag, "Detached From Engine")
        methodChannel = null
        pluginBinding = null
        if (dialog != null) {
            activity?.removeActivityResultListener(dialog!!)
            dialog = null
        }
        methodChannel?.setMethodCallHandler(null)
    }


    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        if (dialog == null) {
            Log.d(tag, "Dialog was null")
            createFileDialog()
        }
        try {
            this.result = result
            when (call.method) {
                "saveFile" -> {
                    Log.d(tag, "Save file Method Called")
                    val dir: String = saveFile(
                        fileName = call.argument("name"),
                        bytes = call.argument("bytes"),
                        extension = call.argument("fileExtension"),
                        includeExtension = call.argument("includeExtension")
                    )
                    result.success(dir)
                }

                "saveAs" -> {
                    Log.d(tag, "Save as Method Called")
                    dialog!!.openFileManager(
                        fileName = call.argument("name"),
                        fileExtension = call.argument("fileExtension"),
                        bytes = call.argument("bytes"),
                        sourcePath = call.argument("sourcePath"),
                        type = call.argument("mimeType"),
                        includeExtension = call.argument("includeExtension"),
                        result = result
                    )
                }
                "downloadLink" -> {
                    Log.d(tag, "Download link Method Called")
                    val downloadId = downloadLink(
                        url = call.argument("url"),
                        name = call.argument("name"),
                        headers = call.argument("headers")
                    )
                    result.success(downloadId)
                }
                else -> {
                    Log.d(tag, "Unknown Method called " + call.method!!)
                    result.notImplemented()
                }
            }
        } catch (e: Exception) {
            Log.d(tag, "Error While Calling method" + e.message)
        }

    }

    private fun saveFile(fileName: String?, bytes: ByteArray?, extension: String?, includeExtension: Boolean?): String {
        return try {
            val uri = activity!!.activity.baseContext.getExternalFilesDir(null)
                ?: throw IllegalStateException("External files directory is unavailable")
            var fileNameWithExtension = sanitizeFileName(fileName)
            if (includeExtension == true) {
                val safeExtension = sanitizeExtension(extension)
                if (safeExtension.isNotEmpty()) {
                    fileNameWithExtension += safeExtension
                }
            }
            val file = safeChild(uri, fileNameWithExtension)
            file.writeBytes(bytes ?: throw IllegalArgumentException("bytes is null"))
            file.absolutePath
        } catch (e: Exception) {
            Log.d(tag, "Error While Saving File" + e.message)
            "Error While Saving File" + e.message
        }
    }

    private fun safeChild(parent: File, fileName: String): File {
        val file = File(parent, fileName)
        val parentPath = parent.canonicalPath + File.separator
        if (!file.canonicalPath.startsWith(parentPath)) {
            throw SecurityException("Invalid file name")
        }
        return file
    }

    private fun sanitizeFileName(fileName: String?): String {
        val safeName = File(fileName ?: "file").name
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

    private fun downloadLink(url: String?, name: String?, headers: Map<String, String>?): String {
        val safeUrl = url ?: throw IllegalArgumentException("url is null")
        val context = activity?.activity?.applicationContext
            ?: pluginBinding?.applicationContext
            ?: throw IllegalStateException("Context is unavailable")
        val uri = Uri.parse(safeUrl)
        val fileName = sanitizeFileName(
            name?.takeIf { it.isNotBlank() } ?: uri.lastPathSegment ?: "download"
        )
        val request = DownloadManager.Request(uri)
            .setTitle(fileName)
            .setDescription(safeUrl)
            .setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE_NOTIFY_COMPLETED)
            .setAllowedOverMetered(true)
            .setAllowedOverRoaming(true)
            .setDestinationInExternalPublicDir(Environment.DIRECTORY_DOWNLOADS, fileName)

        headers.orEmpty().forEach { (key, value) ->
            request.addRequestHeader(key, value)
        }

        val downloadManager = context.getSystemService(Context.DOWNLOAD_SERVICE) as DownloadManager
        val downloadId = downloadManager.enqueue(request)
        return downloadId.toString()
    }

    override fun onDetachedFromActivity() {
        Log.d(tag, "Detached From Activity")
        if (dialog != null) {
            activity?.removeActivityResultListener(dialog!!)
            dialog = null
        }
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        Log.d(tag, "Re Attached to Activity")
        this.activity = binding
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        Log.d(tag, "Attached to Activity")
        this.activity = binding
    }

    override fun onDetachedFromActivityForConfigChanges() {
        Log.d(tag, "On Detached From ConfigChanges")
        if (dialog != null) {
            activity?.removeActivityResultListener(dialog!!)
            dialog = null
        }
        activity = null
    }

    private fun createFileDialog(): Boolean {
        Log.d(tag, "Creating File Dialog Activity")
        var dialog: Dialog? = null
        if (activity != null) {
            dialog = Dialog(
                activity = activity!!.activity
            )
            activity!!.addActivityResultListener(dialog)
        } else {
            Log.d(tag, "Activity was null")
            if (result != null) result?.error("NullActivity", "Activity was Null", null)
        }
        this.dialog = dialog
        return dialog != null
    }
}
