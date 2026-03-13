// import 'dart:convert';
// import 'dart:developer';

// import 'package:http/http.dart' as http;
// import 'package:marketing/constants/api_values';
// import 'package:marketing/services/auth_service.dart';

// /// ─────────────────────────────────────────────────────────────────────────────
// /// ApiClient
// ///
// /// Centralised HTTP wrapper that automatically injects the JWT Bearer token
// /// into every request. Use this for ALL API calls in the app.
// ///
// /// Usage:
// /// ┌─────────────────────────────────────────────────────────────────────┐
// /// │  // GET                                                              │
// /// │  final res = await ApiClient().get(                                  │
// /// │    '${EndPoint.getProducts}',                                        │
// /// │    queryParams: {'companyId': '122', 'partyId': '0'},               │
// /// │  );                                                                  │
// /// │                                                                      │
// /// │  // POST                                                             │
// /// │  final res = await ApiClient().post(                                 │
// /// │    '${EndPoint.someEndpoint}',                                       │
// /// │    body: {'key': 'value'},                                           │
// /// │  );                                                                  │
// /// └─────────────────────────────────────────────────────────────────────┘
// ///
// /// Both methods return the raw `http.Response` so callers can parse freely.
// /// ─────────────────────────────────────────────────────────────────────────────
// class ApiClient {
//   static final ApiClient _instance = ApiClient._internal();
//   factory ApiClient() => _instance;
//   ApiClient._internal();

//   static void _log(String tag, String message) =>
//       log(message, name: '🌐 ApiClient [$tag]');

//   // ── Build full URL ──────────────────────────────────────────────────────────
//   Uri _buildUri(String endpoint, {Map<String, String>? queryParams}) {
//     final base = '${BaseUrl.apiBase}/api/${V.v1}/$endpoint';
//     final uri = Uri.parse(base);
//     return queryParams != null && queryParams.isNotEmpty
//         ? uri.replace(queryParameters: queryParams)
//         : uri;
//   }

//   // ── GET ─────────────────────────────────────────────────────────────────────

//   /// Authenticated GET request.
//   ///
//   /// [endpoint]    — e.g. `EndPoint.getProducts`
//   /// [queryParams] — appended as ?key=value&…
//   Future<http.Response> get(
//     String endpoint, {
//     Map<String, String>? queryParams,
//   }) async {
//     final uri = _buildUri(endpoint, queryParams: queryParams);
//     final headers = await AuthService().authHeaders();

//     _log('GET', '→ $uri');

//     try {
//       final response = await http.get(uri, headers: headers);
//       _log('GET', '← HTTP ${response.statusCode}  endpoint=$endpoint');
//       _handleUnauthorized(response, endpoint);
//       return response;
//     } catch (e, st) {
//       _log('GET → EXCEPTION', '💥 $e\n$st');
//       rethrow;
//     }
//   }

//   // ── POST ────────────────────────────────────────────────────────────────────

//   /// Authenticated POST request with JSON body.
//   ///
//   /// [endpoint] — e.g. `EndPoint.someEndpoint`
//   /// [body]     — serialised to JSON automatically
//   Future<http.Response> post(
//     String endpoint, {
//     Map<String, dynamic>? body,
//   }) async {
//     final uri = _buildUri(endpoint);
//     final headers = await AuthService().authHeaders();

//     _log('POST', '→ $uri  body=${jsonEncode(body)}');

//     try {
//       final response = await http.post(
//         uri,
//         headers: headers,
//         body: body != null ? jsonEncode(body) : null,
//       );
//       _log('POST', '← HTTP ${response.statusCode}  endpoint=$endpoint');
//       _handleUnauthorized(response, endpoint);
//       return response;
//     } catch (e, st) {
//       _log('POST → EXCEPTION', '💥 $e\n$st');
//       rethrow;
//     }
//   }

//   // ── PUT ─────────────────────────────────────────────────────────────────────

//   /// Authenticated PUT request with JSON body.
//   Future<http.Response> put(
//     String endpoint, {
//     Map<String, dynamic>? body,
//   }) async {
//     final uri = _buildUri(endpoint);
//     final headers = await AuthService().authHeaders();

//     _log('PUT', '→ $uri  body=${jsonEncode(body)}');

//     try {
//       final response = await http.put(
//         uri,
//         headers: headers,
//         body: body != null ? jsonEncode(body) : null,
//       );
//       _log('PUT', '← HTTP ${response.statusCode}  endpoint=$endpoint');
//       _handleUnauthorized(response, endpoint);
//       return response;
//     } catch (e, st) {
//       _log('PUT → EXCEPTION', '💥 $e\n$st');
//       rethrow;
//     }
//   }

//   // ── DELETE ──────────────────────────────────────────────────────────────────

//   /// Authenticated DELETE request.
//   Future<http.Response> delete(
//     String endpoint, {
//     Map<String, String>? queryParams,
//   }) async {
//     final uri = _buildUri(endpoint, queryParams: queryParams);
//     final headers = await AuthService().authHeaders();

//     _log('DELETE', '→ $uri');

//     try {
//       final response = await http.delete(uri, headers: headers);
//       _log('DELETE', '← HTTP ${response.statusCode}  endpoint=$endpoint');
//       _handleUnauthorized(response, endpoint);
//       return response;
//     } catch (e, st) {
//       _log('DELETE → EXCEPTION', '💥 $e\n$st');
//       rethrow;
//     }
//   }

//   // ── 401 guard ───────────────────────────────────────────────────────────────

//   void _handleUnauthorized(http.Response response, String endpoint) {
//     if (response.statusCode == 401) {
//       _log(
//         '401 Unauthorized',
//         '⚠️  Token rejected by server at endpoint="$endpoint". '
//             'Consider calling AuthService().logout() and routing to LoginView.',
//       );
//     }
//   }
// }
