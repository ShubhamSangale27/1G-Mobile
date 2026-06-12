# Project Context — 1Guntha Mobile (Flutter)

Single source of truth for the **1G-Mobile** Flutter application. Use this file when continuing development or onboarding an AI assistant.

---

## 1. Project overview

| Item | Detail |
|------|--------|
| **Name** | 1Guntha Mobile (`one_guntha`) |
| **Purpose** | Native Android/iOS client for the 1Guntha real estate platform |
| **Backend** | Same Heroku Spring Boot API as `1G-Frontend` — **no backend changes** |
| **API base** | `https://og-backend-ec80a37e82c0.herokuapp.com/api` |
| **Web counterpart** | `1G-Frontend` (Angular 21) at https://1guntha.com |
| **Package** | `com.oneguntha.one_guntha` |

### Who can use the app

| Role | Mobile |
|------|--------|
| `USER` | Full buyer/seller features |
| `AGENT` | Site visits + browse |
| `ADMIN` | **Blocked** — web only |
| `BLOG` | **Blocked** — web only |

---

## 2. Tech stack

| Layer | Technology |
|-------|------------|
| Framework | Flutter 3.44+ / Dart 3.12+ |
| State | Riverpod 2.x |
| HTTP | Dio 5.x |
| Navigation | GoRouter 14.x |
| Secure storage | flutter_secure_storage |
| Images | cached_network_image |
| Video embeds | webview_flutter (YouTube / Google Drive) |
| Blog HTML | flutter_html |
| Font | **Poppins** (Google Fonts) — Indian e-commerce standard |
| Architecture | Feature-first Clean Architecture |

---

## 3. Repository layout

```
1G-Mobile/
├── lib/
│   ├── config/           # env_config, app_router, route_paths
│   ├── core/             # cache, auth, dio, theme, navigation, utils
│   ├── features/         # auth, home, search, property, blog, agent, ...
│   ├── presentation/   # main_shell (bottom nav)
│   └── shared/         # widgets, models
├── test/                 # Unit + widget navigation tests
├── integration_test/     # Device E2E smoke tests
├── scripts/              # e2e_api_test.ps1, setup_env.ps1
├── android/ ios/         # Platform projects
├── PROJECT_CONTEXT.md    # This file
├── BUILD_COMMANDS.md     # APK build & install
└── ANDROID_DEVICE_SETUP.md
```

Related docs at repo root: `01_Project_Analysis.md`, `02_Flutter_Migration_Plan.md`, `03_Flutter_Architecture.md`.

---

## 4. Session history (what was built)

### Phase 1 — Analysis (no code)
- `01_Project_Analysis.md` — Angular/API inventory
- `02_Flutter_Migration_Plan.md` — 5-phase plan
- `03_Flutter_Architecture.md` — Clean Architecture spec

### Phase 2 — MVP
- Auth: login, signup, OTP, forgot password, persistent session
- Home, search, property detail, favorites, profile, dashboard
- Property list/edit (URL-only media), site visits
- Agent panel: visits list, detail, OTP complete, comments
- Role policy: block ADMIN/BLOG on mobile

### Phase 3 — UI & UX overhaul
- MagicBricks/99acres-inspired search (bottom-sheet filters, list cards)
- Amazon-style horizontal featured carousel
- Blog read-only (list + detail)
- Poppins font, shimmer loaders, branded `AppLoader`
- Blog hero with blurred background image
- Property video gallery (YouTube/Drive embeds)
- Memory cache (stale-while-revalidate, 2–10 min TTL)
- `AppNavigation` debounced routing
- Comprehensive widget tests for tappable surfaces

---

## 5. Key features

### Authentication
- JWT access + refresh tokens in `flutter_secure_storage`
- Cold-start session restore; logout clears storage
- 401 → refresh interceptor (mirrors Angular)

### Home
- Carousel, gradient hero search, Buy/Rent → Search
- Featured properties (horizontal scroll)
- Property Insights blog carousel
- Pull-to-refresh forces cache invalidation

### Search
- Quick filters + modal filter sheet
- List-style property cards
- Cached search results per query key
- Infinite scroll pagination

### Property detail
- Photo + video gallery with thumbnails
- Watchlist, site visit book/reschedule/OTP
- Google Drive + YouTube URL resolution

### Blog (read-only)
- `GET /blogs/published`, `/blogs/published/:slug`, `/blogs/published/filters`
- Hero header with Unsplash background + blur overlay
- No editor/studio features

