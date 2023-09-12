# FileSaver
[![Discord](https://www.hassanansari.dev/public/file_saver_discord.png)](https://discord.gg/4yRFt68kty)


This plugin package primarily focuses on one task: saving files on Android, iOS, Web, Windows, MacOS, and Linux. 
It might not have a plethora of features, but it does this job well.
This package depends on path_provider for Android and iOS and basic html anchor for Web. The main reason I built this plugin was to
avoid using HTML just for downloading files. The plugin is pretty simple and saves the file in Downloads folder in
Windows, MacOS, Linux and directly downloads the file in Web, in iOS, the file is Saved in Application
Documents Directory, and in Android it is saved in the applications files directory Android/data/your.package.name/file/your_file.extension.

## Getting Started

The plugin itself is pretty easy to use. Just call the method saveFile() with respective arguments.

```dart
await FileSaver.instance.saveFile({
      required String name,
      Uint8List? bytes,
      File? file,
      String? filePath,
      LinkDetails? link,
      String ext = "",
      MimeType mimeType = MimeType.other,
      String? customMimeType
      });
```

This saveFile() method has 8 Named arguments.

_String name_ which takes the name of the file,\
_Uint8List bytes_ which will be your actual encoded file,\
Or\
_File file_ which will be your file in the File object (from dart:io)\
Or\
_Stirng filePath_ which will be your file path\
Or\
_LinkDetails link_ which will provide the link & header to your file. LinkDetails can be used as 
```dart
LinkDetails(link: "https://www.example.com/file.extentions", headers: {"your-header-key": "you-header-value"})
```
\
Out of these parameters, you will have to use atleast one

_String ext_ this will be your file extension.\
Another parameter is _MimeType type_ Specifically for Web, which will be your file
type

MimeType is also included in my Package, I've included types for **Sheets, Presentation, Word, Plain Text, PDF,
MP3, MP4 and many other common formats**

or you can call saveAs() _only available for android and iOS & macOS at the moment_

```dart
await FileSaver.instance.saveAs({
      required String name,
      Uint8List? bytes,
      File? file,
      String? filePath,
      LinkDetails? link,
      required String ext,
      required MimeType mimeType,
      String? customMimeType
      });
```

All the parameters in this method is same as the saveFile() method.

### Note: customMimeType can only be used when mimeType is set to MimeType.custom

### Storage Permissions & Network Permissions:

> ##### _These Settings are optional for iOS, as in iOS the file will be saved in application documents directory but will not be visible in Files application, to make your file visible in iOS Files application, make the changes mentioned below._

#### iOS:

Go to your project folder, ios/Runner/info.plist and Add these keys:

```xml
<key>LSSupportsOpeningDocumentsInPlace</key>
<true/>
<key>UIFileSharingEnabled</key>
<true/>
```

![iOS](https://raw.githubusercontent.com/incrediblezayed/file_saver/main/images/ios.png)

#### Or in XCode:

Open Your Project in XCode (Open XCode -> Open a project or file -> Your_Project_Folder/ios/Runner.xcworkspace)
Open info.plist Add these rows:

Application supports iTunes file sharing (Boolean -> Yes)

Supports opening documents in place (Boolean -> Yes)

![iOS Xcode](https://raw.githubusercontent.com/incrediblezayed/file_saver/main/images/iOSXcode.png)

#### macOS:

Go to your project folder, macOS/Runner/DebugProfile.entitlements

> For release you need to open 'YOUR_PROJECT_NAME'Profile.entitlements

and add the following key:

```xml
<key>com.apple.security.files.downloads.read-write</key>
<true/>
```

![MacOS](https://raw.githubusercontent.com/incrediblezayed/file_saver/main/images/macos.png)

#### Or in XCode:

Open Your Project in XCode (Open XCode -> Open a project or file -> Your_Project_Folder/macos/Runner.xcworkspace)
Open your entitlement file (DebugProfile.entitlements & 'YOUR_PROJECT_NAME'Profile.entitlements)

Add these rows:
![MacOS Xcode](https://raw.githubusercontent.com/incrediblezayed/file_saver/main/images/macOSXcode.png)

and if you get Client Socket Exception while saving files in MacOS from link,
you have to add this key in the DebugProfile.entitlements and Release.entitlements of your macOS application and set the value to true

```xml
<key>com.apple.security.network.client</key>
<true/>
```

*You can find these files in the project_folder/macos/Runner/ directory.*

#### And You're done

## Thank You For Reading this far :)
