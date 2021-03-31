package com.one.file_saver

import android.os.Environment
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import io.flutter.plugin.common.PluginRegistry.Registrar


/** FileSaverPlugin */
class FileSaverPlugin : FlutterPlugin, ActivityAware, MethodCallHandler {
    private var fileDialog: FileDialog? = null
    private var activity: ActivityPluginBinding? = null
    private var registrar: Registrar? = null
    private var pluginBinding: FlutterPlugin.FlutterPluginBinding? = null
    private lateinit var channel: MethodChannel
    private var methodChannel: MethodChannel? = null
    private var handler: Handler = Handler(Looper.getMainLooper())

    companion object {
        @JvmStatic
        fun registerWith(registrar: Registrar) {
            Log.d("Hello", "Heyyy")
            if (registrar.activity() != null) {
                val plugin = FileSaverPlugin()
                plugin.doOnAttachedToEngine(registrar.messenger())
                plugin.doOnAttachedToActivity(null, registrar)
            }
        }
    }

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        if (pluginBinding != null) {
            print("Already Initialized")
        }
        pluginBinding = flutterPluginBinding
        val messenger = pluginBinding?.binaryMessenger
        doOnAttachedToEngine(messenger!!)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }


    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        if (fileDialog == null) {
            createFileDialog()
        }
        when (call.method) {
            "getDirectory" -> {
                val dir: String? = getDownloadsPath()
                result.success(dir)
            }
            "saveAs" -> {
                fileDialog!!.openFileManager(fileName = call.argument("name"), bytes = call.argument("bytes"), type = call.argument("type"), result = result)
            }
            else -> {
                result.notImplemented()
            }
        }

    }

    private fun getDownloadsPath(): String? {
        return Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS).absolutePath
    }


    override fun onDetachedFromActivity() {
        TODO("Not yet implemented")
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        TODO("Not yet implemented")
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding
        doOnAttachedToActivity(binding)
        TODO("Not yet implemented")
    }

    override fun onDetachedFromActivityForConfigChanges() {
        TODO("Not yet implemented")
    }

    private fun doOnAttachedToEngine(messenger: BinaryMessenger) {
        methodChannel = MethodChannel(messenger, "file_saver")
        methodChannel?.setMethodCallHandler(this)
    }

    private fun doOnAttachedToActivity(activityBinding: ActivityPluginBinding?,
                                       registrar: Registrar? = null) {

        this.activity = activityBinding
        this.registrar = registrar

    }

    private fun createFileDialog(): Boolean {
        var fileDialog: FileDialog? = null
        if (registrar != null) {
            fileDialog = FileDialog(
                    activity = registrar!!.activity()
            )
            registrar!!.addActivityResultListener(fileDialog)
        } else if (activity != null) {
            fileDialog = FileDialog(
                    activity = activity!!.activity
            )
            activity!!.addActivityResultListener(fileDialog)
        }
        this.fileDialog = fileDialog


        return fileDialog != null
    }
}
