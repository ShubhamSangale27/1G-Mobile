import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';

class DeviceTokenRepository {
  DeviceTokenRepository(this._dio);

  final Dio _dio;

  Future<void> registerToken({required String token, required String platform}) async {
    await _dio.post('/devices/fcm-token', data: {
      'token': token,
      'platform': platform,
    });
  }

  Future<void> deactivateToken(String token) async {
    await _dio.delete('/devices/fcm-token', queryParameters: {'token': token});
  }
}

final deviceTokenRepositoryProvider = Provider<DeviceTokenRepository>((ref) {
  return DeviceTokenRepository(ref.watch(dioProvider));
});
