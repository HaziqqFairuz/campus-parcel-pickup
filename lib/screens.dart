import 'package:flutter/material.dart';

import 'auth_api.dart';
import 'screen_widgets.dart';

const _tileBlue = Color(0xff2259a4);
const _tileBackground = Color(0xffe9f2ff);
const _tileBorder = Color(0xffc6d9f5);
const _tileText = Color(0xff193452);

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.account,
    required this.onLogout,
  });

  final Account account;
  final Future<void> Function() onLogout;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _busy = false;
  String? _error;

  Future<void> _signOut() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onLogout();
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final account = widget.account;
    return Scaffold(
      body: ParcelPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                ParcelMark(),
                SizedBox(width: 12),
                Flexible(
                  child: Text(
                    appName,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _tileBlue,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.waving_hand_outlined,
                    color: _tileBackground,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Welcome, ${account.name}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 29,
                      height: 1.14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'Account details',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: _tileBackground,
                border: Border.all(color: _tileBorder),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  _AccountRow(
                    icon: Icons.person_outline,
                    label: 'Name',
                    value: account.name,
                  ),
                  const Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color: _tileBorder,
                  ),
                  _AccountRow(
                    icon: Icons.mail_outline,
                    label: 'Email',
                    value: account.email,
                  ),
                  const Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color: _tileBorder,
                  ),
                  _AccountRow(
                    icon: Icons.badge_outlined,
                    label: 'Role',
                    value: account.role.label,
                  ),
                ],
              ),
            ),
            if (_error case final error?) ...[
              const SizedBox(height: 14),
              FormFeedback(message: error),
            ],
            const SizedBox(height: 20),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 50)),
              onPressed: _busy ? null : _signOut,
              icon: const Icon(Icons.logout),
              label: Text(_busy ? 'Signing out…' : 'Sign out'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: _tileBlue),
      title: Text(
        label,
        style: const TextStyle(color: _tileBlue, fontSize: 13),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(
          color: _tileText,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
