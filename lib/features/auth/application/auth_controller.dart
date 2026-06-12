import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/datasources/auth_remote_datasource.dart';
import '../data/repositories/auth_repository_impl.dart';
import '../domain/entities/user.dart';
import '../../../core/network/dio_client.dart';

enum AuthStatus { loading, authenticated, unauthenticated }

class AuthState {
  const AuthState({required this.status, this.user, this.error});

  const AuthState.loading() : this(status: AuthStatus.loading);
  const AuthState.authenticated(User user) : this(status: AuthStatus.authenticated, user: user);
  const AuthState.unauthenticated() : this(status: AuthStatus.unauthenticated);

  final AuthStatus status;
  final User? user;
  final String? error;

  bool get isLoggedIn => status == AuthStatus.authenticated && user != null;
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._repo) : super(const AuthState.loading()) {
    _hydrate();
  }

  final AuthRepositoryImpl _repo;

  /// Restore persisted session — user stays logged in across app restarts.
  Future<void> _hydrate() async {
    final session = await _repo.loadSession();
    if (session != null) {
      state = AuthState.authenticated(session.user);
    } else {
      state = const AuthState.unauthenticated();
    }
  }

  Future<void> login(String email, String password) async {
    final session = await _repo.login(email, password);
    state = AuthState.authenticated(session.user);
  }

  Future<SignupResult> signup({
    required String email,
    required String password,
    required String fullName,
    required String mobile,
  }) =>
      _repo.signup(email: email, password: password, fullName: fullName, mobile: mobile);

  Future<void> verifySignup({
    required String email,
    required String mobile,
    required String mobileOtp,
  }) async {
    final session = await _repo.verifySignup(email: email, mobile: mobile, mobileOtp: mobileOtp);
    state = AuthState.authenticated(session.user);
  }

  Future<SignupResult> resendSignupOtp(String email, String mobile) =>
      _repo.resendSignupOtp(email, mobile);

  /// Explicit logout only — clears secure storage.
  Future<void> logout() async {
    await _repo.logout();
    state = const AuthState.unauthenticated();
  }

  Future<void> updateUser(User user) async {
    await _repo.updateLocalUser(user);
    state = AuthState.authenticated(user);
  }

  Future<User> refreshProfile() async {
    final user = await _repo.getProfile();
    await _repo.updateLocalUser(user);
    state = AuthState.authenticated(user);
    return user;
  }

  void clearOnSessionExpired() {
    state = const AuthState.unauthenticated();
  }
}

final authRepositoryProvider = Provider<AuthRepositoryImpl>((ref) {
  return AuthRepositoryImpl(
    AuthRemoteDatasource(ref.watch(dioProvider)),
    ref.watch(secureStorageProvider),
  );
});

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref.watch(authRepositoryProvider));
});

final isLoggedInProvider = Provider<bool>((ref) => ref.watch(authControllerProvider).isLoggedIn);

final currentUserProvider = Provider<User?>((ref) => ref.watch(authControllerProvider).user);

final isAgentProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.role.toUpperCase() == 'AGENT';
});
