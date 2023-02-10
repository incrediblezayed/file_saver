#include "include/file_saver/file_saver_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "file_saver_plugin.h"

void FileSaverPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  file_saver::FileSaverPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
