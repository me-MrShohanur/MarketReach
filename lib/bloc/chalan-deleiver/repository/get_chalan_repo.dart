import 'dart:convert';
import 'dart:developer' as dev;
import 'package:http/http.dart' as http;
import 'package:marketing/services/models/chalan_bill.dart';

class ChallanRepository {
  final String baseUrl = 'http://103.125.253.59:1122/api/v1';

  Future<List<ChallanBill>> getChallanBill({
    required int partyId,
    required int compId,
    required int types,
    required String token,
  }) async {
    final uri = Uri.parse(
      '$baseUrl/Order/GetChallanBill?partyId=$partyId&compId=$compId&types=$types',
    );

    dev.log('[ChallanRepo] GET $uri', name: 'ChallanRepository');

    final response = await http.get(
      uri,
      headers: {'accept': '*/*', 'Authorization': 'Bearer $token'},
    );

    dev.log(
      '[ChallanRepo] status=${response.statusCode}',
      name: 'ChallanRepository',
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);

      if (data['status'] != true) {
        dev.log(
          '[ChallanRepo] types=$types status!=true → []',
          name: 'ChallanRepository',
        );
        return [];
      }

      final dynamic resultWrapper = data['result'];
      if (resultWrapper == null) return [];

      final dynamic list = resultWrapper is Map
          ? (resultWrapper['result'] ?? resultWrapper['data'] ?? [])
          : resultWrapper;

      if (list is! List) return [];
      if (list.isEmpty) return [];

      // ── Print every raw item so we can see exact field names & types ──
      for (int i = 0; i < list.length && i < 3; i++) {
        dev.log(
          '[ChallanRepo] types=$types item[$i] = ${list[i]}',
          name: 'ChallanRepository',
        );
      }

      final result = <ChallanBill>[];
      for (int i = 0; i < list.length; i++) {
        final item = list[i];
        if (item is! Map<String, dynamic>) {
          dev.log(
            '[ChallanRepo] types=$types item[$i] skipped — not a Map: ${item.runtimeType}',
            name: 'ChallanRepository',
          );
          continue;
        }
        try {
          result.add(ChallanBill.fromJson(item));
        } catch (e) {
          // Print the full item and which field failed so we can fix the model
          dev.log(
            '[ChallanRepo] types=$types item[$i] FAILED: $e\nraw=$item',
            name: 'ChallanRepository',
          );
        }
      }
      return result;
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized – please log in again.');
    } else {
      throw Exception('Server error ${response.statusCode} for types=$types');
    }
  }
}
