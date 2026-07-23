import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/route_paths.dart';
import '../../../../core/error/error_mapper.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_logo.dart';
import '../../application/auth_controller.dart';

class OtpVerificationExtra {
  const OtpVerificationExtra({
    required this.email,
    required this.mobile,
    this.resendAttemptsRemaining,
    this.resendAvailableAt,
  });

  final String email;
  final String mobile;
  final int? resendAttemptsRemaining;
  final String? resendAvailableAt;
}

class OtpVerificationScreen extends ConsumerStatefulWidget {
  const OtpVerificationScreen({
    super.key,
    required this.email,
    required this.mobile,
    this.resendAttemptsRemaining,
    this.resendAvailableAt,
  });

  factory OtpVerificationScreen.fromState(GoRouterState state) {
    if (state.extra is OtpVerificationExtra) {
      final extra = state.extra! as OtpVerificationExtra;
      return OtpVerificationScreen(
        email: extra.email,
        mobile: extra.mobile,
        resendAttemptsRemaining: extra.resendAttemptsRemaining,
        resendAvailableAt: extra.resendAvailableAt,
      );
    }

    return OtpVerificationScreen(
      email: state.uri.queryParameters['email'] ?? '',
      mobile: state.uri.queryParameters['mobile'] ?? '',
      resendAttemptsRemaining: int.tryParse(state.uri.queryParameters['resendAttemptsRemaining'] ?? ''),
      resendAvailableAt: state.uri.queryParameters['resendAvailableAt'],
    );
  }

  final String email;
  final String mobile;
  final int? resendAttemptsRemaining;
  final String? resendAvailableAt;

  bool get hasPendingVerification => email.isNotEmpty && mobile.isNotEmpty;

  @override
  ConsumerState<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  bool _submitting = false;
  bool _resending = false;
  int? _resendAttemptsRemaining;
  int _resendCountdownSeconds = 0;
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    _resendAttemptsRemaining = widget.resendAttemptsRemaining;
    _startResendCountdown(widget.resendAvailableAt);
  }

  @override
  void dispose() {
    _otpController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  bool get _canResend {
    if (!widget.hasPendingVerification) return false;
    if ((_resendAttemptsRemaining ?? 1) <= 0) return false;
    return _resendCountdownSeconds <= 0;
  }

  void _startResendCountdown(String? resendAvailableAt) {
    _resendTimer?.cancel();
    if (resendAvailableAt == null || resendAvailableAt.isEmpty) {
      setState(() => _resendCountdownSeconds = 0);
      return;
    }

    final target = DateTime.tryParse(resendAvailableAt);
    if (target == null) {
      setState(() => _resendCountdownSeconds = 0);
      return;
    }

    void tick() {
      final remaining = target.difference(DateTime.now()).inSeconds;
      final seconds = remaining > 0 ? remaining : 0;
      if (!mounted) return;
      setState(() => _resendCountdownSeconds = seconds);
      if (seconds <= 0) {
        _resendTimer?.cancel();
        _resendTimer = null;
      }
    }

    tick();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (_) => tick());
  }

  String _formatCountdown(int totalSeconds) {
    final mins = totalSeconds ~/ 60;
    final secs = totalSeconds % 60;
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  Future<void> _verify() async {
    if (!_formKey.currentState!.validate() || !widget.hasPendingVerification) return;

    setState(() => _submitting = true);
    try {
      await ref.read(authControllerProvider.notifier).verifySignup(
            email: widget.email,
            mobile: widget.mobile,
            mobileOtp: _otpController.text.trim(),
          );
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registration complete. You are now logged in.'),
          backgroundColor: AppColors.success,
        ),
      );
      context.go(RoutePaths.dashboard);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ErrorMapper.toUserMessage(error)),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _resendOtp() async {
    if (!_canResend || _resending) return;

    setState(() => _resending = true);
    try {
      final result = await ref.read(authControllerProvider.notifier).resendSignupOtp(
            widget.email,
            widget.mobile,
          );
      if (!mounted) return;

      setState(() {
        _resendAttemptsRemaining = result.resendAttemptsRemaining ?? _resendAttemptsRemaining;
      });
      _startResendCountdown(result.resendAvailableAt);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message.isNotEmpty ? result.message : 'OTP resent successfully.'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ErrorMapper.toUserMessage(error)),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Verify Mobile')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: widget.hasPendingVerification
                      ? Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Center(
                                  child: AppLogo(
                                    size: AppLogoSize.medium,
                                    maxWidth: 280,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Verify your mobile',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.headlineMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Enter the 6-digit OTP sent to your mobile to complete registration',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
                              ),
                              const SizedBox(height: 32),
                              TextFormField(
                                readOnly: true,
                                initialValue: widget.email,
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                  filled: true,
                                  fillColor: AppColors.background,
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                readOnly: true,
                                initialValue: widget.mobile,
                                decoration: const InputDecoration(
                                  labelText: 'Mobile',
                                  filled: true,
                                  fillColor: AppColors.background,
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _otpController,
                                keyboardType: TextInputType.number,
                                textInputAction: TextInputAction.done,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(6),
                                ],
                                onFieldSubmitted: (_) => _verify(),
                                decoration: const InputDecoration(
                                  labelText: 'OTP (6 digits)',
                                  hintText: 'Enter OTP from SMS',
                                ),
                                validator: Validators.otp,
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'We sent an OTP to your mobile. Enter it above to verify.',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 12,
                                runSpacing: 8,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  OutlinedButton(
                                    onPressed: _canResend && !_resending ? _resendOtp : null,
                                    child: Text(_resending ? 'Resending...' : 'Resend OTP'),
                                  ),
                                  if (_resendCountdownSeconds > 0)
                                    Text(
                                      'Resend available in ${_formatCountdown(_resendCountdownSeconds)}',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                                    ),
                                  if ((_resendAttemptsRemaining ?? 1) <= 0)
                                    Text(
                                      'Daily resend limit reached. Try again after 24 hours.',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              FilledButton(
                                onPressed: _submitting ? null : _verify,
                                child: _submitting
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : const Text('Verify & Continue'),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'No pending verification found. Please sign up first.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
                            ),
                            const SizedBox(height: 16),
                            FilledButton(
                              onPressed: () => context.push(RoutePaths.signup),
                              child: const Text('Go to Sign Up'),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: TextButton(
            onPressed: () => context.push(RoutePaths.login),
            child: const Text('Back to Login'),
          ),
        ),
      ),
    );
  }
}
