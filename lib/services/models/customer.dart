class CustomerModel {
  final int accountId;
  final String accountName;
  final String aliasName;
  final String formattedName;
  final String? deliveryAddress;
  final int locationId;
  final String? locationName;
  final double openingBalance;
  final double creditLimit;
  final double pertyCurrentBalance;
  final int commissionTypeID;
  final String? commissionTypeName;
  final String? billContactNo;

  const CustomerModel({
    required this.accountId,
    required this.accountName,
    required this.aliasName,
    required this.formattedName,
    this.deliveryAddress,
    required this.locationId,
    this.locationName,
    required this.openingBalance,
    required this.creditLimit,
    required this.pertyCurrentBalance,
    required this.commissionTypeID,
    this.commissionTypeName,
    this.billContactNo,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      accountId: json['accountId'] as int,
      accountName: json['accountName'] as String,
      aliasName: json['aliasName'] as String,
      formattedName: json['formattedName'] as String,
      deliveryAddress: json['deliveryAddress'] as String?,
      locationId: json['locationId'] as int,
      locationName: json['locationName'] as String?,
      openingBalance: (json['openingBalance'] as num).toDouble(),
      creditLimit: (json['creditLimit'] as num).toDouble(),
      pertyCurrentBalance: (json['pertyCurrentBalance'] as num).toDouble(),
      commissionTypeID: json['commissionTypeID'] as int,
      commissionTypeName: json['commissionTypeName'] as String?,
      billContactNo: json['billContactNo'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'accountId': accountId,
    'accountName': accountName,
    'aliasName': aliasName,
    'formattedName': formattedName,
    'deliveryAddress': deliveryAddress,
    'locationId': locationId,
    'locationName': locationName,
    'openingBalance': openingBalance,
    'creditLimit': creditLimit,
    'pertyCurrentBalance': pertyCurrentBalance,
    'commissionTypeID': commissionTypeID,
    'commissionTypeName': commissionTypeName,
    'billContactNo': billContactNo,
  };
}
