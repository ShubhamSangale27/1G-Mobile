import 'dart:convert';

import '../../../../core/auth/mobile_role_policy.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/storage/storage_keys.dart';
import '../../domain/entities/user.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl {
  AuthRepositoryImpl(this._remote, this._storage);

  final AuthRemoteDatasource _remote;
  final SecureStorageService _storage;

  /// Restore session from secure storage — called on every app cold start.
  Future<AuthSession?> loadSession() async {
    final token = await _storage.read(StorageKeys.accessToken);
    final refresh = await _storage.read(StorageKeys.refreshToken);
    final userJson = await _storage.read(StorageKeys.user);
    if (token == null || token.isEmpty || userJson == null || userJson.isEmpty) {
      if (token != null || userJson != null || refresh != null) {
        await _storage.clearAuth();
      }
      return null;
    }
    try {
      final user = User.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
      if (!MobileRolePolicy.isAllowed(user.role)) {
        await _storage.clearAuth();
        return null;
      }
      return AuthSession(
        user: user,
        accessToken: token,
        refreshToken: refresh ?? '',
      );
    } catch (_) {
      await _storage.clearAuth();
      return null;
    }
  }

  Future<void> persistSession(AuthSession session) async {
    await _storage.write(StorageKeys.accessToken, session.accessToken);
    await _storage.write(StorageKeys.refreshToken, session.refreshToken);
    await _storage.write(StorageKeys.user, jsonEncode(session.user.toJson()));
  }

  Future<void> updateLocalUser(User user) async {
    await _storage.write(StorageKeys.user, jsonEncode(user.toJson()));
  }

  Future<void> clearSession() => _storage.clearAuth();

  Future<AuthSession> login(String email, String password) async {
    final session = await _remote.login(email, password);
    if (!MobileRolePolicy.isAllowed(session.user.role)) {
      await clearSession();
      MobileRolePolicy.ensureAllowed(session.user.role);
    }
    await persistSession(session);
    return session;
  }

  Future<SignupResult> signup({
    required String email,
    required String password,
    required String fullName,
    required String mobile,
  }) =>
      _remote.signup(email: email, password: password, fullName: fullName, mobile: mobile);

  Future<AuthSession> verifySignup({
    required String email,
    required String mobile,
    required String mobileOtp,
  }) async {
    final session = await _remote.verifySignup(email: email, mobile: mobile, mobileOtp: mobileOtp);
    if (!MobileRolePolicy.isAllowed(session.user.role)) {
      await clearSession();
      MobileRolePolicy.ensureAllowed(session.user.role);
    }
    await persistSession(session);
    return session;
  }

  Future<SignupResult> resendSignupOtp(String email, String mobile) =>
      _remote.resendSignupOtp(email, mobile);

  Future<void> logout() async {
    await _remote.logout();
    await clearSession();
  }

  Future<PasswordOtpResult> forgotPassword(String email) => _remote.forgotPassword(email);

  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) =>
      _remote.resetPassword(email: email, otp: otp, newPassword: newPassword);

  Future<PasswordOtpResult> sendChangePasswordOtp() => _remote.sendChangePasswordOtp();

  Future<void> changePassword({required String otp, required String newPassword}) async {
    await _remote.changePassword(otp: otp, newPassword: newPassword);
    await clearSession();
  }

  Future<void> sendEmailVerification() => _remote.sendEmailVerification();

  Future<User> getProfile() => _remote.getProfile();

  Future<User> updateProfile({
    required String fullName,
    required String email,
    String? profileImageUrl,
  }) async {
    final user = await _remote.updateProfile(
      fullName: fullName,
      email: email,
      profileImageUrl: profileImageUrl,
    );
    await updateLocalUser(user);
    return user;
  }

  Future<void> deleteAccount({required String password}) async {
    await _remote.deleteAccount(password: password);
    await clearSession();
  }
}
