import 'dart:async';
import 'dart:typed_data';
import 'package:app_main/features/money_movement/domain/money_movement.dart';
import 'package:app_main/features/money_movement/domain/money_movement_repository.dart';
import 'package:app_main/features/money_movement/presentation/movement_sharing.dart';
import 'package:flutter/material.dart';
import '../community/fake_community_repository.dart';

// Deliberately synthetic; tests build digits rather than retaining personal bank data.
PrimaryBankAccount bankFixture() => PrimaryBankAccount(
    bankCode: 'FIX',
    bankName: 'Bank Fixture',
    accountNumber: List.filled(8, '0').join(),
    accountName: 'Penerima Pihak Ketiga Fixture',
    maskedNumber: '•••• 0000',
    version: 2);
const recipientFixture = TransferRecipient(
    identityId: '2',
    name: 'Anggota Tujuan Fixture',
    communityId: '2',
    communityName: 'Komunitas Tujuan Fixture');
const transferFixture = MemberTransfer(
    id: 'transfer-fixture',
    reference: 'TRF-FIXTURE',
    amount: 75000,
    status: 'succeeded',
    sender: 'Pengirim Fixture',
    recipient: 'Anggota Tujuan Fixture',
    createdAt: '2026-11-26T00:15:00Z',
    direction: 'out');
Payout payoutFixture(
    {bool manage = false,
    String status = 'uncertain',
    bool pending = true,
    bool platform = false,
    bool longMoney = false,
    bool validPhone = true}) {
  final amount = longMoney ? 999999999 : 100000;
  final verified = status == 'succeeded'
      ? amount
      : status == 'failed'
          ? 0
          : pending
              ? 0
              : 40000;
  final remaining = ['failed', 'cancelled', 'succeeded'].contains(status)
      ? 0
      : amount - verified;
  final part = PayoutPart(
      id: 'part-fixture',
      communityId: platform ? '' : '1',
      communityName:
          platform ? 'Sumber platform' : 'Komunitas Kolektor Fixture',
      amount: amount,
      verified: verified,
      remaining: remaining,
      released: ['failed', 'cancelled'].contains(status) ? amount : 0,
      status: status,
      version: 3,
      canManage: manage,
      founderPhone: validPhone ? '080000000001' : null,
      fragments: status == 'requested'
          ? []
          : [
              PayoutFragment(
                  id: 'fragment-fixture',
                  amount: status == 'succeeded' ? amount : 40000,
                  reference: 'BANK-FIXTURE',
                  note: 'Bukti sintetis untuk pengujian.',
                  status: status == 'failed'
                      ? 'rejected'
                      : pending
                          ? 'pending'
                          : 'verified',
                  proofUrl:
                      'https://anaklangit.manahpro.web.id/api/v1/private-fixture',
                  createdAt: '2026-11-26T00:16:00Z',
                  verifiedAt: pending ? null : '2026-11-26T00:18:00Z',
                  verifiedBy: pending ? '' : 'Admin Fixture')
            ],
      events: [
        const PayoutEvent('requested', 'Anggota Fixture',
            '2026-11-26T00:15:00Z', 'Saldo ditahan.'),
        if (status != 'requested')
          PayoutEvent(status, 'Admin Fixture', '2026-11-26T00:18:00Z',
              'Pemeriksaan berbukti, bukan transfer bank otomatis.')
      ]);
  return Payout(
      id: 'payout-fixture',
      reference: 'PAYOUT-FIXTURE',
      communityId: '1',
      memberName: 'Anggota Pemilik Fixture',
      amount: amount,
      verified: verified,
      remaining: remaining,
      released: ['failed', 'cancelled'].contains(status) ? amount : 0,
      status: status,
      version: 3,
      destination: bankFixture(),
      createdAt: '2026-11-26T00:15:00Z',
      canCancel: status == 'requested',
      parts: [part],
      memberPhone: validPhone ? '080000000002' : null);
}

class FakeMovement implements MoneyMovementRepository {
  PrimaryBankAccount? bank = bankFixture();
  Payout value = payoutFixture();
  bool empty = false;
  Object? loadError, sendError;
  Completer<void>? loadGate, sendGate;
  final List<Map<String, Object?>> sent = [];
  final List<String> actions = [];
  String? lastCommunity;
  bool? lastManage;
  Future<void> _load() async {
    if (loadGate != null) await loadGate!.future;
    if (loadError != null) throw loadError!;
  }

