import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

/// Set with:
/// flutter run --dart-define=API_URL=http://192.168.1.20:8000
const String _configuredUrl = String.fromEnvironment('API_URL');

String resolveBaseUrl() {
  if (_configuredUrl.isNotEmpty) {
    return _configuredUrl.replaceAll(RegExp(r'/+$'), '');
  }
  if (kIsWeb) return 'http://localhost:8000';
  if (defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:8000';
  }
  return 'http://localhost:8000';
}

class ApiFailure implements Exception {
  const ApiFailure(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class UnauthorizedFailure extends ApiFailure {
  const UnauthorizedFailure(
      [super.message = 'Your session has expired. Please sign in again.'])
      : super(statusCode: 401);

  @override
  String toString() => message;
}

class TrustFarmApi {
  TrustFarmApi({String? baseUrl, http.Client? client})
      : baseUrl = baseUrl ?? resolveBaseUrl(),
        _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  static const _tokenKey = 'token';
  static const _userKey = 'session:user';
  static const _cachePrefix = 'cache:v2:';

  final FlutterSecureStorage _secure = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  String? _token;
  UserProfile? _user;

  UserProfile? get currentUser => _user;
  bool get hasToken => _token != null;

  // ---------------------------------------------------------------- session

  Future<UserProfile?> restoreSession() async {
    _token = await _readToken();
    if (_token == null) return null;

    final prefs = await SharedPreferences.getInstance();
    final cachedUser = prefs.getString(_userKey);
    if (cachedUser != null) {
      try {
        _user = UserProfile.fromJson(
            jsonDecode(cachedUser) as Map<String, dynamic>);
      } catch (_) {
        _user = null;
      }
    }

    try {
      final user = await me();
      await _saveUser(user);
      return user;
    } on UnauthorizedFailure {
      await logout();
      return null;
    } on ApiFailure {
      // Offline start with a previously verified identity is allowed. Data is
      // served from the last known cache by the dashboard.
      if (_user != null) return _user;
      return null;
    }
  }

  Future<UserProfile> login(String email, String password) async {
    final response = await _send(
      'POST',
      '/auth/login',
      body: {'email': email.trim(), 'password': password},
      authenticated: false,
    );
    final map = _asMap(response);
    final token = map['token'];
    if (token is! String || token.isEmpty) {
      throw const ApiFailure('The server returned an invalid session.');
    }
    _token = token;
    await _writeToken(token);
    final rawUser = map['user'];
    final user = rawUser is Map<String, dynamic>
        ? UserProfile.fromJson(rawUser)
        : await me();
    await _saveUser(user);
    return user;
  }

  Future<UserProfile> me() async =>
      UserProfile.fromJson(_asMap(await _send('GET', '/me')));

  Future<void> logout() async {
    _token = null;
    _user = null;
    await _deleteToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    final keys =
        prefs.getKeys().where((k) => k.startsWith(_cachePrefix)).toList();
    for (final key in keys) {
      await prefs.remove(key);
    }
  }

  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    final keys =
        prefs.getKeys().where((k) => k.startsWith(_cachePrefix)).toList();
    for (final key in keys) {
      await prefs.remove(key);
    }
  }

  Future<int> cachedResponseCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs
        .getKeys()
        .where((k) => k.startsWith(_cachePrefix) && !k.endsWith(':time'))
        .length;
  }

  // ------------------------------------------------------------------- data

  Future<Fetched<List<ZoneInfo>>> zones() async {
    final fetched = await _getCached('/zones');
    final list = fetched.data is List ? fetched.data as List : const [];
    return Fetched(
      data: list
          .whereType<Map<String, dynamic>>()
          .map(ZoneInfo.fromJson)
          .toList(),
      offline: fetched.offline,
      cachedAt: fetched.cachedAt,
    );
  }

  Future<Fetched<ZoneStatus>> zoneStatus(int zoneId) async {
    final fetched = await _getCached('/zones/$zoneId/status');
    return Fetched(
      data: ZoneStatus.fromJson(fetched.data is Map<String, dynamic>
          ? fetched.data as Map<String, dynamic>
          : const {}),
      offline: fetched.offline,
      cachedAt: fetched.cachedAt,
    );
  }

