#include "file_saver_plugin.h"

// This must be included before many other Windows headers.
#include <windows.h>

#include <Commdlg.h>

#include <flutter/plugin_registrar_windows.h>

#include <algorithm>
#include <cwctype>
#include <filesystem>
#include <fstream>
#include <memory>
#include <string>
#include <vector>

#include "include/file_saver/file_saver_plugin.h"

namespace file_saver {

namespace {

std::wstring Utf8ToWide(const std::string &utf8) {
  if (utf8.empty()) {
    return L"";
  }
  int length = MultiByteToWideChar(CP_UTF8, 0, utf8.data(),
                                   static_cast<int>(utf8.size()), nullptr, 0);
  std::wstring wide(static_cast<size_t>(length), L'\0');
  MultiByteToWideChar(CP_UTF8, 0, utf8.data(), static_cast<int>(utf8.size()),
                      wide.data(), length);
  return wide;
}

std::string WideToUtf8(const std::wstring &wide) {
  if (wide.empty()) {
    return "";
  }
  int length =
      WideCharToMultiByte(CP_UTF8, 0, wide.data(), static_cast<int>(wide.size()),
                          nullptr, 0, nullptr, nullptr);
  std::string utf8(static_cast<size_t>(length), '\0');
  WideCharToMultiByte(CP_UTF8, 0, wide.data(), static_cast<int>(wide.size()),
                      utf8.data(), length, nullptr, nullptr);
  return utf8;
}

// "<EXT> File\0*.<ext>\0\0", the double-null-terminated buffer
// GetSaveFileName expects. Built by hand: a std::wstring literal stops at the
// first embedded null.
std::vector<wchar_t> FileExtensionToFileFilter(const std::string &fileExtension) {
  std::wstring display;
  std::wstring pattern;
  if (fileExtension.empty()) {
    display = L"All Files";
    pattern = L"*.*";
  } else {
    const std::string bare =
        fileExtension[0] == '.' ? fileExtension.substr(1) : fileExtension;
    const std::wstring wide = Utf8ToWide(bare);
    std::wstring upper = wide;
    for (auto &c : upper) {
      c = static_cast<wchar_t>(std::towupper(c));
    }
    display = upper + L" File";
    pattern = L"*." + wide;
  }
  std::vector<wchar_t> filter;
  filter.insert(filter.end(), display.begin(), display.end());
  filter.push_back(L'\0');
  filter.insert(filter.end(), pattern.begin(), pattern.end());
  filter.push_back(L'\0');
  filter.push_back(L'\0');
  return filter;
}

bool HasInvalidFileNameCharacter(const std::string &file_name) {
  if (file_name.empty() || file_name == "." || file_name == "..") {
    return true;
  }

  const std::string invalid_characters = "<>:\"/\\|?*";
  return std::any_of(file_name.begin(), file_name.end(), [&](char c) {
    return static_cast<unsigned char>(c) < 32 ||
           invalid_characters.find(c) != std::string::npos;
  });
}

}  // namespace

// static
void FileSaverPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto plugin = std::make_unique<FileSaverPlugin>(registrar);
  FileSaverHostApi::SetUp(registrar->messenger(), plugin.get());
  registrar->AddPlugin(std::move(plugin));
}

FileSaverPlugin::FileSaverPlugin(flutter::PluginRegistrarWindows *registrar)
    : registrar_(registrar) {}

FileSaverPlugin::~FileSaverPlugin() {}

HWND FileSaverPlugin::OwnerWindow() const {
  if (registrar_ == nullptr) {
    return nullptr;
  }
  flutter::FlutterView *view = registrar_->GetView();
  if (view == nullptr) {
    return nullptr;
  }
  HWND hwnd = view->GetNativeWindow();
  return hwnd == nullptr ? nullptr : GetAncestor(hwnd, GA_ROOT);
}

void FileSaverPlugin::SaveFile(
    const SaveRequest & /*request*/,
    std::function<void(ErrorOr<std::optional<std::string>> reply)> result) {
  result(FlutterError("unsupported", "saveFile is implemented in Dart on Windows"));
}

void FileSaverPlugin::SaveToGallery(
    const SaveRequest & /*request*/,
    std::function<void(ErrorOr<std::optional<std::string>> reply)> result) {
  result(FlutterError("unsupported",
                      "saveToGallery is only supported on Android and iOS"));
}

void FileSaverPlugin::SaveToDownloads(
    const SaveRequest & /*request*/,
    std::function<void(ErrorOr<std::optional<std::string>> reply)> result) {
  result(FlutterError("unsupported",
                      "saveToDownloads is handled in Dart on Windows"));
}

