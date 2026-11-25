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
  String? _message;
  bool get _recovery => widget.mode == PinMode.recovery;
  bool get _manage => widget.mode == PinMode.manage;
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
        final enabled = auth is AuthAuthenticated && auth.user.pinEnabled;
        await repo.save(_pin.text,
            currentPin: enabled ? _current.text : null,
            currentPassword: enabled ? null : _current.text);
        await ref.read(authProvider.notifier).checkCurrentUser();
        _pin.clear();
        _confirm.clear();
        _current.clear();
        if (mounted) setState(() => _message = 'PIN berhasil disimpan.');
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
                              if (!_manage) ...[
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
                              if (_manage) ...[
                                TextFormField(
                                    controller: _current,
                                    obscureText: true,
                                    decoration: InputDecoration(
                                        labelText: enabled
                                            ? 'PIN saat ini'
                                            : 'Password akun saat ini'),
                                    validator: (v) => (v?.isEmpty ?? true)
                                        ? 'Isi verifikasi akun.'
                                        : null),
                                const SizedBox(height: 16),
                                if (!enabled)
                                  const Padding(
                                      padding: EdgeInsets.only(bottom: 16),
                                      child: Text(
                                          'Akun Google tanpa password: gunakan Pulihkan PIN untuk verifikasi melalui email.'))
                              ],
                              if (_recovery && _sent) ...[
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
                              if (!_recovery || _sent) ...[
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
                                    child: const Text(
                                        'Pulihkan PIN melalui email')),
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
