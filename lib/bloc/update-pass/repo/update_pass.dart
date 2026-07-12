import 'dart:developer' as dev;
import 'package:http/http.dart' as http;

class UpdatePasswordResult {
  final bool success;
  final String message;
  UpdatePasswordResult({required this.success, required this.message});
}

class UpdatePasswordRepository {
  final String _base = 'http://103.125.253.59:1122/api/v1';

  Future<UpdatePasswordResult> updatePassword({
    required String userName,
    required String currentPassword,
    required String newPassword,
    required String token,
  }) async {
    final uri = Uri.parse(
      '$_base/Order/UpdatePassword'
      '?userName=$userName'
      '&currentPassword=$currentPassword'
      '&newPassword=$newPassword',
    );

    dev.log('[UpdatePasswordRepo] POST $uri', name: 'UpdatePasswordRepo');

    final response = await http.post(
      uri,
      headers: {'accept': '*/*', 'Authorization': 'Bearer $token'},
    );

    dev.log(
      '[UpdatePasswordRepo] status=${response.statusCode} body=${response.body}',
      name: 'UpdatePasswordRepo',
    );

    if (response.statusCode == 200) {
      // Strip surrounding quotes if API returned a JSON string like "true" or
      // "Username is not valid".
      String raw = response.body.trim();
      if (raw.startsWith('"') && raw.endsWith('"') && raw.length >= 2) {
        raw = raw.substring(1, raw.length - 1);
      }
      final lower = raw.toLowerCase();

      if (lower == 'true') {
        return UpdatePasswordResult(
          success: true,
          message: 'Password changed successfully',
        );
      } else if (lower.contains('username')) {
        // "Username is not valid"
        return UpdatePasswordResult(success: false, message: raw);
      } else if (lower.contains('current password') ||
          lower.contains('password is incorrect')) {
        // "Current password is incorrect"
        return UpdatePasswordResult(success: false, message: raw);
      } else {
        // "false" or anything else unrecognized on a 200 → generic failure
        return UpdatePasswordResult(
          success: false,
          message: 'Failed to update password. Please try again.',
        );
      }
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized – please log in again.');
    } else {
      // Any other status code (400, 404, 500, etc.) → treat as generic false
      return UpdatePasswordResult(
        success: false,
        message: 'Failed to update password. Please try again.',
      );
    }
  }
}
