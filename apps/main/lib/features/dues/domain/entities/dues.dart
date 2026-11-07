import '../../../community/domain/entities/community.dart';

/// Status iuran satu bulan untuk satu anggota.
enum DuesMonthStatus {
  paid('paid', 'Lunas'),
  pending('pending', 'Menunggu verifikasi'),
  overdue('overdue', 'Menunggak'),
  due('due', 'Belum dibayar'),
  upcoming('upcoming', 'Belum jatuh tempo'),
  none('none', 'Di luar masa iuran');

  const DuesMonthStatus(this.apiValue, this.label);
  final String apiValue;
  final String label;

  /// Hanya dua status yang bisa diubah pengelola; sisanya dihitung server.
  bool get isPaid => this == paid;

  static DuesMonthStatus fromApi(Object? value) =>
      values.where((e) => e.apiValue == value).firstOrNull ?? none;
}

enum DuesPaymentStatus {
  pending('pending', 'Menunggu verifikasi'),
  approved('approved', 'Diterima'),
  rejected('rejected', 'Ditolak');

  const DuesPaymentStatus(this.apiValue, this.label);
  final String apiValue;
  final String label;

  static DuesPaymentStatus fromApi(Object? value) =>
      values.where((e) => e.apiValue == value).firstOrNull ?? pending;
}

/// Setelan iuran komunitas. Nominal dalam rupiah utuh.
class DuesSettings {
  const DuesSettings({
    required this.configured,
    this.monthlyAmount,
    this.entryFee = 0,
    this.startDate,
    this.dueDay,
    this.bankName,
    this.accountNumber,
    this.accountName,
  });

  final bool configured;
  final int? monthlyAmount;
  final int entryFee;

  /// Tanggal mulai iuran: bulan tagihan pertama, dan tanggalnya = jatuh tempo.
  final DateTime? startDate;
  final int? dueDay;
  final String? bankName;
  final String? accountNumber;
  final String? accountName;
}

/// Iuran satu bulan; [month] = hari pertama bulan itu.
class DuesMonth {
  const DuesMonth({required this.month, required this.status});

  final DateTime month;
  final DuesMonthStatus status;
}

/// Kalender iuran satu anggota untuk satu tahun beserta ringkasannya.
class DuesCalendar {
  const DuesCalendar({
    required this.months,
    this.billableFrom,
    this.arrearsCount = 0,
    this.paidUntil,
    this.entryFeePaid = false,
  });

  final List<DuesMonth> months;

  /// Bulan pertama yang ditagihkan; null bila iuran belum diatur.
  final DateTime? billableFrom;
  final int arrearsCount;

  /// Bulan terakhir yang lunas berturut-turut sejak awal tagihan.
  final DateTime? paidUntil;
  final bool entryFeePaid;
}

class DuesPayment {
  const DuesPayment({
    required this.id,
    required this.userId,
    required this.userName,
    required this.months,
    required this.monthlyAmount,
    required this.entryFee,
    required this.totalAmount,
    required this.status,
    this.userAvatarUrl,
    this.proofUrl,
    this.note,
    this.reviewNote,
    this.reviewedBy,
    this.reviewedAt,
    this.createdAt,
  });

  final String id;
  final String userId;
  final String userName;
  final String? userAvatarUrl;

  /// Hari pertama tiap bulan yang dibayar.
  final List<DateTime> months;
  final int monthlyAmount;
  final int entryFee;
  final int totalAmount;
  final DuesPaymentStatus status;
  final String? proofUrl;
  final String? note;

  /// Alasan penolakan.
  final String? reviewNote;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final DateTime? createdAt;
}

/// Iuran pengguna yang login di satu komunitas.
class MyDues {
  const MyDues({
    required this.calendar,
    this.entryFeeDue = 0,
    this.nextUnpaidMonths = const [],
  });

  final DuesCalendar calendar;

  /// Uang masuk yang ikut dibayar di pembayaran berikutnya; 0 bila lunas/diajukan.
  final int entryFeeDue;

  /// Bulan yang akan dibayar berikutnya, tunggakan paling awal dulu.
  final List<DateTime> nextUnpaidMonths;
}

class DuesOverview {
  const DuesOverview({
    required this.settings,
    required this.year,
    this.canManage = false,
    this.me,
    this.payments = const [],
    this.pendingPaymentsCount,
  });

  final DuesSettings settings;
  final int year;
  final bool canManage;

  /// Null bila pengguna bukan anggota aktif (mis. super admin).
  final MyDues? me;

  /// Riwayat pembayaran sendiri, terbaru dulu.
  final List<DuesPayment> payments;

  /// Hanya untuk pengelola.
  final int? pendingPaymentsCount;
}

/// Anggota beserta kalender iurannya, untuk pengelola.
class MemberDues {
  const MemberDues({
    required this.userId,
    required this.name,
    required this.role,
    required this.calendar,
    this.avatarUrl,
    this.joinedAt,
    this.entryFeeDue,
  });

  final String userId;
  final String name;
  final String? avatarUrl;
  final CommunityRole role;
  final DateTime? joinedAt;
  final DuesCalendar calendar;
  final int? entryFeeDue;
}

class MemberDuesDetail {
  const MemberDuesDetail({
    required this.settings,
    required this.year,
    required this.member,
    this.payments = const [],
  });

  final DuesSettings settings;
  final int year;
  final MemberDues member;
  final List<DuesPayment> payments;
}

class Paged<T> {
  const Paged({
    required this.items,
    required this.currentPage,
    required this.lastPage,
  });

  final List<T> items;
  final int currentPage;
  final int lastPage;

  bool get hasMore => currentPage < lastPage;
}

class DuesSettingsInput {
  const DuesSettingsInput({
    required this.monthlyAmount,
    required this.entryFee,
    required this.startDate,
    required this.bankName,
    required this.accountNumber,
    required this.accountName,
  });

  final int monthlyAmount;
  final int entryFee;
  final DateTime startDate;
  final String bankName;
  final String accountNumber;
  final String accountName;
}

/// Isian yang ditolak server, untuk ditampilkan di bawah kolomnya.
class DuesFieldException implements Exception {
  const DuesFieldException(this.field, this.message);

  final String field;
  final String message;

  @override
  String toString() => message;
}
