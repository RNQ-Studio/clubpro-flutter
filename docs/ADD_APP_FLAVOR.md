# Add App Flavor Guide

Panduan ini menjelaskan cara menambah app/flavor baru di monorepo. Gunakan `apps/variant` sebagai template karena strukturnya sudah berisi config, bootstrap, router, home screen, settings UI, Android, iOS, web, dan test dasar.

Contoh di dokumen ini memakai nama app baru `client`. Ganti `client` dengan nama app/flavor yang sebenarnya.

---

## 1. Kapan Perlu App Baru

Buat app/flavor baru jika project membutuhkan:

- aplikasi terpisah yang bisa di-install berdampingan,
- white-label app untuk client tertentu,
- produk turunan dengan UI atau route khusus,
- bundle identifier berbeda untuk store,
- konfigurasi backend berbeda per produk.

Jangan buat app baru hanya untuk environment `dev`, `staging`, atau `prod`. Environment sudah ditangani lewat `--dart-define=ENV=...`.

---

## 2. Copy Template App

Dari root repo:

```bash
Copy-Item -Recurse apps/variant apps/client
```

Jika memakai shell non-PowerShell:

```bash
cp -R apps/variant apps/client
```

Setelah copy, semua nama masih mengacu ke `variant`. Langkah berikutnya adalah rename identitas app.

---

## 3. Update Root Workspace

Edit root `pubspec.yaml`.

Tambahkan app baru ke `workspace`:

```yaml
workspace:
  - packages/core
  - packages/features_shared
  - apps/main
  - apps/variant
  - apps/client
```

Tambahkan Melos script untuk menjalankan app baru:

```yaml
melos:
  scripts:
    "dev:client":
      run: cd apps/client && flutter run --dart-define=ENV=dev
```

Jika app baru butuh build command sendiri, tambahkan script eksplisit:

```yaml
"build:android:client":
  run: cd apps/client && flutter build apk --dart-define=ENV=prod

"build:ios:client":
  run: cd apps/client && flutter build ipa --dart-define=ENV=prod
```

---

## 4. Update Pubspec App Baru

Edit:

```text
apps/client/pubspec.yaml
```

Ganti:

```yaml
name: app_variant
description: "Flutter Starter - variant flavor."
```

Menjadi:

```yaml
name: app_client
description: "Flutter Starter - client flavor."
```

Nama package Dart harus lowercase dan memakai underscore, bukan dash.

---

## 5. Rename Config Class

Rename file:

```text
apps/client/lib/config/variant_config.dart
```

Menjadi:

```text
apps/client/lib/config/client_config.dart
```

Update class:

```dart
import 'package:core/core.dart';

class ClientConfig extends AppConfig {
  @override
  Environment get environment => Environment.fromString(
        const String.fromEnvironment('ENV', defaultValue: 'dev'),
      );

  @override
  String get baseUrl => switch (environment) {
        Environment.dev => 'https://anaklangit.manahpro.web.id/api/',
        Environment.staging => 'https://anaklangit.manahpro.web.id/api/',
        Environment.prod => 'https://anaklangit.manahpro.web.id/api/',
      };
}
```

Update `main.dart`:

```dart
import 'package:core/core.dart';

import 'bootstrap.dart';
import 'config/client_config.dart';

void main() async {
  AppConfig.instance = ClientConfig();
  await bootstrap();
}
```

---

## 6. Update App Title Dan UI Awal

Update title di:

```text
apps/client/lib/app.dart
```

Contoh:

```dart
return MaterialApp.router(
  title: 'Flutter Starter Client',
  // ...
);
```

Update home screen:

```text
apps/client/lib/home/home_screen.dart
```

Ganti title dan teks placeholder agar tidak masih bertuliskan Variant.

Update settings screen jika ada label yang spesifik untuk variant:

```text
apps/client/lib/features/settings/presentation/settings_screen.dart
```

---

## 7. Update Router Import

Cek:

```text
apps/client/lib/router/app_router.dart
```

Pastikan import relatif masih valid setelah folder dicopy:

```dart
import '../features/settings/presentation/settings_route.dart';
import '../home/home_screen.dart';
```

Jika app baru punya route eksklusif, tambahkan route di file ini. Shared route dari `features_shared` tetap bisa dipakai melalui `authRoutes` dan `authRedirect`.

---

## 8. Update Android Identity

Edit:

```text
apps/client/android/app/build.gradle.kts
```

Ganti:

```kotlin
namespace = "id.rmq.app_variant"
applicationId = "id.rmq.variant"
```

Menjadi contoh:

