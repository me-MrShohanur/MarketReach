import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:marketing/constants/api_values.dart';

/// Thrown for transport/HTTP-level failures (non-200, timeout, bad JSON).
/// Kept separate from a "false" business-logic result — those are two very
/// different failure modes and the UI should be able to tell them apart.
class ConfirmChallanApiException implements Exception {
  final String message;
  ConfirmChallanApiException(this.message);

  @override
  String toString() => message;
}

/// Handles the raw API call for confirming a challan as received.
///
/// Endpoint:
///   POST /api/v1/Order/ConfirmChallanReceived?challanId={id}&compId={id}
///
/// Swagger showed the response body as a bare boolean (`true` / `false`),
/// with HTTP 200 either way. That matters: a 200 status does NOT mean the
/// confirm succeeded — you have to read the body. So this method returns
/// that bool to the caller instead of assuming 200 == success.
///
/// This layer knows NOTHING about Bloc, UI, or where challanId/compId come
/// from — it just takes plain values, makes the call, and reports what the
/// server actually said. That separation is what lets you reuse/test this
/// independently of the Bloc or the widget.
class ConfirmChallanRepository {
  // TODO: move this to a shared ApiConstants/config file if you have one,
  // so every repository points at the same base URL.
  static const String _baseUrl = '${BaseUrl.apiBase}/api/${V.v1}';

  Future<bool> confirmChallanReceived({
    required int challanId,
    required int compId,
    required String token,
  }) async {
    final uri = Uri.parse('$_baseUrl/Order/ConfirmChallanReceived').replace(
      queryParameters: {'challanId': '$challanId', 'compId': '$compId'},
    );

    developer.log(uri.toString(), name: 'ConfirmChallanReceived');

    final http.Response response;
    try {
      response = await http.post(
        uri,
        headers: {'accept': '*/*', 'Authorization': 'Bearer $token'},
      );
    } catch (e) {
      // Network failure — no internet, DNS, timeout, etc.
      throw ConfirmChallanApiException('Network error: could not reach server');
    }

    developer.log(
      'status=${response.statusCode} body=${response.body}',
      name: 'ConfirmChallanReceived',
    );

    // ── Code-not-200 case ──────────────────────────────────────────────
    if (response.statusCode == 401) {
      throw ConfirmChallanApiException('Session expired. Please log in again.');
    }
    if (response.statusCode != 200) {
      throw ConfirmChallanApiException(
        'Server error (status ${response.statusCode})',
      );
    }

    // ── Parse the boolean body ───────────────────────────────────────
    // The API returns a bare `true`/`false`, but we defensively also
    // handle it being wrapped in quotes or JSON, since APIs like this
    // sometimes change shape without notice.
    final raw = response.body.trim().toLowerCase();

    if (raw == 'true') return true;
    if (raw == 'false') return false;

    try {
      final decoded = jsonDecode(response.body);
      if (decoded is bool) return decoded;
      if (decoded is String) return decoded.toLowerCase() == 'true';
    } catch (_) {
      // fall through to the exception below
    }

    throw ConfirmChallanApiException(
      'Unexpected response from server: "${response.body}"',
    );
  }
}
