package com.incrediblezayed.file_saver

import android.app.DownloadManager
import android.content.Context
import android.net.Uri
import android.os.Environment
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

/** Runs [block], turning any failure into a [FlutterError] with [code] for Dart. */
private inline fun <T> flutterErrors(code: String, block: () -> T): T {
    try {
        return block()
    } catch (e: FlutterError) {
        throw e
    } catch (e: Exception) {
        throw FlutterError(code, e.message)
    }
}

/** FileSaverPlugin */
class FileSaverPlugin : FlutterPlugin, ActivityAware, FileSaverHostApi {
    private var dialog: Dialog? = null
    private var activity: ActivityPluginBinding? = null
    private var pluginBinding: FlutterPlugin.FlutterPluginBinding? = null
    private val tag: String = "FileSaver"

    private val applicationContext: Context?
        get() = activity?.activity?.applicationContext
            ?: pluginBinding?.applicationContext

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        pluginBinding = flutterPluginBinding
        FileSaverHostApi.setUp(flutterPluginBinding.binaryMessenger, this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        Log.d(tag, "Detached From Engine")
        FileSaverHostApi.setUp(binding.binaryMessenger, null)
        pluginBinding = null
    }

    override suspend fun saveFile(request: SaveRequest): String? {
        val context = applicationContext
            ?: throw FlutterError("NoContext", "Context is unavailable")
        return withContext(Dispatchers.IO) {
            flutterErrors("SaveFileError") {
                val directory = context.getExternalFilesDir(null)
                    ?: throw IllegalStateException("External files directory is unavailable")
                val file = FileNames.safeChild(directory, FileNames.withExtension(request))
                file.writeBytes(request.bytes ?: throw IllegalArgumentException("bytes is null"))
                file.absolutePath
            }
        }
    }

    override suspend fun saveAs(request: SaveRequest): String? {
        val dialog = ensureDialog()
            ?: throw FlutterError("NullActivity", "saveAs needs a foreground Activity")
        return dialog.saveAs(request)
    }

    override suspend fun saveToGallery(request: SaveRequest): String? {
        val context = applicationContext
            ?: throw FlutterError("GalleryError", "Context is unavailable")
        return withContext(Dispatchers.IO) {
            flutterErrors("GalleryError") { Gallery(context).save(request) }
        }
    }

    override fun downloadLink(request: DownloadRequest): String = flutterErrors("DownloadError") {
        val context = applicationContext ?: throw IllegalStateException("Context is unavailable")
        val uri = Uri.parse(request.url)
        val fileName = FileNames.sanitizeFileName(
            request.name?.takeIf { it.isNotBlank() } ?: uri.lastPathSegment ?: "download"
        )
        val downloadRequest = DownloadManager.Request(uri)
            .setTitle(fileName)
            .setDescription(request.url)
            .setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE_NOTIFY_COMPLETED)
            .setAllowedOverMetered(true)
            .setAllowedOverRoaming(true)
            .setDestinationInExternalPublicDir(Environment.DIRECTORY_DOWNLOADS, fileName)
        request.headers.orEmpty().forEach { (key, value) ->
            downloadRequest.addRequestHeader(key, value)
        }
        val downloadManager = context.getSystemService(Context.DOWNLOAD_SERVICE) as DownloadManager
        downloadManager.enqueue(downloadRequest).toString()
    }

    /** Creates the dialog lazily; null when there is no Activity to host it. */
    private fun ensureDialog(): Dialog? {
        val binding = activity ?: return null
        dialog?.let { return it }
        return Dialog(binding.activity).also {
            binding.addActivityResultListener(it)
            dialog = it
        }
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) = attach(binding)

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) = attach(binding)

    override fun onDetachedFromActivityForConfigChanges() = detach(cancelPending = false)

    override fun onDetachedFromActivity() = detach(cancelPending = true)

    private fun attach(binding: ActivityPluginBinding) {
        activity = binding
        // Keep the same Dialog across rotation so a picker that is open
        // still delivers its result.
        dialog?.let {
            it.activity = binding.activity
            binding.addActivityResultListener(it)
        }
    }

    private fun detach(cancelPending: Boolean) {
        dialog?.let {
            activity?.removeActivityResultListener(it)
            if (cancelPending) {
                it.cancel()
                dialog = null
            }
        }
        activity = null
    }
}
