#include "include/file_saver/file_saver_plugin.h"

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>

#include <cstring>

#include "messages.g.h"

#define FILE_SAVER_PLUGIN(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), file_saver_plugin_get_type(), \
                              FileSaverPlugin))

struct _FileSaverPlugin {
  GObject parent_instance;

  FlPluginRegistrar* registrar;

  // True while a save dialog is open or its file is being written.
  gboolean save_in_progress;
};

G_DEFINE_TYPE(FileSaverPlugin, file_saver_plugin, g_object_get_type())

// One saveAs call, from showing the dialog until the file is written. Holds
// its own references so it outlives the method call that started it.
typedef struct {
  FileSaverPlugin* plugin;
  FileSaverSaveRequest* request;
  FileSaverFileSaverHostApiResponseHandle* response_handle;
  GFile* destination;
} SaveAsOperation;

static SaveAsOperation* save_as_operation_new(
    FileSaverPlugin* plugin, FileSaverSaveRequest* request,
    FileSaverFileSaverHostApiResponseHandle* response_handle) {
  SaveAsOperation* operation = g_new0(SaveAsOperation, 1);
  operation->plugin = FILE_SAVER_PLUGIN(g_object_ref(plugin));
  operation->request = FILE_SAVER_SAVE_REQUEST(g_object_ref(request));
  operation->response_handle = FILE_SAVER_FILE_SAVER_HOST_API_RESPONSE_HANDLE(
      g_object_ref(response_handle));
  return operation;
}

static void save_as_operation_free(SaveAsOperation* operation) {
  operation->plugin->save_in_progress = FALSE;
  g_clear_object(&operation->destination);
  g_object_unref(operation->response_handle);
  g_object_unref(operation->request);
  g_object_unref(operation->plugin);
  g_free(operation);
}

// Replies to Dart exactly once, then releases the operation.
static void save_as_operation_finish(SaveAsOperation* operation,
                                     const gchar* path) {
  file_saver_file_saver_host_api_respond_save_as(operation->response_handle,
                                                 path);
  save_as_operation_free(operation);
}

static void save_as_operation_fail(SaveAsOperation* operation,
                                   const gchar* code, const gchar* message) {
  file_saver_file_saver_host_api_respond_error_save_as(
      operation->response_handle, code, message, nullptr);
  save_as_operation_free(operation);
}

// Path of the written file, or its URI when it has no local path.
static gchar* destination_location(GFile* destination) {
  gchar* path = g_file_get_path(destination);
  return path != nullptr ? path : g_file_get_uri(destination);
}

static void on_copy_finished(GObject* source, GAsyncResult* result,
                             gpointer user_data) {
  SaveAsOperation* operation = static_cast<SaveAsOperation*>(user_data);
  g_autoptr(GError) error = nullptr;
  if (!g_file_copy_finish(G_FILE(source), result, &error)) {
    save_as_operation_fail(operation, "save_failed", error->message);
    return;
  }
  g_autofree gchar* location = destination_location(operation->destination);
  save_as_operation_finish(operation, location);
}

static void on_write_finished(GObject* source, GAsyncResult* result,
                              gpointer user_data) {
  SaveAsOperation* operation = static_cast<SaveAsOperation*>(user_data);
  g_autoptr(GError) error = nullptr;
  if (!g_file_replace_contents_finish(G_FILE(source), result, nullptr,
                                      &error)) {
    save_as_operation_fail(operation, "save_failed", error->message);
    return;
  }
  g_autofree gchar* location = destination_location(operation->destination);
  save_as_operation_finish(operation, location);
}

