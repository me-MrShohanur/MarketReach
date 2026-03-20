import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:marketing/services/models/products_model.dart';
import 'package:marketing/services/provider/current_user.dart';

// ─── Response Model ───────────────────────────────────────────────────────────

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

// ─── Exception ────────────────────────────────────────────────────────────────

class OrderSaveException implements Exception {
  final String message;
  OrderSaveException(this.message);
  @override
  String toString() => message;
}

// ─── Service ──────────────────────────────────────────────────────────────────

class OrderSaveService {
  static const _baseUrl = 'http://103.125.253.59:1122/api/v1';

  // Placeholder for required string fields that have no UI yet
  // The server rejects empty string '' but accepts any non-empty value
  static const _na = 'N/A';
  static const _zero = '0';

  static Future<OrderSaveResponse> saveOrder({
    required int partyId,
    required List<ProductModel> cart,
    required double discount,
    required double tax,
  }) async {
    // ── Date: "20260320" ──────────────────────────────────────────────────
    final now = DateTime.now();
    final orderDate =
        '${now.year}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}';

    // ── Totals ────────────────────────────────────────────────────────────
    final double subtotal = cart.fold(0, (s, p) => s + p.cartNetAmount);
    final double netAmount = subtotal - discount;
    final double vatAmount = tax;
    final double netPayable = netAmount + vatAmount;

    final boundary =
        '----FlutterBoundary${DateTime.now().millisecondsSinceEpoch}';
    final uri = Uri.parse('$_baseUrl/Order/Save');

    final request = http.Request('POST', uri);
    request.headers['accept'] = '*/*';
    request.headers['Authorization'] = 'Bearer ${CurrentUser.token}';
    request.headers['Content-Type'] = 'multipart/form-data; boundary=$boundary';

    final body = StringBuffer();

    void add(String name, String value) {
      body.write('--$boundary\r\n');
      body.write('Content-Disposition: form-data; name="$name"\r\n');
      body.write('\r\n');
      body.write('$value\r\n');
    }

    // ── Fixed ─────────────────────────────────────────────────────────────
    add('Master.OrderType', '7');
    add('Master.OrderId', '0');
    add('Master.Status', '0');

    // ── From CurrentUser ──────────────────────────────────────────────────
    add('Master.CompId', CurrentUser.compId.toString());
    add('Master.BranchId', CurrentUser.branchId.toString());
    add('Master.UserId', CurrentUser.userId.toString());

    // ── From customer selection ───────────────────────────────────────────
    add('Master.PartyId', partyId.toString());

    // ── Date ──────────────────────────────────────────────────────────────
    add('Master.OrderDate', orderDate);

    // ── Calculated totals ─────────────────────────────────────────────────
    add('Master.NetAmount', netAmount.toStringAsFixed(2));
    add('Master.NetPayable', netPayable.toStringAsFixed(2));
    add('Master.DiscountAmount', discount.toStringAsFixed(2));
    add('Master.VatAmount', vatAmount.toStringAsFixed(2));
    add('Master.DiscountRate', _zero);
    add('Master.VatRate', _zero);

    // ── Payment ───────────────────────────────────────────────────────────
    add('Master.PaidAmount', _zero);
    add('Master.Deposite', _zero);
    add('Master.PaymentType', 'Cash');
    add('Master.BankId', _zero);
    add('Master.CurrencyId', '1');
    add('Master.CurrencyRate', '1');
    add('Master.PercentAmount', _zero);
    add('Master.OtherAddition', _zero);
    add('Master.OtherDeduction', _zero);
    add('Master.QuoteId', _zero);

    // ── Required string fields — server rejects empty string ─────────────
    // All fields below showed up in the validation error list.
    // Using 'N/A' as placeholder until you add UI fields for them.
    add('Master.OrderNo', _na);
    add('Master.RefNo', _na);
    add('Master.Narration', _na);
    add('Master.BillTo', _na);
    add('Master.BillAddress', _na);
    add('Master.BillContactNo', _na);
    add('Master.BillEmail', _na);
    add('Master.BillTerms', _na);
    add('Master.ShippingAddress', _na);
    add('Master.ShippingEmail', _na);
    add('Master.ShippingContract', _na);
    add('Master.ShippingContractName', _na);
    add('Master.City', _na);
    add('Master.PostalCode', _na);
    add('Master.CheckedNarration', _na);
    add('Master.VerifiedNarration', _na);
    add('Master.RejectedNarration', _na);
    add('Master.ManagementNarration', _na);

    // ── Details — one field per product (repeated same key) ───────────────
    for (final product in cart) {
      add('Details', jsonEncode(_buildDetail(product)));
    }

    // ── Close ─────────────────────────────────────────────────────────────
    body.write('--$boundary--\r\n');
    request.body = body.toString();

    log('=== ORDER SAVE ===', name: 'OrderSave');
    log('Date    : $orderDate', name: 'OrderSave');
    log('PartyId : $partyId', name: 'OrderSave');
    log('Items   : ${cart.length}', name: 'OrderSave');
    log('Net     : $netAmount', name: 'OrderSave');

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
        // Parse validation errors into a readable message
        try {
          final errJson = jsonDecode(response.body);
          final errors = errJson['errors'] as Map<String, dynamic>?;
          if (errors != null && errors.isNotEmpty) {
            final firstKey = errors.keys.first;
            final firstMsg = (errors[firstKey] as List).first.toString();
            throw OrderSaveException('$firstKey: $firstMsg');
          }
        } catch (parseErr) {
          if (parseErr is OrderSaveException) rethrow;
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
      'custRef': _na,
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
      'remarks': p.cartNotes.isEmpty ? _na : p.cartNotes,
    };
  }
}
