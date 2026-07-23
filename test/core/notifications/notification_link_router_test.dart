import 'package:flutter_test/flutter_test.dart';
import 'package:one_guntha/core/notifications/notification_link_router.dart';

void main() {
  group('NotificationLinkRouter', () {
    test('returns in-app path for relative link', () {
      expect(
        NotificationLinkRouter.resolveInAppRoute(linkUrl: '/property/42', linkTarget: 'APP'),
        '/property/42',
      );
    });

    test('normalizes 1guntha.com URLs to app routes', () {
      expect(
        NotificationLinkRouter.resolveInAppRoute(
          linkUrl: 'https://www.1guntha.com/blog/my-post',
          linkTarget: 'APP',
        ),
        '/blog/my-post',
      );
    });

    test('external target always opens browser', () {
      expect(
        NotificationLinkRouter.shouldOpenExternally(
          linkUrl: '/property/42',
          linkTarget: 'EXTERNAL',
        ),
        isTrue,
      );
    });

    test('non-app https URLs open externally', () {
      expect(
        NotificationLinkRouter.shouldOpenExternally(
          linkUrl: 'https://example.com/page',
          linkTarget: 'APP',
        ),
        isTrue,
      );
      expect(
        NotificationLinkRouter.resolveInAppRoute(
          linkUrl: 'https://example.com/page',
          linkTarget: 'APP',
        ),
        isNull,
      );
    });
  });
}