```kotlin
namespace = "id.rmq.app_client"
applicationId = "id.rmq.client"
```

Jika ingin mengganti Kotlin package path, rename juga folder:

```text
apps/client/android/app/src/main/kotlin/id/rmq/app_variant/
```

Menjadi:

```text
apps/client/android/app/src/main/kotlin/id/rmq/app_client/
```

Lalu update package declaration di `MainActivity.kt` jika file tersebut mendeklarasikan package.

Update nama app Android di:

```text
apps/client/android/app/src/main/AndroidManifest.xml
```

Cari `android:label`, lalu ganti sesuai nama app.

---

## 9. Update iOS Identity

Edit:

```text
apps/client/ios/Runner.xcodeproj/project.pbxproj
```

Cari semua `PRODUCT_BUNDLE_IDENTIFIER` yang masih memakai variant, lalu ganti ke identifier app baru.

Contoh:

```text
id.rmq.client
id.rmq.client.RunnerTests
```

Update display name di:

```text
apps/client/ios/Runner/Info.plist
```

Cari:

```xml
<key>CFBundleDisplayName</key>
```

Lalu ganti string di bawahnya sesuai nama app.

---

## 10. Update Web Identity

Edit:

```text
apps/client/web/index.html
apps/client/web/manifest.json
```

Update:

- title,
- app name,
- short name,
- description jika ada,
- icon jika project sudah punya icon final.

---

## 11. Update Test

Edit test bawaan hasil copy:

```text
apps/client/test/home_screen_test.dart
```

Ganti expectation yang masih mengacu ke `Variant`.

Contoh:

```dart
expect(find.text('Welcome to Client!'), findsOneWidget);
```

Jika nama package berubah menjadi `app_client`, update import test yang masih mengarah ke `package:app_variant/...`.

---

## 12. Update VS Code Launch Config

Jika repo punya `.vscode/launch.json`, tambahkan konfigurasi app baru:

```json
{
  "name": "client dev",
  "request": "launch",
  "type": "dart",
  "cwd": "apps/client",
  "program": "lib/main.dart",
  "toolArgs": ["--dart-define=ENV=dev"]
}
```

Tambahkan juga `client staging` dan `client prod` jika diperlukan.

---

## 13. Update Firebase Jika Dipakai

Jika app baru memakai Firebase, app baru membutuhkan file konfigurasi sendiri:

```text
apps/client/android/app/google-services.json
apps/client/ios/Runner/GoogleService-Info.plist
```

Pastikan Firebase app menggunakan Android package name dan iOS bundle ID yang sama dengan app baru.

Jika project belum memakai Firebase, lewati langkah ini.

---

## 14. Resolve Dependency

Jalankan dari root:

```bash
dart pub get
melos list
```

Pastikan `apps/client` muncul di daftar package Melos.

Jika ada error package name, cek lagi `apps/client/pubspec.yaml`.

---

## 15. Verifikasi

Jalankan analyzer untuk app baru:

```bash
dart analyze apps/client
```

Jalankan test app baru:

```bash
flutter test apps/client/test
```

Jalankan app:

```bash
melos run dev:client
```

Atau manual:

```bash
cd apps/client
flutter run --dart-define=ENV=dev
```

Build smoke test:

```bash
cd apps/client
flutter build apk --dart-define=ENV=prod
```

---

## 16. Cari Sisa Nama Lama

Sebelum commit, cari sisa `variant` di app baru:

```bash
rg -n "variant|Variant|app_variant|id.rmq.variant" apps/client
```

Beberapa sisa kata mungkin memang disengaja jika nama app masih memakai istilah variant. Jika tidak, bersihkan semua agar app baru tidak membawa identitas template.

---

## 17. Checklist PR App Baru

- [ ] Folder app baru sudah masuk root `workspace`.
- [ ] App baru punya Melos script untuk run dev.
- [ ] `pubspec.yaml` app baru memakai package name unik.
- [ ] Config class sudah direname dan base URL sudah benar.
- [ ] `main.dart` memakai config class baru.
- [ ] Android `namespace` dan `applicationId` sudah unik.
- [ ] iOS bundle identifier sudah unik.
- [ ] Web title dan manifest sudah diganti.
- [ ] Home screen dan settings screen tidak lagi membawa teks template.
- [ ] Test app baru sudah disesuaikan.
- [ ] `melos list` menampilkan app baru.
- [ ] `dart analyze apps/client` clean.
- [ ] `flutter test apps/client/test` pass.
- [ ] App baru bisa dijalankan dengan `melos run dev:client`.
