class Validators {
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(value.trim())) return 'Enter a valid email';
    return null;
  }

  static String? required(String? value, [String label = 'This field']) {
    if (value == null || value.trim().isEmpty) return '$label is required';
    return null;
  }

  static String? passwordLogin(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    return null;
  }

  static String? passwordSignup(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Minimum 8 characters';
    return null;
  }

  static String? passwordReset(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Minimum 6 characters';
    return null;
  }

  static String? mobile(String? value) {
    if (value == null || value.trim().isEmpty) return 'Mobile number is required';
    if (value.replaceAll(RegExp(r'\D'), '').length < 10) {
      return 'Enter a valid 10+ digit mobile number';
    }
    return null;
  }

  static String? otp(String? value) {
    if (value == null || value.trim().isEmpty) return 'OTP is required';
    if (!RegExp(r'^\d{6}$').hasMatch(value.trim())) return 'Enter 6-digit OTP';
    return null;
  }

  static String? confirmPassword(String? value, String other) {
    if (value == null || value.isEmpty) return 'Confirm your password';
    if (value != other) return 'Passwords do not match';
    return null;
  }
}
