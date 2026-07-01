import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:marketing/services/models/getpening_model.dart';

class PendingOrderDetailException implements Exception {
  final String message;
  PendingOrderDetailException(this.message);
  @override
  String toString() => message;
}

class PendingOrderDetailRepository {
  // TODO: replace with your shared base-URL constant if you have one
  // (e.g. ApiConstants.baseUrl) instead of hardcoding it here.
  static const String _baseUrl = 'http://103.125.253.59:1122/api/v1';

  Future<List<PendingOrderDetailModel>> getPendingOrderDetail({
    required int partyId,
    required int compId,
    required int orderId,
    required String token,
  }) async {
    final uri = Uri.parse(
      '$_baseUrl/Order/GetPendingOrderApp'
      '?partyId=$partyId&compId=$compId&orderId=$orderId',
    );

    try {
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        throw PendingOrderDetailException(
          'Failed to load order detail (status ${response.statusCode})',
        );
      }

      final decoded = json.decode(response.body);
      final List<dynamic> result = decoded['result'] ?? [];

      return result.map((e) => PendingOrderDetailModel.fromJson(e)).toList();
    } on PendingOrderDetailException {
      rethrow;
    } catch (e) {
      throw PendingOrderDetailException('Network error: $e');
    }
  }
}
