# 01 — 1Guntha Flutter Mobile App: Project Analysis

**Document version:** 1.0  
**Date:** 2026-06-10  
**Source of truth:** `1G-Frontend` (Angular 21) + `1G-Backend` API contracts (read-only)  
**Production domain:** https://1guntha.com  
**Flutter API base URL (target):** `https://1guntha.com/api`

> **Note:** Angular `environment.prod.ts` currently points to `https://og-backend-ec80a37e82c0.herokuapp.com/api`. The Flutter app should use `https://1guntha.com/api` per product domain. Verify both resolve to the same backend before release.

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Architecture Review](#2-architecture-review)
3. [Feature Inventory](#3-feature-inventory)
4. [User Journeys](#4-user-journeys)
5. [Navigation Structure](#5-navigation-structure)
6. [Authentication Flow](#6-authentication-flow)
7. [Authorization & Role Management](#7-authorization--role-management)
8. [Complete API Inventory](#8-complete-api-inventory)
9. [Angular Services Map](#9-angular-services-map)
10. [Models & DTOs](#10-models--dtos)
11. [Form Validations](#11-form-validations)
12. [State Management Patterns](#12-state-management-patterns)
13. [File Upload Flow](#13-file-upload-flow)
14. [Image & Media Handling](#14-image--media-handling)
15. [Search & Filtering Flow](#15-search--filtering-flow)
16. [Property Listing Flow](#16-property-listing-flow)
17. [Property Detail Flow](#17-property-detail-flow)
18. [Favorites / Watchlist Flow](#18-favorites--watchlist-flow)
19. [User Profile Flow](#19-user-profile-flow)
20. [Property Posting Flow](#20-property-posting-flow)
21. [Admin Functionality](#21-admin-functionality)
22. [Notification Flow](#22-notification-flow)
23. [Theme & Branding Extraction](#23-theme--branding-extraction)
24. [Screens List](#24-screens-list)
25. [Navigation Map](#25-navigation-map)
26. [Role Matrix](#26-role-matrix)
27. [Validation Matrix](#27-validation-matrix)
28. [Backend APIs Not Used by Angular](#28-backend-apis-not-used-by-angular)
29. [Risks](#29-risks)
30. [Recommendations](#30-recommendations)

---

## 1. Executive Summary

**1Guntha** is a full-stack Indian real estate platform. The Angular web client (`1G-Frontend`) is a standalone-component SPA that communicates with a Spring Boot REST API at `/api`. The Flutter mobile app must be a **native client to the same API** — no backend changes.

| Dimension | Angular Web Client |
|-----------|-------------------|
| Framework | Angular 21.1, standalone components |
| HTTP | `HttpClient` + 3 functional interceptors |
| Auth storage | `localStorage` (accessToken, refreshToken, user, userRole) |
| State | Local component state + `AuthService` signals; no global store |
| UI | Bootstrap 3 + custom CSS variables, ngx-bootstrap carousel, ngx-toastr |
| Maps | Google Maps (optional API key), Leaflet CSS bundled |
| Media | URL-based for properties; file upload only for profile photo |
| Roles | `USER`, `ADMIN`, `AGENT`, `BLOG` |

**Mobile benchmark alignment:** UX should follow 99acres / MagicBricks / Housing.com / NoBroker patterns (bottom nav, filter sheets, card-first browsing, OTP flows) while preserving 1Guntha cyan branding and existing business rules.

---

## 2. Architecture Review

### 2.1 Angular Application Structure

```
1G-Frontend/src/app/
├── app.component.ts          # Shell: header + router-outlet + footer
├── app.config.ts             # Providers, interceptors, APP_INITIALIZER
├── app.routes.ts             # Lazy-loaded routes + guards
├── core/
│   ├── components/           # header, footer
│   ├── data/                 # indian-locations.ts (static)
│   ├── guards/               # auth, admin, agent, blog
│   ├── interceptors/         # auth, error, auth-refresh
│   ├── models/               # property, blog, carousel
│   ├── services/             # api, auth, blog, config, google-maps
│   └── utils/                # image-url, property-gallery, http-error
├── features/                 # One folder per route (inline templates)
└── shared/                   # property-card, property-map, skeleton, pipes
```

### 2.2 HTTP Pipeline

```
Request
  → authInterceptor        (attach Bearer token)
  → errorInterceptor       (global toast on error; skip 401)
  → authRefreshInterceptor (401 → refresh → retry once)
  → Backend /api
```

### 2.3 Key Architectural Observations for Flutter

| Angular Pattern | Flutter Equivalent |
|-----------------|------------------|
| `ApiService` thin wrapper | Dio client + interceptors |
| `AuthService` signals | Riverpod `StateNotifier` / `AsyncNotifier` |
| Route guards | GoRouter `redirect` + role checks |
| `localStorage` session | `flutter_secure_storage` |
| Inline component templates | Feature screens + widgets |
| `ChangeDetectorRef.markForCheck()` | Riverpod rebuild / `setState` |
| `sessionStorage` for OTP pending | Secure temp storage or navigation extras |
| `ConfigService` runtime URL | Build flavors + env config |
| No dedicated watchlist route | Add mobile-native favorites tab (same API) |

---

## 3. Feature Inventory

### 3.1 Public (Unauthenticated)

| # | Feature | Angular Route | Backend Dependency |
|---|---------|---------------|-------------------|
| P1 | Homepage carousel | `/` | `GET /carousel/slides` |
| P2 | Hero search (buy/rent) | `/` → `/search` | Query params only |
| P3 | Featured properties | `/` | `GET /properties/public/featured` |
| P4 | Home services cards | `/` | **None** (WhatsApp popup via legacy JS) |
| P5 | Loan calculator widget | `/` | **None** (client-side jQuery) |
| P6 | Property search & filters | `/search` | `GET /properties/search` |
| P7 | Property detail (public view) | `/property/:id` | `GET /properties/:id` |
| P8 | Blog list | `/blog` | `GET /blogs/published` |
| P9 | Blog detail | `/blog/:slug` | `GET /blogs/published/:slug` |
| P10 | Login | `/login` | `POST /auth/login` |
| P11 | Signup | `/signup` | `POST /auth/signup` |
| P12 | Signup OTP verify | `/verify-otp` | `POST /auth/verify-signup` |
| P13 | Forgot password | `/forgot-password` | `POST /auth/forgot-password`, `POST /auth/reset-password` |
| P14 | Email verify (deep link) | `/verify-email?token=` | `GET /auth/verify-email` |

### 3.2 Authenticated — USER Role

| # | Feature | Route | APIs |
|---|---------|-------|------|
| U1 | Dashboard | `/dashboard` | sitevisits, properties/my, alerts |
| U2 | My properties list | `/my-properties` | `GET /properties/my`, `DELETE /properties/:id` |
| U3 | List new property | `/property/new` | `POST /properties` |
| U4 | Edit property | `/property/:id/edit` | `GET /properties/:id`, `PUT /properties/:id` |
| U5 | Book site visit | `/property/:id` | `POST /sitevisits` |
| U6 | Reschedule visit | `/property/:id`, `/dashboard` | `PUT /sitevisits/:id/reschedule` |
| U7 | View visit OTP | `/property/:id` | `GET /sitevisits/:id/otp`, `POST resend-otp` |
| U8 | Watchlist toggle ("likes") | `/property/:id` | watchlist POST/DELETE/GET |
| U9 | Profile & avatar | `/profile` | `GET/PUT /users/me`, `POST /upload` |
| U10 | Change password (OTP) | `/profile` | change-password APIs |
| U11 | Email verification banner | `/dashboard` | `POST /auth/send-email-verification` |
| U12 | Logout | Header | `POST /auth/logout` |

### 3.3 AGENT Role (+ inherits USER where applicable)

| # | Feature | Route | APIs |
|---|---------|-------|------|
| A1 | Agent visit list | `/agent` | `GET /agent/sitevisits` |
| A2 | Complete visit (OTP) | `/agent` | `POST /agent/sitevisits/:id/complete?otp=` |
| A3 | Visit detail | `/agent/visit/:id` | `GET /agent/sitevisits/:id` |
| A4 | Add comment | `/agent/visit/:id` | `POST /agent/sitevisits/:id/comments` |

### 3.4 ADMIN Role

| # | Feature | Route | APIs |
|---|---------|-------|------|
| D1 | Global metrics | `/admin` | `GET /admin/metrics` |
| D2 | Pending property approval | `/admin` | pending list, approve, reject |
| D3 | All properties management | `/admin` | CRUD, featured toggle |
| D4 | Property viewers/likers | `/admin` | viewers, likers endpoints |
| D5 | User management | `/admin` | list, status, role, delete |
| D6 | Site visit assignment | `/admin` | pending, assign, reassign, filter |
| D7 | Homepage carousel CRUD | `/admin` | carousel admin APIs |
| D8 | Admin property create/edit | `/property/new`, `/property/:id/edit` | Uses `/admin/properties` when role=ADMIN |

### 3.5 BLOG Role

| # | Feature | Route | APIs |
|---|---------|-------|------|
| B1 | Blog Studio (CMS) | `/blog-editor` | editor CRUD + publish |
| B2 | Public blog read | `/blog`, `/blog/:slug` | published APIs |

### 3.6 Features in Backend but NOT in Angular Web

| Feature | Backend API | Mobile Recommendation |
|---------|-------------|----------------------|
| Premium payments | `/payments/*`, `/plans` | **Phase 4+** — optional, not in web |
| Full watchlist page | `GET /properties/watchlist` | **Include in mobile** — better UX |
| Standalone OTP | `/otp/send`, `/otp/verify` | Not needed — auth has dedicated flows |
| Analytics POST | `/properties/:id/analytics/*` | Optional — GET detail records VIEW when authed |
| Unread alert count | `GET /alerts/unread-count` | **Include** — Angular only lists alerts |
| Mark alert read | `PUT /alerts/:id/read` | **Include** — Angular displays but doesn't mark read |

---

## 4. User Journeys

### 4.1 New User Registration

```
Home → Sign Up → fill form → POST /auth/signup
  → redirect /verify-otp (email+mobile stored in sessionStorage)
  → enter mobile OTP → POST /auth/verify-signup
  → tokens stored → redirect /dashboard
```

**OTP resend:** `POST /auth/resend-signup-otp` with throttling UI (3/day, countdown timer).

### 4.2 Returning User Login

```
/login → POST /auth/login → setSession → /dashboard
```

On wrong credentials: inline error banner + toast (skip global error interceptor).

### 4.3 Browse & Search Property

```
Home → Search tab OR hero search → /search?params
  → apply filters → GET /properties/search (paginated)
  → tap card → /property/:id
```

### 4.4 Book Site Visit

```
/property/:id (logged in) → Book Visit dialog
  → pick date+time → POST /sitevisits
  → status PENDING_ASSIGNMENT
Admin assigns agent → user gets SMS OTP
  → status ASSIGNED → user sees OTP on property detail
Agent completes with OTP at visit
```

### 4.5 List a Property (Owner)

```
/property/new → fill form + add media URLs → POST /properties
  → status PENDING_APPROVAL → /my-properties
Admin approves → appears in public search
```

### 4.6 Forgot Password

```
/forgot-password → enter email → POST /auth/forgot-password (OTP to mobile)
  → enter OTP + new password → POST /auth/reset-password → /login
```

### 4.7 Agent Workflow

```
/agent → list assigned visits (due today first)
  → enter OTP inline OR open /agent/visit/:id
  → POST complete?otp= → status COMPLETED
  → optional comment
```

### 4.8 Admin Workflow

```
/admin → metrics dashboard
  → approve/reject pending properties
  → assign/reassign site visits to agents
  → manage users (suspend, role change, delete)
  → manage carousel slides
```

---

## 5. Navigation Structure

### 5.1 Angular Route Table

| Path | Component | Guards |
|------|-----------|--------|
| `''` | HomeComponent | — |
| `search` | SearchComponent | — |
| `blog` | BlogListComponent | — |
| `blog/:slug` | BlogDetailComponent | — |
| `login` | LoginComponent | — |
| `signup` | SignupComponent | — |
| `verify-otp` | VerifyOtpComponent | — |
| `verify-email` | VerifyEmailComponent | — |
| `forgot-password` | ForgotPasswordComponent | — |
| `dashboard` | DashboardComponent | authGuard |
| `profile` | ProfileComponent | authGuard |
| `my-properties` | MyPropertiesComponent | authGuard |
| `property/new` | PropertyFormComponent | authGuard |
| `property/:id/edit` | PropertyFormComponent | authGuard |
| `property/:id` | PropertyDetailComponent | — |
| `admin` | AdminComponent | auth + admin |
| `agent` | AgentComponent | auth + agent |
| `agent/visit/:id` | AgentVisitDetailComponent | auth + agent |
| `blog-editor` | BlogEditorDashboardComponent | auth + blog |
| `**` | redirect → `''` | — |

### 5.2 Header Navigation (Role-Gated)

**Logged out:** Home, Search, Blog, Login, Sign Up  
**Logged in (USER):** + Dashboard, My Properties, List Property, Profile, Logout  
**AGENT/ADMIN:** + Agent  
**ADMIN:** + Admin  
**BLOG/ADMIN:** + Blog Studio

---

## 6. Authentication Flow

### 6.1 Token Model

| Token | Storage | Usage |
|-------|---------|-------|
| `accessToken` | localStorage | `Authorization: Bearer {token}` on all authed requests |
| `refreshToken` | localStorage | `POST /auth/refresh` body `{ refreshToken }` |
| `user` | localStorage (JSON) | Profile display, role checks |
| `userRole` | localStorage | Redundant copy of `user.role` |

**Session hydration rule:** Restore session only when **both** `accessToken` AND `user` exist; otherwise clear all auth keys.

### 6.2 Refresh Flow (Critical for Mobile)

```
Any authed request → 401
  → IF not auth URL AND refreshToken exists AND not retry:
      POST /auth/refresh (bypass interceptors)
      → update tokens (+ user if returned)
      → retry original request once (header X-1g-Auth-Retry: 1)
  → IF refresh fails:
      clearSession() + "session expired" message
```

**Anonymous auth URLs (no refresh attempt):**
`/auth/login`, `/auth/signup`, `/auth/verify-signup`, `/auth/resend-signup-otp`, `/auth/refresh`, `/auth/forgot-password`

### 6.3 Signup OTP Payload

Angular sends **mobile OTP only** (not email OTP):

```json
{
  "email": "user@example.com",
  "mobile": "+91XXXXXXXXXX",
  "mobileOtp": "123456"
}
```

### 6.4 Logout

`POST /auth/logout` (fire-and-forget) + clear local storage + navigate home.

---

## 7. Authorization & Role Management

### 7.1 Roles

| Role | Description |
|------|-------------|
| `USER` | Default — list properties, book visits, profile |
| `AGENT` | Manage assigned site visits, complete with OTP |
| `ADMIN` | Full admin panel + can use agent endpoints |
| `BLOG` | Blog Studio CMS |

### 7.2 Guard Logic

| Guard | Condition |
|-------|-----------|
| `authGuard` | `isLoggedIn() && getToken()` else → `/login` |
| `adminGuard` | `getRole() === 'ADMIN'` else → `/` |
| `agentGuard` | `role === 'AGENT' \|\| role === 'ADMIN'` else → `/` |
| `blogGuard` | `role === 'BLOG' \|\| role === 'ADMIN'` else → `/` |

### 7.3 Account Suspension

Backend returns error on login for suspended users. Message: *"Suspended user: your account has been deactivated. Please contact admin."*

---

## 8. Complete API Inventory

> All paths relative to `{baseUrl}/api`. Auth = Bearer JWT unless marked Public.

### 8.1 Authentication

| Method | Endpoint | Request DTO | Response DTO | Auth | Validation | Used By |
|--------|----------|-------------|--------------|------|------------|---------|
| POST | `/auth/login` | `{ email, password }` | `AuthResponse` | Public | email required, password required | login.component |
| POST | `/auth/signup` | `{ email, password, fullName, mobile }` | `SignupResponse` | Public | fullName, email, mobile 10+, password 8+ | signup.component |
| POST | `/auth/verify-signup` | `{ email, mobile, mobileOtp }` | `AuthResponse` | Public | 6-digit OTP | verify-otp.component |
| POST | `/auth/resend-signup-otp` | `{ email, mobile }` | `SignupResponse` | **Auth*** | email+mobile | verify-otp.component |
| POST | `/auth/refresh` | `{ refreshToken }` | `AuthResponse` | Public | refreshToken | auth-refresh.interceptor |
| POST | `/auth/logout` | `{}` | — | Auth | — | auth.service |
| POST | `/auth/forgot-password` | `{ email }` | `PasswordOtpResponse` | Public | valid email | forgot-password.component |
| POST | `/auth/reset-password` | `{ email, otp, newPassword }` | `{ message }` | Public | 6-digit OTP, password 6+ | forgot-password.component |
| POST | `/auth/change-password/send-otp` | `{}` | `PasswordOtpResponse` | Auth | — | profile.component |
| POST | `/auth/change-password` | `{ otp, newPassword }` | `{ message }` | Auth | 6-digit OTP, password 6+ | profile.component |
| POST | `/auth/send-email-verification` | `{}` | — | Auth | — | dashboard.component |
| GET | `/auth/verify-email` | query: `token` | `{ message }` | Public | token | verify-email.component |

*\*Backend `SecurityConfig` does not list `/auth/resend-signup-otp` as public — known mismatch; Angular calls it during pre-login flow.*

### 8.2 Users & Upload

| Method | Endpoint | Request | Response | Auth | Used By |
|--------|----------|---------|----------|------|---------|
| GET | `/users/me` | — | `User` | Auth | profile.component |
| PUT | `/users/me` | `{ fullName, email, profileImageUrl? }` | `User` | Auth | profile.component |
| POST | `/upload` | multipart `file` | `{ url, thumbnailUrl }` | Auth | profile.component |

### 8.3 Properties

| Method | Endpoint | Query/Body | Response | Auth | Used By |
|--------|----------|------------|----------|------|---------|
| GET | `/properties/public/featured` | — | `Property[]` | Public | home.component |
| GET | `/properties/search` | see §15 | `PageResponse<Property>` | Public | search.component |
| GET | `/properties/{id}` | `includeAnalytics=true` | `Property` | Public | property-detail, property-form |
| POST | `/properties` | Property payload | `Property` | Auth | property-form (USER) |
| PUT | `/properties/{id}` | Property payload | `Property` | Auth | property-form (USER) |
| GET | `/properties/my` | `page`, `size` | `PageResponse<Property>` | Auth | my-properties, dashboard |
| DELETE | `/properties/{id}` | — | — | Auth | my-properties |
| GET | `/properties/{id}/watchlist` | — | `{ inWatchlist: bool }` | Auth | property-detail |
| POST | `/properties/{id}/watchlist` | `{}` | — | Auth | property-detail |
| DELETE | `/properties/{id}/watchlist` | — | — | Auth | property-detail |

**Property create/update payload:**

```typescript
{
  title, description?, listingType, propertyType, price,
  address, locality?, city, state, pincode?,
  latitude?, longitude?, bedrooms?, bathrooms?, areaSqft?, amenities?,
  images: [{ imageUrl, mediaType: 'IMAGE'|'VIDEO', displayOrder }]
}
```

### 8.4 Site Visits (User)

| Method | Endpoint | Body | Response | Auth | Used By |
|--------|----------|------|----------|------|---------|
| POST | `/sitevisits` | `{ propertyId, scheduledAt, userNotes? }` | `SiteVisitDto` | Auth | property-detail |
| GET | `/sitevisits/my` | `page`, `size` | `{ content: SiteVisit[] }` | Auth | dashboard |
| GET | `/sitevisits/my/for-property/{id}` | — | `SiteVisitDto \| 204` | Auth | property-detail |
| PUT | `/sitevisits/{id}/reschedule` | `{ scheduledAt }` | `SiteVisitDto` | Auth | property-detail, dashboard |
| GET | `/sitevisits/{id}/otp` | — | `{ otp: string }` | Auth | property-detail |
| POST | `/sitevisits/{id}/resend-otp` | `{}` | `{ otp, message? }` | Auth | property-detail |

### 8.5 Agent

| Method | Endpoint | Body/Query | Auth | Used By |
|--------|----------|------------|------|---------|
| GET | `/agent/sitevisits` | `page`, `size` | AGENT/ADMIN | agent.component |
| GET | `/agent/sitevisits/{id}` | — | AGENT/ADMIN | agent-visit-detail |
| POST | `/agent/sitevisits/{id}/complete` | query `otp` | AGENT/ADMIN | agent components |
| POST | `/agent/sitevisits/{id}/comments` | `{ commentText }` | AGENT/ADMIN | agent-visit-detail |

### 8.6 Alerts

| Method | Endpoint | Query | Auth | Used By |
|--------|----------|-------|------|---------|
| GET | `/alerts` | `page`, `size` | Auth | dashboard |

### 8.7 Carousel

| Method | Endpoint | Auth | Used By |
|--------|----------|------|---------|
| GET | `/carousel/slides` | Public | home.component |
| GET | `/admin/carousel/slides` | ADMIN | admin.component |
| POST | `/admin/carousel/slides` | ADMIN | admin.component |
| PUT | `/admin/carousel/slides/{id}` | ADMIN | admin.component |
| DELETE | `/admin/carousel/slides/{id}` | ADMIN | admin.component |

**Carousel create body:** `{ imageUrl, linkUrl?, altText?, displayOrder?, active? }`

### 8.8 Blog

| Method | Endpoint | Auth | Used By |
|--------|----------|------|---------|
| GET | `/blogs/published` | Public | blog-list |
| GET | `/blogs/published/{slug}` | Public | blog-detail |
| GET | `/blogs/published/filters` | Public | blog-list |
| GET | `/blogs/editor/mine` | BLOG/ADMIN | blog-editor |
| POST | `/blogs/editor` | BLOG/ADMIN | blog-editor |
| PUT | `/blogs/editor/{id}` | BLOG/ADMIN | blog-editor |
| PUT | `/blogs/editor/{id}/publish` | query `published` | BLOG/ADMIN | blog-editor |
| DELETE | `/blogs/editor/{id}` | BLOG/ADMIN | blog-editor |

### 8.9 Admin

| Method | Endpoint | Auth | Used By |
|--------|----------|------|---------|
| GET | `/admin/metrics` | ADMIN | admin |
| GET | `/admin/properties/pending` | ADMIN | admin |
| GET | `/admin/properties` | ADMIN | admin |
| POST | `/admin/properties` | ADMIN | property-form (admin) |
| PUT | `/admin/properties/{id}` | ADMIN | property-form (admin) |
| DELETE | `/admin/properties/{id}` | ADMIN | admin |
| PUT | `/admin/properties/{id}/approve` | ADMIN | admin |
| PUT | `/admin/properties/{id}/reject` | ADMIN | admin |
| PUT | `/admin/properties/{id}/featured` | query `featured` | ADMIN | admin |
| GET | `/admin/properties/{id}/viewers` | ADMIN | admin |
| GET | `/admin/properties/{id}/likers` | ADMIN | admin |
| GET | `/admin/users` | ADMIN | admin |
| PUT | `/admin/users/{id}/status` | query `active` | ADMIN | admin |
| PUT | `/admin/users/{id}/role` | query `role` | ADMIN | admin |
| DELETE | `/admin/users/{id}` | ADMIN | admin |
| GET | `/admin/sitevisits/pending` | ADMIN | admin |
| GET | `/admin/sitevisits` | ADMIN | admin |
| GET | `/admin/agents` | ADMIN | admin |
| PUT | `/admin/sitevisits/{id}/assign` | query `agentId` | ADMIN | admin |
| PUT | `/admin/sitevisits/{id}/reassign` | query `agentId` | ADMIN | admin |

---

## 9. Angular Services Map

| Service | File | Responsibility |
|---------|------|----------------|
| `ConfigService` | `core/services/config.service.ts` | Runtime API URL from `/config.json` or environment |
| `ApiService` | `core/services/api.service.ts` | HTTP GET/POST/PUT/DELETE + multipart upload |
| `AuthService` | `core/services/auth.service.ts` | Session, login/signup/logout, profile, password APIs |
| `BlogService` | `core/services/blog.service.ts` | Published + editor blog reads |
| `GoogleMapsService` | `core/services/google-maps.service.ts` | Dynamic Google Maps JS load |

**No dedicated services for:** properties, search, admin, agent, alerts — components call `ApiService` directly.

---

## 10. Models & DTOs

### 10.1 User (`auth.service.ts`)

```typescript
interface User {
  id: number;
  email: string;
  fullName: string;
  mobile: string;
  role: string;           // USER | ADMIN | AGENT | BLOG
  emailVerified: boolean;
  mobileVerified: boolean;
  active?: boolean;
  profileImageUrl?: string;
}
```

### 10.2 AuthResponse

```typescript
interface AuthResponse {
  accessToken: string;
  refreshToken: string;
  expiresIn: number;
  user: User;
}
```

### 10.3 SignupResponse / PasswordOtpResponse

```typescript
interface SignupResponse {
  message: string;
  email: string;
  mobile: string;
  resendAttemptsUsed?: number;
  resendAttemptsRemaining?: number;
  resendAvailableAt?: string;
  maxResendAttemptsPerDay?: number;
}
```

### 10.4 Property (`property.model.ts`)

```typescript
type ListingType = 'SALE' | 'RENT';
type PropertyType = 'HOUSE' | 'APARTMENT' | 'LAND' | 'COMMERCIAL';
type PropertyStatus = 'PENDING_APPROVAL' | 'APPROVED' | 'REJECTED';

interface PropertyImage {
  id?: number;
  imageUrl: string;
  mediaType?: 'IMAGE' | 'VIDEO';
  caption?: string;
  displayOrder?: number;
}

interface Property {
  id, title, description?, listingType, propertyType, price,
  address, city?, state?, pincode?, locality?,
  latitude?, longitude?, bedrooms?, bathrooms?, areaSqft?, amenities?,
  status?, ownerId?, ownerName?, isPremium?, premiumExpiresAt?,
  images?, viewCount?, clickCount?, visitCount?, createdAt?, featured?
}
```

### 10.5 PageResponse\<T\>

```typescript
interface PageResponse<T> {
  content: T[];
  page: number;
  size: number;
  totalElements: number;
  totalPages: number;
  first: boolean;
  last: boolean;
}
```

### 10.6 Blog (`blog.model.ts`)

See `BlogPost`, `BlogContentBlock`, `BlogPostCreateUpdateRequest`, `BlogFilters`. Block types: `TEXT | IMAGE | VIDEO | LINK`.

### 10.7 Carousel (`carousel.model.ts`)

```typescript
interface CarouselSlide {
  id: number;
  imageUrl: string;
  linkUrl?: string;
  altText?: string;
  displayOrder: number;
  active: boolean;
}
```

### 10.8 Local Component Interfaces (not in models/)

- `SiteVisit` / `SiteVisitDto` — dashboard, property-detail, agent
- `Alert` — dashboard
- `AgentRow`, `UserRow`, `SiteVisitRow` — admin
- `PropertyMediaItem` — property-form (local preview state)

---

## 11. Form Validations

| Screen | Field | Rules |
|--------|-------|-------|
| Login | email | required, email format |
| Login | password | required |
| Signup | fullName | required |
| Signup | email | required, email |
| Signup | mobile | required, minLength 10 |
| Signup | password | required, minLength 8 |
| Verify OTP | mobileOtp | required, 6 digits, numeric |
| Forgot Password | email | required, email |
| Forgot Password | otp | required, 6-digit pattern |
| Forgot Password | newPassword | required, minLength 6 |
| Forgot Password | confirmPassword | required, must match newPassword |
| Profile | fullName | required |
| Profile | email | required, email |
| Profile | mobile | read-only |
| Profile (password) | otp | required, 6-digit |
| Profile (password) | newPassword | minLength 6 |
| Profile (password) | confirmPassword | must match |
| Property Form | title | required |
| Property Form | listingType | required |
| Property Form | propertyType | required |
| Property Form | price | required, min 0 |
| Property Form | address | required |
| Property Form | city | required |
| Property Form | state | required |
| Property Form | media URL | image: valid http(s) URL; video: YouTube or Drive |
| Site Visit | date + time | required, combined to ISO |
| Agent complete | otp | 6 digits |
| Blog Editor | title | required (client) |
| Blog Editor | blocks | min 1 block; per-type URL/content rules |

---

## 12. State Management Patterns

| Concern | Angular Implementation | Notes for Flutter |
|---------|----------------------|-------------------|
| Auth user | `signal<User \| null>` in AuthService | Riverpod `authStateProvider` |
| Session persistence | localStorage | flutter_secure_storage |
| OTP pending | sessionStorage `pendingVerify` | Navigation extras or secure temp store |
| Component data | Local fields + `.subscribe()` | `AsyncValue` + repository |
| Loading states | `loading` boolean per component | `AsyncLoading` |
| Pagination | `page`, `totalPages` locals | `ScrollController` + infinite scroll |
| Form state | ReactiveFormsModule | `flutter_form_builder` or manual |
| Global errors | errorInterceptor + toastr | SnackBar / dialog + error mapper |
| Change detection | `ChangeDetectorRef`, `NgZone.run` | Not needed with Riverpod |
| No NgRx/Akita | — | Keep Riverpod only, avoid over-engineering |

---

## 13. File Upload Flow

### 13.1 What Angular Uploads

| Use Case | Endpoint | Method | Notes |
|----------|----------|--------|-------|
| Profile photo | `POST /upload` | multipart `file` | Returns `{ url, thumbnailUrl }` |
| Property media | **No upload** | — | URL-only (Drive, YouTube, direct) |
| Blog media | **No upload** | — | URL-only in blocks |
| Carousel (admin) | **No upload** | — | URL-only |

### 13.2 Profile Upload Flow

```
User picks image file
  → POST /upload (multipart, Bearer token)
  → response.url stored as profileImageUrl
  → PUT /users/me { fullName, email, profileImageUrl }
  → update local user signal
```

### 13.3 Flutter Mobile Implications

- Use `image_picker` + `dio` multipart for profile photo
- Property listing on mobile: **match web** (URL entry) OR add camera upload only if backend `/upload` accepts property images (it does — same endpoint). Web chose URL-only; mobile can offer both URL + camera upload using existing `/upload` without backend changes.

---

## 14. Image & Media Handling

### 14.1 URL Resolution (`image-url.util.ts`)

| Source | Resolution |
|--------|------------|
| Relative `/uploads/...` | Prefix with `apiUrl` host |
| Google Drive | Extract file ID → thumbnail or embed preview URL |
| YouTube | Extract video ID → embed or hqdefault thumbnail |
| Direct http(s) | Native `<video>` or `<img>` |
| Mixed content | `upgradeInsecureMediaUrl()` http→https |

### 14.2 Property Gallery (`property-gallery.util.ts`)

Builds slides from `PropertyImage[]`:
- `IMAGE` → photo slide
- `VIDEO` → embed (YouTube/Drive) or native file

### 14.3 Property Card Thumbnail

1. First `IMAGE` media item
2. Else first `VIDEO` → `resolveVideoCardPosterUrl()`
3. Fallback placeholder

### 14.4 Indian Price Format (`indian-price.pipe.ts`)

- `>= 1 Cr` → `₹X Cr`
- `>= 1 L` → `₹X L`
- Else → `en-IN` comma format

---

## 15. Search & Filtering Flow

### 15.1 Query Parameters (`GET /properties/search`)

| Param | Type | Source |
|-------|------|--------|
| `page` | int | pagination (default 0) |
| `size` | int | page size (default 12) |
| `sort` | string | `createdAt`, `price`, etc. |
| `direction` | string | `asc` / `desc` |
| `city` | string | filter |
| `state` | string | **Not sent by Angular** (UI has state but only city sent) |
| `listingType` | `SALE` \| `RENT` | filter |
| `propertyType` | enum | filter |
| `minPrice` | number | slider (omitted if full range 0–50Cr) |
| `maxPrice` | number | slider |
| `bedrooms` | int | minimum bedrooms |
| `minArea` | number | sq.ft |

### 15.2 Sort Options

- `createdAt,desc` — Newest First (default)
- `price,asc` — Price Low to High
- `price,desc` — Price High to Low

### 15.3 URL Query Sync

Search reads `?state&city&listingType&propertyType` from route on init.

### 15.4 Static Location Data

`indian-locations.ts` — states/UTs and cities (client-side dropdowns, not API).

---

## 16. Property Listing Flow

```
Authenticated user → /property/new
  → reactive form validation
  → add media via URL (IMAGE or VIDEO)
  → optional map pin (Google Maps pick mode)
  → POST /properties (or /admin/properties if ADMIN)
  → toast "will be reviewed by admin"
  → navigate /my-properties

/my-properties
  → GET /properties/my?page&size=12
  → edit → /property/:id/edit
  → delete → DELETE /properties/:id (confirm dialog)
```

**Status badges:** PENDING_APPROVAL, APPROVED, REJECTED

---

## 17. Property Detail Flow

```
GET /properties/:id?includeAnalytics=true
  → gallery (photos + video embeds)
  → amenities list (comma-split)
  → map (if lat/lng)
  → price (indian format)
  → verified badge (UI-only, all cards show "Verified")

If authenticated:
  → GET watchlist status
  → GET /sitevisits/my/for-property/:id (silent 404/204)
  → if ASSIGNED: show OTP, resend OTP
  → book / reschedule visit modals
  → toggle watchlist ("likes")
```

**Site visit statuses:** `PENDING_ASSIGNMENT`, `ASSIGNED`, `COMPLETED`, `CANCELLED`

---

## 18. Favorites / Watchlist Flow

| Action | API | UI Location |
|--------|-----|-------------|
| Check status | `GET /properties/:id/watchlist` | property-detail |
| Add | `POST /properties/:id/watchlist` | property-detail ("Added to likes") |
| Remove | `DELETE /properties/:id/watchlist` | property-detail ("Removed from likes") |

**Gap:** No dedicated watchlist screen in Angular. Backend supports `GET /properties/watchlist` — **recommend dedicated Favorites tab in Flutter**.

---

## 19. User Profile Flow

```
GET /users/me → populate form
  → edit fullName, email (mobile read-only)
  → upload photo via POST /upload → PUT /users/me

Change password (in-profile):
  → POST /auth/change-password/send-otp
  → enter OTP + new password
  → POST /auth/change-password
  → logout on success
```

---

## 20. Property Posting Flow

See §16. Key constraints:
- Media is URL-based on web
- Admin uses same form with `/admin/properties` endpoints
- `mediaType` persisted per image (`IMAGE` | `VIDEO`)
- Duplicate URL guard client-side

---

## 21. Admin Functionality

Single-page admin dashboard (`/admin`) with sections:

1. **Metrics** — totalProperties, totalViews, pendingProperties, pendingSiteVisits, revenueLast30Days
2. **Pending approvals** — approve/reject
3. **All properties** — filter all/featured/new, pagination, featured toggle, delete, viewers/likers modals
4. **Users** — list, suspend/activate, role change (USER/AGENT/BLOG/ADMIN), delete
5. **Site visits** — pending assign, all visits with date/agent filters, reassign
6. **Carousel** — CRUD by image URL, reorder, active toggle

**Mobile recommendation:** Admin on mobile should be a separate section with simplified tables → card lists. Full parity required but progressive disclosure.

---

## 22. Notification Flow

| Type | Implementation |
|------|----------------|
| In-app alerts | `GET /alerts?page&size` on dashboard |
| Unread count | Computed client-side from `read: false` (API `unread-count` exists but unused) |
| Mark read | `PUT /alerts/:id/read` exists but **not called** in Angular |
| Email verification | Banner on dashboard + `send-email-verification` |
| SMS OTP | Signup, forgot password, change password, site visit — backend MSG91 |
| Push notifications | **Not implemented** — Flutter should be "ready" (FCM scaffold) |

---

## 23. Theme & Branding Extraction

### 23.1 Colors (from `styles.scss`)

| Token | Value | Usage |
|-------|-------|-------|
| Primary | `#0ea5e9` (sky-500) | CTAs, links, active nav |
| Primary Dark | `#0284c7` | Hover states |
| Primary Gradient | `#0ea5e9 → #0284c7` | Buttons, logo |
| Accent | `#f59e0b` (amber) | "List Property" CTA |
| Success | `#10b981` | Verified badge |
| Danger | `#ef4444` | Errors |
| Background | `#f8fafc` | Page bg |
| Surface | `#ffffff` | Cards |
| Text | `#1e293b` | Primary text |
| Text Muted | `#64748b` | Subtitles |
| Footer BG | `#0f172a` | Dark footer |

### 23.2 Typography

| Role | Font |
|------|------|
| Body | DM Sans (400–700) |
| Display/Headings | Space Grotesk (500–700) |

### 23.3 Layout Patterns

- Max content width: 1280px
- Card radius: 10px (`--radius`)
- Property cards: 16:11 aspect ratio image
- Sticky header with blur
- CSS Grid for property grids (`auto-fill, minmax(280px, 1fr)`)
- Skeleton shimmer loaders
- Modal z-index: 600000; toasts: 800000

### 23.4 Component Patterns

- Property card: image + badges (listing type, verified, premium) + price + location + BHK
- Filter sidebar (desktop) → should become bottom sheet on mobile
- Hero with buy/rent tabs
- Carousel: 330px max height, 5s auto-cycle

---

## 24. Screens List

### 24.1 Flutter Screen Mapping (Proposed)

| # | Screen | Priority | Parity with Angular |
|---|--------|----------|---------------------|
| 1 | Splash | P0 | New (mobile) |
| 2 | Onboarding (optional) | P2 | New |
| 3 | Home | P0 | Yes |
| 4 | Search / Filters | P0 | Yes |
| 5 | Property Detail | P0 | Yes |
| 6 | Property Gallery (fullscreen) | P0 | Yes (zoom overlay) |
| 7 | Login | P0 | Yes |
| 8 | Signup | P0 | Yes |
| 9 | OTP Verification | P0 | Yes |
| 10 | Forgot Password | P0 | Yes |
| 11 | Dashboard | P0 | Yes |
| 12 | My Properties | P0 | Yes |
| 13 | Property Form (Create/Edit) | P0 | Yes |
| 14 | Profile | P0 | Yes |
| 15 | Favorites / Watchlist | P1 | **Enhancement** |
| 16 | Site Visit Booking | P0 | Yes (modal → screen) |
| 17 | Notifications / Alerts | P1 | Enhanced |
| 18 | Blog List | P1 | Yes |
| 19 | Blog Detail | P1 | Yes |
| 20 | Agent Dashboard | P1 | Yes |
| 21 | Agent Visit Detail | P1 | Yes |
| 22 | Admin Dashboard | P2 | Yes (simplified mobile) |
| 23 | Blog Studio | P2 | Yes |
| 24 | Email Verify Deep Link | P1 | Yes |
| 25 | Map Picker | P0 | Yes |
| 26 | Settings | P2 | New (dark mode, language) |

---

## 25. Navigation Map

### 25.1 Proposed Mobile Bottom Navigation (USER)

```
[ Home ] [ Search ] [ Post ] [ Activity ] [ Profile ]
```

- **Post** → `/property/new` (center FAB pattern like NoBroker)
- **Activity** → dashboard (visits + alerts)

### 25.2 Role-Based Overflow Menu

```
ADMIN  → Admin Panel
AGENT  → Agent Visits
BLOG   → Blog Studio
```

### 25.3 GoRouter Route Tree (Preview)

```
/                     → HomeScreen
/search               → SearchScreen
/property/:id         → PropertyDetailScreen
/property/new         → PropertyFormScreen
/property/:id/edit    → PropertyFormScreen
/login                → LoginScreen
/signup               → SignupScreen
/verify-otp           → OtpScreen
/forgot-password      → ForgotPasswordScreen
/verify-email         → VerifyEmailScreen
/dashboard            → DashboardScreen
/profile              → ProfileScreen
/my-properties        → MyPropertiesScreen
/favorites            → FavoritesScreen (new)
/blog                 → BlogListScreen
/blog/:slug           → BlogDetailScreen
/agent                → AgentScreen
/agent/visit/:id      → AgentVisitDetailScreen
/admin                → AdminScreen
/blog-editor          → BlogEditorScreen
```

---

## 26. Role Matrix

| Feature | USER | AGENT | BLOG | ADMIN |
|---------|:----:|:-----:|:----:|:-----:|
| Browse/search properties | ✅ | ✅ | ✅ | ✅ |
| View property detail | ✅ | ✅ | ✅ | ✅ |
| Book site visit | ✅ | ✅ | ✅ | ✅ |
| List property | ✅ | ✅ | ✅ | ✅ |
| Watchlist toggle | ✅ | ✅ | ✅ | ✅ |
| Profile management | ✅ | ✅ | ✅ | ✅ |
| Dashboard | ✅ | ✅ | ✅ | ✅ |
| Agent visit management | ❌ | ✅ | ❌ | ✅ |
| Blog Studio | ❌ | ❌ | ✅ | ✅ |
| Admin panel | ❌ | ❌ | ❌ | ✅ |
| Admin property endpoints | ❌ | ❌ | ❌ | ✅ |
| Public blog read | ✅ | ✅ | ✅ | ✅ |

---

## 27. Validation Matrix

| Domain | Client Rule | Server Rule (inferred) |
|--------|-------------|------------------------|
| Auth email | RFC-like email | Unique, not registered |
| Auth mobile | 10+ digits | Unique, MSG91 SMS |
| Auth password (signup) | min 8 | BCrypt stored |
| Auth password (reset) | min 6 | OTP verified |
| OTP | 6 digits | Expiry + throttling |
| Property price | >= 0 | Required |
| Property title | non-empty | Required |
| Property location | city + state + address | Required |
| Site visit datetime | future valid ISO | Business rules server-side |
| Agent OTP | 6 digits | Must match visit OTP |
| Media image URL | http(s) or Drive | Stored as-is |
| Media video URL | YouTube or Drive | `mediaType=VIDEO` |
| Profile email | valid email | Unique check server |
| Carousel image URL | non-empty URL | URL validation server |

---

## 28. Backend APIs Not Used by Angular

| API | Mobile Opportunity |
|-----|-------------------|
| `GET /properties/watchlist` | Favorites screen |
| `GET /alerts/unread-count` | Badge on Activity tab |
| `PUT /alerts/:id/read` | Mark notifications read |
| `GET /plans` | Premium listing (Phase 4) |
| `POST /payments/create-intent` | Premium listing (Phase 4) |
| `POST /payments/confirm` | Premium listing (Phase 4) |
| `POST /otp/send`, `/otp/verify` | Redundant with auth flows |

---

## 29. Risks

| # | Risk | Severity | Mitigation |
|---|------|----------|------------|
| R1 | `/auth/resend-signup-otp` may require auth on backend | High | Test against production; handle 401 gracefully |
| R2 | API URL mismatch (heroku vs 1guntha.com) | High | Confirm `https://1guntha.com/api` before build |
| R3 | Property media URL-only on web — mobile users expect camera | Medium | Use existing `/upload` for images (no backend change) |
| R4 | Admin panel is dense single-page — poor on small screens | Medium | Tabbed admin with progressive disclosure |
| R5 | Google Maps API key empty in prod env | Medium | Flavor-based key; fallback to lat/lng text |
| R6 | No offline support in Angular | Low | Cache search results + favorites locally |
| R7 | Site visit OTP shown in UI (security) | Low | Match web behavior; consider masking |
| R8 | `state` filter not sent to search API | Low | Match web; optionally send state param if backend supports |
| R9 | Legacy home services have no backend | Low | WhatsApp deep link or defer to Phase 3 |
| R10 | Blog rich text rendering | Medium | Use `flutter_html` or WebView for TEXT blocks |

---

## 30. Recommendations

### 30.1 Must-Have for MVP (Phase 1–2)

1. Auth with secure token storage + refresh interceptor parity
2. Home + Search + Property Detail + Favorites
3. Site visit booking flow with OTP display
4. List/Edit/Delete property (URL media + optional camera upload via `/upload`)
5. Profile + password change
6. Indian price formatting + media URL resolver port

### 30.2 Should-Have (Phase 3)

1. Dashboard with visits, alerts (with mark-read)
2. Agent workflow
3. Blog read-only
4. Deep linking (`/property/:id`, `/verify-email`, `/blog/:slug`)

### 30.3 Could-Have (Phase 4–5)

1. Admin mobile panel
2. Blog Studio
3. Premium payments (if product requests)
4. Home services WhatsApp enquiry
5. Firebase Analytics + Crashlytics
6. Push notifications (FCM) — needs future backend webhook

### 30.4 UX Recommendations (Benchmark-Driven)

| Pattern | Source | Apply To |
|---------|--------|----------|
| Bottom nav + center FAB | NoBroker | Main navigation |
| Filter bottom sheet | 99acres | Search |
| Property card with badges | Housing.com | Search/Home |
| OTP auto-read hint | MagicBricks | Signup/Forgot password |
| Skeleton loaders | All | List screens |
| Pull-to-refresh | All | Search, Dashboard, My Properties |
| Infinite scroll | 99acres | Search results |
| Map half-sheet | MagicBricks | Property detail |

---

*End of Project Analysis. Proceed to `02_Flutter_Migration_Plan.md` and `03_Flutter_Architecture.md`.*
