# 📦 Fase 04: Backlog — Nice-to-Have (Jangka Panjang)

> Dokumen ini berisi backlog tugas-tugas pengembangan jangka panjang yang bersifat "nice-to-have":
> 1. Mason CLI Bricks — Otomasi Pembuatan Boilerplate Fitur
> 2. Firebase Crashlytics & Performance Monitoring
> 3. Network Certificate Pinning
>
> **Prasyarat**: Seluruh tugas di [Fase 02: Sprint 2](02_sprint_2.md) harus terselesaikan.
> **Catatan**: Tugas-tugas ini tidak bersifat mendesak dan dapat dikerjakan secara bertahap sesuai kebutuhan.

---

## Daftar Tugas

- [x] [Tugas 4.1: Mason CLI Bricks — Otomasi Boilerplate Fitur](#tugas-41-mason-cli-bricks--otomasi-boilerplate-fitur)
- [x] [Tugas 4.2: Firebase Crashlytics & Performance Monitoring](#tugas-42-firebase-crashlytics--performance-monitoring)
- [x] [Tugas 4.3: Network Certificate Pinning](#tugas-43-network-certificate-pinning)

---

## Tugas 4.1: Mason CLI Bricks — Otomasi Boilerplate Fitur

### Deskripsi & Konteks
Saat ini, untuk membuat fitur baru dengan struktur Clean Architecture (folder `data/`, `domain/`, `presentation/` beserta file-file di dalamnya), developer harus membuat setiap file dan folder secara manual mengikuti panduan di `docs/ADD_FEATURE.md`. Hal ini memakan waktu dan rentan kesalahan. Mason CLI adalah alat template kode yang memungkinkan pembuatan *boilerplate* fitur secara otomatis dengan satu perintah.

### Lokasi Berkas
- **File baru yang harus dibuat**:
  - `bricks/feature/__brick__/` — Template Mason untuk fitur Clean Architecture
  - `bricks/feature/brick.yaml` — Konfigurasi brick
  - `mason.yaml` — Konfigurasi Mason workspace di root

### Langkah Eksekusi (Step-by-step)

#### Langkah 1: Install Mason CLI
```bash
dart pub global activate mason_cli
```

#### Langkah 2: Inisialisasi Mason di Proyek
```bash
mason init
```

#### Langkah 3: Buat Brick Template Fitur
Buat struktur brick untuk pembuatan fitur Clean Architecture otomatis:

```
bricks/feature/
├── brick.yaml
├── __brick__/
│   └── {{feature_name.snakeCase()}}/
│       ├── data/
│       │   ├── datasources/
│       │   │   ├── {{feature_name.snakeCase()}}_remote_data_source.dart
│       │   │   └── {{feature_name.snakeCase()}}_local_data_source.dart
│       │   ├── models/
│       │   │   └── {{feature_name.snakeCase()}}_model.dart
│       │   └── repositories/
│       │       └── {{feature_name.snakeCase()}}_repository_impl.dart
│       ├── domain/
│       │   ├── entities/
│       │   │   └── {{feature_name.snakeCase()}}_entity.dart
│       │   ├── repositories/
│       │   │   └── {{feature_name.snakeCase()}}_repository.dart
│       │   └── usecases/
│       │       ├── get_{{feature_name.snakeCase()}}_use_case.dart
│       │       └── create_{{feature_name.snakeCase()}}_use_case.dart
│       └── presentation/
│           ├── {{feature_name.snakeCase()}}_notifier.dart
│           ├── {{feature_name.snakeCase()}}_state.dart
│           └── {{feature_name.snakeCase()}}_screen.dart
```

Konfigurasi `brick.yaml`:
```yaml
name: feature
description: Generate Clean Architecture feature structure for Flutter Starter
version: 1.0.0
vars:
  feature_name:
    type: string
    description: Name of the feature (e.g., "order", "product", "payment")
    prompt: What is the feature name?
  package_name:
    type: string
    description: Target package (e.g., "features_shared", "apps/main")
    default: features_shared
    prompt: Which package should contain this feature?
```

#### Langkah 4: Tulis Template File
Setiap file template harus berisi kode Dart boilerplate yang mengikuti konvensi proyek. Contoh template untuk entity:

```dart
// {{feature_name.snakeCase()}}_entity.dart
/// Entity untuk fitur {{feature_name.titleCase()}}
class {{feature_name.pascalCase()}}Entity {
  const {{feature_name.pascalCase()}}Entity({
    required this.id,
  });

  final String id;
}
```

Contoh template untuk repository interface:
```dart
// {{feature_name.snakeCase()}}_repository.dart
import '../entities/{{feature_name.snakeCase()}}_entity.dart';

/// Kontrak repository untuk fitur {{feature_name.titleCase()}}
abstract class {{feature_name.pascalCase()}}Repository {
  Future<List<{{feature_name.pascalCase()}}Entity>> getAll();
  Future<{{feature_name.pascalCase()}}Entity?> getById(String id);
  Future<void> create({{feature_name.pascalCase()}}Entity entity);
  Future<void> update({{feature_name.pascalCase()}}Entity entity);
  Future<void> delete(String id);
}
```

#### Langkah 5: Dokumentasikan Cara Penggunaan
Tambahkan instruksi di `docs/ADD_FEATURE.md`:
```markdown
## Cara Cepat (Mason CLI)
```bash
mason make feature --feature_name order --package_name features_shared --output-dir packages/features_shared/lib/src/
```
```

#### Langkah 6: Tambahkan Skrip Melos
```yaml
scripts:
  make-feature:
    run: mason make feature --output-dir packages/features_shared/lib/src/
    description: Generate a new Clean Architecture feature
```

### Batasan Arsitektur (Architectural Constraints)
- Template Mason **harus** menghasilkan kode yang langsung sesuai dengan konvensi proyek (penamaan, import path, dll.).
- Template **tidak boleh** menghasilkan import absolut antar-package — gunakan relative import di dalam `src/`.
- Brick template harus disimpan di folder `bricks/` di root repositori.

### Cara Verifikasi
```bash
# 1. Generate fitur percobaan
mason make feature --feature_name test_order --output-dir /tmp/test_feature

# 2. Verifikasi struktur folder terbentuk
ls -R /tmp/test_feature/test_order/

# 3. Verifikasi kode valid
cd /tmp/test_feature && dart analyze
```

### Estimasi Effort
**M** (2-3 hari) — Perancangan template yang akurat membutuhkan iterasi untuk memastikan kode hasil generate langsung valid.

---

## Tugas 4.2: Firebase Crashlytics & Performance Monitoring

### Deskripsi & Konteks
Setelah integrasi Firebase Core di Sprint 1, proyek belum memanfaatkan layanan monitoring produksi: **Firebase Crashlytics** (pelaporan crash otomatis) dan **Firebase Performance Monitoring** (pelacakan latensi UI dan jaringan). Kedua layanan ini krusial untuk aplikasi SaaS yang sudah berjalan di produksi.

### Lokasi Berkas
- **Package**: `packages/core`
- **File baru yang harus dibuat**:
  - `packages/core/lib/src/services/crashlytics_service.dart`
  - `packages/core/lib/src/services/performance_service.dart`
- **File yang harus dimodifikasi**:
  - `packages/core/pubspec.yaml` (tambah dependensi)
  - `apps/main/lib/bootstrap.dart` (inisialisasi)
  - `apps/variant/lib/bootstrap.dart` (inisialisasi)

### Langkah Eksekusi (Step-by-step)

#### Langkah 1: Tambahkan Dependensi
Di `packages/core/pubspec.yaml`:
```yaml
dependencies:
  firebase_crashlytics: ^4.1.4
  firebase_performance: ^0.10.0+8
```

#### Langkah 2: Buat Crashlytics Service
```dart
// packages/core/lib/src/services/crashlytics_service.dart
import 'dart:async';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

class CrashlyticsService {
  static Future<void> init() async {
    // Aktifkan hanya di mode release
    if (kReleaseMode) {
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
    }

    // Tangkap error Flutter framework
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

    // Tangkap error async yang tidak tertangkap
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  /// Catat error non-fatal
  static Future<void> recordError(
    dynamic exception,
    StackTrace? stack, {
    String? reason,
  }) async {
    await FirebaseCrashlytics.instance.recordError(
      exception, stack,
      reason: reason ?? 'Non-fatal error',
    );
  }

  /// Set user identifier untuk tracking
  static Future<void> setUserIdentifier(String userId) async {
    await FirebaseCrashlytics.instance.setUserIdentifier(userId);
  }

  /// Tambahkan custom log
  static void log(String message) {
    FirebaseCrashlytics.instance.log(message);
  }
}
```

#### Langkah 3: Buat Performance Service
```dart
// packages/core/lib/src/services/performance_service.dart
import 'package:firebase_performance/firebase_performance.dart';

class PerformanceService {
  static final FirebasePerformance _performance = FirebasePerformance.instance;

  /// Buat custom trace untuk mengukur durasi operasi
  static Future<T> trace<T>(
    String name,
    Future<T> Function() operation,
  ) async {
    final trace = _performance.newTrace(name);
    await trace.start();
    try {
      final result = await operation();
      trace.putAttribute('status', 'success');
      return result;
    } catch (e) {
      trace.putAttribute('status', 'error');
      trace.putAttribute('error', e.toString().substring(0, 100));
      rethrow;
    } finally {
      await trace.stop();
    }
  }

  /// Buat HTTP metric untuk tracking network request
  static HttpMetric createHttpMetric(String url, HttpMethod method) {
    return _performance.newHttpMetric(url, method);
  }
}
```

#### Langkah 4: Integrasikan ke Bootstrap
```dart
// Di bootstrap.dart
await CrashlyticsService.init();
```

#### Langkah 5: Integrasikan dengan DioClient
Tambahkan interceptor performance monitoring di `DioClient`:
```dart
_dio.interceptors.add(InterceptorsWrapper(
  onRequest: (options, handler) {
    final metric = PerformanceService.createHttpMetric(
      options.uri.toString(),
      HttpMethod.values.firstWhere(
        (m) => m.name.toLowerCase() == options.method.toLowerCase(),
        orElse: () => HttpMethod.Get,
      ),
    );
    options.extra['performance_metric'] = metric;
    metric.start();
    handler.next(options);
  },
  onResponse: (response, handler) {
    final metric = response.requestOptions.extra['performance_metric'] as HttpMetric?;
    metric?.httpResponseCode = response.statusCode;
    metric?.stop();
    handler.next(response);
  },
  onError: (error, handler) {
    final metric = error.requestOptions.extra['performance_metric'] as HttpMetric?;
    metric?.httpResponseCode = error.response?.statusCode;
    metric?.stop();
    handler.next(error);
  },
));
```

### Batasan Arsitektur (Architectural Constraints)
- Service Crashlytics dan Performance **harus** diletakkan di `packages/core`.
- Crashlytics harus **dinonaktifkan di mode debug** agar tidak mencemari data produksi.
- Integrasikan error handler Crashlytics di level paling awal (bootstrap), sebelum framework Flutter dirender.
- Performance traces harus diberi nama yang deskriptif dan konsisten (misal `api_login`, `api_get_profile`).

### Cara Verifikasi
```bash
# 1. Build release mode
cd apps/main && flutter build apk --release --dart-define=ENV=prod

# 2. Install di device → picu crash (test crash button)
# 3. Cek Firebase Console → Crashlytics → verifikasi crash report muncul
# 4. Cek Firebase Console → Performance → verifikasi trace HTTP muncul
```

### Estimasi Effort
**M** (2-3 hari) — Integrasi SDK cukup langsung, namun testing di release mode membutuhkan perhatian ekstra.

---

## Tugas 4.3: Network Certificate Pinning

### Deskripsi & Konteks
Certificate Pinning adalah teknik keamanan tingkat tinggi yang memastikan aplikasi hanya berkomunikasi dengan server yang memiliki sertifikat SSL/TLS spesifik yang di-*pin*. Ini melindungi dari serangan *Man-in-the-Middle (MITM)* bahkan jika penyerang berhasil memasukkan sertifikat palsu ke perangkat pengguna.

### Lokasi Berkas
- **Package**: `packages/core`
- **File baru yang mungkin dibuat**:
  - `packages/core/lib/src/network/certificate_pinning.dart`
  - `packages/core/assets/certificates/` (folder sertifikat)
- **File yang harus dimodifikasi**:
  - `packages/core/lib/src/network/dio_client.dart` (konfigurasi HttpClient)

### Langkah Eksekusi (Step-by-step)

#### Langkah 1: Dapatkan Certificate Hash (SHA256 fingerprint)
Untuk mendapatkan hash public key dari server produksi:
```bash
echo | openssl s_client -connect anaklangit.manahpro.web.id:443 2>/dev/null | \
  openssl x509 -pubkey -noout | \
  openssl pkey -pubin -outform DER | \
  openssl dgst -sha256 -binary | base64
```

#### Langkah 2: Implementasi Certificate Pinning
```dart
// packages/core/lib/src/network/certificate_pinning.dart
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';

class CertificatePinning {
  /// Daftar SHA256 hash dari public key server yang dipercaya
  static const List<String> _trustedFingerprints = [
    // Ganti dengan fingerprint server produksi Anda
    'BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=',
    // Backup fingerprint (untuk rotasi sertifikat)
    'CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC=',
  ];

  /// Konfigurasi certificate pinning pada instance Dio
  static void configure(Dio dio, {List<String>? customFingerprints}) {
    final fingerprints = customFingerprints ?? _trustedFingerprints;

    (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();
      client.badCertificateCallback = (X509Certificate cert, String host, int port) {
        // Hitung SHA256 dari certificate
        // Bandingkan dengan daftar fingerprint yang dipercaya
        // Return true jika cocok, false jika tidak
        return _validateCertificate(cert, fingerprints);
      };
      return client;
    };
  }

  static bool _validateCertificate(
    X509Certificate cert,
    List<String> trustedFingerprints,
  ) {
    // Implementasi validasi fingerprint
    // Catatan: Untuk implementasi production, gunakan package
    // seperti `http_certificate_pinning` untuk validasi yang lebih robust
    return false; // Default: tolak semua sertifikat yang tidak dikenal
  }
}
```

#### Langkah 3: Integrasikan ke DioClient
```dart
// Di DioClient constructor atau init
if (AppConfig.environment == Environment.prod) {
  CertificatePinning.configure(_dio);
}
```

#### Langkah 4: Strategi Rotasi Sertifikat
Siapkan mekanisme untuk rotasi sertifikat:
- Simpan beberapa fingerprint backup
- Implementasi fallback jika pinning gagal (hanya di mode non-prod)
- Dokumentasikan prosedur update fingerprint saat sertifikat server di-renew

### Batasan Arsitektur (Architectural Constraints)
- Certificate pinning **harus** diletakkan di `packages/core` bersama `DioClient`.
- **HANYA aktifkan di production environment** — di development dan staging, pinning akan menghambat penggunaan proxy debugging (Charles, Proxyman).
- Selalu sertakan **minimal 2 fingerprint** (primary + backup) untuk menghindari outage saat rotasi sertifikat.
- Jangan simpan private key di dalam kode — hanya public key hash yang diperlukan.

### Cara Verifikasi
```bash
# 1. Analisis statis bersih
dart run melos run analyze

# 2. Build production
cd apps/main && flutter build apk --release --dart-define=ENV=prod

# 3. Test manual:
#    a. Jalankan app di mode prod → API call berhasil (pinning cocok)
#    b. Ubah fingerprint ke nilai salah → API call gagal (pinning menolak)
#    c. Jalankan app di mode dev → API call berhasil (pinning dinonaktifkan)
```

### Estimasi Effort
**L** (3-5 hari) — Membutuhkan pemahaman kriptografi SSL, testing di environment production-like, dan strategi rotasi sertifikat yang matang.
