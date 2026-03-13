import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:marketing/services/models/customer.dart';

class CustomerService {
  static const String _baseUrl =
      'http://103.125.253.59:1122/api/v1/Order/GetCustomer';

  Future<List<CustomerModel>> fetchCustomers() async {
    final uri = Uri.parse(
      '$_baseUrl?companyId=122&type=2&empId=5892&userId=3631&customerId=0',
    );

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data
          .map((item) => CustomerModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception(
        'Failed to load customers. Status: ${response.statusCode}',
      );
    }
  }
}
