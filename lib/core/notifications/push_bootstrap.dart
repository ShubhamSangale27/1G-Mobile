import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/app_router.dart';
import '../../config/route_paths.dart';
import '../../features/auth/application/auth_controller.dart';
import 'notification_link_router.dart';
import 'push_notification_service.dart';

class PushBootstrap extends ConsumerStatefulWidget {
  const PushBootstrap({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<PushBootstrap> createState() => _PushBootstrapState();
}

class _PushBootstrapState extends ConsumerState<PushBootstrap> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initPush());
  }

  Future<void> _initPush() async {
    final push = ref.read(pushNotificationServiceProvider);
    await push.initialize(onTap: _handleNotificationTap);

    ref.listen<AuthState>(authControllerProvider, (previous, next) async {
      if (next.isLoggedIn && previous?.isLoggedIn != true) {
        await push.syncTokenWithBackend();
      } else if (!next.isLoggedIn && previous?.isLoggedIn == true) {
        await push.unregisterToken();
      }
    });

    if (ref.read(authControllerProvider).isLoggedIn) {
      await push.syncTokenWithBackend();
    }

    final pending = push.consumePendingTap();
    if (pending != null) {
      _handleNotificationTap(pending);
    }
  }

  void _handleNotificationTap(Map<String, String> data) {
    final linkUrl = data['linkUrl'];
    final linkTarget = data['linkTarget'] ?? 'APP';
    final router = ref.read(appRouterProvider);

    if (NotificationLinkRouter.shouldOpenExternally(
      linkUrl: linkUrl,
      linkTarget: linkTarget,
    )) {
      final uri = Uri.tryParse(linkUrl!.trim());
      if (uri != null) {
        launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return;
    }

    final route = NotificationLinkRouter.resolveInAppRoute(
      linkUrl: linkUrl,
      linkTarget: linkTarget,
    );

    if (route == null || route.isEmpty || route == RoutePaths.home) {
      router.go(RoutePaths.home);
      return;
    }

    final auth = ref.read(authControllerProvider);
    final requiresAuth = route.startsWith(RoutePaths.favorites) ||
        route.startsWith(RoutePaths.dashboard) ||
        route.startsWith(RoutePaths.agent) ||
        route.startsWith(RoutePaths.myProperties) ||
        route.startsWith(RoutePaths.propertyNew) ||
        route.contains('/edit') ||
        route.startsWith(RoutePaths.profile);

    if (requiresAuth && !auth.isLoggedIn) {
      router.go('${RoutePaths.login}?redirect=${Uri.encodeComponent(route)}');
      return;
    }

    router.go(route);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
