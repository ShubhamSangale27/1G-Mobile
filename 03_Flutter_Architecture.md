# 03 — 1Guntha Flutter Architecture

**Document version:** 1.0  
**Date:** 2026-06-10  
**Prerequisite:** `01_Project_Analysis.md`, `02_Flutter_Migration_Plan.md`

---

## Table of Contents

1. [Architecture Overview](#1-architecture-overview)
2. [Folder Structure](#2-folder-structure)
3. [Layer Responsibilities](#3-layer-responsibilities)
4. [State Management Strategy](#4-state-management-strategy)
5. [Repository Strategy](#5-repository-strategy)
6. [DTO Strategy](#6-dto-strategy)
7. [Error Handling Strategy](#7-error-handling-strategy)
8. [Caching Strategy](#8-caching-strategy)
9. [Offline Strategy](#9-offline-strategy)
10. [Security Strategy](#10-security-strategy)
11. [Navigation Strategy](#11-navigation-strategy)
12. [Networking Strategy](#12-networking-strategy)
13. [Theme & Design System](#13-theme--design-system)
14. [Testing Strategy](#14-testing-strategy)
15. [Code Generation](#15-code-generation)
16. [Dependency Injection](#16-dependency-injection)
17. [Feature Module Template](#17-feature-module-template)
18. [Cross-Cutting Concerns](#18-cross-cutting-concerns)

---

## 1. Architecture Overview

### 1.1 Clean Architecture Layers

```
┌─────────────────────────────────────────────────────────┐
│                    PRESENTATION                          │
│  Screens, Widgets, Riverpod Consumers/Controllers        │
├─────────────────────────────────────────────────────────┤
│                    APPLICATION                           │
│  Use Cases (optional), StateNotifiers, Providers         │
├─────────────────────────────────────────────────────────┤
│                      DOMAIN                              │
│  Entities, Repository Interfaces, Value Objects          │
├─────────────────────────────────────────────────────────┤
│                       DATA                               │
│  Repository Impl, DTOs, Remote/Local Data Sources        │
├─────────────────────────────────────────────────────────┤
│                    NETWORK / STORAGE                     │
│  Dio Client, Interceptors, Secure Storage, Cache         │
└─────────────────────────────────────────────────────────┘
```

### 1.2 Dependency Rule

**Dependencies point inward only.**

- Presentation → Application → Domain ← Data
- Domain has **zero** imports from Flutter, Dio, or data layer
- Data implements domain repository interfaces
- Application layer orchestrates; no UI widgets

### 1.3 Mapping from Angular

| Angular | Flutter Layer |
|---------|---------------|
| `*.component.ts` (template + logic) | `presentation/screens/` + `presentation/widgets/` |
| `AuthService` signals | `application/auth_controller.dart` |
| `ApiService` | `data/datasources/*_remote_datasource.dart` |
| `*.model.ts` | `domain/entities/` + `data/models/*_dto.dart` |
| Guards | GoRouter `redirect` + `RouteGuard` utils |
| Interceptors | Dio `Interceptor` classes |
| `image-url.util.ts` | `core/utils/media_url_resolver.dart` |

---

## 2. Folder Structure

```
1G-Mobile/
├── android/
├── ios/
├── assets/
│   ├── images/
│   ├── fonts/                    # Optional self-hosted fonts
│   └── l10n/                     # ARB files (Phase 5)
├── lib/
│   ├── main.dart                 # Entry — flavor bootstrap
│   ├── main_dev.dart
│   ├── main_prod.dart
│   │
│   ├── config/
│   │   ├── env_config.dart       # API URL, keys per flavor
│   │   ├── app_router.dart       # GoRouter definition
│   │   ├── route_paths.dart      # Path constants
│   │   └── firebase_config.dart  # Analytics/Crashlytics init
│   │
│   ├── core/
│   │   ├── constants/
│   │   │   ├── api_endpoints.dart
│   │   │   └── app_constants.dart
│   │   ├── data/
│   │   │   └── indian_locations.dart
│   │   ├── error/
│   │   │   ├── app_exception.dart
│   │   │   ├── failure.dart
│   │   │   └── error_mapper.dart
│   │   ├── network/
│   │   │   ├── dio_client.dart
│   │   │   ├── api_response.dart
│   │   │   └── interceptors/
│   │   │       ├── auth_interceptor.dart
│   │   │       ├── refresh_interceptor.dart
│   │   │       └── error_interceptor.dart
│   │   ├── storage/
│   │   │   ├── secure_storage_service.dart
│   │   │   └── storage_keys.dart
│   │   ├── theme/
│   │   │   ├── app_theme.dart
│   │   │   ├── app_colors.dart
│   │   │   ├── app_typography.dart
│   │   │   └── app_spacing.dart
│   │   └── utils/
│   │       ├── media_url_resolver.dart
│   │       ├── indian_price_formatter.dart
│   │       ├── date_time_utils.dart
│   │       └── validators.dart
│   │
│   ├── shared/
│   │   ├── extensions/
│   │   ├── models/
│   │   │   └── page_response.dart
│   │   └── widgets/
│   │       ├── app_scaffold.dart
│   │       ├── app_button.dart
│   │       ├── app_text_field.dart
│   │       ├── skeleton_loader.dart
│   │       ├── error_view.dart
│   │       ├── empty_view.dart
│   │       ├── property_card.dart
│   │       ├── price_tag.dart
│   │       ├── status_badge.dart
│   │       ├── otp_input.dart
│   │       └── pull_to_refresh_wrapper.dart
│   │
│   └── features/
│       ├── auth/
│       │   ├── data/
│       │   │   ├── datasources/auth_remote_datasource.dart
│       │   │   ├── models/
│       │   │   │   ├── user_dto.dart
│       │   │   │   ├── auth_response_dto.dart
│       │   │   │   └── signup_response_dto.dart
│       │   │   └── repositories/auth_repository_impl.dart
│       │   ├── domain/
│       │   │   ├── entities/user.dart
│       │   │   └── repositories/auth_repository.dart
│       │   ├── application/
│       │   │   ├── auth_controller.dart
│       │   │   └── auth_providers.dart
│       │   └── presentation/
│       │       ├── screens/
│       │       │   ├── login_screen.dart
│       │       │   ├── signup_screen.dart
│       │       │   ├── otp_verification_screen.dart
│       │       │   └── forgot_password_screen.dart
│       │       └── widgets/
│       │
│       ├── home/
│       ├── search/
│       ├── property/
│       ├── favorites/
│       ├── dashboard/
│       ├── my_properties/
│       ├── property_form/
│       ├── profile/
│       ├── site_visits/
│       ├── notifications/
│       ├── agent/
│       ├── admin/
│       ├── blog/
│       └── blog_editor/
│
├── test/
│   ├── core/
│   ├── features/
│   └── shared/
├── integration_test/
├── pubspec.yaml
└── analysis_options.yaml
```

---

## 3. Layer Responsibilities

### 3.1 Presentation

- `ConsumerWidget` / `ConsumerStatefulWidget`
- Reads state from Riverpod providers
- Delegates actions to controllers/notifiers
- **No** direct Dio calls
- **No** JSON parsing

### 3.2 Application

- `StateNotifier` / `@riverpod` async providers
- Holds `AsyncValue<T>` for loading/error/data
- Calls repository methods
- Maps `Failure` → user messages
- Coordinates multi-step flows (signup → OTP)

### 3.3 Domain

- Pure Dart entities (equatable or freezed)
- Abstract repository interfaces
- Business rules that are UI-independent
- Example: `bool get isAdmin => role == UserRole.admin`

### 3.4 Data

- DTOs with `@JsonSerializable` / `@freezed`
- `*_remote_datasource.dart` — raw Dio calls
- `*_repository_impl.dart` — DTO → entity mapping
- Handles `PageResponse` unwrapping

---

## 4. State Management Strategy

### 4.1 Riverpod 2.x (Primary)

| Pattern | Use Case |
|---------|----------|
| `@riverpod` future | One-shot API fetch (property detail) |
| `@riverpod` class notifier | Paginated list with load-more (search) |
| `StateNotifier` | Auth session state |
| `Provider` | Repositories, Dio, config singletons |
| `family` | Parameterized providers (`propertyDetailProvider(id)`) |

### 4.2 Auth State (Critical)

```dart
// Conceptual — not generated code
@Riverpod(keepAlive: true)
class AuthController extends _$AuthController {
  @override
  AuthState build() => const AuthState.unauthenticated();

  Future<void> login(String email, String password) async { ... }
  Future<void> logout() async { ... }
  Future<bool> refreshSession() async { ... }
}
```

**AuthState variants:**
- `unauthenticated`
- `authenticated(User user, String accessToken)`
- `loading`

### 4.3 List State Pattern

```dart
// Search results with pagination
class PropertyListState {
  final List<Property> items;
  final int currentPage;
  final bool hasMore;
  final bool isLoadingMore;
  final Object? error;
}
```

### 4.4 What We Avoid

- ❌ BLoC (unnecessary boilerplate for this app size)
- ❌ Global `setState` in root
- ❌ Provider without codegen (prefer `@riverpod` annotations)
- ❌ Storing API responses in widgets

### 4.5 Angular Signal Parity

| Angular | Riverpod |
|---------|----------|
| `user = signal<User \| null>` | `authControllerProvider` |
| `isLoggedIn = computed(...)` | `isLoggedInProvider` (derived) |
| `localStorage` hydrate on init | `AuthController.build()` reads secure storage |

---

## 5. Repository Strategy

### 5.1 Interface per Feature (Domain)

```dart
abstract class PropertyRepository {
  Future<PageResponse<Property>> search(PropertySearchParams params);
  Future<List<Property>> getFeatured();
  Future<Property> getById(int id, {bool includeAnalytics = false});
  Future<PageResponse<Property>> getMyProperties({int page = 0, int size = 12});
  Future<Property> create(PropertyCreateRequest request);
  Future<Property> update(int id, PropertyCreateRequest request);
  Future<void> delete(int id);
  Future<bool> isInWatchlist(int propertyId);
  Future<void> addToWatchlist(int propertyId);
  Future<void> removeFromWatchlist(int propertyId);
  Future<List<Property>> getWatchlist();
}
```

### 5.2 Single Repository per Aggregate

| Repository | APIs Covered |
|------------|-------------|
| `AuthRepository` | All `/auth/*` + session |
| `UserRepository` | `/users/me`, `/upload` |
| `PropertyRepository` | `/properties/*` |
| `SiteVisitRepository` | `/sitevisits/*` |
| `AgentRepository` | `/agent/*` |
| `AlertRepository` | `/alerts/*` |
| `CarouselRepository` | `/carousel/*` |
| `BlogRepository` | `/blogs/*` |
| `AdminRepository` | `/admin/*` |

### 5.3 Return Types

- Repositories return **entities** or `Either<Failure, T>` (optional; can throw `AppException` mapped in application layer)
- Never expose DTOs above data layer

---

## 6. DTO Strategy

### 6.1 Freezed + JsonSerializable

```dart
@freezed
class PropertyDto with _$PropertyDto {
  const factory PropertyDto({
    required int id,
    required String title,
    required String listingType,
    required String propertyType,
    required double price,
    // ...
    List<PropertyImageDto>? images,
  }) = _PropertyDto;

  factory PropertyDto.fromJson(Map<String, dynamic> json) =>
      _$PropertyDtoFromJson(json);
}
```

### 6.2 DTO → Entity Mapping

```dart
extension PropertyDtoX on PropertyDto {
  Property toEntity() => Property(
    id: id,
    title: title,
    listingType: ListingType.fromString(listingType),
    // ...
  );
}
```

### 6.3 Enum Handling

Backend sends strings (`SALE`, `RENT`). Domain uses typed enums:

```dart
enum ListingType { sale, rent }

extension ListingTypeParsing on ListingType {
  static ListingType fromString(String value) => switch (value) {
    'SALE' => ListingType.sale,
    'RENT' => ListingType.rent,
    _ => throw ArgumentError('Unknown listing type: $value'),
  };

  String toApiString() => switch (this) {
    ListingType.sale => 'SALE',
    ListingType.rent => 'RENT',
  };
}
```

### 6.4 Request DTOs

Separate immutable request objects for POST/PUT bodies matching Angular payloads exactly.

---

## 7. Error Handling Strategy

### 7.1 Exception Hierarchy

```dart
sealed class AppException implements Exception {
  const AppException(this.message);
  final String message;
}

class NetworkException extends AppException { ... }
class UnauthorizedException extends AppException { ... }
class ForbiddenException extends AppException { ... }
class NotFoundException extends AppException { ... }
class ValidationException extends AppException { ... }
class ServerException extends AppException { ... }
class SessionExpiredException extends AppException { ... }
```

### 7.2 Error Mapper (Port of `http-error-message.util.ts`)

```dart
class ErrorMapper {
  static String toUserMessage(Object error) {
    if (error is DioException) {
      final status = error.response?.statusCode;
      final data = error.response?.data;
      // Extract message / error fields from JSON body
      // Match Angular priority: message → error → status defaults
    }
    return 'Something went wrong. Please try again.';
  }
}
```

### 7.3 Interceptor Responsibilities

| Interceptor | Handles |
|-------------|---------|
| `AuthInterceptor` | Attach `Bearer {accessToken}` |
| `RefreshInterceptor` | 401 → refresh → retry once with `X-1g-Auth-Retry: 1` |
| `ErrorInterceptor` | Log (dev), transform DioException |

### 7.4 UI Error Display

| Context | Display |
|---------|---------|
| Form submit | Inline field errors + SnackBar |
| List load | `ErrorView` with retry button |
| Background action | SnackBar |
| Auth failure | Inline banner (match Angular login) |
| Session expired | Dialog → navigate to login |

### 7.5 Silent Errors

Match Angular `SILENT_NOT_FOUND`:
- `GET /sitevisits/my/for-property/:id` → 204/404 = no visit, not an error

---

## 8. Caching Strategy

### 8.1 Image Cache

- `cached_network_image` with resolved URLs from `MediaUrlResolver`
- Cache key = resolved URL string
- Placeholder: shimmer skeleton
- Error widget: grey box with icon

### 8.2 API Response Cache (In-Memory)

| Data | TTL | Invalidation |
|------|-----|-------------|
| Featured properties | 5 min | Pull-to-refresh |
| Carousel slides | 30 min | App resume |
| Property detail | 2 min | On edit |
| Search results | None (paginated fresh) | — |
| User profile | Session | On profile update |

Use Riverpod `keepAlive` + manual `ref.invalidate()` — no heavy cache framework.

### 8.3 Persistent Cache (Optional Phase 5)

- `hive` or `isar` for recent searches and favorites offline list
- Not required for MVP

---

## 9. Offline Strategy

### 9.1 MVP (Phase 1–3)

| Capability | Offline Behavior |
|------------|-----------------|
| Browse cached images | ✅ Works |
| Search | ❌ Show "No connection" |
| Auth | ❌ Requires network |
| View previously loaded detail | ✅ If in memory |
| Create property | ❌ Queue not implemented |

### 9.2 Connectivity Check

- `connectivity_plus` to show banner "You're offline"
- Disable submit buttons when offline

### 9.3 Future (Phase 5+)

- Optimistic watchlist toggle with retry queue
- Draft property form in local storage

---

## 10. Security Strategy

### 10.1 Token Storage

| Item | Storage |
|------|---------|
| `accessToken` | `flutter_secure_storage` |
| `refreshToken` | `flutter_secure_storage` |
| `user` JSON | `flutter_secure_storage` |
| Pending OTP email/mobile | `flutter_secure_storage` (temp) |

**Never** use `SharedPreferences` for tokens.

### 10.2 Session Rules (Match Angular)

- Hydrate session only if **both** token and user exist
- Clear all keys on logout or refresh failure
- Invalidate all providers on session clear

### 10.3 Certificate Pinning

- Optional for Phase 5
- Pin `1guntha.com` leaf or Let's Encrypt ISRG root

### 10.4 Input Validation

- Client-side validation mirrors Angular (see Validation Matrix)
- Never trust client — display server validation errors

### 10.5 Sensitive Data

- No API keys in source (use `--dart-define` or flavor config)
- Google Maps key via environment
- ProGuard/R8 rules for release Android

---

## 11. Navigation Strategy

### 11.1 GoRouter Configuration

```dart
// Conceptual structure
GoRouter(
  initialLocation: RoutePaths.splash,
  refreshListenable: authListenable,  // Rebuild on auth change
  redirect: (context, state) => authRedirect(ref, state),
  routes: [
    GoRoute(path: '/splash', ...),
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(path: '/', ...),          // Home tab
        GoRoute(path: '/search', ...),
        GoRoute(path: '/favorites', ...),
        GoRoute(path: '/profile', ...),
      ],
    ),
    // Full-screen routes outside shell
    GoRoute(path: '/property/:id', ...),
    GoRoute(path: '/login', ...),
    // ...
  ],
);
```

### 11.2 Auth Redirect Logic

```dart
String? authRedirect(Ref ref, GoRouterState state) {
  final isLoggedIn = ref.read(isLoggedInProvider);
  final isAuthRoute = state.matchedLocation.startsWith('/login')
      || state.matchedLocation.startsWith('/signup')
      || ...;

  if (!isLoggedIn && _requiresAuth(state.matchedLocation)) {
    return '/login?redirect=${state.matchedLocation}';
  }
  if (isLoggedIn && isAuthRoute) return '/';
  return null;
}
```

### 11.3 Role Guards

```dart
bool canAccessAdmin(User? user) => user?.role == UserRole.admin;
bool canAccessAgent(User? user) =>
    user?.role == UserRole.agent || user?.role == UserRole.admin;
bool canAccessBlogEditor(User? user) =>
    user?.role == UserRole.blog || user?.role == UserRole.admin;
```

### 11.4 Deep Linking (Phase 5)

| URL Pattern | Screen |
|-------------|--------|
| `https://1guntha.com/property/{id}` | Property Detail |
| `https://1guntha.com/blog/{slug}` | Blog Detail |
| `https://1guntha.com/verify-email?token=` | Verify Email |
| `1guntha://property/{id}` | Custom scheme fallback |

---

## 12. Networking Strategy

### 12.1 Dio Client Setup

```dart
class DioClient {
  late final Dio _dio;

  DioClient({required EnvConfig config, required SecureStorageService storage}) {
    _dio = Dio(BaseOptions(
      baseUrl: config.apiBaseUrl,       // https://1guntha.com/api
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
    ));
    _dio.interceptors.addAll([
      AuthInterceptor(storage),
      RefreshInterceptor(storage, config, _dio),
      if (config.isDev) LogInterceptor(requestBody: true, responseBody: true),
    ]);
  }
}
```

### 12.2 Refresh Interceptor (Angular Parity)

1. On 401, check: not retry, not auth URL, has refresh token
2. `POST /auth/refresh` with `{ refreshToken }` — use separate Dio instance to avoid loop
3. Store new tokens
4. Retry original request with `X-1g-Auth-Retry: 1`
5. On failure: clear session, emit `SessionExpiredException`

### 12.3 Multipart Upload

```dart
Future<UploadResponse> uploadFile(File file) async {
  final formData = FormData.fromMap({
    'file': await MultipartFile.fromFile(file.path),
  });
  final response = await _dio.post('/upload', data: formData);
  return UploadResponse.fromJson(response.data);
}
```

### 12.4 Pagination

Match Angular `PageResponse`:

```dart
class PageResponse<T> {
  final List<T> content;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;
  final bool first;
  final bool last;
}
```

---

## 13. Theme & Design System

### 13.1 Material 3 ThemeData

```dart
// Light theme primary
static const Color primary = Color(0xFF0EA5E9);
static const Color primaryDark = Color(0xFF0284C7);
static const Color accent = Color(0xFFF59E0B);
static const Color success = Color(0xFF10B981);
static const Color danger = Color(0xFFEF4444);
static const Color background = Color(0xFFF8FAFC);
static const Color surface = Color(0xFFFFFFFF);
static const Color textPrimary = Color(0xFF1E293B);
static const Color textMuted = Color(0xFF64748B);
```

### 13.2 Dark Theme

- Surface: `#1E293B`
- Background: `#0F172A`
- Primary: same cyan (Material 3 tonal palette auto-generated)

### 13.3 Typography

```dart
// google_fonts package
final bodyFont = GoogleFonts.dmSans();
final displayFont = GoogleFonts.spaceGrotesk();
```

### 13.4 Spacing & Radius

| Token | Value |
|-------|-------|
| `radiusSm` | 6 |
| `radiusMd` | 10 |
| `radiusLg` | 14 |
| `spacingXs` | 4 |
| `spacingSm` | 8 |
| `spacingMd` | 16 |
| `spacingLg` | 24 |

### 13.5 Platform Adaptation

- iOS: Cupertino date/time pickers for site visits
- Android: Material 3 date/time pickers
- `Platform.isIOS` for navigation bar styling

---

## 14. Testing Strategy

### 14.1 Test Pyramid

| Level | Target | Tools |
|-------|--------|-------|
| Unit | 80% coverage on utils, mappers, validators | `flutter_test` |
| Widget | Key widgets (PropertyCard, OtpInput) | `flutter_test` |
| Integration | Auth flow, search, property create | `integration_test` |

### 14.2 Mocking

- `mocktail` for repository mocks
- Custom `MockDio` or `http_mock_adapter` for datasource tests

### 14.3 Test Files per Feature

```
test/features/auth/
├── data/auth_repository_impl_test.dart
├── application/auth_controller_test.dart
└── presentation/login_screen_test.dart
```

---

## 15. Code Generation

### 15.1 build_runner Commands

```bash
# Generate freezed + json_serializable for one feature
dart run build_runner build --delete-conflicting-outputs --build-filter="lib/features/auth/**"

# Watch mode during development
dart run build_runner watch --delete-conflicting-outputs
```

### 15.2 Generated Files (Gitignored or Committed)

- Commit generated `*.g.dart` and `*.freezed.dart` in CI for reproducible builds
- Or generate in CI pipeline before build

### 15.3 Riverpod Generator

```dart
@riverpod
class PropertySearch extends _$PropertySearch { ... }
// Generates propertySearchProvider
```

---

## 16. Dependency Injection

### 16.1 Riverpod Providers (No get_it)

```dart
@Riverpod(keepAlive: true)
Dio dio(DioRef ref) {
  final config = ref.watch(envConfigProvider);
  final storage = ref.watch(secureStorageProvider);
  return DioClient(config: config, storage: storage).dio;
}

@Riverpod(keepAlive: true)
PropertyRepository propertyRepository(PropertyRepositoryRef ref) {
  return PropertyRepositoryImpl(
    remote: PropertyRemoteDatasource(ref.watch(dioProvider)),
  );
}
```

### 16.2 Provider Scope

- `ProviderScope` at app root in `main.dart`
- Override providers in tests via `ProviderScope(overrides: [...])`

---

## 17. Feature Module Template

When implementing each feature, create files in this order:

```
1. domain/entities/{entity}.dart
2. domain/repositories/{feature}_repository.dart
3. data/models/{entity}_dto.dart          → run build_runner
4. data/datasources/{feature}_remote_datasource.dart
5. data/repositories/{feature}_repository_impl.dart
6. application/{feature}_providers.dart
7. application/{feature}_controller.dart
8. presentation/screens/{screen}.dart
9. presentation/widgets/{widget}.dart
10. test/...
```

### 17.1 Feature Dependency Matrix

| Feature | Depends On |
|---------|-----------|
| home | property, carousel, auth (optional) |
| search | property |
| property detail | property, site_visits, auth |
| favorites | property, auth |
| dashboard | site_visits, property, alerts, auth |
| property_form | property, upload, auth |
| profile | user, upload, auth |
| agent | site_visits, auth |
| admin | property, site_visits, user, carousel, auth |
| blog | auth (optional) |
| blog_editor | blog, auth |

---

## 18. Cross-Cutting Concerns

### 18.1 Firebase Analytics (Ready)

```dart
// Track screen views via GoRouter observer
FirebaseAnalyticsObserver(analytics: analytics)

// Custom events
analytics.logEvent(name: 'property_view', parameters: {'id': propertyId});
analytics.logEvent(name: 'site_visit_booked', parameters: {'property_id': id});
```

### 18.2 Firebase Crashlytics (Ready)

```dart
FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
PlatformDispatcher.instance.onError = (error, stack) {
  FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  return true;
};
```

### 18.3 Localization (Ready)

```dart
MaterialApp.router(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,  // en, hi (future)
)
```

### 18.4 Responsive Layout

```dart
class Breakpoints {
  static const double mobile = 600;
  static const double tablet = 900;
}

// Use LayoutBuilder for tablet grid columns (2 → 3)
```

### 18.5 Analytics Event Catalog

| Event | Parameters |
|-------|-----------|
| `login` | method: email |
| `signup_complete` | — |
| `search` | city, listing_type, property_type |
| `property_view` | id, listing_type |
| `watchlist_add` | property_id |
| `site_visit_book` | property_id |
| `property_list` | — |
| `blog_view` | slug |

---

## Appendix A: Package Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.x
  riverpod_annotation: ^2.x
  dio: ^5.x
  go_router: ^14.x
  freezed_annotation: ^2.x
  json_annotation: ^4.x
  flutter_secure_storage: ^9.x
  cached_network_image: ^3.x
  google_fonts: ^6.x
  connectivity_plus: ^6.x
  image_picker: ^1.x
  google_maps_flutter: ^2.x
  url_launcher: ^6.x
  intl: ^0.19.x
  equatable: ^2.x
  firebase_core: ^3.x
  firebase_analytics: ^11.x
  firebase_crashlytics: ^4.x
  flutter_localizations:
    sdk: flutter

dev_dependencies:
  build_runner: ^2.x
  freezed: ^2.x
  json_serializable: ^6.x
  riverpod_generator: ^2.x
  mocktail: ^1.x
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
```

---

## Appendix B: API Base URL Configuration

```dart
class EnvConfig {
  final String apiBaseUrl;
  final String googleMapsApiKey;
  final bool enableAnalytics;
  final bool isDev;

  static const prod = EnvConfig(
    apiBaseUrl: 'https://1guntha.com/api',
    googleMapsApiKey: String.fromEnvironment('GOOGLE_MAPS_KEY'),
    enableAnalytics: true,
    isDev: false,
  );
}
```

---

*End of Architecture Document. Awaiting approval before Phase 1 code generation.*
