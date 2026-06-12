import 'package:dio/dio.dart';

import 'app_exception.dart';

/// Mirrors Angular `extractHttpErrorMessage`.
class ErrorMapper {
  static String toUserMessage(Object error) {
    if (error is AppException) return error.message;
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map) {
        final message = data['message'];
        if (message is String && message.trim().isNotEmpty) return message.trim();
        final err = data['error'];
        if (err is String && err.trim().isNotEmpty) return err.trim();
      }
      if (error.response?.data is String) {
        final s = (error.response!.data as String).trim();
        if (s.isNotEmpty) return s;
      }
      final status = error.response?.statusCode;
      if (status == 0 || error.type == DioExceptionType.connectionError) {
        return 'Unable to connect to the server. Please check your internet connection.';
      }
      if (status == 401) return 'Invalid email or password.';
      if (status == 403) return 'You do not have permission to perform this action.';
      if (status != null && status >= 500) {
        return 'Something went wrong on the server. Please try again.';
      }
      return error.message ?? 'Something went wrong. Please try again.';
    }
    return 'Something went wrong. Please try again.';
  }

  static AppException fromDio(DioException e) {
    final status = e.response?.statusCode;
    final msg = toUserMessage(e);
    if (status == 401) return UnauthorizedException(msg);
    if (status == 403) return ForbiddenException(msg);
    if (status == 404) return NotFoundException(msg);
    if (status != null && status >= 500) return ServerException(msg);
    if (e.type == DioExceptionType.connectionError) return NetworkException(msg);
    return ValidationException(msg);
  }
}
