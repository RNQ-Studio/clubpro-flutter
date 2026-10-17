# 📋 Bagian 2: State Management & Auto-Synchronization Logic

> [!IMPORTANT]
> **MANDATORY / WAJIB SEBELUM MEMULAI:**
> Sebelum menulis state management dan logika sinkronisasi, Anda **HARUS** menganalisis kembali:
> * **`docs/ADD_FEATURE.md`** — khususnya Bagian 2 (Pilih Bentuk Struktur) dan Bagian 10 (Tambah Test).
> * **`CLAUDE.md`** — khususnya bagian State Management (Riverpod Generator).
>
> Semua notifier dan providers **WAJIB** menggunakan **Riverpod Generator** (`@riverpod` annotation) seperti yang didefinisikan dalam panduan arsitektur workspace. Pastikan berkas generator (`*.g.dart`) digenerate menggunakan build_runner/Melos.
>
> ⚠️ **JANGAN** menulis provider secara manual (vanilla). Gunakan `@riverpod` generator.

Pekerjaan bagian kedua ini berfokus pada **State Management menggunakan Riverpod** serta logika sinkronisasi data offline-to-online otomatis. Ketika aplikasi dibuka atau koneksi kembali tersedia, aplikasi harus memindai SQLite lokal untuk mendeteksi data yang belum tersinkronisasi (`isSynced = false`), lalu mengirimkannya ke server secara bertahap sesuai aksi yang tertunda ('create', 'update', 'delete').

---

## 📡 Referensi API (Ringkasan dari Bagian 1)

Base URL: `https://anaklangit.manahpro.web.id/api/v1`

| Method   | Endpoint             | Deskripsi                    |
|----------|----------------------|------------------------------|
| `GET`    | `/quotes`            | Ambil semua quotes           |
| `POST`   | `/quotes`            | Buat quote baru              |
| `PUT`    | `/quotes/{id}`       | Update quote                 |
| `DELETE` | `/quotes/{id}`       | Hapus quote                  |
| `GET`    | `/health`            | Cek koneksi server           |

---

## 🛠️ Langkah-Langkah yang Harus Dikerjakan

### 1. Registrasi Providers di Presentation Layer
Buat file `apps/main/lib/features/quotes/presentation/providers/quotes_providers.dart`:

Deklarasikan provider untuk DataSource, Repository, dan UseCases menggunakan **Riverpod Generator (`@riverpod` annotation)**.

```dart
// Contoh pola yang harus digunakan:
@riverpod
QuotesLocalDataSource quotesLocalDataSource(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return QuotesLocalDataSource(db);
}

@riverpod
QuotesRemoteDataSource quotesRemoteDataSource(Ref ref) {
  // Gunakan DioClient dari core package
  final storage = ref.watch(storageServiceProvider);
  final dioClient = DioClient(storage);
  return QuotesRemoteDataSource(dioClient.dio);
}

@riverpod
QuotesRepository quotesRepository(Ref ref) {
  final remoteDS = ref.watch(quotesRemoteDataSourceProvider);
  final localDS = ref.watch(quotesLocalDataSourceProvider);
  return QuotesRepositoryImpl(remoteDS, localDS);
}

// Deklarasikan juga provider untuk setiap UseCase:
// getQuotesUseCaseProvider, createQuoteUseCaseProvider,
// updateQuoteUseCaseProvider, deleteQuoteUseCaseProvider,
// syncQuotesUseCaseProvider
```

> [!NOTE]
> Perhatikan cara mendapatkan instance `AppDatabase` — gunakan `ref.watch(appDatabaseProvider)` yang sudah terdefinisi di core package. Untuk `Dio`, gunakan `DioClient` yang menerima `StorageService`.

### 2. Implementasi Notifier Utama (`QuotesNotifier`)
Buat kelas `QuotesNotifier` di `apps/main/lib/features/quotes/presentation/quotes_notifier.dart` yang meng-extend `_$QuotesNotifier` (generated).

Gunakan anotasi `@riverpod` sehingga kelas ini akan di-generate sebagai `AsyncNotifier`:

```dart
@riverpod
class QuotesNotifier extends _$QuotesNotifier {
  @override
  Future<List<QuoteEntity>> build() async {
    // 1. Jalankan sinkronisasi data latar belakang terlebih dahulu secara asinkron
    // 2. Ambil data quotes dari lokal SQLite database sebagai source of truth utama
  }
}
```

