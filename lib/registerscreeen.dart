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
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    scrollable: true,
                    title: const Text('Confirm account creation'),
                    content: Text('Create a recipient account for $email?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(dialogContext, true),
                        child: const Text('Confirm'),
                      ),
                    ],
                  ),
                );
                if (confirmed != true || !context.mounted) return;

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