ErrorOr<std::string> FileSaverPlugin::DownloadLink(
    const DownloadRequest & /*request*/) {
  return FlutterError("unsupported",
                      "downloadLink is only supported on Android and web");
}

void FileSaverPlugin::SaveAs(
    const SaveRequest &request,
    std::function<void(ErrorOr<std::optional<std::string>> reply)> result) {
  const std::string &inputFileName = request.name();
  if (HasInvalidFileNameCharacter(inputFileName)) {
    result(FlutterError("INVALID_FILE_NAME",
                        "The file name contains invalid Windows path characters"));
    return;
  }

  const std::string &inputExtension = request.file_extension();
  // Borrowed, never copied: a large Uint8List would otherwise double memory.
  const std::vector<uint8_t> *inputFileBytes = request.bytes();
  const std::string *inputSourcePath = request.source_path();
  if (inputSourcePath == nullptr && inputFileBytes == nullptr) {
    result(FlutterError("INVALID_ARGUMENTS",
                        "Either bytes or sourcePath must be supplied"));
    return;
  }

  std::string defaultFileName = inputFileName;
  if (request.include_extension() && !inputExtension.empty()) {
    defaultFileName +=
        inputExtension[0] == '.' ? inputExtension : ("." + inputExtension);
  }

  // Heap buffers: no fixed-size statics to overflow or to corrupt when a
  // second call arrives while the dialog is up.
  std::vector<wchar_t> szFile(32768, L'\0');
  const std::wstring wideDefaultFileName = Utf8ToWide(defaultFileName);
  if (wideDefaultFileName.size() >= szFile.size()) {
    result(FlutterError("FILE_NAME_TOO_LONG", "The file name is too long"));
    return;
  }
  std::copy(wideDefaultFileName.begin(), wideDefaultFileName.end(),
            szFile.begin());

  std::vector<wchar_t> lpstrFilter = FileExtensionToFileFilter(inputExtension);
  const std::wstring initialDirectory =
      Utf8ToWide(request.initial_directory() ? *request.initial_directory() : "");
  const std::wstring dialogTitle =
      Utf8ToWide(request.dialog_title() ? *request.dialog_title() : "");

  OPENFILENAMEW ofn = {};
  ofn.lStructSize = sizeof(ofn);
  ofn.hwndOwner = OwnerWindow();
  ofn.lpstrFilter = lpstrFilter.data();
  ofn.lpstrFile = szFile.data();
  ofn.nMaxFile = static_cast<DWORD>(szFile.size());
  ofn.lpstrInitialDir =
      initialDirectory.empty() ? nullptr : initialDirectory.c_str();
  ofn.lpstrTitle = dialogTitle.empty() ? nullptr : dialogTitle.c_str();
  ofn.Flags = OFN_OVERWRITEPROMPT | OFN_PATHMUSTEXIST | OFN_HIDEREADONLY |
              OFN_NOCHANGEDIR;

  if (!GetSaveFileNameW(&ofn)) {
    const DWORD dialogError = CommDlgExtendedError();
    if (dialogError == 0) {
      // The user cancelled.
      result(std::optional<std::string>());
    } else {
      result(FlutterError("DIALOG_ERROR", "The save dialog failed with error " +
                                              std::to_string(dialogError)));
    }
    return;
  }

  const std::wstring filePath(szFile.data());
  std::ofstream file(std::filesystem::path(filePath),
                     std::ios::binary | std::ios::trunc);
  if (!file.is_open()) {
    result(FlutterError("FILE_WRITE_ERROR",
                        "Failed to write file to selected location"));
    return;
  }

  if (inputSourcePath != nullptr) {
    std::ifstream source_file(
        std::filesystem::path(Utf8ToWide(*inputSourcePath)), std::ios::binary);
    if (!source_file.is_open()) {
      result(FlutterError("FILE_READ_ERROR", "Failed to read source file"));
      return;
    }
    // 1 MiB on the heap; a stack array this size overflows the default stack.
    std::vector<char> buffer(1024 * 1024);
    while (source_file) {
      source_file.read(buffer.data(),
                       static_cast<std::streamsize>(buffer.size()));
      file.write(buffer.data(), source_file.gcount());
    }
  } else {
    file.write(reinterpret_cast<const char *>(inputFileBytes->data()),
               static_cast<std::streamsize>(inputFileBytes->size()));
  }
  file.close();
  if (file.fail()) {
    result(FlutterError("FILE_WRITE_ERROR", "Writing the file failed"));
    return;
  }

  result(std::optional<std::string>(WideToUtf8(filePath)));
}

}  // namespace file_saver

void FileSaverPluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  file_saver::FileSaverPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
