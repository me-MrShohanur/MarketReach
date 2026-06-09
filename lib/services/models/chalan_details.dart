// ════════════════════════════════════════════════════════════════════════════
// MODEL
// lib/services/models/challan_details_model.dart
// ════════════════════════════════════════════════════════════════════════════

class ChallanDetailsModel {
  final String orderNo;
  final int partyId;
  final int compId;
  final int challanId;
  final int challanNo;
  final String challanType;
  final String challanDate;
  final String? deliveryLocation;
  final String? driverName;
  final String? driverContactNo;
  final String billTo;
  final String? transPortName;
  final List<ChallanDetailItem> details;

  ChallanDetailsModel({
    required this.orderNo,
    required this.partyId,
    required this.compId,
    required this.challanId,
    required this.challanNo,
    required this.challanType,
    required this.challanDate,
    this.deliveryLocation,
    this.driverName,
    this.driverContactNo,
    required this.billTo,
    this.transPortName,
    required this.details,
  });

  /// Parses directly from the full API response body:
  /// { "result": { "result": [ {...} ] } }
  factory ChallanDetailsModel.fromApiResponse(
    Map<String, dynamic> apiResponse,
  ) {
    final outer = apiResponse['result'];
    final list = outer['result'] as List;
    final json = list.first as Map<String, dynamic>;
    return ChallanDetailsModel.fromJson(json);
  }

  factory ChallanDetailsModel.fromJson(Map<String, dynamic> json) {
    final rawDetails = json['details'];
    final List<ChallanDetailItem> detailList = rawDetails is List
        ? rawDetails
              .whereType<Map<String, dynamic>>()
              .map(ChallanDetailItem.fromJson)
              .toList()
        : [];

    return ChallanDetailsModel(
      orderNo: json['orderNo']?.toString() ?? '',
      partyId: (json['partyId'] is num) ? (json['partyId'] as num).toInt() : 0,
      compId: (json['compId'] is num) ? (json['compId'] as num).toInt() : 0,
      challanId: (json['challanId'] is num)
          ? (json['challanId'] as num).toInt()
          : 0,
      challanNo: (json['challanNo'] is num)
          ? (json['challanNo'] as num).toInt()
          : 0,
      challanType: json['challanType']?.toString() ?? '',
      challanDate: json['challanDate']?.toString() ?? '',
      deliveryLocation: json['deliveryLocation']?.toString(),
      driverName: json['driverName']?.toString(),
      driverContactNo: json['driverContactNo']?.toString(),
      billTo: json['billTo']?.toString() ?? '',
      transPortName: json['transPortName']?.toString(),
      details: detailList,
    );
  }
}

class ChallanDetailItem {
  final int productId;
  final String name;
  final String description;
  final int unitQty;
  final double unitPrice;
  final int autoChallanId;
  final String
  remarks; // API sends "remarks" (response) but writes back as "remarts" (API typo)
  final int returnQty;
  final int isApproved; // ← NEW

  ChallanDetailItem({
    required this.productId,
    required this.name,
    required this.description,
    required this.unitQty,
    required this.unitPrice,
    required this.autoChallanId,
    required this.remarks,
    required this.returnQty,
    required this.isApproved,
  });

