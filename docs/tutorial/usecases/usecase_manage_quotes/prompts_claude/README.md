# 🤖 Prompt Claude — Fitur Manajemen Kutipan (Quotes Management)

Kumpulan prompt terstruktur untuk memandu **Claude** mengimplementasikan fitur **CRUD Quotes** secara lengkap pada project Flutter Starter, menggunakan pendekatan **Offline-First Architecture**.

---

## 📋 Daftar Prompt

| Bagian | File | Fokus Pekerjaan | Estimasi Beban |
|--------|------|------------------|----------------|
| **1** | [part_1_data_domain.md](part_1_data_domain.md) | Data Layer & Domain Layer: Drift SQLite table, Entity, Model, DataSource (Remote & Local), Repository, Use Cases | Berat |
| **2** | [part_2_state_sync.md](part_2_state_sync.md) | State Management (Riverpod Generator) & Logika Auto-Sinkronisasi Offline-to-Online | Sedang |
| **3** | [part_3_ui_routing.md](part_3_ui_routing.md) | UI Screen, GoRouter routing, Lokalisasi (L10n), Integrasi menu beranda, Test suite, Verifikasi akhir | Berat |

---

## 🏗️ Arsitektur yang Digunakan

```
apps/main/lib/features/quotes/
├── data/
│   ├── datasources/       ← Remote (API) & Local (SQLite/Drift)
│   ├── models/            ← DTO / JSON + Database model
│   └── repositories/      ← Implementasi repository
├── domain/
│   ├── entities/          ← Entity bisnis (pure Dart, Equatable)
│   ├── repositories/      ← Interface/kontrak repository
│   └── usecases/          ← Business logic per aksi CRUD + Sync
└── presentation/
    ├── providers/         ← Riverpod Generator providers
    ├── screens/           ← QuotesScreen, QuoteFormScreen
    ├── widgets/           ← Komponen UI pembantu
    └── quotes_notifier.dart ← AsyncNotifier state management
```

---

## 📡 API Backend

**Base URL**: `https://anaklangit.manahpro.web.id/api/v1`

| Method   | Endpoint          | Deskripsi              |
|----------|-------------------|------------------------|
| `GET`    | `/quotes`         | List semua quotes      |
| `POST`   | `/quotes`         | Buat quote baru        |
| `GET`    | `/quotes/{id}`    | Detail satu quote      |
| `PUT`    | `/quotes/{id}`    | Update quote           |
| `DELETE` | `/quotes/{id}`    | Hapus quote            |
| `GET`    | `/health`         | Health check server    |

---

## 📌 Cara Menggunakan

1. **Berikan prompt Bagian 1** ke Claude. Tunggu hingga selesai dan pastikan codegen berhasil.
2. **Berikan prompt Bagian 2** ke Claude. Tunggu hingga codegen berhasil dan state management berjalan.
3. **Berikan prompt Bagian 3** ke Claude. Ini mencakup UI, routing, L10n, test, dan verifikasi akhir.

> [!TIP]
> Setiap prompt sudah dilengkapi instruksi **MANDATORY** agar Claude membaca `docs/ADD_FEATURE.md` dan `CLAUDE.md` terlebih dahulu. Ini memastikan implementasi sesuai dengan konvensi dan best practice yang berlaku di project.

---

## 🔑 Catatan Penting

- **Offline-First**: Data disimpan ke SQLite (Drift) terlebih dahulu, kemudian disinkronisasi ke server saat koneksi tersedia.
- **Optimistic UI**: Perubahan langsung terlihat di UI tanpa menunggu respons server.
- **Riverpod Generator**: Semua provider menggunakan anotasi `@riverpod`, bukan vanilla provider.
- **L10n Wajib**: Semua teks UI harus dilokalkan di file ARB (Bahasa Indonesia & Inggris).
- **App-Specific**: Fitur ini dibuat di `apps/main/` (bukan `features_shared`) karena hanya dipakai oleh app utama.
