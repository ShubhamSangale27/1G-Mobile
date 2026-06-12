import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/env_config.dart';
import '../storage/secure_storage_service.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/refresh_interceptor.dart';

final envConfigProvider = Provider<EnvConfig>((_) => EnvConfig.prod);

final secureStorageProvider = Provider<SecureStorageService>((_) => SecureStorageService());

final dioProvider = Provider<Dio>((ref) {
  final config = ref.watch(envConfigProvider);
  final storage = ref.watch(secureStorageProvider);

  final refreshDio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
    headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
  ));

  final dio = Dio(BaseOptions(
    baseUrl: config.apiBaseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
    headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
  ));

  dio.interceptors.addAll([
    AuthInterceptor(storage),
    RefreshInterceptor(
      storage: storage,
      refreshDio: refreshDio,
      apiBaseUrl: config.apiBaseUrl,
      onSessionExpired: () async => storage.clearAuth(),
    ),
    if (config.isDev) LogInterceptor(requestBody: true, responseBody: true),
  ]);

  return dio;
});