**Method `build()`**:
1. Jalankan sinkronisasi data latar belakang terlebih dahulu secara asinkron (panggil method `syncData()`).
2. Ambil data quotes dari lokal SQLite database sebagai source of truth utama.

**Method `syncData()`** — Logika sinkronisasi offline-first otomatis:
1. Cek apakah server backend dapat dihubungi dengan memanggil endpoint `GET /v1/health` melalui `RemoteDataSource.checkHealth()`.
2. Jika server aktif, cari semua data di SQLite lokal yang memiliki bendera `isSynced = false` via `LocalDataSource.getUnsyncedQuotes()`.
3. Lakukan sinkronisasi ke server bertahap berdasarkan `syncAction`:
   * **`'create'`**: Kirim `POST /v1/quotes` dengan isi `text`, `author`, `source`, dan `isActive`. Setelah berhasil, perbarui kolom `id` lokal dengan ID dari server, lalu set `isSynced = true` dan `syncAction = null` via `LocalDataSource.markAsSynced()`.
   * **`'update'`**: Kirim `PUT /v1/quotes/{id}`. Setelah sukses, set `isSynced = true` dan `syncAction = null`.
   * **`'delete'`**: Kirim `DELETE /v1/quotes/{id}`. Setelah sukses, hapus baris tersebut dari SQLite lokal via `LocalDataSource.deletePermanently()`.
4. **Error handling penting**: Jika terjadi error di salah satu sinkronisasi (misal validasi server gagal untuk satu item), **abaikan item tersebut dan lanjutkan ke item berikutnya**. Jangan biarkan satu error menghentikan seluruh proses sinkronisasi. Log error secara deskriptif tapi jangan throw exception.
5. Setelah seluruh sinkronisasi selesai, lakukan fetch data terbaru dari server (`GET /v1/quotes`) untuk memperbarui data SQLite lokal via `LocalDataSource.replaceAllWithServerData()`, lalu muat ulang state list UI.

### 3. Aksi CRUD di Notifier (Optimistic UI Update)
Tambahkan method berikut di `QuotesNotifier` untuk dipanggil dari UI:

**`addQuote(String text, String author, String? source, bool isActive)`**:
1. Lakukan *Optimistic Update*: Simpan ke SQLite lokal dengan status `isSynced = false` dan `syncAction = 'create'` via `LocalDataSource.insertQuote()`.
2. Rebuild state list lokal secara instan agar pengguna dapat melihat quote baru secara langsung tanpa menunggu loading server.
3. **Pemicu Sinkronisasi**: Jalankan `syncData()` di background (jangan await di UI flow) untuk langsung mengirim data ke server.

**`updateQuote(int localId, {String? text, String? author, String? source, bool? isActive})`**:
1. Update data di SQLite lokal secara langsung, set `isSynced = false` dan `syncAction = 'update'`.
2. Perbarui state list lokal secara instan.
3. Jalankan `syncData()` di background.

**`deleteQuote(int localId)`**:
1. Panggil `LocalDataSource.markAsDeleted(localId)`:
   * Jika data belum pernah dikirim ke server (`id == null`), hapus langsung dari SQLite.
   * Jika sudah pernah sinkron, set `isSynced = false` dan `syncAction = 'delete'`.
2. Perbarui state list lokal secara instan (hilangkan dari list).
3. Jalankan `syncData()` di background.

**`refreshQuotes()`**:
1. Set state ke `AsyncLoading()`.
2. Jalankan `syncData()` terlebih dahulu.
3. Ambil data lokal terbaru dan rebuild state.

### 4. Jalankan Code Generator
Setelah semua file selesai ditulis, jalankan code generator untuk meng-compile berkas `.g.dart`:
```bash
dart run melos run codegen
```
Pastikan tidak ada error kompilasi sebelum melanjutkan ke bagian selanjutnya.

---

## 🔍 Hasil Yang Diharapkan
1. File `quotes_notifier.dart` dan `quotes_providers.dart` berhasil dibuat dan lolos kompilasi generator Riverpod (`codegen`).
2. Logika sinkronisasi tangguh yang mampu menangani transisi offline-to-online secara mulus.
3. State UI selalu tersinkronisasi secara reaktif dengan SQLite lokal sebagai single source of truth.
4. Optimistic UI update berjalan dengan baik — user melihat perubahan instan tanpa menunggu server.
