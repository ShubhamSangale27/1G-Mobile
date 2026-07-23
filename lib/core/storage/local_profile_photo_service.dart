import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'secure_storage_service.dart';
import 'storage_keys.dart';

/// Stores profile photos on device only — not synced to the backend.
class LocalProfilePhotoService {
  LocalProfilePhotoService({
    required SecureStorageService storage,
    Future<Directory> Function()? getDocumentsDirectory,
  })  : _storage = storage,
        _getDocumentsDirectory =
            getDocumentsDirectory ?? getApplicationDocumentsDirectory;

  final SecureStorageService _storage;
  final Future<Directory> Function() _getDocumentsDirectory;

  static const _photosSubdir = 'profile_photos';

  Future<String> saveLocalPhoto(int userId, String sourceFilePath) async {
    final docs = await _getDocumentsDirectory();
    final dir = Directory('${docs.path}${Platform.pathSeparator}$_photosSubdir');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final destPath = '${dir.path}${Platform.pathSeparator}$userId.jpg';
    await File(sourceFilePath).copy(destPath);
    await _storage.write(StorageKeys.localProfilePhotoPath(userId), destPath);
    return destPath;
  }

  Future<String?> getLocalPhotoPath(int userId) async {
    final path = await _storage.read(StorageKeys.localProfilePhotoPath(userId));
    if (path == null || path.isEmpty) return null;

    if (!await File(path).exists()) {
      await _storage.delete(StorageKeys.localProfilePhotoPath(userId));
      return null;
    }

    return path;
  }

  Future<void> removeLocalPhoto(int userId) async {
    final path = await _storage.read(StorageKeys.localProfilePhotoPath(userId));
    if (path != null && path.isNotEmpty) {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    }
    await _storage.delete(StorageKeys.localProfilePhotoPath(userId));
  }
}
