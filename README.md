# document_opener

A Flutter package to open PDF and CSV files without requesting broad media permissions. This package is designed to comply with Google's policy regarding personal and sensitive user data.

## Features

- Open PDF and CSV files on Android and iOS
- No broad media permissions required
- Desktop platform support (Windows, macOS, Linux)
- Simple and easy to use API
- Proper error handling and user feedback

## Getting Started

### Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  document_opener: ^1.0.0
```

### Usage

```dart
import 'package:document_opener/document_opener.dart';

// Open a PDF or CSV file
final result = await DocumentOpener.open('/path/to/your/file.pdf');

if (result.type == DocumentResultType.done) {
  print('File opened successfully');
} else {
  print('Error: ${result.message}');
}
```

### Android Configuration

Add the following to your `android/app/src/main/AndroidManifest.xml`:

```xml
<provider
    android:name="androidx.core.content.FileProvider"
    android:authorities="${applicationId}.fileprovider"
    android:exported="false"
    android:grantUriPermissions="true">
    <meta-data
        android:name="android.support.FILE_PROVIDER_PATHS"
        android:resource="@xml/file_paths" />
</provider>
```

Create a new file `android/app/src/main/res/xml/file_paths.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<paths>
    <external-path name="external_files" path="."/>
    <external-cache-path name="external_cache_files" path="."/>
    <cache-path name="cache_files" path="."/>
    <files-path name="files" path="."/>
    <external-files-path name="external_files_path" path="."/>
</paths>
```

### iOS Configuration

No additional configuration is required for iOS.

## License

This project is licensed under the MIT License - see the LICENSE file for details. 