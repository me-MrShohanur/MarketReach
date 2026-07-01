class PendingOrderDetailModel {
  final int orderId;
  final String orderNo;
  final String orderDate;
  final int compId;
  final int partyId;
  final String itemName;
  final String itemDescription;
  final double orderQty;
  final double delivaryQty;
  final double pendingQty;
  final double amt;
  final double netAmount;

  PendingOrderDetailModel({
    required this.orderId,
    required this.orderNo,
    required this.orderDate,
    required this.compId,
    required this.partyId,
    required this.itemName,
    required this.itemDescription,
    required this.orderQty,
    required this.delivaryQty,
    required this.pendingQty,
    required this.amt,
    required this.netAmount,
  });

  factory PendingOrderDetailModel.fromJson(Map<String, dynamic> json) {
    return PendingOrderDetailModel(
      orderId: json['orderId'] ?? 0,
      orderNo: json['orderNo']?.toString() ?? '',
      orderDate: json['orderDate']?.toString() ?? '',
      compId: json['compId'] ?? 0,
      partyId: json['partyId'] ?? 0,
      itemName: json['itemName']?.toString() ?? '',
      itemDescription: json['itemDescription']?.toString() ?? '',
      orderQty: (json['orderQty'] ?? 0).toDouble(),
      delivaryQty: (json['delivaryQty'] ?? 0).toDouble(),
      pendingQty: (json['pendingQty'] ?? 0).toDouble(),
      amt: (json['amt'] ?? 0).toDouble(),
      netAmount: (json['netAmount'] ?? 0).toDouble(),
    );
  }
}
