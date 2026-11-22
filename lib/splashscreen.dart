import 'package:flutter/material.dart';

import 'screen_widgets.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key, required this.error, required this.onRetry});

  final String? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ParcelPage(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ParcelMark(),
              const SizedBox(height: 14),
              const Text(
                appName,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 20),
              if (error case final message?) ...[
                FormFeedback(message: message),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: onRetry,
                  child: const Text('Try again'),
                ),
              ] else
                const CircularProgressIndicator(
                  semanticsLabel: 'Checking your session',
                ),
            ],
          ),
        ),
      ),
    );
  }
}
