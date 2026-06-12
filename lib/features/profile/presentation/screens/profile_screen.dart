import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../config/route_paths.dart';
import '../../../../core/error/error_mapper.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/auth/mobile_role_policy.dart';
import '../../../../features/auth/application/auth_controller.dart';
import '../../../../features/property/data/repositories/property_repository.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _loadingProfile = true;
  bool _savingProfile = false;
  bool _uploadingPhoto = false;
  bool _sendingOtp = false;
  bool _changingPassword = false;
  String? _profileImageUrl;
  String? _profileImagePreview;
  String? _passwordError;
  String? _maskedMobile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _loadingProfile = true);
    try {
      final user = await ref.read(authControllerProvider.notifier).refreshProfile();
      _applyUser(user.fullName, user.email, user.mobile, user.profileImageUrl);
    } catch (_) {
      final user = ref.read(authControllerProvider).user;
      if (user != null) {
        _applyUser(user.fullName, user.email, user.mobile, user.profileImageUrl);
      }
    } finally {
      if (mounted) setState(() => _loadingProfile = false);
    }
  }

  void _applyUser(String fullName, String email, String mobile, String? imageUrl) {
    _fullNameController.text = fullName;
    _emailController.text = email;
    _mobileController.text = mobile;
    _profileImageUrl = imageUrl;
    _profileImagePreview = imageUrl != null
        ? ref.read(mediaUrlResolverProvider).resolvePropertyImageUrl(imageUrl)
        : null;
  }

  String get _initials {
    final name = _fullNameController.text.trim();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    setState(() => _uploadingPhoto = true);
    try {
      final url = await ref.read(propertyRepositoryProvider).uploadProfileImage(file.path);
      if (!mounted) return;
      setState(() {
        _profileImageUrl = url;
        _profileImagePreview = ref.read(mediaUrlResolverProvider).resolvePropertyImageUrl(url);
        _uploadingPhoto = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo uploaded. Save profile to apply.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploadingPhoto = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ErrorMapper.toUserMessage(e))),
      );
    }
  }

  void _removePhoto() {
    setState(() {
      _profileImageUrl = null;
      _profileImagePreview = null;
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _savingProfile = true);
    try {
      final user = await ref.read(authRepositoryProvider).updateProfile(
            fullName: _fullNameController.text.trim(),
            email: _emailController.text.trim(),
            profileImageUrl: _profileImageUrl,
          );
      await ref.read(authControllerProvider.notifier).updateUser(user);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ErrorMapper.toUserMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _savingProfile = false);
    }
  }

  Future<void> _sendPasswordOtp() async {
    setState(() {
      _sendingOtp = true;
      _passwordError = null;
    });
    try {
      final result = await ref.read(authRepositoryProvider).sendChangePasswordOtp();
      if (!mounted) return;
      setState(() => _maskedMobile = result.maskedMobile);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _passwordError = ErrorMapper.toUserMessage(e));
    } finally {
      if (mounted) setState(() => _sendingOtp = false);
    }
  }

  Future<void> _changePassword() async {
    if (Validators.otp(_otpController.text) != null ||
        Validators.passwordReset(_newPasswordController.text) != null ||
        Validators.confirmPassword(_confirmPasswordController.text, _newPasswordController.text) != null) {
      setState(() => _passwordError = 'Please fill all password fields correctly');
      return;
    }
    setState(() {
      _changingPassword = true;
      _passwordError = null;
    });
    try {
      await ref.read(authRepositoryProvider).changePassword(
            otp: _otpController.text.trim(),
            newPassword: _newPasswordController.text,
          );
      if (!mounted) return;
      await ref.read(authControllerProvider.notifier).logout();
      if (!mounted) return;
      context.go(RoutePaths.login);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated. Please sign in again.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _passwordError = ErrorMapper.toUserMessage(e));
    } finally {
      if (mounted) setState(() => _changingPassword = false);
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ref.read(authControllerProvider.notifier).logout();
    if (!mounted) return;
    context.go(RoutePaths.login);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final isAgent = MobileRolePolicy.isAgent(user?.role);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        actions: [
          TextButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout, color: AppColors.danger),
            label: const Text('LOGOUT', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: _loadingProfile
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Column(
                    children: [
                      if (isAgent) ...[
                        ListTile(
                          leading: const Icon(Icons.event_note_outlined),
                          title: const Text('My Site Visits'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.go(RoutePaths.agent),
                        ),
                        const Divider(height: 1),
                      ] else ...[
                        ListTile(
                          leading: const Icon(Icons.dashboard_outlined),
                          title: const Text('Dashboard'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.push(RoutePaths.dashboard),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.home_work_outlined),
                          title: const Text('My Properties'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.push(RoutePaths.myProperties),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Profile Details', style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 40,
                                backgroundColor: AppColors.primary,
                                backgroundImage: _profileImagePreview != null
                                    ? CachedNetworkImageProvider(_profileImagePreview!)
                                    : null,
                                child: _profileImagePreview == null
                                    ? Text(_initials, style: const TextStyle(color: Colors.white, fontSize: 28))
                                    : null,
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  OutlinedButton(
                                    onPressed: _uploadingPhoto ? null : _pickPhoto,
                                    child: Text(_uploadingPhoto ? 'Uploading...' : 'Change photo'),
                                  ),
                                  if (_profileImagePreview != null)
                                    TextButton(onPressed: _removePhoto, child: const Text('Remove')),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _fullNameController,
                            decoration: const InputDecoration(labelText: 'Full name'),
                            validator: (v) => Validators.required(v, 'Full name'),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(labelText: 'Email'),
                            keyboardType: TextInputType.emailAddress,
                            validator: Validators.email,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _mobileController,
                            decoration: const InputDecoration(
                              labelText: 'Mobile (read-only)',
                              helperText: 'Contact support to change your mobile number.',
                            ),
                            readOnly: true,
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: _savingProfile ? null : _saveProfile,
                            child: Text(_savingProfile ? 'Saving...' : 'Save profile'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Change Password', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Text(
                          'We\'ll send an OTP to your registered mobile to confirm the change.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                        ),
                        if (_passwordError != null) ...[
                          const SizedBox(height: 8),
                          Text(_passwordError!, style: const TextStyle(color: AppColors.danger)),
                        ],
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: _sendingOtp ? null : _sendPasswordOtp,
                          child: Text(_sendingOtp ? 'Sending...' : 'Send OTP'),
                        ),
                        if (_maskedMobile != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'Sent to mobile ending $_maskedMobile',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _otpController,
                          decoration: const InputDecoration(labelText: 'OTP'),
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _newPasswordController,
                          decoration: const InputDecoration(labelText: 'New password'),
                          obscureText: true,
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _confirmPasswordController,
                          decoration: const InputDecoration(labelText: 'Confirm new password'),
                          obscureText: true,
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _changingPassword ? null : _changePassword,
                          child: Text(_changingPassword ? 'Updating...' : 'Update password'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.danger,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: _logout,
                    icon: const Icon(Icons.logout),
                    label: const Text('LOGOUT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
    );
  }
}
