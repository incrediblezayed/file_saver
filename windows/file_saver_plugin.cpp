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
	return L"All Files (*.*)|*.*|";
  }

  std::string fileExtensionName = fileExtension.substr(1);
  for (auto& c : fileExtensionName) c = (char) std::toupper(c);

  std::wstring wideFileExtension = std::wstring(fileExtension.begin(), fileExtension.end());
  std::wstring wideFileExtensionName = std::wstring(fileExtensionName.begin(), fileExtensionName.end());
  return wideFileExtensionName + L" File|*." + wideFileExtensionName + L"|";
}

void FileSaverPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  if (method_call.method_name().compare("saveAs") == 0) {
    const auto& arguments = *method_call.arguments();
    const auto& mapArgs = std::get<flutter::EncodableMap>(arguments);

    const flutter::EncodableValue& inputFileNameValue = mapArgs.at(flutter::EncodableValue("name"));
    const std::string inputFileName = std::get<std::string>(inputFileNameValue);

    const flutter::EncodableValue& inputExtensionValue = mapArgs.at(flutter::EncodableValue("ext"));
    std::string inputExtension = std::get<std::string>(inputExtensionValue);

    if (!inputExtension.empty() && inputExtension[0] != '.') {
        inputExtension = "." + inputExtension;
    }

    const std::string defaultFileName = inputFileName + inputExtension;
    static wchar_t szFile[MAX_PATH] = L"";
    wcscpy_s(szFile, std::wstring(defaultFileName.begin(), defaultFileName.end()).c_str());

    std::wstring defaultFileFilter = FileExtensionToFileFilter(inputExtension);
    std::replace(defaultFileFilter.begin(), defaultFileFilter.end(), '|', '\0');

    OPENFILENAME ofn;
    ZeroMemory(&ofn, sizeof(ofn));
    ofn.lStructSize = sizeof(ofn);
    ofn.hwndOwner = NULL;
    ofn.lpstrFilter = defaultFileFilter.data();
    ofn.lpstrFile = szFile;
    ofn.nMaxFile = MAX_PATH;
    ofn.Flags = OFN_OVERWRITEPROMPT | OFN_PATHMUSTEXIST | OFN_HIDEREADONLY;

    if (GetSaveFileName(&ofn)) {
      std::vector<int64_t> value = WideStringToVector(szFile);
      result->Success(flutter::EncodableValue(value));
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
