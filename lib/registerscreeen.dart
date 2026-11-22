  import 'package:flutter/material.dart';

import 'auth_api.dart';
import 'screen_widgets.dart';

class RegistrationScreen extends StatelessWidget {
  const RegistrationScreen({super.key, required this.api});

  final AuthApi api;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: ParcelPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AuthHeading(
              title: 'Create an account',
              description: 'Register as a parcel recipient.',
            ),
            const SizedBox(height: 24),
            AuthForm(
              register: true,
              submit: (name, email, password, confirm) async {
                await api.register(
                  name: name,
                  email: email,
                  password: password,
                  confirmPassword: confirm,
                );
                if (context.mounted) Navigator.pop(context, true);
              },
            ),
          ],
        ),
      ),
    );
  }
}
