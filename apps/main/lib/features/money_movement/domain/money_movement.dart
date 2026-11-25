import 'dart:typed_data';

class PrimaryBankAccount {
  const PrimaryBankAccount(
      {required this.bankCode,
      required this.bankName,
      required this.accountNumber,
      required this.accountName,
      required this.maskedNumber,
      required this.version});
  final String bankCode, bankName, accountNumber, accountName, maskedNumber;
  final int version;
}

class TransferRecipient {
  const TransferRecipient(
      {required this.identityId,
      required this.name,
      required this.communityId,
      required this.communityName});
  final String identityId, name, communityId, communityName;
}

class MemberTransfer {
  const MemberTransfer(
      {required this.id,
      required this.reference,
      required this.amount,
      required this.status,
      required this.sender,
      required this.recipient,
      required this.createdAt,
      this.direction = ''});
  final String id, reference, status, sender, recipient, createdAt, direction;
  final int amount;
}

class PayoutFragment {
  const PayoutFragment(
      {required this.id,
      required this.amount,
      required this.reference,
      required this.note,
      required this.status,
      this.proofUrl,
      required this.createdAt,
      this.verifiedAt,
      this.verifiedBy = ''});
  final String id, reference, note, status, createdAt, verifiedBy;
  final String? proofUrl, verifiedAt;
  final int amount;
}

class PayoutEvent {
  const PayoutEvent(this.status, this.actor, this.at, this.note);
  final String status, actor, at, note;
}

class PayoutPart {
  const PayoutPart(
      {required this.id,
      required this.communityId,
      required this.communityName,
      required this.amount,
      required this.verified,
      required this.remaining,
      required this.status,
      required this.version,
      required this.canManage,
      this.founderPhone,
      required this.fragments,
      required this.events,
      this.released = 0,
      this.sourceAccount});
  final String id, communityId, communityName, status;
  final int amount, verified, remaining, version;
  final int released;
  final bool canManage;
  final String? founderPhone;
  final List<PayoutFragment> fragments;
  final List<PayoutEvent> events;
  final PrimaryBankAccount? sourceAccount;
  bool get finalStatus => ['succeeded', 'failed', 'cancelled'].contains(status);
}

class Payout {
  const Payout(
      {required this.id,
      required this.reference,
      required this.communityId,
      required this.memberName,
      required this.amount,
      required this.verified,
      required this.remaining,
      required this.status,
      required this.version,
      required this.destination,
      required this.createdAt,
      required this.canCancel,
      required this.parts,
      this.released = 0,
      this.memberPhone});
  final String id, reference, communityId, memberName, status, createdAt;
  final int amount, verified, remaining, version;
  final int released;
  final PrimaryBankAccount destination;
  final bool canCancel;
  final List<PayoutPart> parts;
  final String? memberPhone;
}

class MovementPage<T> {
  const MovementPage(this.items,
      {this.page = 1, this.lastPage = 1, this.canManage = false});
  final List<T> items;
  final int page, lastPage;
  final bool canManage;
}

class PayoutReconciliation {
  const PayoutReconciliation(
      {required this.requested,
      required this.verified,
      required this.held,
      required this.released,
      required this.balanced});
  final int requested, verified, held, released;
  final bool balanced;
}

class ProofFile {
  const ProofFile(this.bytes, this.mimeType);
  final Uint8List bytes;
  final String mimeType;
}

String payoutStatusLabel(String status) => switch (status) {
      'requested' => 'Diminta',
      'processing' => 'Diproses',
      'uncertain' => 'Belum pasti',
      'succeeded' => 'Berhasil',
      'failed' => 'Gagal definitif',
      'cancelled' => 'Dibatalkan',
      _ => 'Status belum dikenali'
    };

String? normalizedWhatsAppPhone(String? raw) {
  if (raw == null || !RegExp(r'^\+?[0-9 ()-]+$').hasMatch(raw.trim())) {
    return null;
  }
  var phone = raw.replaceAll(RegExp(r'[^0-9]'), '');
  if (phone.startsWith('0')) phone = '62${phone.substring(1)}';
  if (!RegExp(r'^[1-9][0-9]{7,14}$').hasMatch(phone)) return null;
  return phone;
}

Uri? payoutWhatsAppUri(Payout payout, PayoutPart part) {
  final phone = normalizedWhatsAppPhone(part.founderPhone);
  if (phone == null) return null;
  return Uri.https('wa.me', '/$phone', {
    'text':
        'Permintaan pencairan ${payout.reference} untuk ${part.communityName}. Nominal Rp${part.amount}; tujuan ${payout.destination.bankName} ${payout.destination.maskedNumber} a.n. ${payout.destination.accountName}. Mohon periksa status dalam aplikasi sebelum memproses. Pesan ini bukan bukti transfer.'
  });
}

String payoutProofShareText(
        Payout payout, PayoutPart part, PayoutFragment fragment) =>
    'Bukti pencairan ${payout.reference} untuk ${payout.memberName}. ${part.communityName}; Rp${fragment.amount}; referensi ${fragment.reference}; tujuan ${payout.destination.bankName} ${payout.destination.maskedNumber}. Status aplikasi: ${payoutStatusLabel(part.status)}. Periksa nominal dan status pada aplikasi.';

Uri? payoutMemberWhatsAppUri(Payout payout) {
  final phone = normalizedWhatsAppPhone(payout.memberPhone);
  if (phone == null) return null;
  return Uri.https('wa.me', '/$phone', {
    'text':
        'Pencairan ${payout.reference} untuk ${payout.memberName}. Nominal diminta Rp${payout.amount}, terverifikasi Rp${payout.verified}. Tujuan ${payout.destination.bankName} ${payout.destination.maskedNumber}. Status ${payoutStatusLabel(payout.status)}. Periksa bukti pada aplikasi; pesan ini tidak mengirim uang.'
  });
}