// Writes the payload with GIO's async API so a large file never blocks the
// UI thread; the callbacks run back on the main loop.
static void write_payload(SaveAsOperation* operation) {
  const gchar* source_path =
      file_saver_save_request_get_source_path(operation->request);
  if (source_path != nullptr) {
    g_autoptr(GFile) source = g_file_new_for_path(source_path);
    g_file_copy_async(source, operation->destination, G_FILE_COPY_OVERWRITE,
                      G_PRIORITY_DEFAULT, nullptr, nullptr, nullptr,
                      on_copy_finished, operation);
    return;
  }

  size_t length = 0;
  const uint8_t* bytes =
      file_saver_save_request_get_bytes(operation->request, &length);
  // Borrow the request's buffer instead of copying it; the GBytes keeps the
  // request alive until GIO is done with it.
  g_autoptr(GBytes) contents = g_bytes_new_with_free_func(
      length > 0 ? bytes : nullptr, length, g_object_unref,
      g_object_ref(operation->request));
  g_file_replace_contents_bytes_async(
      operation->destination, contents, nullptr, FALSE,
      G_FILE_CREATE_REPLACE_DESTINATION, nullptr, on_write_finished,
      operation);
}

static void on_dialog_response(GtkNativeDialog* dialog, gint response,
                               gpointer user_data) {
  SaveAsOperation* operation = static_cast<SaveAsOperation*>(user_data);
  if (response == GTK_RESPONSE_ACCEPT) {
    operation->destination = gtk_file_chooser_get_file(GTK_FILE_CHOOSER(dialog));
  }
  g_object_unref(dialog);

  if (response != GTK_RESPONSE_ACCEPT) {
    // Cancelled: null, as on the other platforms.
    save_as_operation_finish(operation, nullptr);
    return;
  }
  if (operation->destination == nullptr) {
    save_as_operation_fail(operation, "save_failed", "No file was selected");
    return;
  }
  write_payload(operation);
}

// The window hosting the Flutter view, so the dialog is modal to the app.
static GtkWindow* get_window(FileSaverPlugin* self) {
  FlView* view = fl_plugin_registrar_get_view(self->registrar);
  if (view == nullptr) {
    return nullptr;
  }
  GtkWidget* toplevel = gtk_widget_get_toplevel(GTK_WIDGET(view));
  return GTK_IS_WINDOW(toplevel) ? GTK_WINDOW(toplevel) : nullptr;
}

// Restricts the dialog to the requested extension, with "All files" as the
// escape hatch.
static void add_filters(GtkFileChooser* chooser, const gchar* extension) {
  const gchar* bare = extension[0] == '.' ? extension + 1 : extension;
  if (bare[0] == '\0') {
    return;
  }
  g_autofree gchar* upper = g_ascii_strup(bare, -1);
  g_autofree gchar* name = g_strdup_printf("%s files", upper);
  g_autofree gchar* pattern = g_strdup_printf("*.%s", bare);

  GtkFileFilter* matching = gtk_file_filter_new();
  gtk_file_filter_set_name(matching, name);
  gtk_file_filter_add_pattern(matching, pattern);
  gtk_file_chooser_add_filter(chooser, matching);

  GtkFileFilter* all = gtk_file_filter_new();
  gtk_file_filter_set_name(all, "All files");
  gtk_file_filter_add_pattern(all, "*");
  gtk_file_chooser_add_filter(chooser, all);
}

