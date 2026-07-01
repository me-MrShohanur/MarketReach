class ChallanBillModel {
  final int challanId;
  final int orderId;
  final String challanNo;
  final String orderNo;
  final String orderDate;
  final String challanDate;
  final int compId;
  final int partyId;
  final int untitQty;
  final int deliverdQty;

  ChallanBillModel({
    required this.challanId,
    required this.orderId,
    required this.challanNo,
    required this.orderNo,
    required this.orderDate,
    required this.challanDate,
    required this.compId,
    required this.partyId,
    required this.untitQty,
    required this.deliverdQty,
  });

  factory ChallanBillModel.fromJson(Map<String, dynamic> json) {
    return ChallanBillModel(
      challanId: json['challanId'] ?? 0,
      orderId: json['orderId'] ?? 0,
      challanNo: json['challanNo']?.toString() ?? '',
      orderNo: json['orderNo']?.toString() ?? '',
      orderDate: json['orderDate']?.toString() ?? '',
      challanDate: json['challanDate']?.toString() ?? '',
      compId: json['compId'] ?? 0,
      partyId: json['partyId'] ?? 0,
      untitQty: json['untitQty'] ?? 0,
      deliverdQty: json['deliverdQty'] ?? 0,
    );
  }
}
