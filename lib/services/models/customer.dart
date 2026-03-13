class CustomerModel {
  int? accountId;
  String? accountName;
  String? aliasName;
  String? formattedName;
  String? deliveryAddress;
  int? locationId;
  String? locationName;
  double? openingBalance;
  int? creditLimit;
  int? pertyCurrentBalance;
  int? commissionTypeId;
  dynamic commissionTypeName;
  String? billContactNo;

  CustomerModel({
    this.accountId,
    this.accountName,
    this.aliasName,
    this.formattedName,
    this.deliveryAddress,
    this.locationId,
    this.locationName,
    this.openingBalance,
    this.creditLimit,
    this.pertyCurrentBalance,
    this.commissionTypeId,
    this.commissionTypeName,
    this.billContactNo,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      accountId: json['accountId'] as int?,
      accountName: json['accountName'] as String?,
      aliasName: json['aliasName'] as String?,
      formattedName: json['formattedName'] as String?,
      deliveryAddress: json['deliveryAddress'] as String?,
      locationId: json['locationId'] as int?,
      locationName: json['locationName'] as String?,
      openingBalance: (json['openingBalance'] as num?)?.toDouble(),
      creditLimit: json['creditLimit'] as int?,
      pertyCurrentBalance: json['pertyCurrentBalance'] as int?,
      commissionTypeId: json['commissionTypeId'] as int?,
      commissionTypeName: json['commissionTypeName'],
      billContactNo: json['billContactNo'] as String?,
    );
  }
}