static void save_as(FileSaverSaveRequest* request,
                    FileSaverFileSaverHostApiResponseHandle* response_handle,
                    gpointer user_data) {
  FileSaverPlugin* self = FILE_SAVER_PLUGIN(user_data);
  if (self->save_in_progress) {
    file_saver_file_saver_host_api_respond_error_save_as(
        response_handle, "busy", "A saveAs dialog is already open", nullptr);
    return;
  }

  const gchar* extension = file_saver_save_request_get_file_extension(request);
  g_autofree gchar* file_name = nullptr;
  if (file_saver_save_request_get_include_extension(request) &&
      extension[0] != '\0') {
    file_name = g_strconcat(file_saver_save_request_get_name(request),
                            extension[0] == '.' ? "" : ".", extension, nullptr);
  } else {
    file_name = g_strdup(file_saver_save_request_get_name(request));
  }

  const gchar* title = file_saver_save_request_get_dialog_title(request);
  // GtkFileChooserNative goes through the XDG desktop portal when the app is
  // sandboxed (Flatpak, Snap) and falls back to the GTK dialog otherwise.
  GtkFileChooserNative* dialog = gtk_file_chooser_native_new(
      title != nullptr && title[0] != '\0' ? title : "Save File",
      get_window(self), GTK_FILE_CHOOSER_ACTION_SAVE, "_Save", "_Cancel");
  GtkFileChooser* chooser = GTK_FILE_CHOOSER(dialog);
  gtk_native_dialog_set_modal(GTK_NATIVE_DIALOG(dialog), TRUE);
  gtk_file_chooser_set_do_overwrite_confirmation(chooser, TRUE);
  gtk_file_chooser_set_current_name(chooser, file_name);
  const gchar* initial_directory =
      file_saver_save_request_get_initial_directory(request);
  if (initial_directory != nullptr && initial_directory[0] != '\0') {
    gtk_file_chooser_set_current_folder(chooser, initial_directory);
  }
  add_filters(chooser, extension);

  self->save_in_progress = TRUE;
  // on_dialog_response takes over both the dialog and the operation.
  g_signal_connect(dialog, "response", G_CALLBACK(on_dialog_response),
                   save_as_operation_new(self, request, response_handle));
  gtk_native_dialog_show(GTK_NATIVE_DIALOG(dialog));
}

// saveFile and saveToDownloads are written in Dart on Linux (path_provider),
// so these entries only guard against a mismatched Dart side.
static void save_file(FileSaverSaveRequest* request,
                      FileSaverFileSaverHostApiResponseHandle* response_handle,
                      gpointer user_data) {
  file_saver_file_saver_host_api_respond_error_save_file(
      response_handle, "unsupported", "saveFile is implemented in Dart on Linux",
      nullptr);
}

static void save_to_gallery(
    FileSaverSaveRequest* request,
    FileSaverFileSaverHostApiResponseHandle* response_handle,
    gpointer user_data) {
  file_saver_file_saver_host_api_respond_error_save_to_gallery(
      response_handle, "unsupported",
      "saveToGallery is only supported on Android and iOS", nullptr);
}

static void save_to_downloads(
    FileSaverSaveRequest* request,
    FileSaverFileSaverHostApiResponseHandle* response_handle,
    gpointer user_data) {
  file_saver_file_saver_host_api_respond_error_save_to_downloads(
      response_handle, "unsupported",
      "saveToDownloads is implemented in Dart on Linux", nullptr);
}

static FileSaverFileSaverHostApiDownloadLinkResponse* download_link(
    FileSaverDownloadRequest* request, gpointer user_data) {
  return file_saver_file_saver_host_api_download_link_response_new_error(
      "unsupported", "downloadLink is only supported on Android and web",
      nullptr);
}

static const FileSaverFileSaverHostApiVTable host_api_vtable = {
    save_file, save_as, save_to_gallery, save_to_downloads, download_link,
};

static void file_saver_plugin_dispose(GObject* object) {
  FileSaverPlugin* self = FILE_SAVER_PLUGIN(object);
  g_clear_object(&self->registrar);
  G_OBJECT_CLASS(file_saver_plugin_parent_class)->dispose(object);
}

static void file_saver_plugin_class_init(FileSaverPluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = file_saver_plugin_dispose;
}

static void file_saver_plugin_init(FileSaverPlugin* self) {}

void file_saver_plugin_register_with_registrar(FlPluginRegistrar* registrar) {
  FileSaverPlugin* plugin = FILE_SAVER_PLUGIN(
      g_object_new(file_saver_plugin_get_type(), nullptr));
  plugin->registrar = FL_PLUGIN_REGISTRAR(g_object_ref(registrar));

  file_saver_file_saver_host_api_set_method_handlers(
      fl_plugin_registrar_get_messenger(registrar), nullptr, &host_api_vtable,
      g_object_ref(plugin), g_object_unref);

  g_object_unref(plugin);
}
