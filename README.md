# FileSaver

This plugin package is not much but only for saving files in Android, iOS, Web, Windows, MacOS and Linux.
The package depends on path_provider for Android and iOS and basic html anchor for Web
The main reason I built this plugin was to avoid using html only for downloading files.
The plugin is pretty simple and saves the file in Downloads folder in Android, Windows, MacOS, Linux and directly downloads the file in Web, and the in iOS, the file is Saved in Application Documents Directory.

## Getting Started

The plugin itself is pretty easy to use.
Just call the method saveFile() with respective arguments.

```dart
    FileSaver.instance.saveFile(String name,List<int> bytes,String ext, mimeType: MimeType);
```


This saveFile() method takes 3 Positional Arguments.
_String name_ which takes the name of the file, _Uint8List bytes_ which will be your actual encoded file, _String ext_ this will be your file extension.
1 Optional Named Argument Specifically for Web _MimeType type_ which will be your file type,
MimeType is also included in my Package, I've included types for **Sheets, Presentation, Word, Plain Text, PDF, MP3, MP4 and many other common formats**

### Storage Permissions:
#### Android:
Go to your project folder, android/src/main/AndroidMaifest.xml
And add this above the application tag:
```xml
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
```
![AndroidManifest.xml](https://raw.githubusercontent.com/incrediblezayed/file_saver/e43220a4b49dd6f3316adce7ccb808264538b3ad/images/android.png)

#### iOS:
Go to your project folder, ios/Runner/info.plist and Add these keys:
```xml
<key>LSSupportsOpeningDocumentsInPlace</key>
<true />
<key>UIFileSharingEnabled</key>
<true />
```

#### And You're done

## Thank You For Reading this far :)