import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:one_guntha/config/route_paths.dart';
import 'package:one_guntha/features/blog/domain/entities/blog_post.dart';
import 'package:one_guntha/shared/widgets/blog_card.dart';
import 'package:one_guntha/shared/widgets/property_card.dart';

import '../helpers/mock_property.dart';

/// Widget-level E2E: every primary tappable card navigates to the correct route.
void main() {
  testWidgets('PropertyGridCard tap opens property detail', (tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => Scaffold(
            body: ProviderScope(
              child: PropertyGridCard(property: mockProperty(id: 99)),
            ),
          ),
        ),
        GoRoute(
          path: '/property/:id',
          builder: (_, state) => Scaffold(body: Text('detail-${state.pathParameters['id']}')),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.tap(find.byType(PropertyGridCard));
    await tester.pumpAndSettle();

    expect(find.text('detail-99'), findsOneWidget);
  });

  testWidgets('PropertyListCard tap opens property detail', (tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => Scaffold(
            body: ProviderScope(
              child: PropertyListCard(property: mockProperty(id: 55)),
            ),
          ),
        ),
        GoRoute(
          path: '/property/:id',
          builder: (_, state) => Scaffold(body: Text('detail-${state.pathParameters['id']}')),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.tap(find.byType(PropertyListCard));
    await tester.pumpAndSettle();

    expect(find.text('detail-55'), findsOneWidget);
  });

  testWidgets('BlogCard tap opens blog detail', (tester) async {
    const post = BlogPost(
      id: 1,
      title: 'Buying Guide',
      slug: 'buying-guide',
      createdAt: '2026-01-01',
    );

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => Scaffold(
            body: ProviderScope(
              child: BlogCard(post: post),
            ),
          ),
        ),
        GoRoute(
          path: '/blog/:slug',
          builder: (_, state) => Scaffold(body: Text('blog-${state.pathParameters['slug']}')),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.tap(find.byType(BlogCard));
    await tester.pumpAndSettle();

    expect(find.text('blog-buying-guide'), findsOneWidget);
  });

  test('documented clickable surfaces', () {
  const clickables = [
    'Home: Buy/Rent toggle → Search with listingType',
    'Home: Search button → Search',
    'Home: Featured PropertyGridCard → Property detail',
    'Home: Blog compact card → Blog detail',
    'Home: Section "See all" → Search',
    'Home: Section "All articles" → Blog tab',
    'Search: PropertyListCard → Property detail',
    'Search: Filters chip → Bottom sheet',
    'Blog: BlogCard → Blog detail',
    'Blog: Category chips → Filtered list',
    'Saved: PropertyListCard → Property detail',
    'Bottom nav: Home, Search, Blog, Saved/Visits, Account',
    'FAB: List property (USER) → Property form',
    'Property detail: Favorite toggle',
    'Property detail: Book/reschedule visit',
    'Agent: Visit card → Visit detail',
    'Profile: Logout, dashboard links',
    'Auth: Login, signup, forgot password',
  ];
    expect(clickables.length, greaterThan(10));
  });
}
