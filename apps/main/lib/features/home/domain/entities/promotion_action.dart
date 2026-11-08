/// Jenis aksi tombol Paid Promotion, dibaca dari `link_url`.
enum PromotionActionKind {
  none,

  /// Halaman app, diawali `/`.
  appPage,

  /// Chat WhatsApp `https://wa.me/<nomor>?text=<pesan>`.
  whatsapp,

  /// Tautan http/https lain, dibuka di browser.
  web;

  static PromotionActionKind of(String? link) {
    if (link == null || link.isEmpty) return none;
    if (link.startsWith('/')) return appPage;
    final uri = Uri.tryParse(link);
    if (uri == null) return none;
    if (uri.host.toLowerCase() == PromotionAction.whatsappHost) return whatsapp;
    return uri.scheme == 'http' || uri.scheme == 'https' ? web : none;
  }

  /// Label tombol bila admin tidak mengisinya (data lama).
  String get defaultLabel => switch (this) {
        none => '',
        appPage => 'Lihat Selengkapnya',
        whatsapp => 'Chat via WhatsApp',
        web => 'Kunjungi Situs',
      };
}

/// Tautan chat WhatsApp; sama dengan `Banner::WHATSAPP_LINK_PATTERN` di server.
abstract final class PromotionAction {
  static const whatsappHost = 'wa.me';

  /// Nomor berkode negara tanpa `+`: 8–15 digit, tidak diawali 0.
  static final _whatsappNumber = RegExp(r'^[1-9][0-9]{7,14}$');

  /// "0812-3456 7890", "+62 812…", "62812…" → "6281234567890"; tidak sah → null.
  /// Nomor yang diawali 0 dianggap nomor Indonesia.
  static String? normalizeWhatsappNumber(String input) {
    var digits = input.replaceAll(RegExp(r'[\s\-().]'), '');
    if (digits.startsWith('+')) {
      digits = digits.substring(1);
    } else if (digits.startsWith('0')) {
      digits = '62${digits.substring(1)}';
    }
    return _whatsappNumber.hasMatch(digits) ? digits : null;
  }

  static String whatsappLink(String number, [String message = '']) {
    final text = message.trim();
    return 'https://$whatsappHost/$number'
        '${text.isEmpty ? '' : '?text=${Uri.encodeComponent(text)}'}';
  }

  /// Nomor dari tautan wa.me; null bila bukan tautan WhatsApp.
  static String? whatsappNumber(String? link) {
    if (PromotionActionKind.of(link) != PromotionActionKind.whatsapp) {
      return null;
    }
    final segments = Uri.parse(link!).pathSegments;
    return segments.isEmpty ? null : segments.first;
  }

  /// Pesan awal dari tautan wa.me; kosong bila tidak ada.
  static String whatsappMessage(String? link) {
    if (PromotionActionKind.of(link) != PromotionActionKind.whatsapp) return '';
    return Uri.parse(link!).queryParameters['text'] ?? '';
  }

  /// "+62 812-3456-7890" untuk ditampilkan; nomor luar negeri apa adanya.
  static String formatWhatsappNumber(String number) {
    if (!number.startsWith('62') || number.length < 10) return '+$number';
    final local = number.substring(2);
    return '+62 ${local.substring(0, 3)}-${local.substring(3, 7)}'
        '${local.length > 7 ? '-${local.substring(7)}' : ''}';
  }
}