  Future<void> _send(Map<String, Object?> f) async {
    sent.add(Map.of(f));
    if (sendGate != null) await sendGate!.future;
    if (sendError != null) throw sendError!;
  }

  @override
  Future<PrimaryBankAccount?> primaryAccount() async {
    await _load();
    return bank;
  }

  @override
  Future<PrimaryBankAccount> savePrimaryAccount(
      Map<String, Object?> fields) async {
    await _send(fields);
    return bank = PrimaryBankAccount(
        bankCode: '${fields['bank_code']}',
        bankName: '${fields['bank_name']}',
        accountNumber: '${fields['account_number']}',
        accountName: '${fields['account_name']}',
        maskedNumber: '•••• 0000',
        version: 3);
  }

  @override
  Future<MovementPage<TransferRecipient>> recipients(
      String query, String communityId,
      {int page = 1}) async {
    await _load();
    return MovementPage(empty ? [] : [recipientFixture]);
  }

  @override
  Future<MemberTransfer> transfer(Map<String, Object?> fields) async {
    await _send(fields);
    return transferFixture;
  }

  @override
  Future<MovementPage<MemberTransfer>> transfers({int page = 1}) async {
    await _load();
    return MovementPage(empty ? [] : [transferFixture], page: page);
  }

  @override
  Future<MovementPage<Payout>> payouts(
      {String? communityId,
      bool manage = false,
      String status = '',
      String query = '',
      int page = 1}) async {
    lastCommunity = communityId;
    lastManage = manage;
    await _load();
    return MovementPage(empty ? [] : [value], page: page, canManage: manage);
  }

  @override
  Future<Payout> payout(String id) async {
    await _load();
    return value;
  }

  @override
  Future<Payout> requestPayout(Map<String, Object?> fields) async {
    await _send(fields);
    return value;
  }

  @override
  Future<Payout> partAction(
      String partId, String action, Map<String, Object?> fields,
      {String? fragmentId}) async {
    actions.add(action);
    await _send(fields);
    return value;
  }

  @override
  Future<Payout> editPendingFragment(
      String partId, String fragmentId, Map<String, Object?> fields) async {
    actions.add('edit');
    await _send(fields);
    return value;
  }

  @override
  Future<PayoutReconciliation> reconciliation(String communityId) async {
    await _load();
    return PayoutReconciliation(
        requested: value.amount,
        verified: value.verified,
        held: value.remaining,
        released: value.status == 'failed' ? value.amount : 0,
        balanced: true);
  }

  @override
  Future<ProofFile> proof(String url) async =>
      ProofFile(Uint8List.fromList(testImageBytes), 'image/png');
}

class FakeMovementSharing implements MovementSharing {
  final List<Uri> composers = [];
  final List<String> texts = [];
  final List<ProofFile> files = [];
  @override
  Future<bool> openComposer(Uri uri) async {
    composers.add(uri);
    return true;
  }

  @override
  Future<void> shareProof(ProofFile file, String text, Rect origin) async {
    files.add(file);
    texts.add(text);
  }
}

Payout mixedPayoutFixture({bool manage = true}) => Payout(
        id: 'payout-fixture',
        reference: 'PAYOUT-MIXED',
        communityId: '1',
        memberName: 'Anggota Pemilik Fixture',
        amount: 100000,
        verified: 60000,
        remaining: 0,
        released: 40000,
        status: 'uncertain',
        version: 5,
        destination: bankFixture(),
        createdAt: '2026-11-26T00:15:00Z',
        canCancel: false,
        parts: [
          PayoutPart(
              id: 'paid-part',
              communityId: '1',
              communityName: 'Kolektor bagian terverifikasi',
              amount: 60000,
              verified: 60000,
              remaining: 0,
              status: 'succeeded',
              version: 4,
              canManage: manage,
              fragments: const [],
              events: const [],
              sourceAccount: bankFixture()),
          PayoutPart(
              id: 'released-part',
              communityId: '2',
              communityName: 'Kolektor bagian belum terkirim',
              amount: 40000,
              verified: 0,
              remaining: 0,
              released: 40000,
              status: 'failed',
              version: 4,
              canManage: manage,
              fragments: const [],
              events: const [],
              sourceAccount: bankFixture())
        ]);