  factory ChallanDetailItem.fromJson(Map<String, dynamic> json) {
    return ChallanDetailItem(
      productId: (json['productId'] is num)
          ? (json['productId'] as num).toInt()
          : 0,
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      unitQty: (json['unitQty'] is num) ? (json['unitQty'] as num).toInt() : 0,
      unitPrice: (json['unitPrice'] is num)
          ? (json['unitPrice'] as num).toDouble()
          : 0.0,
      autoChallanId: (json['autoChallanID'] is num)
          ? (json['autoChallanID'] as num).toInt()
          : 0,
      // Response uses "remarks", but falls back to "remarts" if server ever
      // returns the typo'd key — whichever is non-null wins.
      remarks: (json['remarks'] ?? json['remarts'])?.toString() ?? '',
      returnQty: (json['returnQty'] is num)
          ? (json['returnQty'] as num).toInt()
          : 0,
      isApproved:
          (json['isApproved'] is num) // ← NEW
          ? (json['isApproved'] as num).toInt()
          : 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'name': name,
    'description': description,
    'unitQty': unitQty,
    'unitPrice': unitPrice,
    'autoChallanID': autoChallanId,
    'remarts': remarks, // keep API typo for write-back
    'returnQty': returnQty,
    'isApproved': isApproved,
  };
}

// // ════════════════════════════════════════════════════════════════════════════
// // MODEL
// // lib/services/models/challan_details_model.dart
// // ════════════════════════════════════════════════════════════════════════════

// class ChallanDetailsModel {
//   final String orderNo;
//   final int partyId;
//   final int compId;
//   final int challanId;
//   final int challanNo;
//   final String challanType;
//   final String challanDate;
//   final String? deliveryLocation;
//   final String? driverName;
//   final String? driverContactNo;
//   final String billTo;
//   final String? transPortName;
//   final List<ChallanDetailItem> details;

//   ChallanDetailsModel({
//     required this.orderNo,
//     required this.partyId,
//     required this.compId,
//     required this.challanId,
//     required this.challanNo,
//     required this.challanType,
//     required this.challanDate,
//     this.deliveryLocation,
//     this.driverName,
//     this.driverContactNo,
//     required this.billTo,
//     this.transPortName,
//     required this.details,
//   });

//   factory ChallanDetailsModel.fromJson(Map<String, dynamic> json) {
//     final rawDetails = json['details'];
//     final List<ChallanDetailItem> detailList = rawDetails is List
//         ? rawDetails
//               .whereType<Map<String, dynamic>>()
//               .map(ChallanDetailItem.fromJson)
//               .toList()
//         : [];

//     return ChallanDetailsModel(
//       orderNo: json['orderNo']?.toString() ?? '',
//       partyId: (json['partyId'] is num) ? (json['partyId'] as num).toInt() : 0,
//       compId: (json['compId'] is num) ? (json['compId'] as num).toInt() : 0,
//       challanId: (json['challanId'] is num)
//           ? (json['challanId'] as num).toInt()
//           : 0,
//       challanNo: (json['challanNo'] is num)
//           ? (json['challanNo'] as num).toInt()
//           : 0,
//       challanType: json['challanType']?.toString() ?? '',
//       challanDate: json['challanDate']?.toString() ?? '',
//       deliveryLocation: json['deliveryLocation']?.toString(),
//       driverName: json['driverName']?.toString(),
//       driverContactNo: json['driverContactNo']?.toString(),
//       billTo: json['billTo']?.toString() ?? '',
//       transPortName: json['transPortName']?.toString(),
//       details: detailList,
//     );
//   }
// }

// class ChallanDetailItem {
//   final int productId;
//   final String name;
//   final String description;
//   final int unitQty;
//   final double unitPrice;
//   final int autoChallanId;
//   final String remarks;
//   final int returnQty;

//   ChallanDetailItem({
//     required this.productId,
//     required this.name,
//     required this.description,
//     required this.unitQty,
//     required this.unitPrice,
//     required this.autoChallanId,
//     required this.remarks,
//     required this.returnQty,
//   });

//   factory ChallanDetailItem.fromJson(Map<String, dynamic> json) {
//     return ChallanDetailItem(
//       productId: (json['productId'] is num)
//           ? (json['productId'] as num).toInt()
//           : 0,
//       name: json['name']?.toString() ?? '',
//       description: json['description']?.toString() ?? '',
//       unitQty: (json['unitQty'] is num) ? (json['unitQty'] as num).toInt() : 0,
//       unitPrice: (json['unitPrice'] is num)
//           ? (json['unitPrice'] as num).toDouble()
//           : 0.0,
//       autoChallanId: (json['autoChallanID'] is num)
//           ? (json['autoChallanID'] as num).toInt()
//           : 0,
//       remarks: json['remarts']?.toString() ?? '', // API typo: "remarts"
//       returnQty: (json['returnQty'] is num)
//           ? (json['returnQty'] as num).toInt()
//           : 0,
//     );
//   }

//   Map<String, dynamic> toJson() => {
//     'productId': productId,
//     'name': name,
//     'description': description,
//     'unitQty': unitQty,
//     'unitPrice': unitPrice,
//     'autoChallanID': autoChallanId,
//     'remarts': remarks, // keep API typo for write-back
//     'returnQty': returnQty,
//   };
// }
