import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:marketing/constants/api_values';
import 'package:marketing/services/models/products_model.dart';
import 'package:marketing/services/provider/current_user.dart';

class ProductService {
  Future<List<ProductModel>> getProducts({required int categoryId}) async {
    final uri =
        Uri.parse(
          '${BaseUrl.apiBase}/api/${V.v1}/${EndPoint.getProducts}',
        ).replace(
          queryParameters: {
            'companyId': CurrentUser.compId.toString(),
            'partyId': CurrentUser.customerID.toString(),
            'categoryId': categoryId.toString(),
          },
        );

    log(uri.toString(), name: 'ProductService');

    final response = await http.get(
      uri,
      headers: {
        'accept': '*/*',
        'Authorization': 'Bearer ${CurrentUser.token}',
      },
    );

    log('Status: ${response.statusCode}', name: 'ProductService');

    if (response.statusCode == 200) {
      log(name: EndPoint.getProducts, uri.toString());
      final Map<String, dynamic> jsonMap = jsonDecode(response.body);
      if (jsonMap['status'] == true) {
        final List<dynamic> result = jsonMap['result'];
        return result
            .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('API returned status: false');
      }
    } else {
      log('Body: ${response.body}', name: 'ProductService');
      throw Exception('HTTP ${response.statusCode}');
    }
  }
}
