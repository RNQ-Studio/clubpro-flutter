# 📋 Bagian 1: Setup Data & Domain Layer (Offline-First Architecture)

> [!IMPORTANT]
> **MANDATORY / WAJIB SEBELUM MEMULAI:**
> Sebelum Anda menulis baris kode pertama, Anda **HARUS** membaca dan menganalisis secara mendalam dokumen **`docs/ADD_FEATURE.md`** di workspace ini.
> Sesuai panduan di **`docs/ADD_FEATURE.md` (Bagian 5: Menambah App-Specific Feature)**, fitur Quotes ini akan dibuat eksklusif untuk aplikasi utama sehingga seluruh kodenya diletakkan di dalam **`apps/main/lib/features/quotes/`** (bukan di `features_shared`). Anda wajib mematuhi aturan arah dependensi (*dependency direction*), konvensi penamaan, dan struktur folder tiga lapisan (Data, Domain, Presentation) yang tercantum di dokumen tersebut.
>
> Baca juga **`CLAUDE.md`** di root project untuk memahami konvensi penamaan, state management (Riverpod Generator), navigasi (GoRouter), error handling, dan hal-hal yang **HARUS DIHINDARI**.

Pekerjaan bagian pertama ini bertujuan untuk mengimplementasikan fondasi Data Layer dan Domain Layer untuk fitur **Quotes (CRUD) Lengkap** yang bertipe **Offline-First**.

---

## 📡 Referensi API Backend

API backend menggunakan **Laravel Starter API** dengan base URL: `https://anaklangit.manahpro.web.id/api/v1`

Semua response API mengikuti format standar Laravel Starter:
```json
{
  "success": true,
  "message": "...",
  "data": { ... },
  "meta": "..."
}
```

### Endpoint CRUD Quotes

| Method   | Endpoint             | Deskripsi                    | Auth Required |
|----------|----------------------|------------------------------|---------------|
| `GET`    | `/quotes`            | Ambil semua quotes (array)   | Tidak         |
| `POST`   | `/quotes`            | Buat quote baru              | Tidak         |
| `GET`    | `/quotes/{id}`       | Ambil detail satu quote      | Tidak         |
| `PUT`    | `/quotes/{id}`       | Update quote                 | Tidak         |
| `DELETE` | `/quotes/{id}`       | Hapus quote                  | Tidak         |

### QuoteResource (Response `data`)
```json
{
  "id": 1,
  "text": "Isi kutipan",
  "author": "Nama Penulis",
  "source": "Sumber atau null",
  "is_active": true,
  "created_at": "2025-01-01T00:00:00.000000Z",
  "updated_at": "2025-01-01T00:00:00.000000Z"
}
```

### StoreQuoteRequest (POST Body)
```json
{
  "text": "string (min: 5 karakter, required)",
  "author": "string (max: 255, required)",
  "source": "string|null (max: 255, optional)",
  "is_active": "boolean (optional)"
}
```

### UpdateQuoteRequest (PUT Body)
```json
{
  "text": "string (min: 5 karakter, optional)",
  "author": "string (max: 255, optional)",
  "source": "string|null (max: 255, optional)",
  "is_active": "boolean (optional)"
}
```

### Health Check
| Method | Endpoint   | Deskripsi             |
|--------|------------|-----------------------|
| `GET`  | `/health`  | Cek status server     |

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

> [!NOTE]
> **Tentang folder `bricks/`**: Folder ini berisi **Mason CLI template** (brick) untuk men-generate scaffolding fitur baru secara otomatis. Anda bisa menggunakannya via `mason make feature --feature_name quotes --output-dir apps/main/lib/features/` atau langsung membuat file secara manual sesuai struktur di atas. Kedua pendekatan valid, namun untuk kontrol penuh atas implementasi offline-first, **buat file secara manual** sesuai instruksi di bawah.

### 4. Implementasikan Entity
**Entity (`domain/entities/quote_entity.dart`)**:
Buat kelas `QuoteEntity` murni Dart yang meng-extend `Equatable`. Entity ini merepresentasikan data bisnis murni tanpa dependensi ke framework apapun.

Properti yang harus ada:
* `localId` (int) — Primary key lokal SQLite
* `id` (int?) — ID dari backend, nullable karena bisa null saat dibuat offline
* `text` (String) — Isi kutipan
* `author` (String) — Nama penulis
* `source` (String?) — Sumber kutipan, nullable
* `isActive` (bool) — Status aktif/nonaktif
* `isSynced` (bool) — Apakah sudah tersinkronisasi ke server
* `syncAction` (String?) — Aksi tertunda: `'create'`, `'update'`, `'delete'`, atau `null`
* `createdAt` (DateTime?) — Timestamp pembuatan
* `updatedAt` (DateTime?) — Timestamp update terakhir

Sediakan juga method `copyWith()` agar memudahkan update immutable.

