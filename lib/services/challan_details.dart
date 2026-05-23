import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:marketing/services/models/chalan_details.dart';

class ChallanService {
  static const String baseUrl = 'http://103.125.253.59:1122';

  Future<ChallanDetailsResponse> getChallanDetails({
    required int partyId,
    required int compId,
    required int challanId,
    required String token,
  }) async {
    try {
      final url = Uri.parse(
        '$baseUrl/api/v1/Order/GetChallanDetails?partyId=$partyId&compId=$compId&challanId=$challanId',
      );

      final response = await http.get(
        url,
        headers: {'accept': '*/*', 'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return ChallanDetailsResponse.fromJson(data);
      } else {
        throw Exception(
          'Failed to load challan details: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching challan details: $e');
    }
  }
}
