import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:one_guntha/core/storage/local_profile_photo_service.dart';
import 'package:one_guntha/core/storage/secure_storage_service.dart';
import 'package:one_guntha/core/storage/storage_keys.dart';

class _InMemorySecureStorageService extends SecureStorageService {
  _InMemorySecureStorageService() : super(storage: null);

  final Map<String, String> _store = {};

  @override
  Future<void> write(String key, String value) async {
    _store[key] = value;
  }

  @override
  Future<String?> read(String key) async => _store[key];

  @override
  Future<void> delete(String key) async {
    _store.remove(key);
  }
}

void main() {
  late Directory docsDir;
  late _InMemorySecureStorageService storage;
  late LocalProfilePhotoService service;

  setUp(() async {
    docsDir = await Directory.systemTemp.createTemp('local_profile_photo_test');
    storage = _InMemorySecureStorageService();
    service = LocalProfilePhotoService(
      storage: storage,
      getDocumentsDirectory: () async => docsDir,
    );
  });

  tearDown(() async {
    if (await docsDir.exists()) {
      await docsDir.delete(recursive: true);
    }
  });

  test('saveLocalPhoto copies file and returns persisted path', () async {
    const userId = 42;
    final source = File('${docsDir.path}${Platform.pathSeparator}source.jpg');
    await source.writeAsBytes([1, 2, 3]);

    final savedPath = await service.saveLocalPhoto(userId, source.path);

    expect(savedPath, endsWith('${Platform.pathSeparator}42.jpg'));
    expect(await File(savedPath).exists(), isTrue);
    expect(await storage.read(StorageKeys.localProfilePhotoPath(userId)), savedPath);
  });

  test('getLocalPhotoPath returns path when file exists', () async {
    const userId = 7;
    final source = File('${docsDir.path}${Platform.pathSeparator}pick.jpg');
    await source.writeAsBytes([9, 9, 9]);

    final savedPath = await service.saveLocalPhoto(userId, source.path);
    final loadedPath = await service.getLocalPhotoPath(userId);

    expect(loadedPath, savedPath);
  });

  test('getLocalPhotoPath returns null and clears key when file deleted', () async {
    const userId = 3;
    final source = File('${docsDir.path}${Platform.pathSeparator}gone.jpg');
    await source.writeAsBytes([0]);

    final savedPath = await service.saveLocalPhoto(userId, source.path);
    await File(savedPath).delete();

    final loadedPath = await service.getLocalPhotoPath(userId);

    expect(loadedPath, isNull);
    expect(await storage.read(StorageKeys.localProfilePhotoPath(userId)), isNull);
  });

  test('removeLocalPhoto deletes file and clears key', () async {
    const userId = 99;
    final source = File('${docsDir.path}${Platform.pathSeparator}remove.jpg');
    await source.writeAsBytes([4, 5, 6]);

    final savedPath = await service.saveLocalPhoto(userId, source.path);
    expect(await File(savedPath).exists(), isTrue);

    await service.removeLocalPhoto(userId);

    expect(await File(savedPath).exists(), isFalse);
    expect(await storage.read(StorageKeys.localProfilePhotoPath(userId)), isNull);
  });
}
