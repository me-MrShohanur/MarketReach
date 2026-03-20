import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:marketing/services/models/products_model.dart';
import 'package:marketing/services/provider/current_user.dart';

class OrderSaveResponse {
  final bool status;
  final int orderId;
  final String result;

  OrderSaveResponse({
    required this.status,
    required this.orderId,
    required this.result,
  });

  factory OrderSaveResponse.fromJson(Map<String, dynamic> json) {
    return OrderSaveResponse(
      status: json['status'] ?? false,
      orderId: json['orderId'] ?? 0,
      result: json['result'] ?? '',
    );
  }
}

class OrderSaveException implements Exception {
  final String message;
  OrderSaveException(this.message);
  @override
  String toString() => message;
}

class OrderSaveService {
  static const _baseUrl = 'http://103.125.253.59:1122/api/v1';

  static Future<OrderSaveResponse> saveOrder({
    required int partyId,
    required List<ProductModel> cart,
    required double discount,
    required double tax,
    List<File>? files, // ← optional order-level attachments
  }) async {
    final now = DateTime.now();
    final orderDate =
        '${now.year}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}';

    final double subtotal = cart.fold(0, (s, p) => s + p.cartNetAmount);
    final double netAmount = subtotal - discount;
    final double vatAmount = tax;
    final double netPayable = netAmount + vatAmount;

    final uri = Uri.parse('$_baseUrl/Order/Save');
    final request = http.MultipartRequest('POST', uri);

    request.headers['accept'] = '*/*';
    request.headers['Authorization'] = 'Bearer ${CurrentUser.token}';

    request.fields.addAll({
      'Master.OrderType': '7',
      'Master.OrderId': '0',
      'Master.Status': '0',
      'Master.CompId': CurrentUser.compId.toString(),
      'Master.BranchId': CurrentUser.branchId.toString(),
      'Master.UserId': CurrentUser.userId.toString(),
      'Master.PartyId': partyId.toString(),
      'Master.OrderDate': orderDate,
      'Master.NetAmount': netAmount.toStringAsFixed(2),
      'Master.NetPayable': netPayable.toStringAsFixed(2),
      'Master.DiscountAmount': discount.toStringAsFixed(2),
      'Master.VatAmount': vatAmount.toStringAsFixed(2),
      'Master.DiscountRate': '0',
      'Master.VatRate': '0',
      'Master.PaidAmount': '0',
      'Master.Deposite': '0',
      'Master.PaymentType': 'string',
      'Master.BankId': '0',
      'Master.CurrencyId': '0',
      'Master.CurrencyRate': '0',
      'Master.PercentAmount': '0',
      'Master.OtherAddition': '0',
      'Master.OtherDeduction': '0',
      'Master.QuoteId': '0',
      'Master.OrderNo': 'string',
      'Master.RefNo': 'string',
      'Master.Narration': 'string',
      'Master.BillTo': 'string',
      'Master.BillAddress': 'string',
      'Master.BillContactNo': 'string',
      'Master.BillEmail': 'string',
      'Master.BillTerms': 'string',
      'Master.ShippingAddress': 'string',
      'Master.ShippingEmail': 'string',
      'Master.ShippingContract': 'string',
      'Master.ShippingContractName': 'string',
      'Master.City': 'string',
      'Master.PostalCode': 'string',
      'Master.CheckedNarration': 'string',
      'Master.VerifiedNarration': 'string',
      'Master.RejectedNarration': 'string',
      'Master.ManagementNarration': 'string',
    });

    // ── Details — one field per product ───────────────────────────────────
    for (final product in cart) {
      request.files.add(
        http.MultipartFile.fromString(
          'Details',
          jsonEncode(_buildDetail(product)),
        ),
      );
    }

    // ── Files — one field per attachment ──────────────────────────────────
    // Each file uses field name "formFiles" — same key repeated per file.
    // Mirrors: -F 'formFiles=@photo1.jpg' -F 'formFiles=@photo2.jpg'
    if (files != null && files.isNotEmpty) {
      for (final file in files) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'formFiles', // field name — repeated per file
            file.path, // actual file path
          ),
        );
      }
      log('Attaching ${files.length} file(s)', name: 'OrderSave');
    }

    log('=== ORDER SAVE ===', name: 'OrderSave');
    log('PartyId : $partyId', name: 'OrderSave');
    log('Date    : $orderDate', name: 'OrderSave');
    log('Items   : ${cart.length}', name: 'OrderSave');
    log('Files   : ${files?.length ?? 0}', name: 'OrderSave');

    try {
      final streamed = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final response = await http.Response.fromStream(streamed);

      log('Status : ${response.statusCode}', name: 'OrderSave');
      log('Body   : ${response.body}', name: 'OrderSave');

      if (response.statusCode == 200) {
        final jsonMap = jsonDecode(response.body) as Map<String, dynamic>;
        final result = OrderSaveResponse.fromJson(jsonMap);
        if (!result.status) {
          throw OrderSaveException(
            result.result.isNotEmpty ? result.result : 'Order save failed.',
          );
        }
        return result;
      } else if (response.statusCode == 400) {
        log('400 body: ${response.body}', name: 'OrderSave.ERROR');
        try {
          final err = jsonDecode(response.body);
          final errors = err['errors'] as Map<String, dynamic>?;
          if (errors != null && errors.isNotEmpty) {
            final msgs = errors.entries
                .map((e) => '${e.key}: ${(e.value as List).first}')
                .join('\n');
            throw OrderSaveException(msgs);
          }
        } catch (e) {
          if (e is OrderSaveException) rethrow;
        }
        throw OrderSaveException('Validation error: ${response.body}');
      } else if (response.statusCode == 401) {
        throw OrderSaveException('Session expired. Please login again.');
      } else {
        throw OrderSaveException(
          'Server error ${response.statusCode}: ${response.body}',
        );
      }
    } on OrderSaveException {
      rethrow;
    } catch (e) {
      throw OrderSaveException('Network error: $e');
    }
  }

  static Map<String, dynamic> _buildDetail(ProductModel p) {
    return {
      'productId': p.productId,
      'productTypeId': 0,
      'productDesc': p.name,
      'custRef': 'string',
      'unitQty': p.cartQty,
      'tQty': p.cartQty * p.factor,
      'pcsQty': p.cartQty,
      'uniqueQty': p.cartQty,
      'unitPrice': p.cartRate,
      'uniquePrice': p.cartRate,
      'discount': 0,
      'discountAmt': p.cartDiscount,
      'netAmount': p.cartNetAmount,
      'vat': 0,
      'forfeiture': 0,
      'unitId': 0,
      'sizeId': 0,
      'rdId': 0,
      'factor': p.factor,
      'boxConv': 0,
      'orderId': 0,
      'orderType': 7,
      'compId': CurrentUser.compId,
      'branchId': CurrentUser.branchId,
      'id': 0,
      'remarks': p.cartNotes.isEmpty ? 'string' : p.cartNotes,
    };
  }
}
