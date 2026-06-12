import 'dart:convert';

import 'package:dio/dio.dart';

import '../../auth/mobile_role_policy.dart';
import '../../error/app_exception.dart';
import '../../storage/secure_storage_service.dart';
import '../../storage/storage_keys.dart';

const _retryHeader = 'X-1g-Auth-Retry';

bool _isAnonymousAuthUrl(String path) {
  return path.contains('/auth/login') ||
      path.contains('/auth/signup') ||
      path.contains('/auth/verify-signup') ||
      path.contains('/auth/resend-signup-otp') ||
      path.contains('/auth/refresh') ||
      path.contains('/auth/forgot-password');
}

/// On 401: refresh tokens and retry once — matches Angular auth-refresh interceptor.
class RefreshInterceptor extends QueuedInterceptor {
  RefreshInterceptor({
    required SecureStorageService storage,
    required Dio refreshDio,
    required String apiBaseUrl,
    this.onSessionExpired,
  })  : _storage = storage,
        _refreshDio = refreshDio,
        _apiBaseUrl = apiBaseUrl;

  final SecureStorageService _storage;
  final Dio _refreshDio;
  final String _apiBaseUrl;
  final Future<void> Function()? onSessionExpired;

  Future<void>? _refreshFuture;

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    final req = err.requestOptions;
    if (req.headers[_retryHeader] == '1' || _isAnonymousAuthUrl(req.path)) {
      return handler.next(err);
    }

    final refreshToken = await _storage.read(StorageKeys.refreshToken);
    if (refreshToken == null || refreshToken.isEmpty) {
      return handler.next(err);
    }

    try {
      await _sharedRefresh(refreshToken);
      final access = await _storage.read(StorageKeys.accessToken);
      if (access == null) return handler.next(err);

      final retry = await Dio().fetch<dynamic>(
        req.copyWith(
          headers: {
            ...req.headers,
            'Authorization': 'Bearer $access',
            _retryHeader: '1',
          },
        ),
      );
      return handler.resolve(retry);
    } catch (_) {
      await _storage.clearAuth();
      await onSessionExpired?.call();
      return handler.reject(
        DioException(
          requestOptions: req,
          error: const SessionExpiredException(),
        ),
      );
    }
  }

  Future<void> _sharedRefresh(String refreshToken) {
    _refreshFuture ??= _doRefresh(refreshToken).whenComplete(() => _refreshFuture = null);
    return _refreshFuture!;
  }

  Future<void> _doRefresh(String refreshToken) async {
    final res = await _refreshDio.post<Map<String, dynamic>>(
      '$_apiBaseUrl/auth/refresh',
      data: {'refreshToken': refreshToken},
    );
    final data = res.data;
    final access = data?['accessToken'] as String?;
    final refresh = data?['refreshToken'] as String?;
    if (access == null || refresh == null) {
      throw const SessionExpiredException();
    }
    await _storage.write(StorageKeys.accessToken, access);
    await _storage.write(StorageKeys.refreshToken, refresh);
    final user = data?['user'];
    if (user is Map<String, dynamic>) {
      final role = user['role'] as String?;
      if (!MobileRolePolicy.isAllowed(role)) {
        await _storage.clearAuth();
        throw const SessionExpiredException(MobileRolePolicy.blockedLoginMessage);
      }
      await _storage.write(StorageKeys.user, jsonEncode(user));
    }
  }
}
