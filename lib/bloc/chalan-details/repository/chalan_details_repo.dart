// ════════════════════════════════════════════════════════════════════════════
// REPOSITORY
// lib/bloc/challan-details/repository/challan_details_repo.dart
// ════════════════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'dart:developer' as dev;
import 'package:http/http.dart' as http;
import 'package:marketing/services/models/chalan_details.dart';

class ChallanDetailsRepository {
  final String _base = 'http://103.125.253.59:1122/api/v1';

  Future<ChallanDetailsModel> getChallanDetails({
    required int partyId,
    required int compId,
    required int challanId,
    required String token,
  }) async {
    final uri = Uri.parse(
      '$_base/Order/GetChallanDetails'
      '?partyId=$partyId&compId=$compId&challanId=$challanId',
    );

    dev.log('[ChallanDetailsRepo] GET $uri', name: 'ChallanDetailsRepo');

    final response = await http.get(
      uri,
      headers: {'accept': '*/*', 'Authorization': 'Bearer $token'},
    );

    dev.log(
      '[ChallanDetailsRepo] status=${response.statusCode}',
      name: 'ChallanDetailsRepo',
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> body = jsonDecode(response.body);

      final dynamic resultWrapper = body['result'];
      if (resultWrapper == null) {
        throw Exception('Empty result from server');
      }

      final dynamic list = resultWrapper is Map
          ? (resultWrapper['result'] ?? resultWrapper['data'] ?? [])
          : resultWrapper;

      if (list is! List || list.isEmpty) {
        throw Exception('No challan details found for challanId=$challanId');
      }

      final first = list.first;
      if (first is! Map<String, dynamic>) {
        throw Exception('Unexpected data format');
      }

      dev.log('[ChallanDetailsRepo] raw=$first', name: 'ChallanDetailsRepo');

      return ChallanDetailsModel.fromJson(first);
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized – please log in again.');
    } else {
      throw Exception(
        'Server error ${response.statusCode} for challanId=$challanId',
      );
    }
  }
}
