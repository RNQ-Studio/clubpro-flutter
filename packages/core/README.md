# core

`core` adalah package fondasi untuk semua app di monorepo ini. Package ini berisi infrastruktur lintas fitur seperti konfigurasi environment, theme, localization, network client, storage abstraction, responsive layout, route constants, error model, extension, utility, dan widget reusable.

Package ini tidak boleh bergantung pada package internal lain seperti `features_shared` atau `apps/*`.

---

## Isi Package

Public API diexport melalui:

```dart
import 'package:core/core.dart';
```

Area utama:

| Area | Isi |
|------|-----|
| `config` | `AppConfig`, `Environment` |
| `constants` | key dan nilai global |
| `errors` | `AppException`, `Failure` |
| `extensions` | extension untuk `BuildContext`, `String`, dan helper sejenis |
| `l10n` | generated `AppLocalizations` |
| `network` | `DioClient` dan auth interceptor |
| `responsive` | breakpoints dan `ResponsiveLayout` |
| `router` | `AppRoutes`, `AppNavigatorObserver` |
| `storage` | `StorageService`, `SecureStorageService`, `SharedPreferencesStorage` |
| `theme` | `AppTheme`, `AppColors`, `AppTextStyles` |
| `utils` | date formatter, input validator |
| `widgets` | `AppButton`, `AppTextField`, `LoadingOverlay` |

---

## Aturan Import

Gunakan barrel export:

```dart
import 'package:core/core.dart';
```

Jangan import file `src/` dari package/app lain:

```dart
// Hindari dari luar package core.
import 'package:core/src/theme/app_theme.dart';
```

Import relatif ke file `src/` boleh dipakai dari dalam package `core` sendiri.

---

## AppConfig dan Environment

Setiap app wajib mengisi `AppConfig.instance` sebelum `bootstrap()`.

Contoh:

```dart
void main() async {
  AppConfig.instance = MainConfig();
  await bootstrap();
}
```

Implementasi config ada di masing-masing app:

```dart
class MainConfig extends AppConfig {
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

---

## Network

`DioClient` memakai `AppConfig.instance.baseUrl` dan menambahkan auth token melalui `AuthInterceptor`.

Contoh:

```dart
final storage = SecureStorageService();
await storage.init();

final dio = DioClient(storage).dio;
final response = await dio.get('/profile');
```

Jika `DioClient` dipakai sebelum `AppConfig.instance` diisi, app akan error. Karena itu config harus diset di `main.dart` sebelum bootstrap.

---

## Storage

Gunakan storage sesuai jenis data:

- `SecureStorageService` untuk data sensitif seperti token auth.
- `SharedPreferencesStorage` untuk preference non-sensitif seperti theme, locale, dan flag UI.

Keduanya mengikuti kontrak yang sama:

```dart
abstract class StorageService {
  Future<void> init();
  Future<void> write(String key, String value);
  Future<String?> read(String key);
  Future<void> delete(String key);
  Future<void> clear();
}
```

---

## Localization

File ARB berada di:

```text
lib/src/l10n/app_id.arb
lib/src/l10n/app_en.arb
```

Generate ulang localization dari folder package:

```bash
cd packages/core
flutter gen-l10n
```

Gunakan di app melalui `MaterialApp.router`:

```dart
MaterialApp.router(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
)
```

---

## Routing

Route global diletakkan di `AppRoutes`:

```dart
abstract final class AppRoutes {
  static const String home = '/';
  static const String login = '/login';
  static const String settings = '/settings';
}
```

Tambahkan route constant ke `core` hanya jika route tersebut menjadi kontrak lintas app. Route yang hanya milik satu app boleh diletakkan di app tersebut.

---

## Test dan Analyze

Jalankan dari root repo:

```bash
dart analyze packages/core
flutter test packages/core/test
```

Atau dari folder package:

```bash
cd packages/core
flutter test
```
