class ChallanDetailsResponse {
  final ResultData result;
  final int id;
  final dynamic exception;
  final int status;
  final bool isCanceled;
  final bool isCompleted;
  final bool isCompletedSuccessfully;
  final int creationOptions;
  final dynamic asyncState;
  final bool isFaulted;

  ChallanDetailsResponse({
    required this.result,
    required this.id,
    this.exception,
    required this.status,
    required this.isCanceled,
    required this.isCompleted,
    required this.isCompletedSuccessfully,
    required this.creationOptions,
    this.asyncState,
    required this.isFaulted,
  });

  factory ChallanDetailsResponse.fromJson(Map<String, dynamic> json) {
    return ChallanDetailsResponse(
      result: ResultData.fromJson(json['result']),
      id: json['id'],
      exception: json['exception'],
      status: json['status'],
      isCanceled: json['isCanceled'],
      isCompleted: json['isCompleted'],
      isCompletedSuccessfully: json['isCompletedSuccessfully'],
      creationOptions: json['creationOptions'],
      asyncState: json['asyncState'],
      isFaulted: json['isFaulted'],
    );
  }
}

class ResultData {
  final List<ChallanDetail> result;
  final int id;
  final dynamic exception;
  final int status;
  final bool isCanceled;
  final bool isCompleted;
  final bool isCompletedSuccessfully;
  final int creationOptions;
  final dynamic asyncState;
  final bool isFaulted;

  ResultData({
    required this.result,
    required this.id,
    this.exception,
    required this.status,
    required this.isCanceled,
    required this.isCompleted,
    required this.isCompletedSuccessfully,
    required this.creationOptions,
    this.asyncState,
    required this.isFaulted,
  });

  factory ResultData.fromJson(Map<String, dynamic> json) {
    return ResultData(
      result: (json['result'] as List)
          .map((e) => ChallanDetail.fromJson(e))
          .toList(),
      id: json['id'],
      exception: json['exception'],
      status: json['status'],
      isCanceled: json['isCanceled'],
      isCompleted: json['isCompleted'],
      isCompletedSuccessfully: json['isCompletedSuccessfully'],
      creationOptions: json['creationOptions'],
      asyncState: json['asyncState'],
      isFaulted: json['isFaulted'],
    );
  }
}

class ChallanDetail {
  final String orderNo;
  final int partyId;
  final int compId;
  final int challanId;
  final int challanNo;
  final String challanType;
  final String challanDate;
  final dynamic deliveryLocation;
  final dynamic driverName;
  final dynamic driverContactNo;
  final String billTo;
  final dynamic transportName;
  final List<ProductDetail> details;

  ChallanDetail({
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
    this.transportName,
    required this.details,
  });

  factory ChallanDetail.fromJson(Map<String, dynamic> json) {
    return ChallanDetail(
      orderNo: json['orderNo'] ?? '',
      partyId: json['partyId'],
      compId: json['compId'],
      challanId: json['challanId'],
      challanNo: json['challanNo'],
      challanType: json['challanType'] ?? '',
      challanDate: json['challanDate'] ?? '',
      deliveryLocation: json['deliveryLocation'],
      driverName: json['driverName'],
      driverContactNo: json['driverContactNo'],
      billTo: json['billTo'] ?? '',
      transportName: json['transPortName'],
      details: (json['details'] as List)
          .map((e) => ProductDetail.fromJson(e))
          .toList(),
    );
  }
}

class ProductDetail {
  final int productId;
  final String name;
  final String description;
  final int unitQty;
  final int unitPrice;
  final int autoChallanID;
  final String remarts;
  final int returnQty;

  ProductDetail({
    required this.productId,
    required this.name,
    required this.description,
    required this.unitQty,
    required this.unitPrice,
    required this.autoChallanID,
    required this.remarts,
    required this.returnQty,
  });

  factory ProductDetail.fromJson(Map<String, dynamic> json) {
    return ProductDetail(
      productId: json['productId'],
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      unitQty: json['unitQty'],
      unitPrice: json['unitPrice'],
      autoChallanID: json['autoChallanID'],
      remarts: json['remarts'] ?? '',
      returnQty: json['returnQty'],
    );
  }
}
