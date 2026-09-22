package com.incrediblezayed.file_saver

import android.app.Activity
import android.content.ContentResolver
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.DocumentsContract
import android.util.Log
import io.flutter.plugin.common.PluginRegistry
import java.io.File
import java.io.FileInputStream
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException
import kotlinx.coroutines.CancellableContinuation
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.withContext

private const val SAVE_FILE = 886325063

class Dialog(var activity: Activity) : PluginRegistry.ActivityResultListener {
    /** The call waiting on the picker; null when no dialog is open. */
    private var pending: CancellableContinuation<Uri?>? = null
    private val TAG = "Dialog Activity"

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != SAVE_FILE) {
            return false
        }
        val continuation = pending ?: return true
        pending = null
        val uri = if (resultCode == Activity.RESULT_OK) data?.data else null
        if (uri == null) Log.d(TAG, "Save dialog cancelled")
        if (continuation.isActive) continuation.resume(uri)
        return true
    }

    /** Shows the picker, then copies the payload to the chosen document. Null when cancelled. */
    suspend fun saveAs(request: SaveRequest): String? {
        if (pending != null) {
            throw FlutterError("Busy", "A saveAs dialog is already open")
        }
        Log.d(TAG, "Opening File Manager")
        val intent = Intent(Intent.ACTION_CREATE_DOCUMENT)
        intent.addCategory(Intent.CATEGORY_OPENABLE)
        intent.putExtra(Intent.EXTRA_TITLE, FileNames.withExtension(request))
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            initialDirectoryUri(request.initialDirectory)?.let {
                intent.putExtra(DocumentsContract.EXTRA_INITIAL_URI, it)
            }
        }
        intent.type = request.mimeType

        val uri = suspendCancellableCoroutine<Uri?> { continuation ->
            pending = continuation
            continuation.invokeOnCancellation { pending = null }
            try {
                activity.startActivityForResult(intent, SAVE_FILE)
            } catch (e: Exception) {
                pending = null
                continuation.resumeWithException(
                    FlutterError("NoFileManager", "No app can show the save dialog: ${e.message}")
                )
            }
        } ?: return null

        val resolver = activity.contentResolver
        return withContext(Dispatchers.IO) {
            try {
                writeTo(resolver, uri, request)
                uri.toString()
            } catch (e: SecurityException) {
                Log.d(TAG, "Security Exception while saving file: ${e.message}")
                throw FlutterError("Security Exception", e.localizedMessage)
            } catch (e: Exception) {
                Log.d(TAG, "Exception while saving file: ${e.message}")
                throw FlutterError("Error", e.localizedMessage)
            }
        }
    }

    /** Fails the pending call when the activity goes away for good. */
    fun cancel() {
        val continuation = pending ?: return
        pending = null
        if (continuation.isActive) {
            continuation.resumeWithException(
                FlutterError(
                    "ActivityDetached",
                    "The activity was destroyed while the save dialog was open"
                )
            )
        }
    }

    private fun writeTo(resolver: ContentResolver, uri: Uri, request: SaveRequest) {
        resolver.openOutputStream(uri)?.use { output ->
            val sourcePath = request.sourcePath
            if (sourcePath != null) {
                FileInputStream(sourcePath).use { input -> input.copyTo(output) }
            } else {
                output.write(request.bytes ?: throw IllegalArgumentException("bytes is null"))
            }
        } ?: throw IllegalStateException("Unable to open output stream")
    }

    /**
     * Maps [initialDirectory] to a document URI for [DocumentsContract.EXTRA_INITIAL_URI].
     * A `content://` value is used as-is. An absolute path under external
     * storage is converted to the matching ExternalStorageProvider document URI.
     */
    private fun initialDirectoryUri(initialDirectory: String?): Uri? {
        val value = initialDirectory?.trim().orEmpty()
        if (value.isEmpty()) return null
        if (value.startsWith("content://")) return Uri.parse(value)
        val root = Environment.getExternalStorageDirectory().absolutePath
        val absolute = File(value).absolutePath
        if (!absolute.startsWith(root)) return null
        val relative = absolute.removePrefix(root).trimStart('/')
        return DocumentsContract.buildDocumentUri(
            "com.android.externalstorage.documents",
            "primary:$relative"
        )
    }
}
