#ifndef FLUTTER_PLUGIN_FILE_SAVER_PLUGIN_H_
#define FLUTTER_PLUGIN_FILE_SAVER_PLUGIN_H_

#include <flutter/plugin_registrar_windows.h>
#include <windows.h>

#include <functional>
#include <optional>
#include <string>

#include "messages.g.h"

namespace file_saver {

class FileSaverPlugin : public flutter::Plugin, public FileSaverHostApi {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  explicit FileSaverPlugin(flutter::PluginRegistrarWindows *registrar);

  virtual ~FileSaverPlugin();

  // Disallow copy and assign.
  FileSaverPlugin(const FileSaverPlugin &) = delete;
  FileSaverPlugin &operator=(const FileSaverPlugin &) = delete;

  // FileSaverHostApi
  void SaveFile(
      const SaveRequest &request,
      std::function<void(ErrorOr<std::optional<std::string>> reply)> result)
      override;
  void SaveAs(
      const SaveRequest &request,
      std::function<void(ErrorOr<std::optional<std::string>> reply)> result)
      override;
  void SaveToGallery(
      const SaveRequest &request,
      std::function<void(ErrorOr<std::optional<std::string>> reply)> result)
      override;
  void SaveToDownloads(
      const SaveRequest &request,
      std::function<void(ErrorOr<std::optional<std::string>> reply)> result)
      override;
  ErrorOr<std::string> DownloadLink(const DownloadRequest &request) override;

 private:
  // Top-level window of the Flutter view, so the dialog is modal to the app.
  HWND OwnerWindow() const;

  flutter::PluginRegistrarWindows *registrar_;
};

}  // namespace file_saver

#endif  // FLUTTER_PLUGIN_FILE_SAVER_PLUGIN_H_
