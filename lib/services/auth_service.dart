import 'dart:convert';
import 'dart:developer';

import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:marketing/constants/api_values';
import 'package:marketing/services/models/auth_model.dart';
import 'package:marketing/utilities/show_error_dialog.dart';

class AuthService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      biometricPromptTitle: 'Flutter Secure Storage Example',
      biometricPromptSubtitle: 'Please unlock to access data.',
    ),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const String _tokenKey = 'auth_jwt_token';
  static const String _userDataKey = 'auth_user_json';

  /// Returns true on success, false on failure
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
        showErrorDialog(context, 'Check your credentials and try again.');
        return false;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      final status = data['status'] as bool?;
      if (status == null || !status) {
        showErrorDialog(context, 'Login failed. Please try again.');
        return false;
      }

      final result = data['result'] as Map<String, dynamic>?;
      if (result == null) {
        showErrorDialog(context, 'Unexpected response from server.');
        return false;
      }

      final token = result['token'] as String?;
      if (token == null || token.isEmpty) {
        showErrorDialog(context, 'No token received from server.');
        return false;
      }

      // Write token
      await _storage.write(key: _tokenKey, value: token);
      await _storage.write(key: _userDataKey, value: jsonEncode(result));

      // ✅ Immediately read back to confirm it was actually saved
      final savedToken = await _storage.read(key: _tokenKey);
      if (savedToken == null || savedToken.isEmpty) {
        log(
          name: 'AuthService',
          '❌ Token write FAILED — read-back returned null',
        );
        showErrorDialog(context, 'Failed to save session. Please try again.');
        return false;
      }

      log(name: 'AuthService', '✅ Token saved and verified');
      log(
        name: 'AuthService → Token',
        '🔑 ${token.substring(0, token.length > 40 ? 40 : token.length)}...',
      );
      log(name: 'AuthService → User', jsonEncode(result));

      return true;
    } catch (e) {
      log(name: 'AuthService.login error', e.toString());
      rethrow;
    }
  }

  /// Get raw JWT token
  Future<String?> getToken() async {
    final token = await _storage.read(key: _tokenKey);
    log(name: 'AuthService.getToken', '🔍 token = ${token?.length ?? 0}');
    return token;
  }

  /// Returns true if a token exists in storage
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    final result = token != null && token.isNotEmpty;
    log(name: 'AuthService.isLoggedIn', '➡️ $result');
    return result;
  }

  /// Get full user data saved during login
  Future<Map<String, dynamic>?> getUserData() async {
    final jsonStr = await _storage.read(key: _userDataKey);
    if (jsonStr == null || jsonStr.isEmpty) return null;
    try {
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Get a specific field from saved user data
  Future<dynamic> getUserField(String field) async {
    final userData = await getUserData();
    return userData?[field];
  }

  /// ✅ NEW — Get typed AuthUser model from stored data
  Future<AuthUser?> getUser() async {
    final data = await getUserData();
    if (data == null) return null;
    try {
      return AuthUser.fromJson(data);
    } catch (e) {
      log(name: 'AuthService.getUser', '❌ Failed to parse AuthUser: $e');
      return null;
    }
  }

  /// Clear all stored data (logout)
  Future<void> logout() async {
    await _storage.deleteAll();
    log(name: 'AuthService', '🚪 User logged out. Storage cleared.');
  }
}
