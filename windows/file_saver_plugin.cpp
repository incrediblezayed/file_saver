#include "include/file_saver/file_saver_plugin.h"

// This must be included before many other Windows headers.
#include <windows.h>

// For getPlatformVersion; remove unless needed for your plugin implementation.
#include <VersionHelpers.h>

#include <Commdlg.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <map>
#include <memory>
#include <sstream>
#include <algorithm>
#include <array>
#include <fstream>

namespace {

class FileSaverPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  FileSaverPlugin();

  virtual ~FileSaverPlugin();

 private:
  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

// static
void FileSaverPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "file_saver",
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<FileSaverPlugin>();

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

FileSaverPlugin::FileSaverPlugin() {}

FileSaverPlugin::~FileSaverPlugin() {}

std::vector<int64_t> WideStringToVector(const wchar_t* wideStr) {
  std::vector<int64_t> result;

  int length = 0;
  while (wideStr[length] != L'\0') {
    length++;
  }

  for (int i = 0; i < length; i++) {
    result.push_back(static_cast<int64_t>(wideStr[i]));
  }

  return result;
}

std::wstring FileExtensionToFileFilter(std::string fileExtension) {
  if (fileExtension.empty()) {
    return L"All Files\0*.*\0\0";
  }
  std::string fileExtensionName =
      fileExtension[0] == '.' ? fileExtension.substr(1) : fileExtension;
  for (auto& c : fileExtensionName) c = (char) std::toupper(c);

  std::wstring wideFileExtension = std::wstring(fileExtensionName.begin(), fileExtensionName.end());
  std::wstring wideFileExtensionName = std::wstring(fileExtensionName.begin(), fileExtensionName.end());
  return wideFileExtensionName + L" File\0*." + wideFileExtensionName + L"\0\0";
}

bool HasInvalidFileNameCharacter(const std::string& file_name) {
  if (file_name.empty() || file_name == "." || file_name == "..") {
    return true;
  }

  const std::string invalid_characters = "<>:\"/\\|?*";
  return std::any_of(file_name.begin(), file_name.end(), [&](char c) {
    return static_cast<unsigned char>(c) < 32 ||
           invalid_characters.find(c) != std::string::npos;
  });
}

void FileSaverPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  if (method_call.method_name().compare("saveAs") == 0) {
    const auto& arguments = *method_call.arguments();
    const auto& mapArgs = std::get<flutter::EncodableMap>(arguments);

    const flutter::EncodableValue& inputFileNameValue = mapArgs.at(flutter::EncodableValue("name"));
    const std::string inputFileName = std::get<std::string>(inputFileNameValue);
    if (HasInvalidFileNameCharacter(inputFileName)) {
      result->Error("INVALID_FILE_NAME", "The file name contains invalid Windows path characters");
      return;
    }

    const flutter::EncodableValue& inputExtensionValue = mapArgs.at(flutter::EncodableValue("fileExtension"));
    const std::string inputExtension = std::get<std::string>(inputExtensionValue);
    
    const flutter::EncodableValue& inputIncludeExtensionValue = mapArgs.at(flutter::EncodableValue("includeExtension"));
    const bool inputIncludeExtension = std::get<bool>(inputIncludeExtensionValue);

    const flutter::EncodableValue& inputFileValue = mapArgs.at(flutter::EncodableValue("bytes"));
    const std::vector<uint8_t> inputFileBytes = std::get<std::vector<uint8_t>>(inputFileValue);
    std::string inputSourcePath = "";
    const auto sourcePathIterator = mapArgs.find(flutter::EncodableValue("sourcePath"));
    if (sourcePathIterator != mapArgs.end() &&
        std::holds_alternative<std::string>(sourcePathIterator->second)) {
      inputSourcePath = std::get<std::string>(sourcePathIterator->second);
    }

    const std::string defaultFileName = inputFileName + (inputIncludeExtension && !inputExtension.empty() ? (inputExtension.find(".") != std::string::npos ? inputExtension : ("." + inputExtension)) : "");
    static wchar_t szFile[MAX_PATH] = L"";
    wcscpy_s(szFile, std::wstring(defaultFileName.begin(), defaultFileName.end()).c_str());

    const std::wstring defaultFileFilter = FileExtensionToFileFilter(inputExtension);
    static wchar_t lpstrFilter[MAX_PATH] = L"";
    wcscpy_s(lpstrFilter, defaultFileFilter.c_str());

    OPENFILENAME ofn;
    ZeroMemory(&ofn, sizeof(ofn));
    ofn.lStructSize = sizeof(ofn);
    ofn.hwndOwner = NULL;
    // ofn.lpstrFilter = L"All Files\0*.*\0";
    ofn.lpstrFilter = lpstrFilter;
    ofn.lpstrFile = szFile;
    ofn.nMaxFile = MAX_PATH;
    ofn.Flags = OFN_OVERWRITEPROMPT | OFN_PATHMUSTEXIST | OFN_HIDEREADONLY;

    if (GetSaveFileName(&ofn)) {
      // Write the file data to the selected path
      std::wstring filePath(szFile);
      std::ofstream file(filePath, std::ios::binary);
      
      if (file.is_open()) {
        if (!inputSourcePath.empty()) {
          std::ifstream source_file(
              std::wstring(inputSourcePath.begin(), inputSourcePath.end()),
              std::ios::binary);
          if (!source_file.is_open()) {
            result->Error("FILE_READ_ERROR", "Failed to read source file");
            return;
          }
          std::array<char, 1024 * 1024> buffer;
          while (source_file) {
            source_file.read(buffer.data(), buffer.size());
            file.write(buffer.data(), source_file.gcount());
          }
          source_file.close();
        } else {
          file.write(reinterpret_cast<const char*>(inputFileBytes.data()), inputFileBytes.size());
        }
        file.close();
        
        std::vector<int64_t> value = WideStringToVector(szFile);
        result->Success(flutter::EncodableValue(value));
      } else {
        // Failed to open file for writing
        result->Error("FILE_WRITE_ERROR", "Failed to write file to selected location");
      }
    } else {
      result->Success(flutter::EncodableValue());
    }

  } else {
    result->NotImplemented();
  }
}

}  // namespace

void FileSaverPluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  FileSaverPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
