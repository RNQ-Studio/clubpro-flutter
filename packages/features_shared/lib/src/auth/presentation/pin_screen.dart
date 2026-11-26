import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'auth_provider.dart';
import 'auth_guard.dart';
import 'auth_state.dart';
import 'pin_provider.dart';

enum PinMode { login, manage, recovery }

class PinScreen extends ConsumerStatefulWidget {
  const PinScreen({super.key, this.mode = PinMode.login, this.onLoggedIn});
  final PinMode mode;
  final VoidCallback? onLoggedIn;
  @override
  ConsumerState<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends ConsumerState<PinScreen> {
  final _form = GlobalKey<FormState>();
  final _identifier = TextEditingController();
  final _pin = TextEditingController();
  final _confirm = TextEditingController();
  final _current = TextEditingController();
  final _code = TextEditingController();
  bool _busy = false, _sent = false;
  String? _message, _verification;
  bool get _recovery => widget.mode == PinMode.recovery;
  bool get _manage => widget.mode == PinMode.manage;
  List<String> _methods(AuthState auth) => [
        if (auth is AuthAuthenticated && auth.user.pinGoogleReauthenticated)
          'google',
        if (auth is AuthAuthenticated && auth.user.pinEnabled) 'pin',
        'password'
      ];
  String _method(AuthState auth) => _methods(auth).contains(_verification)
      ? _verification!
      : _methods(auth).first;
  void _reauthenticate() {
    final from = decodeLoginReturn(
        GoRouterState.of(context).uri.queryParameters['from']);
    final target =
        '/account/pin${from == null ? '' : '?from=${encodeLoginReturn(from)}'}';
    context.go('/login?from=${encodeLoginReturn(target)}&reauth=1');
  }

  @override
  void dispose() {
    for (final c in [_identifier, _pin, _confirm, _current, _code]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !(_form.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final repo = ref.read(pinRepositoryProvider);
      final auth = ref.read(authProvider);
      if (_recovery && !_sent) {
        await repo.recover(_identifier.text.trim());
        if (mounted) {
          setState(() {
            _sent = true;
            _message =
                'Jika akun memenuhi syarat, kode telah dikirim ke email terverifikasi. Kode berlaku 10 menit.';
          });
        }
      } else if (_recovery) {
        await repo.reset(_identifier.text.trim(), _code.text.trim(), _pin.text);
        await ref.read(authProvider.notifier).sessionExpired();
        if (mounted) {
          context.go(authMethodLocation(context, '/login/pin'));
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('PIN diperbarui. Silakan masuk kembali.')));
        }
      } else if (_manage) {
        final method = _method(auth);
        await repo.save(_pin.text,
            verificationMethod: method,
            currentPin: method == 'pin' ? _current.text : null,
            currentPassword: method == 'password' ? _current.text : null);
        // Move to the validated destination before session refresh publishes
        // AuthLoading; the app's auth-check route must capture checkout itself.
        final destination = mounted
            ? decodeLoginReturn(
                GoRouterState.of(context).uri.queryParameters['from'])
            : null;
        if (mounted && destination != null) context.go(destination);
        await ref.read(authProvider.notifier).checkCurrentUser();
        if (!mounted) return;
        _pin.clear();
        _confirm.clear();
        _current.clear();
        if (mounted && destination == null) {
          setState(() => _message = 'PIN berhasil disimpan.');
        }
      } else {
        final user = await repo.login(_identifier.text.trim(), _pin.text);
        ref.read(authProvider.notifier).acceptAuthenticatedUser(user);
        if (mounted) {
          if (widget.onLoggedIn != null) {
            widget.onLoggedIn!();
          } else {
            context.go('/');
          }
        }
      }
    } catch (e) {
      if (mounted) setState(() => _message = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _pinField(TextEditingController controller, String label,
          {bool confirm = false}) =>
      TextFormField(
        controller: controller,
        obscureText: true,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(6)
        ],
        decoration: InputDecoration(labelText: label),
        validator: (v) => v == null || !RegExp(r'^\d{6}$').hasMatch(v)
            ? 'Gunakan tepat 6 angka.'
            : confirm && v != _pin.text
                ? 'Konfirmasi PIN tidak sama.'
                : null,
      );
  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final enabled = auth is AuthAuthenticated && auth.user.pinEnabled;
    final verification = _method(auth);
    final recoveryOptions =
        _recovery ? ref.watch(pinEmailRecoveryAvailableProvider) : null;
    final emailRecoveryAvailable = recoveryOptions?.asData?.value ?? false;
    final title = _recovery
        ? 'Pulihkan PIN'
        : _manage
            ? enabled
                ? 'Ubah PIN'
                : 'Buat PIN'
            : 'Masuk dengan PIN';
    return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: SafeArea(
            child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                          key: _form,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall),
                              const SizedBox(height: 12),
                              const Text(
                                  'PIN 6 angka digunakan bersama email atau nomor telepon terverifikasi. Semua peran memakai alur yang sama.'),
                              const SizedBox(height: 20),
                              if (!_manage &&
                                  (!_recovery || emailRecoveryAvailable)) ...[
                                TextFormField(
                                    controller: _identifier,
                                    keyboardType: TextInputType.emailAddress,
                                    decoration: const InputDecoration(
                                        labelText:
                                            'Email atau telepon terverifikasi'),
                                    validator: (v) =>
                                        (v?.trim().isEmpty ?? true)
                                            ? 'Isi pengenal akun.'
                                            : null),
                                const SizedBox(height: 16)
                              ],
                              if (_recovery) ...[
                                const Text(
                                    'Pulihkan dengan masuk kembali ke akun Google atau password Anda, lalu buat PIN baru. Pemulihan email juga tersedia bila pengiriman email aktif.'),
                                const SizedBox(height: 12),
                                OutlinedButton.icon(
                                    onPressed: _busy ? null : _reauthenticate,
                                    icon: const Icon(
                                        Icons.account_circle_outlined),
                                    label: const Text('Pulihkan melalui akun')),
                                if (recoveryOptions?.isLoading ?? false)
                                  const LinearProgressIndicator(),
                                if (recoveryOptions?.hasError ?? false) ...[
                                  const Text(
                                      'Pilihan pemulihan email belum dapat dimuat. Pemulihan melalui akun tetap tersedia.'),
                                  TextButton(
                                      onPressed: () => ref.invalidate(
                                          pinEmailRecoveryAvailableProvider),
                                      child:
                                          const Text('Coba Muat Pilihan Lagi'))
                                ],
                                if (recoveryOptions?.asData?.value == false)
                                  const Text(
                                      'Pemulihan email belum tersedia. Gunakan akun Google atau password yang terhubung.'),
                                const Divider(height: 28),
                              ],
                              if (_manage) ...[
                                DropdownButtonFormField<String>(
                                    key: ValueKey(
                                        'pin-verification-$verification'),
                                    initialValue: verification,
                                    decoration: const InputDecoration(
                                        labelText: 'Verifikasi akun'),
                                    items: [
                                      for (final method in _methods(auth))
                                        DropdownMenuItem(
                                            value: method,
                                            child: Text(switch (method) {
                                              'google' =>
                                                'Google baru diverifikasi',
                                              'pin' => 'PIN saat ini',
                                              _ => 'Password akun'
                                            }))
                                    ],
                                    onChanged: _busy
                                        ? null
                                        : (v) => setState(() {
                                              _verification = v;
                                              _current.clear();
                                            })),
                                const SizedBox(height: 16),
                                if (verification != 'google')
                                  TextFormField(
                                      controller: _current,
                                      obscureText: true,
                                      decoration: InputDecoration(
                                          labelText: verification == 'pin'
                                              ? 'PIN saat ini'
                                              : 'Password akun saat ini'),
                                      validator: (v) => (v?.isEmpty ?? true)
                                          ? 'Isi verifikasi akun.'
                                          : null)
                                else
                                  const Text(
                                      'Verifikasi Google baru terdeteksi. Simpan PIN sekarang; jika verifikasi kedaluwarsa, masuk ulang.'),
                                const SizedBox(height: 12),
                                TextButton(
                                    onPressed: _busy ? null : _reauthenticate,
                                    child: const Text(
                                        'Verifikasi ulang melalui Google / password')),
                                const SizedBox(height: 16),
                              ],
                              if (_recovery &&
                                  _sent &&
                                  emailRecoveryAvailable) ...[
                                TextFormField(
                                    controller: _code,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                        labelText: 'Kode dari email'),
                                    validator: (v) => (v?.isEmpty ?? true)
                                        ? 'Isi kode verifikasi.'
                                        : null),
                                const SizedBox(height: 16)
                              ],
                              if (!_recovery ||
                                  (_sent && emailRecoveryAvailable)) ...[
                                _pinField(_pin,
                                    _manage || _recovery ? 'PIN baru' : 'PIN'),
                                const SizedBox(height: 16),
                                if (_manage || _recovery) ...[
                                  _pinField(_confirm, 'Ulangi PIN baru',
                                      confirm: true),
                                  const SizedBox(height: 16)
                                ]
                              ],
                              if (_message != null)
                                Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: Text(_message!,
                                        key: const Key('pin-message'),
                                        style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary))),
                              if (!_recovery || emailRecoveryAvailable)
                                FilledButton(
                                    onPressed: _busy ? null : _submit,
                                    child: _busy
                                        ? const SizedBox.square(
                                            dimension: 20,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2))
                                        : Text(_recovery && !_sent
                                            ? 'Kirim kode'
                                            : _manage
                                                ? 'Simpan PIN'
                                                : _recovery
                                                    ? 'Perbarui PIN'
                                                    : 'Masuk')),
                              if (!_recovery)
                                TextButton(
                                    onPressed: _busy
                                        ? null
                                        : () => context.push(authMethodLocation(
                                            context, '/login/recovery')),
                                    child: const Text('Pilihan pemulihan PIN')),
                              if (!_manage)
                                TextButton(
                                    onPressed: _busy
                                        ? null
                                        : () => context.go(authMethodLocation(
                                            context, '/login')),
                                    child: const Text(
                                        'Masuk atau daftar dengan Google')),
                            ],
                          ))),
                ))));
  }
}
