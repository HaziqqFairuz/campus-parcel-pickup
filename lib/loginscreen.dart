import 'package:flutter/material.dart';

import 'auth_api.dart';
import 'registerscreeen.dart';
import 'screen_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.api,
    required this.onLogin,
    required this.rememberSession,
  });

  final AuthApi api;
  final Future<void> Function(
    String email,
    String password,
    bool rememberSession,
  )
  onLogin;
  final bool rememberSession;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _registered = false;
  late bool _rememberSession = widget.rememberSession;

  Future<void> _openRegistration() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => RegistrationScreen(api: widget.api)),
    );
    if (created == true && mounted) setState(() => _registered = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ParcelPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AuthHeading(
              title: 'Welcome back',
              description: 'Sign in to your campus parcel account.',
            ),
            const SizedBox(height: 26),
            if (_registered) ...[
              const FormFeedback(
                message: 'Account created. You can now sign in.',
                success: true,
              ),
              const SizedBox(height: 14),
            ],
            AuthForm(
              submit: (_, email, password, _) =>
                  widget.onLogin(email, password, _rememberSession),
              rememberSession: _rememberSession,
              onRememberSessionChanged: (value) =>
                  setState(() => _rememberSession = value),
              onRegister: _openRegistration,
            ),
          ],
        ),
      ),
    );
  }
}
