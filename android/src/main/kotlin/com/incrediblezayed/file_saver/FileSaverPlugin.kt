package com.incrediblezayed.file_saver


import android.util.Log
import androidx.annotation.NonNull
import androidx.core.app.ActivityCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.File
import java.lang.Exception
import java.util.jar.Manifest


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
                    Log.d(tag, "Get directory Method Called")
                    val dir: String = saveFile(
                        fileName = call.argument("name"),
                        bytes = call.argument("bytes"),
                        extension = call.argument("ext")
                    )
                    result.success(dir)
                }

                "saveAs" -> {
                    Log.d(tag, "Save as Method Called")
                    dialog!!.openFileManager(
                        fileName = call.argument("name"),
                        ext = call.argument("ext"),
                        bytes = call.argument("bytes"),
                        type = call.argument("mimeType"),
                        result = result
                    )

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

    private fun saveFile(fileName: String?, bytes: ByteArray?, extension: String?): String {
        return try {
            val uri = activity!!.activity.baseContext.getExternalFilesDir(null)
            val file = File(uri!!.absolutePath + "/" + fileName + extension)
            file.writeBytes(bytes!!)
            uri.absolutePath + "/" + file.name
        } catch (e: Exception) {
            Log.d(tag, "Error While Saving File" + e.message)
            "Error While Saving File" + e.message
        }
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
