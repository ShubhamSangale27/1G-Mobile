sealed class AppException implements Exception {
  const AppException(this.message);
  final String message;

  @override
  String toString() => message;
}

final class NetworkException extends AppException {
  const NetworkException([super.message = 'Unable to connect. Check your internet.']);
}

final class UnauthorizedException extends AppException {
  const UnauthorizedException([super.message = 'Invalid email or password.']);
}

final class ForbiddenException extends AppException {
  const ForbiddenException([super.message = 'You do not have permission.']);
}

final class NotFoundException extends AppException {
  const NotFoundException([super.message = 'Resource not found.']);
}

final class ValidationException extends AppException {
  const ValidationException(super.message);
}

final class ServerException extends AppException {
  const ServerException([super.message = 'Server error. Please try again.']);
}

final class SessionExpiredException extends AppException {
  const SessionExpiredException([super.message = 'Your session has expired. Please sign in again.']);
}

final class UnknownException extends AppException {
  const UnknownException([super.message = 'Something went wrong. Please try again.']);
}
