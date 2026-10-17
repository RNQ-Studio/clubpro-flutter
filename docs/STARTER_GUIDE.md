# Starter Guide

Panduan ini dipakai setelah repo di-fork atau dicopy untuk project baru. Tujuannya sederhana: ubah identitas project, pastikan dependency siap, lalu jalankan app tanpa harus menebak file mana yang perlu disentuh.

> [!TIP]
> **Baru mengenal monorepo, Clean Architecture, Riverpod Generator, Drift SQLite, atau Mason Bricks?**
> Kami menyediakan seri panduan belajar interaktif khusus pemula di folder [docs/tutorial/](file:///c:/Users/62822/Documents/Work/flutter/flutter-starter/docs/tutorial/).
> Silakan mulai dari **[00_overview.md (Peta Jalur Belajar)](file:///c:/Users/62822/Documents/Work/flutter/flutter-starter/docs/tutorial/00_overview.md)**!

---


## 1. Prasyarat

Pastikan tool berikut sudah tersedia:

- Flutter SDK stable
- Dart SDK dari Flutter
- Melos

Install Melos jika belum ada:

```bash
dart pub global activate melos
```

Cek versi:

```bash
flutter --version
dart --version
melos --version
```

---

## 2. Setup Pertama

Jalankan dari root repo:

```bash
dart pub get
melos list
```

Jalankan app utama:

```bash
melos run dev
```

Jalankan app variant:

```bash
melos run dev:variant
```

Jika ingin menjalankan environment selain `dev`, masuk ke folder app yang sesuai:

```bash
cd apps/main
flutter run --dart-define=ENV=staging
flutter run --dart-define=ENV=prod
```

```bash
cd apps/variant
flutter run --dart-define=ENV=staging
flutter run --dart-define=ENV=prod
```

---

## 3. Checklist Setelah Fork

Gunakan checklist ini sebelum mulai development fitur.

- [ ] Rename root workspace name di `pubspec.yaml`.
- [ ] Rename app package name di `apps/main/pubspec.yaml` dan `apps/variant/pubspec.yaml` jika diperlukan.
- [ ] Update description dan version di masing-masing `pubspec.yaml`.
- [ ] Update Android `namespace` dan `applicationId`.
- [ ] Update iOS bundle identifier.
- [ ] Update nama app di Android, iOS, dan web.
- [ ] Update base URL di `MainConfig` dan `VariantConfig`.
- [ ] Tentukan apakah `variant` tetap dipakai, dihapus, atau direname menjadi app/client lain.
- [ ] Tentukan apakah debug fake auth tetap dipakai.
- [ ] Tambahkan konfigurasi Firebase jika project memakai Firebase.
- [ ] Update icon, splash screen, dan web manifest.
- [ ] Update LICENSE dan package README yang masih boilerplate.
- [ ] Tentukan apakah UI Gallery tetap dipertahankan sebagai referensi komponen atau dihapus sebelum production release (lihat bagian 13).

---

## 4. File Yang Paling Sering Diubah

### Root Workspace

| File | Kapan diubah |
|------|--------------|
| `pubspec.yaml` | Rename workspace, tambah app/package workspace, tambah Melos script |
| `README.md` | Update nama project, quickstart, tech stack, dan link docs |
| `ARCHITECTURE.md` | Update aturan arsitektur jika struktur project berubah |
| `CONTRIBUTING.md` | Update branching, PR policy, dan commit convention |

### App Main

| File | Kapan diubah |
|------|--------------|
| `apps/main/pubspec.yaml` | Rename package, version, dependency app |
| `apps/main/lib/config/main_config.dart` | Update base URL per environment |
| `apps/main/lib/app.dart` | Override dependency app, theme, locale, auth repository |
| `apps/main/lib/router/app_router.dart` | Tambah route app main |
| `apps/main/android/app/build.gradle.kts` | Update namespace, applicationId, signing config |
| `apps/main/ios/Runner.xcodeproj/project.pbxproj` | Update bundle identifier |
| `apps/main/web/index.html` | Update title web |
| `apps/main/web/manifest.json` | Update metadata PWA |

### App Variant

| File | Kapan diubah |
|------|--------------|
| `apps/variant/pubspec.yaml` | Rename package, version, dependency app |
| `apps/variant/lib/config/variant_config.dart` | Update base URL per environment |
| `apps/variant/lib/app.dart` | Override dependency app, theme, locale |
| `apps/variant/lib/router/app_router.dart` | Tambah route app variant |
| `apps/variant/android/app/build.gradle.kts` | Update namespace, applicationId, signing config |
| `apps/variant/ios/Runner.xcodeproj/project.pbxproj` | Update bundle identifier |
| `apps/variant/web/index.html` | Update title web |
| `apps/variant/web/manifest.json` | Update metadata PWA |

### Shared Packages

| File | Kapan diubah |
|------|--------------|
| `packages/core/lib/core.dart` | Export public API baru dari core |
| `packages/features_shared/lib/features_shared.dart` | Export public API fitur shared |
| `packages/core/lib/src/router/app_routes.dart` | Tambah konstanta route global |
| `packages/core/lib/src/l10n/*.arb` | Tambah atau ubah teks lokalisasi |

---

## 5. Rename Identitas App

### Android

Update file berikut untuk setiap app:

- `apps/main/android/app/build.gradle.kts`
- `apps/variant/android/app/build.gradle.kts`

Field utama:

```kotlin
namespace = "com.company.app"
applicationId = "com.company.app"
```

Jika app main dan variant adalah dua aplikasi berbeda yang bisa terpasang bersamaan, pastikan `applicationId` keduanya berbeda.

### iOS

Update bundle identifier di:

- `apps/main/ios/Runner.xcodeproj/project.pbxproj`
- `apps/variant/ios/Runner.xcodeproj/project.pbxproj`

Cari `PRODUCT_BUNDLE_IDENTIFIER`, lalu ganti ke identifier project baru.

### Web

Update title dan manifest:

- `apps/main/web/index.html`
- `apps/main/web/manifest.json`
- `apps/variant/web/index.html`
- `apps/variant/web/manifest.json`

---

## 6. Update Environment Dan Base URL

Environment valid saat ini:

- `dev`
- `staging`
- `prod`

Base URL app main ada di:

```text
apps/main/lib/config/main_config.dart
```

Base URL app variant ada di:

```text
apps/variant/lib/config/variant_config.dart
```

Contoh pola:

```dart
String get baseUrl => switch (environment) {
  Environment.dev => 'https://anaklangit.manahpro.web.id/api/',
  Environment.staging => 'https://anaklangit.manahpro.web.id/api/',
  Environment.prod => 'https://anaklangit.manahpro.web.id/api/',
};
```

Jika project membutuhkan konfigurasi tambahan seperti API key, region, tenant ID, atau feature flag, tambahkan getter baru di `AppConfig`, lalu implementasikan di `MainConfig` dan `VariantConfig`.

---

## 7. Auth Dan Backend

Auth shared berada di:

```text
packages/features_shared/lib/src/auth/
```

`apps/main` saat ini memakai `FakeAuthRepository` pada debug mode:

```text
apps/main/lib/dev/fake_auth_repository.dart
apps/main/lib/app.dart
```

Ini berguna agar development bisa berjalan tanpa backend. Untuk project production, pilih salah satu:

- tetap gunakan fake auth hanya untuk debug/demo,
- hapus override fake auth,
- ganti dengan mock repository yang sesuai kebutuhan project.

Token auth memakai `SecureStorageService` melalui `storageServiceProvider`. Provider ini dioverride di app root, bukan di package shared.

---

## 8. Firebase

Firebase Core dan Firebase Cloud Messaging (FCM) sudah terintegrasi di `packages/core`:
- `FirebaseService` — wrapper untuk inisialisasi Firebase Core
- `FCMNotificationService` — handler untuk permission, token, dan message listener

Namun, inisialisasi masih ter-comment di `bootstrap.dart` karena memerlukan konfigurasi per-project melalui `flutterfire configure`.

**Untuk panduan lengkap integrasi Firebase multi-flavor, lihat [Panduan Firebase Setup](firebase-setup.md).**

Jika project tidak memakai Firebase, hapus dependency Firebase dari `packages/core/pubspec.yaml` dan bersihkan kode terkait.

---

## 9. Menentukan Nasib Variant

Repo ini menyediakan dua app:

- `apps/main` untuk produk utama.
- `apps/variant` untuk contoh app kedua, client app, white-label app, atau produk turunan.

Jika project hanya butuh satu app:

- hapus `apps/variant`,
- hapus `apps/variant` dari root `workspace`,
- hapus script `dev:variant` jika tidak dipakai,
- jalankan `dart pub get`,
- jalankan `melos list` untuk memastikan workspace bersih.

Jika `variant` akan direname:

- rename folder `apps/variant`,
- update root `workspace`,
- update package name di `pubspec.yaml`,
- update namespace/applicationId Android,
- update bundle identifier iOS,
- update Melos script,
- update VS Code launch config jika ada.

---

## 10. Verifikasi Sebelum Mulai Fitur

Jalankan dari root repo:

```bash
dart pub get
dart run melos list
dart run melos run format:check
dart run melos run analyze
dart run melos run test
```

Build smoke test untuk Android app main:

```bash
melos run build:android
```

Jika semua lolos, project siap dipakai sebagai fondasi development.

---

## 11. Continuous Integration

Workflow GitHub Actions ada di:

```text
.github/workflows/ci.yml
```

CI berjalan pada `push` dan `pull_request` ke branch:

- `main`
- `develop`

Command yang dijalankan CI:

```bash
dart pub get
dart run melos list
dart run melos run format:check
dart run melos run analyze
dart run melos run test
```

Jika CI gagal:

- Jalankan command yang sama dari root repo.
- Untuk format failure, jalankan `dart run melos run format`, lalu commit hasil format.
- Untuk analyzer failure, perbaiki warning/error yang ditampilkan.
- Untuk test failure, jalankan test package/app terkait, misalnya `dart run melos run test:main`.

---

## 12. Aturan Praktis Saat Menambah Kode

- Fitur reusable untuk semua app masuk ke `packages/features_shared`.
- Fitur yang hanya berlaku untuk satu app masuk ke `apps/<app_name>/lib/features`.
- Fondasi lintas app seperti theme, network, storage, responsive, router constants, dan l10n masuk ke `packages/core`.
- Public API package diexport lewat `core.dart` atau `features_shared.dart`.
- Jangan import file `src/` dari package lain secara langsung.
- Tambahkan route constant ke `AppRoutes` jika route dipakai lintas app.
- Tambahkan test minimal untuk provider, repository, atau screen yang punya logic penting.

---

## 13. UI Component Gallery

`apps/main` menyertakan **UI Component Gallery** — mini showcase interaktif yang menampilkan komponen-komponen Flutter yang umum dipakai. Gallery ini dibangun di Sprint 009 dan tersedia langsung dari Home screen tanpa perlu konfigurasi tambahan.

### Cara Mengakses Gallery

Jalankan `apps/main`, lalu tap item **"UI Gallery"** di grid menu Home screen. Gallery membuka halaman daftar 8 kategori:

| Kategori | Isi |
|----------|-----|
| Dialog & Popup | Alert dialog, confirm dialog, shake dialog, countdown dialog, loading dialog, bottom sheet, snackbar (4 varian) |
| Form & Input | TextField, password toggle, validasi email real-time, date picker, dropdown, radio, checkbox, switch, slider |
| Cards & Lists | 5 varian card, dismissible list + undo, reorderable list |
| Navigation & Tab | TabBar, Stepper, Drawer dengan UserAccountsDrawerHeader, BottomNavigationBar (M2 & M3) |
| Loading & Empty | Shimmer manual via ShaderMask, linear/circular progress, 4 varian empty state, pull-to-refresh |
| Animation | Hero transition, page transition 3 tipe, AnimatedList, staggered animation |
| Feedback & Input | Star rating drag, like button animation, reaction picker, OTP 6-digit |
| Utilities | Clipboard copy, search highlight dengan RichText, color picker, tooltip & badge |

### Cara Pakai Sebagai Referensi

Saat membangun fitur baru yang memerlukan komponen tertentu — misalnya dialog konfirmasi, form dengan validasi, atau animasi sederhana — buka layar gallery yang relevan dan lihat implementasinya langsung di file berikut:

```text
apps/main/lib/features/ui_gallery/screens/
├── dialog_popup_screen.dart
├── form_input_screen.dart
├── cards_list_screen.dart
├── navigation_tab_screen.dart
├── loading_empty_screen.dart
├── animation_screen.dart
├── feedback_screen.dart
└── utilities_screen.dart
```

Dummy data yang dipakai gallery tersimpan di:

```text
apps/main/lib/features/ui_gallery/data/dummy_data.dart
```

Widget helper (section header, demo card, gallery menu card) tersimpan di:

```text
apps/main/lib/features/ui_gallery/widgets/
```

### Menghapus Gallery Sebelum Production

Gallery adalah referensi development, bukan fitur produk. Jika project tidak memerlukan gallery di production, hapus seluruh kodenya:

**1. Hapus folder gallery:**

```bash
rm -rf apps/main/lib/features/ui_gallery/
```

**2. Hapus route dari `app_router.dart`:**

```dart
// hapus import ini:
import '../features/ui_gallery/screens/ui_gallery_home_screen.dart';

// hapus GoRoute ini:
GoRoute(
  path: '/ui-gallery',
  builder: (context, state) => const UiGalleryHomeScreen(),
),
```

**3. Kembalikan `home_screen.dart` ke perilaku semula:**

```dart
// ubah kembali onMenuTap menjadi selalu menampilkan SnackBar,
// atau hubungkan ke fitur nyata yang sudah dibangun:
onMenuTap: (label) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('$label belum tersedia')),
  );
},
```

**4. Update `home_menu_grid.dart`:**

Hapus item `_MenuItem` dengan label `'UI Gallery'` dan field `isGallery`. Pastikan method `onMenuTap` tidak mengecek label ini lagi.

**5. Verifikasi:**

```bash
dart run melos run analyze
dart run melos run test
```

---

## 14. Setelah Project Mulai Stabil

Hal yang sebaiknya ditambahkan ketika starter sudah menjadi project nyata:

- Signing config Android release.
- App icon dan splash screen final.
- Error reporting seperti Crashlytics atau Sentry.
- Environment secret management.
- Coverage untuk shared package penting.
- Release checklist untuk Android, iOS, dan web.
