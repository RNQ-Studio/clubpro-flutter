# 📋 Bagian 1: Setup Data & Domain Layer (Offline-First Architecture)

> [!IMPORTANT]
> **MANDATORY / WAJIB SEBELUM MEMULAI:**
> Sebelum Anda menulis baris kode pertama, Anda **HARUS** membaca dan menganalisis secara mendalam dokumen **`docs/ADD_FEATURE.md`** di workspace ini. 
> Sesuai panduan di **`docs/ADD_FEATURE.md` (Bagian 5: Menambah App-Specific Feature)**, fitur Quotes ini akan dibuat eksklusif untuk aplikasi utama sehingga seluruh kodenya diletakkan di dalam **`apps/main/lib/features/quotes/`** (bukan di `features_shared`). Anda wajib mematuhi aturan arah dependensi (*dependency direction*), konvensi penamaan, dan struktur folder tiga lapisan (Data, Domain, Presentation) yang tercantum di dokumen tersebut.

Pekerjaan bagian pertama ini bertujuan untuk mengimplementasikan fondasi Data Layer dan Domain Layer untuk fitur **Quotes (CRUD) Lengkap** yang bertipe **Offline-First**. 

---

## 🛠️ Panduan Implementasi Bertahap

### 1. Konfigurasi Base URL
Ubah file `apps/main/lib/config/main_config.dart` agar mengarah ke API real:
* Base URL untuk Production: `https://anaklangit.manahpro.web.id/api` (pastikan berakhiran `/api` agar endpoint `/v1/quotes` dapat diakses sebagai `/v1/quotes`).
* Base URL untuk Dev dan Staging **sama**: `https://anaklangit.manahpro.web.id/api`. Backend ClubPro hanya satu; jangan arahkan ke server/domain lain.

### 2. Definisikan Tabel SQLite di Drift (`packages/core`)
Buka file `packages/core/lib/src/storage/app_database.dart` dan lakukan:
1. Buat definisi kelas tabel baru bernama `Quotes`:
   ```dart
   class Quotes extends Table {
     IntColumn get localId => integer().autoIncrement()(); // ID Lokal sebagai primary key
     IntColumn get id => integer().nullable()(); // ID dari backend (bisa null jika dibuat saat offline)
     TextColumn get text => text()();
     TextColumn get author => text()();
     TextColumn get source => text().nullable()();
     BoolColumn get isActive => boolean().withDefault(const Constant(true))();
     
     // Kolom Sinkronisasi Offline
     BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
     TextColumn get syncAction => text().nullable()(); // 'create', 'update', 'delete', atau null
     
     DateTimeColumn get createdAt => dateTime().nullable()();
     DateTimeColumn get updatedAt => dateTime().nullable()();
   }
   ```
2. Daftarkan tabel `Quotes` pada dekorator `@DriftDatabase` di file tersebut:
   ```dart
   @DriftDatabase(tables: [CacheEntries, Quotes])
   ```
3. Jalankan perintah kompilasi code generator Melos dari root directory untuk memperbarui kelas database:
   ```bash
   dart run melos run codegen
   ```

### 3. Buat Kerangka Fitur Quotes di `apps/main`
Sesuai **`docs/ADD_FEATURE.md`**, buat folder terstruktur berikut di dalam `apps/main/lib/features/quotes/`:
```text
apps/main/lib/features/quotes/
├── data/
│   ├── datasources/
│   │   ├── quotes_local_data_source.dart
│   │   └── quotes_remote_data_source.dart
│   ├── models/
│   │   └── quote_model.dart
│   └── repositories/
│       └── quotes_repository_impl.dart
└── domain/
    ├── entities/
    │   └── quote_entity.dart
    ├── repositories/
    │   └── quotes_repository.dart
    └── usecases/
        ├── get_quotes_use_case.dart
        ├── create_quote_use_case.dart
        ├── update_quote_use_case.dart
        ├── delete_quote_use_case.dart
        └── sync_quotes_use_case.dart
```

### 4. Implementasikan Model & Entity
* **Entity (`domain/entities/quote_entity.dart`)**:
  Buat kelas `QuoteEntity` murni Dart yang meng-extend `Equatable` (properti: `localId`, `id`, `text`, `author`, `source`, `isActive`, `isSynced`, `syncAction`, `createdAt`, `updatedAt`).
* **Model (`data/models/quote_model.dart`)**:
  Buat `QuoteModel` yang mewarisi `QuoteEntity` dengan method `fromJson` dan `toJson`.
  Format JSON dari backend Laravel adalah: `{"success": true, "message": "...", "data": {...}}`. Pastikan parsing data aman terhadap null.

### 5. Implementasikan Data Sources
* **Remote Data Source (`data/datasources/quotes_remote_data_source.dart`)**:
  Gunakan instance `Dio` dari `DioClient` bawaan core untuk melakukan request ke backend `/v1/quotes`:
  * `fetchAll()`: `GET /v1/quotes` (kembalikan daftar `QuoteModel`).
  * `create(text, author, source, isActive)`: `POST /v1/quotes`.
  * `update(id, text, author, source, isActive)`: `PUT /v1/quotes/{id}`.
  * `delete(id)`: `DELETE /v1/quotes/{id}`.
  * Pastikan memetakan error `DioException` ke `AppException` dari core package (`ServerException`, `NetworkException`, dll.).

* **Local Data Source (`data/datasources/quotes_local_data_source.dart`)**:
  Gunakan `AppDatabase` untuk memanipulasi SQLite secara offline:
  * Ambil semua data quotes lokal yang tidak berstatus `delete`.
  * Simpan/Upsert daftar quotes dari server ke SQLite lokal (cache sync).
  * Insert quote baru secara offline (set `isSynced = false`, `syncAction = 'create'`).
  * Update quote secara offline (jika sudah disinkronkan, ubah `isSynced = false`, `syncAction = 'update'`).
  * Hapus quote secara offline (jika belum sinkron ke server, hapus langsung dari SQLite. Jika sudah sinkron, ubah `isSynced = false`, `syncAction = 'delete'`).
  * Dapatkan semua item yang belum disinkronkan (`isSynced == false`).
  * Hapus data fisik quotes yang bertanda `syncAction = 'delete'` setelah sinkronisasi berhasil.

### 6. Implementasikan Repository & Use Cases
* **Repository Interface (`domain/repositories/quotes_repository.dart`)** dan **Implementasinya (`data/repositories/quotes_repository_impl.dart`)**:
  Gabungkan logika online dan offline. Saat mengambil data:
  1. Coba fetch dari `RemoteDataSource`. Jika sukses, simpan datanya ke SQLite lokal menggunakan `LocalDataSource`, lalu return data lokal terbaru.
  2. Jika offline/gagal koneksi, tangkap error-nya secara aman dan kembalikan data dari `LocalDataSource` (offline fallback).
* **Use Cases (`domain/usecases/...`)**:
  Buat usecase individual untuk setiap fungsionalitas CRUD dan Sync. Setiap usecase hanya memiliki satu method `call()`.

---

## 🔍 Hasil Yang Diharapkan
1. Skema SQLite di Drift database berhasil diperbarui dengan tabel `Quotes`.
2. Seluruh kode Data Layer dan Domain Layer selesai ditulis tanpa error kompilasi dan mengikuti standar `docs/ADD_FEATURE.md`.
