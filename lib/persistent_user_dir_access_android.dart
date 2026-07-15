import 'package:flutter/services.dart';

/// Class for working with external directories on android.
///
/// Provides new URIs through [requestDirectoryUri] and allows creating files
/// through [writeFile].
///
/// All exceptions are caught. Optional logging can be enabled through
/// [doLogging].
class PersistentUserDirAccessAndroid {
  // Intentionally not static to improve mock- and testability

  /// Initialize class for working with external android directories.
  const PersistentUserDirAccessAndroid();

  static const _channel = MethodChannel('persistent_user_dir_access_android');

  /// Whether to print log messages.
  static bool doLogging = false;

  /// Request picking an external directory from the system.
  ///
  /// Users are responsible for persisting the returned file URI.
  ///
  /// Returns null when canceled or picking is not possible. There is no
  /// guarantee other methods work with a modified Uri.
  Future<String?> requestDirectoryUri() async {
    try {
      final uri = await _channel.invokeMethod<String>('requestDirectoryUri');
      if (uri?.isEmpty ?? true) return null;
      return uri;
    } on PlatformException catch (e) {
      if (doLogging) print('persistent_user_dir_access_android: $e');
      return null;
    }
  }

  /// Write a file named [fileName] containing [data].
  ///
  /// The file is a direct descendent from [dirUri] and has a [mimeType] such as
  /// `*/*`, `image/png` or `audio/flac`.
  ///
  /// Returns success state of the operation.
  Future<bool> writeFile(
      String dirUri, String fileName, String mimeType, Uint8List data, [bool overwrite = false]) async {
    try {
      final res =
          await _channel.invokeMethod<bool>('writeFile', <String, dynamic>{
        'dir': dirUri,
        'name': fileName,
        'mime': mimeType,
        'data': data,
        'overwrite': overwrite,
      });
      return res ?? false;
    } on PlatformException catch (e) {
      if (doLogging) print('persistent_user_dir_access_android: $e');
      return false;
    }
  }
}
