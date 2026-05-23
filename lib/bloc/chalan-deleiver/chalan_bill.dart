import 'dart:developer' as dev;

class ChallanBill {
  final String orderNo;
  final String orderDate;
  final int challanId;
  final int untitQty;
  final int deliverdQty;

  ChallanBill({
    required this.orderNo,
    required this.orderDate,
    required this.challanId,
    required this.untitQty,
    required this.deliverdQty,
  });

  factory ChallanBill.fromJson(Map<String, dynamic> json) {
    // Log every key-value pair with its runtime type so we can see
    // exactly what the API is sending and fix mismatches immediately.
    dev.log('[ChallanBill] keys: ${json.keys.toList()}', name: 'ChallanBill');
    json.forEach(
      (k, v) => dev.log(
        '[ChallanBill]   $k = $v (${v.runtimeType})',
        name: 'ChallanBill',
      ),
    );

    return ChallanBill(
      // toString() handles int/double/null safely for string fields
      orderNo: json['orderNo']?.toString() ?? '',
      orderDate: json['orderDate']?.toString() ?? '',
      // num handles cases where the API sends a double like 1.0 instead of 1
      challanId: (json['challanId'] is num
          ? (json['challanId'] as num).toInt()
          : 0),
      untitQty: (json['untitQty'] is num
          ? (json['untitQty'] as num).toInt()
          : 0),
      deliverdQty: (json['deliverdQty'] is num
          ? (json['deliverdQty'] as num).toInt()
          : 0),
    );
  }

  Map<String, dynamic> toJson() => {
    'orderNo': orderNo,
    'orderDate': orderDate,
    'challanId': challanId,
    'untitQty': untitQty,
    'deliverdQty': deliverdQty,
  };
}
