# Changelog

All notable changes to this project will be documented in this file.

## [0.2.12]
 * Minor network related bug fixes, fixing issue [#105](https://github.com/incrediblezayed/file_saver/issues/105) 
 * & Issue [#106](https://github.com/incrediblezayed/file_saver/issues/106)

## [0.2.11]
 * Merged PR [#87](https://github.com/incrediblezayed/file_saver/pull/87) for backward compatibility with the older versions of java

## [0.2.10]
 * Moved from `http` to `dio` for better control over the headers and other options
 * LinkDetails has more options such as `method` & `body`\
   here is the example of how to use the LinkDetails
   ```dart
    LinkDetails(
        link: "www.example.com/file.extention",
        headers: /// Your headers here,
        method: /// Your method here (GET, POST, PUT, DELETE, PATCH),
        body: /// Request body here
    ),
    ```
 * Both `saveFile` and `saveAs` methods now have the `dioClient` & `transformDioResponse` as a parameter, so you can pass your own dio client to the method and it will use that client to download the file & you can also pass the `transformDioResponse` to transform the response as per your requirement.\
    ```dart
    await FileSaver.instance.saveFile(
                      name: "FileName",
                      link: "www.example.com/file.extention", 
                      filePath: "pathOfFile",
                      file: File(),
                      bytes: bytes,
                      ext: "extention",
                      mimeType: MimeType.pdf,
                      dioClient: Dio(),
                      transformDioResponse: (response) {
                        return response.data;
                      });
    ```
 * Fixed ([GitHub issue #95](https://github.com/incrediblezayed/file_saver/issues/95))
 * Fixed ([GitHub issue #92](https://github.com/incrediblezayed/file_saver/issues/92))

## [0.2.9]
 * Merged PR [#75](https://github.com/incrediblezayed/file_saver/pull/81) resolving issue [#75][https://github.com/incrediblezayed/file_saver/issues/75]
 * Merged PR [#79](https://github.com/incrediblezayed/file_saver/pull/79) resolving issue [#78](https://github.com/incrediblezayed/file_saver/issues/78)
 * Merged PR [#74](https://github.com/incrediblezayed/file_saver/pull/74/) resolving issue [#73](https://github.com/incrediblezayed/file_saver/issues/73)
 * Merged PR [#77](https://github.com/incrediblezayed/file_saver/pull/77) for better README.md

## [0.2.8]
 * Moving saveAs() support for macOS to production.

## [0.2.7]
 * Updated the http package to the latest version (issue [#63](https://github.com/incrediblezayed/file_saver/issues/63))

## [0.2.6]
 * Merged ([PR70])(https://github.com/incrediblezayed/file_saver/pull/70), resolving the issue ([#42])(https://github.com/incrediblezayed/file_saver/issues/42)


## [0.2.5]
 * Added apng mime type
 * Added custom mimetype \
  So basically if you have a custom mimetype and it does not exists in the given enum, you can add your own mimeType using the field \
  ```dart
  String? customMimeType,
  ```
  and you will have to set the mimetype to custom and call the method like 
  ```dart
  await FileSaver.instance.saveFile(
                      name: "FileName",
                      link: "www.example.com/file.extention", 
                      filePath: "pathOfFile",
                      file: File(),
                      bytes: bytes,
                      ext: "extention",
                      customMimeType: 'YourCustomType',
                      mimeType: MimeType.custom);
  ```

 * Fixed repeated extension when using saveAs with MimeType.other on iOS ([GitHub issue #65](https://github.com/incrediblezayed/file_saver/issues/65))

## [0.2.4]
 * Bug Fix -> Link Details not available publically

## [0.2.3]
 * Replaced the ```String? link``` with ```LinkDetails? link``` in order to add headers with the link for downloading file
 * Fixed ([GitHub issue #59](https://github.com/incrediblezayed/file_saver/issues/59))

## 0.2.2
 * Implemented the web platform without method channel, using the conditional imports.

## 0.2.1
 * Fixed a bug in web ([git issue #57]("https://github.com/incrediblezayed/file_saver/issues/57))
 * Updated dart version constraints
 * Updated MimeType enum to enhanced enum (from dart 2.17.0) and removed method getMimetype(), if you want to get the mimeType from the enum you can directly write
  ```dart
    MimeType.pdf.type
  ```
  And if you want the formatted name of the given type, you can get it by
  ```dart
  MimeType.pdf.name
```



## 0.2.0
 * Fixed several issues from github
 * **Feature** Added a parameter _link_ for saving file directly through network
 * **Feature** Added filePath if you have the filepath, no need to get the bytes of the file, you can directly pass the path in _filePath_ parameter and the file_saver will do the rest
 * **Feature** Added file parameter to direct save the file from File object
 * Regardless of all the new options for saving files, bytes parameter is still there and you can still use it but, **All the parameters are optional now so you have to use atleast one of these parameter (link, filePath, file, bytes)**
 * Changed all the parameters to named instead of positional so now instead of
    ```dart
    await FileSaver.instance.saveFile("FileName", bytes, "extension", mimeType: mimeType);

    await FileSaver.instance.saveAs("File", bytes, "extension", type);
    ```
    you will have to use

    ```dart
    await FileSaver.instance.saveFile(
                      name: "FileName",
                      link: "www.example.com/file.extention", 
                      filePath: "pathOfFile",
                      file: File(),
                      bytes: bytes,
                      ext: "extention",
                      mimeType: type);

    await FileSaver.instance.saveFile(
                      name: "FileName",
                      link: "www.example.com/file.extention", 
                      filePath: "pathOfFile",
                      file: File(),
                      bytes: bytes,
                      ext: "extention",
                      mimeType: type);
    ```
    ### _link_, _filePath_, _bytes_ & _file_ are all optional parameters but any one of these parameter is required and thus you can use any one of these parameter as per your requirement

* Changed the MimeType enum values to lower case (as per dart's naming conventions)
* Upgraded everything to latest versions (gradle tools = 7.4.2, kotlin=1.8.0)


## 0.1.1
 * Updated the pub to the latest commit, fixing the issues with flutter 3.

## 0.1.0
 * Fixed the incomplete path in saveFile method ([GitHub issue #16](https://github.com/incrediblezayed/file_saver/issues/16))
 * Fixed some crashes in some folders on saveAs method with the help of [this answer](https://stackoverflow.com/a/60642994/10787445)
 * Fixed application crash issue **_reply already submitted_** with the help of [this](https://github.com/incrediblezayed/file_saver/issues/14#issuecomment-1040444757) suggestion ([GitHub issue #14](https://github.com/incrediblezayed/file_saver/issues/14))
 * Fixed **_Wrong or missing file extension when calling saveAs()_** ([GitHub issue #20](https://github.com/incrediblezayed/file_saver/issues/20))

## 0.0.12
 * Fixed Path Provider version
## 0.0.11
 * Updated Readme
 * Upgraded Path Provider
 * Updated Kotlin version to 1.16.10

## 0.0.10
 * Updated Readme
 * Due to security reasons, I'm not able to save the files to downloads folder in android, if anyone has any idea that would work on Android 11 so please connect.
## 0.0.9

* Android Permission Bug Fixed
* Other bugs fixes

## 0.0.8

* Minor Bug Fixes
* Updated Readme

## 0.0.7

* Added Save as method for Android and iOS, more coming soon 
* Bug fixes & Suggestions (Reported on Github) 

## 0.0.6

* Added More File Types

## 0.0.5

* Minor Bug Fixes

## 0.0.4

* saveFile method returns the path where the file is saved.

## 0.0.3

* Minor Bug Fixes

## 0.0.2

* Updated Guide

## 0.0.1

* File Saver for all platforms