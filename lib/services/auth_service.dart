import 'dart:convert';
import 'dart:developer';

import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:marketing/constants/api_values';
import 'package:marketing/utilities/show_error_dialog.dart';

class AuthService {
  static const _storage = FlutterSecureStorage();

  static const String _tokenKey = 'auth_jwt_token';
  static const String _userDataKey = 'auth_user_json';

  /// Returns true on success, throws Exception on failure
  Future<bool> login(
    String userName,
    String password,
    BuildContext context,
  ) async {
    final url = Uri.parse('${BaseUrl.apiBase}/api/${V.v1}/${EndPoint.login}');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'userName': userName.trim(),
          'password': password.trim(),
        }),
      );

      if (response.statusCode != 200) {
        // throw Exception(
        //   'Login failed • Status: ${response.statusCode}\n${response.body}',
        // );
        showErrorDialog(context, 'Check your credentials and try again.');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      final token = data['token'] as String?;
      if (token == null || token.isEmpty) {
        throw Exception('No token received from server');
      }

      // Save token + full user data (you can access later anywhere)
      await _storage.write(key: _tokenKey, value: token);
      await _storage.write(key: _userDataKey, value: jsonEncode(data));
      // ────────────────────────────────────────────────
      // Print to console immediately after saving

      log(
        name: 'Token: ',
        '${token.substring(0, token.length > 40 ? 40 : token.length)}...',
      );
      log(
        name: 'Full user data:',
        jsonEncode(data),
      ); // or use jsonDecode(data).toString() if you want nicer format

      // ────────────────────────────────────────────────

      return true;
    } catch (e) {
      rethrow; // Let the UI show the error
    }
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
    // You could add JWT expiration check later if needed
  }

  Future<Map<String, dynamic>?> getUserData() async {
    final jsonStr = await _storage.read(key: _userDataKey);
    if (jsonStr == null || jsonStr.isEmpty) return null;
    try {
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> logout() async {
    await _storage.deleteAll();
  }
}
