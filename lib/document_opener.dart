import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

/// Result type for document opening operations
enum DocumentResultType {
  done,
  error,
  noAppToOpen,
  permissionDenied,
}

/// Result class for document opening operations
class DocumentOpenResult {
  final DocumentResultType type;
  final String message;

  DocumentOpenResult({
    required this.type,
    required this.message,
  });

  factory DocumentOpenResult.fromJson(Map<String, dynamic> json) {
    return DocumentOpenResult(
      type: _parseResultType(json['type']),
      message: json['message'],
    );
  }

  static DocumentResultType _parseResultType(String? typeString) {
    switch (typeString) {
      case 'done':
        return DocumentResultType.done;
      case 'noAppToOpen':
        return DocumentResultType.noAppToOpen;
      case 'permissionDenied':
        return DocumentResultType.permissionDenied;
      default:
        return DocumentResultType.error;
    }
  }
}

/// DocumentOpener class that only handles PDF and CSV files
class DocumentOpener {
  static const MethodChannel _channel = MethodChannel('com.scanpay.document_opener');

  DocumentOpener._();

  /// Opens a PDF or CSV file
  ///
  /// Returns a [DocumentOpenResult] with the operation result
  static Future<DocumentOpenResult> open(String filePath) async {
    // Validate file type
    if (!_isValidFileType(filePath)) {
      return DocumentOpenResult(
        type: DocumentResultType.error,
        message: 'Only PDF and CSV files are supported',
      );
    }

    // Handle desktop platforms
    if (!Platform.isIOS && !Platform.isAndroid) {
      int result = -1;
      if (Platform.isMacOS) {
        final process = await Process.start('open', [filePath]);
        result = await process.exitCode;
      } else if (Platform.isWindows) {
        final process = await Process.start('cmd', ['/c', 'start', '', filePath]);
        result = await process.exitCode;
      } else if (Platform.isLinux) {
        final process = await Process.start("xdg-open", [filePath]);
        result = await process.exitCode;
      } else {
        throw UnsupportedError("Unsupported platform");
      }

      return DocumentOpenResult(
        type: result == 0 ? DocumentResultType.done : DocumentResultType.error,
        message: result == 0
            ? "done"
            : result == -1
                ? "This operating system is not currently supported"
                : "There was an error opening $filePath",
      );
    }

    // For iOS and Android, use platform channel
    try {
      final result = await _channel.invokeMethod('openDocument', {
        "file_path": filePath,
      });

      final resultMap = json.decode(result) as Map<String, dynamic>;
      return DocumentOpenResult.fromJson(resultMap);
    } on PlatformException catch (e) {
      return DocumentOpenResult(
        type: DocumentResultType.error,
        message: e.message ?? 'Unknown error occurred',
      );
    }
  }

  /// Checks if the file type is valid (PDF or CSV)
  static bool _isValidFileType(String filePath) {
    final lowercasePath = filePath.toLowerCase();
    return lowercasePath.endsWith('.pdf') || lowercasePath.endsWith('.csv');
  }
}
