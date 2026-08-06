import 'dart:convert';
import 'package:http/http.dart' as http;
import 'backend_config.dart';

/// Holds the signed-in user for this device.
///
/// The backend issues one session token per device and keeps them all valid at
/// the same time, so signing in here never disturbs the same account signed in
/// elsewhere.
class Session {
  static int? userId;
  static String? userEmail;

  /// Session token from the login response. Sent as a bearer token on every
  /// request by [AuthHttpClient], which is installed in main().
  static String? token;

  /// When the token stops being accepted by the backend.
  static DateTime? expiresAt;

  static bool get isLoggedIn => token != null && userId != null;

  /// Headers for manual requests. Requests made through the normal `http`
  /// helpers already get the token added for them.
  static Map<String, String> get authHeaders =>
      token == null ? {} : {'Authorization': 'Bearer $token'};

  static Map<String, String> get jsonHeaders => {
        'Content-Type': 'application/json',
        ...authHeaders,
      };

  static void start({
    required int id,
    required String email,
    required String? sessionToken,
    DateTime? expiry,
  }) {
    userId = id;
    userEmail = email;
    // An empty string is not a usable session. Treating it as one would make
    // every request send `Bearer ` and fail confusingly, so keep it null.
    token = (sessionToken == null || sessionToken.isEmpty) ? null : sessionToken;
    expiresAt = expiry;
  }

  static void clear() {
    userId = null;
    userEmail = null;
    token = null;
    expiresAt = null;
  }

  /// Ends this device's session on the server, then clears it locally. Other
  /// devices signed in to the same account are unaffected.
  static Future<void> logout() async {
    final currentToken = token;
    // Clear locally first so the UI can never act on a dead session, even if
    // the network call below fails.
    clear();

    if (currentToken == null) return;
    try {
      await http.post(
        Uri.parse('$backendUrl/api/auth/logout'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $currentToken',
        },
      );
    } catch (_) {
      // The local session is already gone; a failed call just leaves the row
      // on the server to expire on its own.
    }
  }

  /// Signs out every other device, keeping this one active.
  static Future<int> logoutOtherDevices() async {
    final response = await http.post(
      Uri.parse('$backendUrl/api/auth/logout-all'),
      headers: jsonHeaders,
      body: jsonEncode({'includeCurrent': false}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to sign out other devices');
    }
    return jsonDecode(response.body)['revoked'] as int? ?? 0;
  }

  /// Lists the devices currently signed in to this account.
  static Future<List<Map<String, dynamic>>> activeDevices() async {
    final response = await http.get(
      Uri.parse('$backendUrl/api/auth/sessions'),
      headers: jsonHeaders,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load active devices');
    }
    final data = jsonDecode(response.body);
    return List<Map<String, dynamic>>.from(data['sessions'] as List);
  }
}

/// Adds the session token to every outgoing request.
///
/// Installed once in main() via `runWithClient`, so the plain `http.get` /
/// `http.post` calls spread across the app pick it up without each call site
/// having to remember the header.
class AuthHttpClient extends http.BaseClient {
  AuthHttpClient(this._inner);

  final http.Client _inner;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    final token = Session.token;
    // The token is only ever sent to our own backend. Third-party calls (map
    // tiles, OpenRouteService) must not receive it, and some of them carry
    // their own Authorization header that must survive untouched.
    if (token != null &&
        _isBackend(request.url) &&
        !request.headers.containsKey('Authorization')) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    return _inner.send(request);
  }

  /// True when the request targets this app's backend rather than an
  /// external service.
  static bool _isBackend(Uri url) {
    final backend = Uri.parse(backendUrl);
    return url.host == backend.host && url.port == backend.port;
  }

  @override
  void close() => _inner.close();
}
