import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_api.dart';
import 'loginscreen.dart';
import 'screen_widgets.dart';
import 'screens.dart';
import 'splashscreen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ParcelApp());
}

class ParcelApp extends StatefulWidget {
  const ParcelApp({super.key});

  @override
  State<ParcelApp> createState() => _ParcelAppState();
}

class _ParcelAppState extends State<ParcelApp> {
  static const _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.19.5.233:8088/hzqqfairuz/',
  );
  static const _storage = FlutterSecureStorage();
  static const _sessionKey = 'parcel_session:$_baseUrl';
  static const _rememberSessionKey = 'remember_session:$_baseUrl';

  final _client = http.Client();
  late final _api = AuthApi(baseUrl: _baseUrl, client: _client);
  Account? _account;
  String? _token;
  String? _restoreError;
  bool _restoring = true;
  bool _rememberSession = false;

  @override
  void initState() {
    super.initState();
    _restoreSession(showStartupSplash: true);
  }

  @override
  void dispose() {
    _client.close();
    super.dispose();
  }

  Future<void> _restoreSession({bool showStartupSplash = false}) async {
    final splashDelay = showStartupSplash
        ? Future<void>.delayed(const Duration(seconds: 3))
        : null;
    String? restoreError;
    var rememberSession = false;
    setState(() {
      _restoring = true;
      _restoreError = null;
    });
    try {
      final preferences = await SharedPreferences.getInstance();
      rememberSession = preferences.getBool(_rememberSessionKey) ?? false;
      if (!rememberSession) return;

      final token = await _storage.read(key: _sessionKey);
      if (token == null) return;

      try {
        final account = await _api.profile(token);
        if (!mounted) return;
        _token = token;
        _account = account;
      } on ApiException catch (error) {
        if (error.status != 401) rethrow;
        await _storage.delete(key: _sessionKey);
      }
    } on ApiException catch (error) {
      restoreError = error.message;
    } on Exception {
      restoreError = 'Could not load your sign-in settings. Please try again.';
    } finally {
      if (splashDelay != null) await splashDelay;
      if (mounted) {
        setState(() {
          _restoring = false;
          _restoreError = restoreError;
          _rememberSession = rememberSession;
        });
      }
    }
  }

  Future<void> _signIn(
    String email,
    String password,
    bool rememberSession,
  ) async {
    final token = await _api.login(email, password);
    final account = await _api.profile(token);
    final bool savedPreference;
    try {
      if (rememberSession) {
        await _storage.write(key: _sessionKey, value: token);
      } else {
        await _storage.delete(key: _sessionKey);
      }
      final preferences = await SharedPreferences.getInstance();
      savedPreference = await preferences.setBool(
        _rememberSessionKey,
        rememberSession,
      );
    } on Exception {
      throw const ApiException(
        'Could not save your sign-in settings. Please try again.',
      );
    }
    if (!savedPreference) {
      throw const ApiException('Could not save your sign-in preference.');
    }
    if (!mounted) return;
    setState(() {
      _token = token;
      _account = account;
      _rememberSession = rememberSession;
    });
  }

  Future<void> _signOut() async {
    await _api.logout(_token!);
    try {
      await _storage.delete(key: _sessionKey);
    } on Exception {
      throw const ApiException(
        'Signed out on the server. Tap Sign out again to clear this device.',
      );
    }
    if (!mounted) return;
    setState(() {
      _token = null;
      _account = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final account = _account;
    return MaterialApp(
      title: appName,
      debugShowCheckedModeBanner: false,
      theme: parcelTheme(),
      home: _restoring || _restoreError != null
          ? SplashScreen(error: _restoreError, onRetry: _restoreSession)
          : account == null
          ? LoginScreen(
              api: _api,
              onLogin: _signIn,
              rememberSession: _rememberSession,
            )
          : DashboardScreen(account: account, onLogout: _signOut),
    );
  }
}
