import 'package:flutter_test/flutter_test.dart';
import 'package:one_guntha/core/auth/mobile_role_policy.dart';
import 'package:one_guntha/core/error/app_exception.dart';

void main() {
  group('MobileRolePolicy', () {
    test('allows USER and AGENT', () {
      expect(MobileRolePolicy.isAllowed('USER'), isTrue);
      expect(MobileRolePolicy.isAllowed('AGENT'), isTrue);
      expect(MobileRolePolicy.isAgent('AGENT'), isTrue);
    });

    test('blocks ADMIN and BLOG', () {
      expect(MobileRolePolicy.isAllowed('ADMIN'), isFalse);
      expect(MobileRolePolicy.isAllowed('BLOG'), isFalse);
      expect(
        () => MobileRolePolicy.ensureAllowed('ADMIN'),
        throwsA(isA<ForbiddenException>()),
      );
    });
  });
}