### 5. Implementasikan Model
**Model (`data/models/quote_model.dart`)**:
Buat `QuoteModel` yang mewarisi `QuoteEntity` dengan factory constructors:
* `QuoteModel.fromJson(Map<String, dynamic> json)` — Parsing dari response API backend Laravel. Format response: `{"success": true, "message": "...", "data": {...}}`. Parsing harus aman terhadap null.
* `QuoteModel.fromDatabase(Quote row)` — Konstruksi dari row database Drift (kelas `Quote` yang di-generate oleh Drift dari tabel `Quotes`).
* `Map<String, dynamic> toJson()` — Serialisasi untuk dikirim ke API backend.
* `QuotesCompanion toDatabaseCompanion()` — Konversi ke Drift companion untuk insert/update ke SQLite.

### 6. Implementasikan Data Sources
**Remote Data Source (`data/datasources/quotes_remote_data_source.dart`)**:
Gunakan instance `Dio` dari `DioClient` bawaan core untuk melakukan request ke backend:
* `fetchAll()`: `GET /v1/quotes` — Kembalikan daftar `QuoteModel`. Parsing dari `response.data['data']` (array).
* `create(text, author, source, isActive)`: `POST /v1/quotes` — Kembalikan `QuoteModel` dari `response.data['data']`.
* `update(id, text, author, source, isActive)`: `PUT /v1/quotes/{id}` — Kembalikan `QuoteModel` dari `response.data['data']`.
* `delete(id)`: `DELETE /v1/quotes/{id}` — Tidak perlu return data.
* `checkHealth()`: `GET /v1/health` — Return `true` jika server merespons, `false` jika gagal.
* Pastikan memetakan error `DioException` ke `AppException` dari core package (`ServerException`, `NetworkException`, dll.).

**Local Data Source (`data/datasources/quotes_local_data_source.dart`)**:
Gunakan `AppDatabase` (Drift) untuk memanipulasi SQLite secara offline:
* `getAllQuotes()` — Ambil semua data quotes lokal yang **tidak** berstatus `syncAction = 'delete'`.
* `insertQuote(QuotesCompanion)` — Insert quote baru ke SQLite (set `isSynced = false`, `syncAction = 'create'`). Return `localId` yang baru dibuat.
* `updateQuote(int localId, QuotesCompanion)` — Update quote di SQLite. Jika data sudah pernah sinkron ke server, set `isSynced = false` dan `syncAction = 'update'`.
* `markAsDeleted(int localId)` — Jika data **belum pernah sinkron** ke server (`id == null`), hapus langsung dari SQLite. Jika sudah sinkron, ubah `isSynced = false` dan `syncAction = 'delete'`.
* `getUnsyncedQuotes()` — Ambil semua item yang memiliki `isSynced == false`.
* `markAsSynced(int localId, {int? serverId})` — Set `isSynced = true`, `syncAction = null`, dan update `id` dari server jika diberikan.
* `deletePermanently(int localId)` — Hapus data fisik dari SQLite (dipanggil setelah sinkronisasi `delete` berhasil).
* `replaceAllWithServerData(List<QuotesCompanion>)` — Hapus semua data yang `isSynced == true`, lalu masukkan data terbaru dari server. Data yang belum sinkron (`isSynced == false`) **TIDAK BOLEH** dihapus.

### 7. Implementasikan Repository & Use Cases
**Repository Interface (`domain/repositories/quotes_repository.dart`)**:
```dart
abstract class QuotesRepository {
  Future<List<QuoteEntity>> getQuotes();
  Future<QuoteEntity> createQuote({required String text, required String author, String? source, bool isActive = true});
  Future<QuoteEntity> updateQuote({required int localId, String? text, String? author, String? source, bool? isActive});
  Future<void> deleteQuote(int localId);
  Future<void> syncQuotes();
}
```

**Implementasi (`data/repositories/quotes_repository_impl.dart`)**:
Gabungkan logika online dan offline. Saat mengambil data (`getQuotes`):
1. Coba fetch dari `RemoteDataSource`. Jika sukses, simpan datanya ke SQLite lokal menggunakan `LocalDataSource.replaceAllWithServerData()`, lalu return data lokal terbaru.
2. Jika offline/gagal koneksi, tangkap error-nya secara aman dan kembalikan data dari `LocalDataSource` (offline fallback).

**Use Cases (`domain/usecases/...`)**:
Buat usecase individual untuk setiap fungsionalitas: `GetQuotesUseCase`, `CreateQuoteUseCase`, `UpdateQuoteUseCase`, `DeleteQuoteUseCase`, `SyncQuotesUseCase`. Setiap usecase hanya memiliki satu method `call()`.

---

## 🔍 Hasil Yang Diharapkan
1. Skema SQLite di Drift database berhasil diperbarui dengan tabel `Quotes`.
2. Seluruh kode Data Layer dan Domain Layer selesai ditulis tanpa error kompilasi dan mengikuti standar `docs/ADD_FEATURE.md`.
3. Code generator (Drift & Riverpod) berhasil dijalankan tanpa error:
   ```bash
   dart run melos run codegen
   ```
