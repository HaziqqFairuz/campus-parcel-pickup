import 'dart:convert';

import 'package:flutter/material.dart';

import 'auth_api.dart';

const appName = 'Campus Parcel Pickup';
const _ink = Color(0xff242129);
const _orange = Color(0xffaa430a);
const _peach = Color(0xffffe4cf);
const _paper = Color(0xfffff8f1);
const _muted = Color(0xff625a53);
const _border = Color(0xffe4d6c9);

ThemeData parcelTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: _orange)
      .copyWith(primary: _orange, surface: _paper, onSurface: _ink);
  return ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: _paper,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _border),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
  );
}

class ParcelMark extends StatelessWidget {
  const ParcelMark({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: _peach,
        borderRadius: BorderRadius.circular(15),
      ),
      child: const Icon(Icons.inventory_2_outlined, color: _orange, size: 26),
    );
  }
}

class ParcelPage extends StatelessWidget {
  const ParcelPage({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: child,
          ),
        ),
      ),
    );
  }
}

class AuthHeading extends StatelessWidget {
  const AuthHeading({
    super.key,
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ParcelMark(),
        const SizedBox(height: 14),
        const Text(
          appName,
          style: TextStyle(color: _orange, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: const TextStyle(
            fontSize: 36,
            height: 1.1,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(description, style: const TextStyle(fontSize: 15, color: _muted)),
      ],
    );
  }
}

class FormFeedback extends StatelessWidget {
  const FormFeedback({super.key, required this.message, this.success = false});

  final String message;
  final bool success;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: success ? _peach : scheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          message,
          style: TextStyle(color: success ? _orange : scheme.onErrorContainer),
        ),
      ),
    );
  }
}

class AuthForm extends StatefulWidget {
  const AuthForm({
    super.key,
    required this.submit,
    this.register = false,
    this.rememberSession = false,
    this.onRememberSessionChanged,
    this.onRegister,
  });

  final Future<void> Function(
    String name,
    String email,
    String password,
    String confirm,
  )
  submit;
  final bool register;
  final bool rememberSession;
  final ValueChanged<bool>? onRememberSessionChanged;
  final VoidCallback? onRegister;

  @override
  State<AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<AuthForm> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  bool _hidePassword = true;
  bool _hideConfirm = true;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    setState(() => _error = null);
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      await widget.submit(
        _name.text.trim(),
        _email.text.trim(),
        _password.text,
        _confirm.text,
      );
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _passwordField({required bool confirm}) {
    final hidden = confirm ? _hideConfirm : _hidePassword;
    final label = confirm ? 'Confirm password' : 'Password';
    final last = confirm || !widget.register;
    return TextFormField(
      controller: confirm ? _confirm : _password,
      enabled: !_busy,
      obscureText: hidden,
      enableSuggestions: false,
      autocorrect: false,
      autofillHints: [
        widget.register ? AutofillHints.newPassword : AutofillHints.password,
      ],
      textInputAction: last ? TextInputAction.done : TextInputAction.next,
      onFieldSubmitted: last ? (_) => _submit() : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          tooltip: hidden
              ? 'Show ${label.toLowerCase()}'
              : 'Hide ${label.toLowerCase()}',
          onPressed: () => setState(() {
            if (confirm) {
              _hideConfirm = !hidden;
            } else {
              _hidePassword = !hidden;
            }
          }),
          icon: Icon(
            hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          ),
        ),
      ),
      validator: (value) {
        final password = value ?? '';
        if (password.isEmpty) return 'Enter your ${label.toLowerCase()}.';
        if (confirm) {
          return password == _password.text ? null : 'Passwords must match.';
        }
        final size = utf8.encode(password).length;
        if (widget.register && (size < 8 || size > 72)) {
          return 'Use 8 to 72 bytes (e.g. 8–72 English characters).';
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_busy,
      child: AutofillGroup(
        onDisposeAction: AutofillContextAction.cancel,
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.register) ...[
                TextFormField(
                  controller: _name,
                  enabled: !_busy,
                  autofillHints: const [AutofillHints.name],
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Full name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    final name = (value ?? '').trim();
                    if (name.isEmpty) return 'Enter your full name.';
                    if (utf8.encode(name).length > 100) {
                      return 'Use a shorter name.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
              ],
              TextFormField(
                controller: _email,
                enabled: !_busy,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Email address',
                  prefixIcon: Icon(Icons.mail_outline),
                ),
                validator: (value) {
                  final email = (value ?? '').trim();
                  if (email.isEmpty) return 'Enter your email address.';
                  if (email.length > 254 ||
                      !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
                    return 'Enter a valid email address.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              _passwordField(confirm: false),
              if (widget.register) ...[
                const SizedBox(height: 14),
                _passwordField(confirm: true),
              ],
              if (widget.onRememberSessionChanged case final onChanged?)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text('Keep me signed in'),
                  value: widget.rememberSession,
                  onChanged: _busy
                      ? null
                      : (value) => onChanged(value ?? false),
                ),
              if (_error case final error?) ...[
                const SizedBox(height: 14),
                FormFeedback(message: error),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _busy ? null : _submit,
                child: Text(
                  _busy
                      ? (widget.register ? 'Creating account…' : 'Signing in…')
                      : (widget.register ? 'Create account' : 'Sign in'),
                ),
              ),
              if (widget.onRegister != null) ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _busy ? null : widget.onRegister,
                  child: const Text('New here? Create a recipient account'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