### Agent
- `GET /agent/sitevisits`, detail, complete with OTP, comments

---

## 6. Caching strategy

`lib/core/cache/memory_cache.dart` — in-memory stale-while-revalidate:

| Key prefix | TTL | Invalidation |
|------------|-----|--------------|
| `properties:featured` | 5 min | Pull-to-refresh, `forceRefresh: true` |
| `properties:search:*` | 3 min | New search query, pull-to-refresh |
| `properties:watchlist` | 2 min | Pull-to-refresh, after watchlist change |
| `carousel:slides` | 10 min | Pull-to-refresh |
| `blogs:published:*` | 5 min | Pull-to-refresh, category change |

Background revalidation updates cache without blocking UI. Pull-to-refresh always passes `forceRefresh: true`.

---

## 7. Navigation map

| User action | Route |
|-------------|-------|
| Bottom nav Home | `/` |
| Bottom nav Search | `/search` |
| Bottom nav Blog | `/blog` |
| Bottom nav Saved / Visits | `/favorites` or `/agent` |
| Bottom nav Account | `/profile` |
| Property card tap | `/property/:id` (root navigator) |
| Blog card tap | `/blog/:slug` (root navigator) |
| FAB List property | `/property/new` |
| Login | `/login` |

All pushes go through `AppNavigation` (500 ms debounce prevents double-tap freezes).

---

## 8. Test accounts (backend seed)

| Role | Email | Password |
|------|-------|----------|
| User | user@realestate.com | user123 |
| Agent | agent@realestate.com | agent123 |
| Admin | admin@realestate.com | admin123 (blocked) |
| Blogger | blogger@realestate.com | blog123 (blocked) |

---

## 9. Running & building

### Prerequisites
- Flutter SDK: `C:\Users\admin\Documents\flutter\bin`
- Android SDK + JDK 17 (see `ANDROID_DEVICE_SETUP.md`)

### Commands
```powershell
cd C:\Users\admin\Documents\1G\1G-Mobile
. .\scripts\setup_env.ps1
flutter pub get
flutter test
powershell -ExecutionPolicy Bypass -File scripts\e2e_api_test.ps1
flutter build apk --debug
```

See `BUILD_COMMANDS.md` for signed release APK steps.

### Device E2E
```powershell
flutter test integration_test/app_test.dart -d <device-id>
```

---

## 10. Test coverage

| Suite | Path | Covers |
|-------|------|--------|
| Role policy | `test/core/auth/` | ADMIN/BLOG block |
| Memory cache | `test/core/cache/` | TTL, forceRefresh |
| Route paths | `test/core/navigation/` | All route constants |
| Navigation taps | `test/navigation/clickable_coverage_test.dart` | Property/Blog card → detail |
| Widget smoke | `test/widget_test.dart` | App boots |
| API E2E | `scripts/e2e_api_test.ps1` | Live Heroku (13 checks) |
| Device E2E | `integration_test/app_test.dart` | Splash → shell |

---

## 11. Important files

| File | Purpose |
|------|---------|
| `lib/config/env_config.dart` | API URL |
| `lib/config/app_router.dart` | GoRouter + auth guards |
| `lib/core/auth/mobile_role_policy.dart` | USER/AGENT only |
| `lib/core/navigation/app_navigation.dart` | Debounced navigation |
| `lib/core/cache/memory_cache.dart` | Response cache |
| `lib/core/utils/media_url_resolver.dart` | Drive/YouTube URLs |
| `lib/core/utils/property_gallery.dart` | Photo + video slides |
| `lib/core/theme/app_theme.dart` | Poppins theme |
| `lib/shared/widgets/blog_hero_header.dart` | Insights hero UI |
| `lib/shared/widgets/shimmer_box.dart` | Loading shimmer |
| `lib/presentation/shell/main_shell.dart` | Bottom navigation |

---

## 12. Quick reference for next session

- **Run on phone:** `BUILD_COMMANDS.md` → debug APK install via `adb`
- **API issues:** Compare with `1G-Frontend` services; backend is shared
- **New feature:** Add under `lib/features/<name>/` with data/domain/presentation
- **New route:** `route_paths.dart` + `app_router.dart`
- **Cache new endpoint:** Use `MemoryCache.instance.getOrFetch` in repository
- **Font/theme:** Poppins via `AppTheme` — do not add second font families

Use **PROJECT_CONTEXT.md** as the main context file when continuing work on 1G-Mobile.
