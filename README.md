# FileSaver
[![Discord](https://www.hassanansari.dev/public/file_saver_discord.png)](https://discord.gg/4yRFt68kty)


## Huge Shoutout to all the contributors and the people who are using this package, I'm really grateful to all of you. Thank you for your support.

This plugin package primarily focuses on one task: saving files on Android, iOS, Web, Windows, MacOS, and Linux. 
It might not have a plethora of features, but it does this job well.
This package depends on path_provider for Android and iOS, browser download APIs for Web, and platform file APIs for desktop. The main reason I built this plugin was to
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
      String fileExtension = "",
      bool includeExtension = true,
      MimeType mimeType = MimeType.other,
      String? customMimeType,
      Dio? dioClient,
      Uint8List Function(Uint8List)? transformDioResponse,
});
```

This saveFile() method has 9 Named arguments.

_String name_ which takes the name of the file,\
_Uint8List bytes_ which will be your actual encoded file,\
Or\
_File file_ which will be your file in the File object (from dart:io)\
Or\
_Stirng filePath_ which will be your file path\
Or\
_LinkDetails link_ which will provide the link, header, request methid and body to your file. LinkDetails can be used as 
```dart
LinkDetails(
      link: "https://www.example.com/file.extentions",
      headers: {"your-header-key": "you-header-value"},
      method: "POST",
      body: body
)
```
\
Out of these parameters, you will have to use atleast one

_String fileExtension_ this will be your file extension.\
_bool includeExtension_ this controls whether to include the extension in the saved file name. Set to false to save files without extension (e.g., "myfile" instead of "myfile.txt"). Defaults to true.\
Another parameter is _MimeType type_ Specifically for Web, which will be your file
type

_String customMimeType_ this will be your custom mime type, if you want to use your own mime type, you can use this parameter

_Dio dioClient_ this will be your dio client, if you want to use dio for downloading the file, you can use this parameter

_Uint8List Function(Uint8List) transformDioResponse_ this will be your function to transform the response, if you want to transform the response as per your requirement, you can use this parameter

MimeType is also included in my Package, I've included types for **Sheets, Presentation, Word, Plain Text, PDF,
MP3, MP4 and many other common formats**

or you can call saveAs() _available for Android, iOS, macOS, Windows, and Web_

```dart
await FileSaver.instance.saveAs({
      required String name,
      Uint8List? bytes,
      File? file,
      String? filePath,
      LinkDetails? link,
      String fileExtension = "",
      bool includeExtension = true,
      required MimeType mimeType,
      String? customMimeType,
      Dio? dioClient,
      Uint8List Function(Uint8List)? transformDioResponse,
});
```

All the parameters in this method is same as the saveFile() method.

For very large direct URL downloads, prefer handing the URL to the browser on
web or Android DownloadManager so the app does not fetch the full file into
memory:

```dart
await FileSaver.instance.downloadLink(
  link: LinkDetails(link: "https://example.com/large-file.zip"),
  name: "large-file.zip",
);
```

`downloadLink` is a browser/system handoff. On Web it cannot attach custom
headers such as `Authorization`. Browser-managed cookies may be sent only if the
URL and cookie policy allow it. On Android, `downloadLink` uses
DownloadManager and can pass request headers.

For authenticated large downloads on Web, use `saveLinkAsStream`. It uses
`fetch`, so request headers and browser-managed credentials can be included,
then it streams the response into a user-selected file:

```dart
await FileSaver.instance.saveLinkAsStream(
  name: "private-export",
  link: LinkDetails(
    link: "https://example.com/private/export.zip",
    headers: {"Authorization": "Bearer token"},
  ),
  fileExtension: "zip",
  includeCredentials: true,
);
```

This Web path requires the File System Access API and CORS permission from the
server. JavaScript cannot manually set the `Cookie` header; use normal browser
session cookies, a signed URL, or an `Authorization` header instead.

For native platforms, prefer `filePath`/`file` or `saveAsStream` for large
generated content so the final save step can stream/copy from disk. On Web,
`saveAsStream` uses the File System Access API where the browser supports it:

```dart
await FileSaver.instance.saveAsStream(
  name: "large-export",
  stream: myByteStream,
  fileExtension: "zip",
  mimeType: MimeType.zip,
);
```

### Large files on Web

Web has different behavior depending on where the data comes from:

| Use case | Recommended API | Memory behavior | Browser support |
| --- | --- | --- | --- |
| Direct public/signed URL | `downloadLink` | Browser handles the download; the Flutter app does not hold the full file | Chrome, Edge, Firefox, Safari |
| Direct URL with request headers | `saveLinkAsStream` | Fetch streams the response into a user-selected file | Chrome/Edge and other browsers that implement the File System Access API |
| Already have `Uint8List` bytes | `saveFile` / `saveAs` | Creates a `Blob`, so the full file is held in browser memory | Chrome, Edge, Firefox, Safari |
| App-generated stream | `saveAsStream` | Writes chunks to a user-selected file without creating a giant `Blob` | Chrome/Edge and other browsers that implement the File System Access API |
| Local file path | Not supported on Web | Browsers do not expose real local file paths to web apps | Not available |

Firefox/Mozilla and Safari do not currently provide the writable File System
Access API needed by `saveAsStream`. For very large files in those browsers,
use `downloadLink` with a direct server/CDN/S3 URL so the browser download
manager streams the file to disk. Avoid passing multi-GB `Uint8List` values to
`saveFile`/`saveAs` on Web because that path must create a `Blob` in memory.

### Note: customMimeType can only be used when mimeType is set to MimeType.custom

### Usage Examples:

**Save file with extension (default behavior):**
```dart
await FileSaver.instance.saveFile(
  name: "my_document",
  bytes: fileBytes,
  fileExtension: "pdf",
  mimeType: MimeType.pdf,
);
// Saves as: my_document.pdf
```

**Save file without extension:**
```dart
await FileSaver.instance.saveFile(
  name: "my_document",
  bytes: fileBytes,
  fileExtension: "pdf",
  includeExtension: false,
  mimeType: MimeType.pdf,
);
// Saves as: my_document
```

**Save file from URL without extension:**
```dart
await FileSaver.instance.saveFile(
  name: "downloaded_file",
  link: LinkDetails(link: "https://example.com/file.pdf"),
  fileExtension: "pdf",
  includeExtension: false,
  mimeType: MimeType.pdf,
);
// Saves as: downloaded_file
```

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

### Contributors

