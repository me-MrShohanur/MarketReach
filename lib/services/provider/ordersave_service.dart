// lib/services/provider/ordersave_service.dart

import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:marketing/constants/api_values.dart';
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
  static const _encoder = JsonEncoder.withIndent('  ');

  static void _log(String msg, {String name = 'OrderSave'}) =>
      dev.log(msg, name: name, level: 800);

  // Pretty-prints any Map or List as indented JSON in a single log entry
  static void _logJson(String label, Object json, {String name = 'OrderSave'}) {
    final pretty = _encoder.convert(json);
    dev.log('\n$label\n$pretty', name: name, level: 800);
  }

  static Future<OrderSaveResponse> saveOrder({
    required int partyId,
    required List<ProductModel> cart,
    required double discount,
    required double tax,
    List<File>? files,
    DateTime? chequeDate,
    String? shippingAddress,
    String? shippingContact,
  }) async {
    // ── Dates ─────────────────────────────────────────────────────────────
    final now = DateTime.now();
    final String orderDate = _formatDate(now);
    final String chequeDateValue = chequeDate != null
        ? _formatDate(chequeDate)
        : _formatDate(now);

    // ── Totals ────────────────────────────────────────────────────────────
    final double subtotal = cart.fold(0.0, (s, p) => s + p.cartNetAmount);
    final double netAmount = subtotal - discount;
    final double vatAmount = tax;
    final double netPayable = netAmount + vatAmount;

    // ── Master ────────────────────────────────────────────────────────────
    final Map<String, dynamic> master = {
      'partyId': partyId,
      'compId': CurrentUser.compId,
      'branchId': CurrentUser.branchId,
      'userId': CurrentUser.userId,
      'orderType': 7,
      'orderDate': orderDate,
      'chequeDate': chequeDateValue,
      'orderId': 0,
      'quoteId': 0,
      'status': 0,
      'netAmount': netAmount,
      'netPayable': netPayable,
      'discountAmount': discount,
      'discountRate': 0,
      'vatAmount': vatAmount,
      'vatRate': 0,
      'paidAmount': 0,
      'deposite': 0,
      'percentAmount': 0,
      'bankId': 0,
      'currencyId': 0,
      'currencyRate': 0,
      'otherAddition': 0,
      'otherDeduction': 0,
      'orderNo': '',
      'refNo': '',
      'narration': '',
      'paymentType': '',
      'billTo': '',
      'billAddress': '',
      'billContactNo': '',
      'billEmail': '',
      'billTerms': '',
      'shippingAddress':
          (shippingAddress == null || shippingAddress.trim().isEmpty)
          ? ''
          : shippingAddress.trim(),
      'shippingContract':
          (shippingContact == null || shippingContact.trim().isEmpty)
          ? ''
          : shippingContact.trim(),
      'shippingEmail': '',
      'shippingContractName': '',
      'city': '',
      'postalCode': '',
      'checkedNarration': '',
      'verifiedNarration': '',
      'rejectedNarration': '',
      'managementNarration': '',
    };

    // ── Details ───────────────────────────────────────────────────────────
    final List<Map<String, dynamic>> details = cart
        .map((p) => _buildDetail(p))
        .toList();

    // ── Full body ─────────────────────────────────────────────────────────
    final Map<String, dynamic> body = {'master': master, 'details': details};

    final uri = Uri.parse('${BaseUrl.apiBase}/api/${V.v1}/${EndPoint.save}');
    final String jsonBody = jsonEncode(body); // compact — for the HTTP call

    // ═══════════════════════════════════════════════════════════════════════
    // PRETTY REQUEST LOG
    // ═══════════════════════════════════════════════════════════════════════
    _log('');
    _log('╔════════════════════════════════════════╗');
    _log('║        ORDER SAVE ▶ REQUEST             ║');
    _log('╚════════════════════════════════════════╝');
    _log('URL   : $uri');
    _log('Token : Bearer ${CurrentUser.token}');
    _log('');

    // Master — pretty JSON
    _logJson('━━━ MASTER ━━━', master, name: 'OrderSave.master');

    // Each detail item — pretty JSON individually so it's easy to read
    for (int i = 0; i < details.length; i++) {
      _logJson(
        '━━━ DETAIL [${i + 1} / ${details.length}] ━━━',
        details[i],
        name: 'OrderSave.detail',
      );
    }

    // Full body — pretty JSON in one shot (paste into Postman to verify)
    _logJson(
      '━━━ FULL BODY (copy → Postman) ━━━',
      body,
      name: 'OrderSave.body',
    );

    _log('════════════════════════════════════════');

    try {
      final response = await http
          .post(
            uri,
            headers: {
              'accept': '*/*',
              'Authorization': 'Bearer ${CurrentUser.token}',
              'Content-Type': 'application/json',
            },
            body: jsonBody,
          )
          .timeout(const Duration(seconds: 30));

      // ── Pretty response log ────────────────────────────────────────────
      _log('');
      _log('╔════════════════════════════════════════╗');
      _log('║        ORDER SAVE ▶ RESPONSE            ║');
      _log('╚════════════════════════════════════════╝');
      _log('Status : ${response.statusCode}');

      // Try to pretty-print the response if it's valid JSON
      try {
        final decoded = jsonDecode(response.body);
        _logJson('━━━ RESPONSE BODY ━━━', decoded, name: 'OrderSave.response');
      } catch (_) {
        // Not JSON — log raw
        _log('Body   : ${response.body}', name: 'OrderSave.response');
      }

      _log('════════════════════════════════════════');

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
        try {
          final err = jsonDecode(response.body) as Map<String, dynamic>;
          final errors = err['errors'] as Map<String, dynamic>?;
          if (errors != null && errors.isNotEmpty) {
            final msgs = errors.entries
                .map((e) => '${e.key}: ${(e.value as List).first}')
                .join('\n');
            throw OrderSaveException(msgs);
          }
          final title = err['title'] as String?;
          if (title != null) throw OrderSaveException(title);
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

  // ── Date formatter: DateTime → "yyyyMMdd" ─────────────────────────────────
  static String _formatDate(DateTime d) {
    final y = d.year.toString();
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y$m$day';
  }

  // ── Build a single detail row ─────────────────────────────────────────────
  static Map<String, dynamic> _buildDetail(ProductModel p) => {
    'id': p.productId,
    'orderId': 0,
    'productId': p.productId,
    'productDesc': p.name,
    'productTypeId': 0,
    'unitId': 0,
    'sizeId': 0,
    'rdId': 0,
    'unitQty': p.cartQty,
    'pcsQty': p.cartQty,
    'tQty': (p.cartQty * p.factor).toInt(),
    'uniqueQty': p.cartQty,
    'unitPrice': p.cartRate,
    'uniquePrice': p.cartRate,
    'discount': p.cartDiscount.toInt(),
    'discountAmt': p.cartDiscountAmt,
    'netAmount': p.cartNetAmount,
    'vat': 0,
    'forfeiture': 0,
    'factor': p.factor,
    'boxConv': 0,
    'orderType': 7,
    'compId': CurrentUser.compId,
    'branchId': CurrentUser.branchId,
    'custRef': '',
    'remarks': p.cartNotes.isEmpty ? '' : p.cartNotes,
  };
}

//-----------------

// import 'dart:convert';
// import 'dart:developer';
// import 'dart:io';
// import 'package:http/http.dart' as http;
// import 'package:marketing/constants/api_values.dart';
// import 'package:marketing/services/models/products_model.dart';
// import 'package:marketing/services/provider/current_user.dart';

// class OrderSaveResponse {
//   final bool status;
//   final int orderId;
//   final String result;

//   OrderSaveResponse({
//     required this.status,
//     required this.orderId,
//     required this.result,
//   });

//   factory OrderSaveResponse.fromJson(Map<String, dynamic> json) {
//     return OrderSaveResponse(
//       status: json['status'] ?? false,
//       orderId: json['orderId'] ?? 0,
//       result: json['result'] ?? '',
//     );
//   }
// }

// class OrderSaveException implements Exception {
//   final String message;
//   OrderSaveException(this.message);
//   @override
//   String toString() => message;
// }

// class OrderSaveService {
//   static Future<OrderSaveResponse> saveOrder({
//     required int partyId,
//     required List<ProductModel> cart,
//     required double discount,
//     required double tax,
//     List<File>? files,
//     DateTime? chequeDate,
//     String? shippingAddress,
//     String? shippingContact,
//   }) async {
//     final now = DateTime.now();
//     final orderDate =
//         '${now.year}'
//         '${now.month.toString().padLeft(2, '0')}'
//         '${now.day.toString().padLeft(2, '0')}';

//     final double subtotal = cart.fold(0, (s, p) => s + p.cartNetAmount);
//     final double netAmount = subtotal - discount;
//     final double vatAmount = tax;
//     final double netPayable = netAmount + vatAmount;

//     // Format cheque date — default to today if not provided
//     final String chequeDateValue = chequeDate != null
//         ? '${chequeDate.year}${chequeDate.month.toString().padLeft(2, '0')}${chequeDate.day.toString().padLeft(2, '0')}'
//         : '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';

//     final uri = Uri.parse('${BaseUrl.apiBase}/api/${V.v1}/${EndPoint.save}');
//     final request = http.MultipartRequest('POST', uri);

//     request.headers['accept'] = '*/*';
//     request.headers['Authorization'] = 'Bearer ${CurrentUser.token}';

//     // ── Master fields ─────────────────────────────────────────────────────
//     request.fields.addAll({
//       'Master.OrderType': '7',
//       'Master.OrderId': '0',
//       'Master.Status': '0',
//       'Master.CompId': CurrentUser.compId.toString(),
//       'Master.BranchId': CurrentUser.branchId.toString(),
//       'Master.UserId': CurrentUser.userId.toString(),
//       'Master.PartyId': partyId.toString(),
//       'Master.OrderDate': orderDate,
//       'Master.NetAmount': netAmount.toStringAsFixed(2),
//       'Master.NetPayable': netPayable.toStringAsFixed(2),
//       'Master.DiscountAmount': discount.toStringAsFixed(2),
//       'Master.VatAmount': vatAmount.toStringAsFixed(2),
//       'Master.DiscountRate': '0',
//       'Master.VatRate': '0',
//       'Master.PaidAmount': '0',
//       'Master.Deposite': '0',
//       'Master.PaymentType': 'string',
//       'Master.BankId': '0',
//       'Master.CurrencyId': '0',
//       'Master.CurrencyRate': '0',
//       'Master.PercentAmount': '0',
//       'Master.OtherAddition': '0',
//       'Master.OtherDeduction': '0',
//       'Master.QuoteId': '0',
//       'Master.OrderNo': 'string',
//       'Master.RefNo': 'string',
//       'Master.Narration': 'string',
//       'Master.BillTo': 'string',
//       'Master.BillAddress': 'string',
//       'Master.BillContactNo': 'string',
//       'Master.BillEmail': 'string',
//       'Master.BillTerms': 'string',
//       'Master.ShippingAddress':
//           (shippingAddress == null || shippingAddress.trim().isEmpty)
//           ? 'string'
//           : shippingAddress,
//       'Master.ShippingEmail': 'string',
//       'Master.ShippingContract':
//           (shippingContact == null || shippingContact.trim().isEmpty)
//           ? 'string'
//           : shippingContact,
//       'Master.ShippingContractName': 'string',
//       'Master.City': 'string',
//       'Master.PostalCode': 'string',
//       'Master.ChequeDate': chequeDateValue,
//       'Master.CheckedNarration': 'string',
//       'Master.VerifiedNarration': 'string',
//       'Master.RejectedNarration': 'string',
//       'Master.ManagementNarration': 'string',
//     });