  Future<Fetched<List<Reading>>> readings(int zoneId, {int hours = 24}) async {
    final fetched = await _getCached('/zones/$zoneId/readings?hours=$hours');
    final list = fetched.data is List ? fetched.data as List : const [];
    return Fetched(
      data:
          list.whereType<Map<String, dynamic>>().map(Reading.fromJson).toList(),
      offline: fetched.offline,
      cachedAt: fetched.cachedAt,
    );
  }

  Future<Fetched<List<TrustPoint>>> trustHistory(int zoneId,
      {int hours = 24}) async {
    final fetched =
        await _getCached('/zones/$zoneId/trust-history?hours=$hours');
    final list = fetched.data is List ? fetched.data as List : const [];
    return Fetched(
      data: list
          .whereType<Map<String, dynamic>>()
          .map(TrustPoint.fromJson)
          .toList(),
      offline: fetched.offline,
      cachedAt: fetched.cachedAt,
    );
  }

  Future<Fetched<List<AlertInfo>>> alerts() async {
    final fetched = await _getCached('/alerts');
    final list = fetched.data is List ? fetched.data as List : const [];
    return Fetched(
      data: list
          .whereType<Map<String, dynamic>>()
          .map(AlertInfo.fromJson)
          .toList(),
      offline: fetched.offline,
      cachedAt: fetched.cachedAt,
    );
  }

  Future<bool> health() async {
    try {
      final response = await _client
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 4));
      if (response.statusCode != 200) return false;
      final json = jsonDecode(response.body);
      return json is Map && json['ok'] == true;
    } catch (_) {
      return false;
    }
  }

  // ---------------------------------------------------------------- helpers

  Future<Fetched<dynamic>> _getCached(String path) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_cachePrefix$path';
    try {
      final response = await _send('GET', path);
      await prefs.setString(key, jsonEncode(response));
      await prefs.setString('$key:time', DateTime.now().toIso8601String());
      return Fetched(data: response);
    } on UnauthorizedFailure {
      rethrow;
    } on ApiFailure {
      final cached = prefs.getString(key);
      if (cached == null) rethrow;
      final cachedAt = DateTime.tryParse(prefs.getString('$key:time') ?? '');
      return Fetched(
          data: jsonDecode(cached), offline: true, cachedAt: cachedAt);
    }
  }

  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (authenticated && _token != null) 'Authorization': 'Bearer $_token',
    };

    try {
      final http.Response response;
      if (method == 'POST') {
        response = await _client
            .post(uri, headers: headers, body: jsonEncode(body ?? const {}))
            .timeout(const Duration(seconds: 10));
      } else {
        response = await _client
            .get(uri, headers: headers)
            .timeout(const Duration(seconds: 10));
      }

      if (response.statusCode == 401) throw const UnauthorizedFailure();

      if (response.statusCode < 200 || response.statusCode >= 300) {
        var message =
            'The server could not complete this request (${response.statusCode}).';
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map && decoded['detail'] is String) {
            message = decoded['detail'] as String;
          }
        } catch (_) {
          // Keep the friendly fallback.
        }
        throw ApiFailure(message, statusCode: response.statusCode);
      }

      if (response.body.trim().isEmpty) return null;
      return jsonDecode(response.body);
    } on TimeoutException {
      throw const ApiFailure(
          'The farm server took too long to respond. Check your connection.');
    } on UnauthorizedFailure {
      rethrow;
    } on ApiFailure {
      rethrow;
    } catch (_) {
      throw const ApiFailure(
          'Cannot reach the TrustFarm server. Showing the last known state when possible.');
    }
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return value.cast<String, dynamic>();
    throw const ApiFailure('The server returned an unexpected response.');
  }

  Future<String?> _readToken() async {
    try {
      return await _secure.read(key: _tokenKey);
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('secure_fallback:$_tokenKey');
    }
  }

  Future<void> _writeToken(String token) async {
    try {
      await _secure.write(key: _tokenKey, value: token);
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('secure_fallback:$_tokenKey', token);
    }
  }

  Future<void> _deleteToken() async {
    try {
      await _secure.delete(key: _tokenKey);
    } catch (_) {
      // Fallback storage is cleared below.
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('secure_fallback:$_tokenKey');
  }

  Future<void> _saveUser(UserProfile user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
    _user = user;
  }

  void dispose() => _client.close();
}
