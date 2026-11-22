import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

enum AccountRole {
  recipient('Recipient'),
  parcelOperator('Parcel Operator');

  const AccountRole(this.label);

  final String label;
}

class Account {
  const Account({required this.name, required this.email, required this.role});

  final String name;
  final String email;
  final AccountRole role;

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      name: json['name'] as String,
      email: json['email'] as String,
      role: switch (json['role']) {
        'recipient' => AccountRole.recipient,
        'parcel_operator' => AccountRole.parcelOperator,
        _ => throw const FormatException('Unknown account role'),
      },
    );
  }
}

class ApiException implements Exception {
  const ApiException(this.message, {this.status});

  final String message;
  final int? status;
}

class AuthApi {
  AuthApi({required this.baseUrl, required this.client});

  static const _showConnectionDiagnostics = bool.fromEnvironment(
    'SHOW_CONNECTION_DIAGNOSTICS',
  );

  final String baseUrl;
  final http.Client client;

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    await _request(
      'POST',
      'register.php',
      fields: {
        'name': name,
        'email': email,
        'password': password,
        'confirm_password': confirmPassword,
      },
    );
  }

  Future<String> login(String email, String password) async {
    final Map<String, dynamic> data;
    try {
      data = await _request(
        'POST',
        'login.php',
        fields: {'email': email, 'password': password},
      );
    } on ApiException catch (error) {
      if (error.status != 401) rethrow;
      throw const ApiException(
        'Email or password is incorrect. If you haven’t registered, '
        'create a recipient account below.',
        status: 401,
      );
    }
    final token = data['token'];
    if (token is! String || !RegExp(r'^[0-9a-f]{64}$').hasMatch(token)) {
      throw const ApiException('The server returned an invalid session.');
    }
    return token;
  }

  Future<Account> profile(String token) async {
    final data = await _request('GET', 'profile.php', token: token);
    try {
      return Account.fromJson(data['user'] as Map<String, dynamic>);
    } on FormatException {
      throw const ApiException('The server returned an invalid account.');
    } on TypeError {
      throw const ApiException('The server returned an invalid account.');
    }
  }

  Future<void> logout(String token) async {
    await _request('POST', 'logout.php', token: token);
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String endpoint, {
    Map<String, String>? fields,
    String? token,
  }) async {
    final url = Uri.tryParse(baseUrl);
    if (url == null ||
        !const {'http', 'https'}.contains(url.scheme) ||
        url.host.isEmpty ||
        url.userInfo.isNotEmpty ||
        url.hasQuery ||
        url.hasFragment) {
      throw const ApiException('The server address is invalid.');
    }
    final path = url.path.endsWith('/') ? url.path : '${url.path}/';
    final request = http.Request(method, url.replace(path: '$path$endpoint'))
      ..followRedirects = false
      ..headers['Accept'] = 'application/json';

    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    if (fields != null) request.bodyFields = fields;

    final http.Response response;
    try {
      response = await client
          .send(request)
          .then(http.Response.fromStream)
          .timeout(const Duration(seconds: 12));
    } on TimeoutException {
      throw _connectionFailure('Request timed out');
    } on http.ClientException catch (error) {
      final reason = error.message.toLowerCase();
      final detail = switch (reason) {
        _
            when reason.contains('permission denied') ||
                reason.contains('operation not permitted') =>
          'Network access denied',
        _
            when reason.contains('cleartext') ||
                reason.contains('insecure http') =>
          'HTTP blocked',
        _ when reason.contains('unreachable') || reason.contains('no route') =>
          'No route to server',
        _ when reason.contains('refused') => 'Connection refused',
        _ when reason.contains('reset') || reason.contains('closed') =>
          'Connection closed',
        _ when reason.contains('timed out') => 'Connection timed out',
        _ => 'HTTP client error',
      };
      throw _connectionFailure(detail);
    } on Exception {
      throw _connectionFailure('Unexpected connection error');
    }

    final Object? body;
    try {
      body = jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      throw const ApiException('The server returned an unexpected response.');
    }
    if (body is! Map<String, dynamic>) {
      throw const ApiException('The server returned an unexpected response.');
    }
    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        body['success'] != true) {
      final message = body['message'];
      throw ApiException(
        message is String ? message : 'The request could not be completed.',
        status: response.statusCode,
      );
    }
    return body;
  }

  ApiException _connectionFailure(String detail) {
    const message =
        'Could not reach the server. Check your connection and try again.';
    return ApiException(
      _showConnectionDiagnostics
          ? '$message\nConnection check: $detail.'
          : message,
    );
  }
}
