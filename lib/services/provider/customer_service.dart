import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:marketing/constants/api_values.dart';
import 'package:marketing/services/models/customer.dart';
import 'package:marketing/services/provider/current_user.dart';

class CustomerService {
  Future<List<CustomerModel>> getCustomers() async {
    final uri =
        Uri.parse(
          '${BaseUrl.apiBase}/api/${V.v1}/${EndPoint.getCustomer}',
        ).replace(
          queryParameters: {
            'companyId': CurrentUser.compId.toString(),
            'type': CurrentUser.userTypeId.toString(),
            'empId': CurrentUser.empId.toString(),
            'userId': CurrentUser.userId.toString(),
            'customerId': CurrentUser.customerID.toString(),
          },
        );

    final response = await http.get(
      uri,
      headers: {
        'accept': '*/*',
        'Authorization': 'Bearer ${CurrentUser.token}',
      },
    );

    if (response.statusCode == 200) {
      log(uri.toString(), name: EndPoint.getCustomer); // ✅ fixed
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList
          .map((e) => CustomerModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      log(
        'Status: ${response.statusCode} | Body: ${response.body}',
        name: EndPoint.getCustomer,
      );
      throw Exception(
        'Failed to load customers. Status: ${response.statusCode}',
      );
    }
  }
}
