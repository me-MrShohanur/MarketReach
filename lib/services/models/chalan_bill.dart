class ChallanBill {
  final int challanId;
  final String orderNo;
  final String orderDate;
  final int compId;
  final int untitQty;
  final int deliverdQty;

  ChallanBill({
    required this.challanId,
    required this.orderNo,
    required this.orderDate,
    required this.compId,
    required this.untitQty,
    required this.deliverdQty,
  });

  factory ChallanBill.fromJson(Map<String, dynamic> json) {
    return ChallanBill(
      challanId: json['challanId'],
      orderNo: json['orderNo'],
      orderDate: json['orderDate'],
      compId: json['compId'],
      untitQty: json['untitQty'],
      deliverdQty: json['deliverdQty'],
    );
  }
}
