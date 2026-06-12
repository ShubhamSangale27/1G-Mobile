import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/route_paths.dart';
import '../../core/navigation/app_navigation.dart';
import '../../core/theme/app_colors.dart';
import '../../features/auth/application/auth_controller.dart';

class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.child});

  final Widget child;

  int _selectedIndex(String location, bool isAgent) {
    if (location.startsWith(RoutePaths.search)) return 1;
    if (location.startsWith(RoutePaths.blog)) return 2;
    if (isAgent && location.startsWith(RoutePaths.agent)) return 3;
    if (!isAgent && location.startsWith(RoutePaths.favorites)) return 3;
    if (location.startsWith(RoutePaths.profile) || location.startsWith(RoutePaths.dashboard)) {
      return 4;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.path;
    final isLoggedIn = ref.watch(isLoggedInProvider);
    final isAgent = ref.watch(isAgentProvider);

    return Scaffold(
      body: child,
      floatingActionButton: isAgent
          ? null
          : FloatingActionButton.extended(
              onPressed: () {
                if (!isLoggedIn) {
                  AppNavigation.openLogin(context);
                  return;
                }
                AppNavigation.push(context, RoutePaths.propertyNew);
              },
              tooltip: 'List Property',
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_home_work_outlined),
              label: const Text('List'),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: NavigationBar(
        height: 64,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        selectedIndex: _selectedIndex(location, isAgent),
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              AppNavigation.go(context, RoutePaths.home);
            case 1:
              AppNavigation.go(context, RoutePaths.search);
            case 2:
              AppNavigation.go(context, RoutePaths.blog);
            case 3:
              if (!isLoggedIn) {
                AppNavigation.openLogin(context);
              } else if (isAgent) {
                AppNavigation.go(context, RoutePaths.agent);
              } else {
                AppNavigation.go(context, RoutePaths.favorites);
              }
            case 4:
              if (!isLoggedIn) {
                AppNavigation.openLogin(context);
              } else {
                AppNavigation.go(context, RoutePaths.profile);
              }
          }
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: 'Search',
          ),
          const NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Blog',
          ),
          NavigationDestination(
            icon: Icon(isAgent ? Icons.event_note_outlined : Icons.favorite_border),
            selectedIcon: Icon(isAgent ? Icons.event_note : Icons.favorite),
            label: isAgent ? 'Visits' : 'Saved',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}
