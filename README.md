# FileSaver

This plugin package is not much but only for saving files in Android, iOS, Web, Windows, MacOS and Linux. The package
depends on path_provider for Android and iOS and basic html anchor for Web The main reason I built this plugin was to
avoid using html only for downloading files. The plugin is pretty simple and saves the file in Downloads folder in
Windows, MacOS, Linux and directly downloads the file in Web, in iOS, the file is Saved in Application
Documents Directory, and in Android it is saved in the applications files directory Android/data/your.package.name/file/your_file.extension.

## Getting Started

The plugin itself is pretty easy to use. Just call the method saveFile() with respective arguments.

```dart
    await FileSaver.instance.saveFile(String name, Uint8List bytes, String ext, mimeType: MimeType);
```

This saveFile() method takes 3 Positional Arguments.
_String name_ which takes the name of the file, _Uint8List bytes_ which will be your actual encoded file, _String ext_
this will be your file extension. 1 Optional Named Argument Specifically for Web _MimeType type_ which will be your file
type, MimeType is also included in my Package, I've included types for **Sheets, Presentation, Word, Plain Text, PDF,
MP3, MP4 and many other common formats**

or you can call saveAs() _only available for android and iOS at the moment_

```dart
    await
FileSaver.instance.saveAs(

String name, Uint8List
bytes,

String ext, MimeType
)
```

All the parameters in this method is same as the saveFile() method, the only difference is all the parameters here are
positional

### Storage Permissions:

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

#### And You're done

## Thank You For Reading this far :)
