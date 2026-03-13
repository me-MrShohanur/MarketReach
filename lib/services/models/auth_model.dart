class AuthUser {
  final int userId;
  final String userName;
  final String password;
  final int userTypeId;
  final String userTypeName;
  final String memberName;
  final int empId;
  final bool isActive;
  final int clientId;
  final bool? isHaveSms;
  final String clientName;
  final int compId;
  final String companyName;
  final int branchId;
  final String branchName;
  final String createdDate;
  final int createdBy;
  final String? creatorName;
  final String? modifiedDate;
  final int modifiedBy;
  final String? modifierName;
  final int userRole;
  final int customerID;
  final String token;

  AuthUser({
    required this.userId,
    required this.userName,
    required this.password,
    required this.userTypeId,
    required this.userTypeName,
    required this.memberName,
    required this.empId,
    required this.isActive,
    required this.clientId,
    required this.isHaveSms,
    required this.clientName,
    required this.compId,
    required this.companyName,
    required this.branchId,
    required this.branchName,
    required this.createdDate,
    required this.createdBy,
    required this.creatorName,
    required this.modifiedDate,
    required this.modifiedBy,
    required this.modifierName,
    required this.userRole,
    required this.customerID,
    required this.token,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      userId: json['userId'] as int? ?? 0,
      userName: json['userName'] as String? ?? '',
      password: json['password'] as String? ?? '',
      userTypeId: json['userTypeId'] as int? ?? 0,
      userTypeName: json['userTypeName'] as String? ?? '',
      memberName: json['memberName'] as String? ?? '',
      empId: json['empId'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? false,
      clientId: json['clientId'] as int? ?? 0,
      isHaveSms: json['isHaveSms'] as bool?,
      clientName: json['clientName'] as String? ?? '',
      compId: json['compId'] as int? ?? 0,
      companyName: json['companyName'] as String? ?? '',
      branchId: json['branchId'] as int? ?? 0,
      branchName: json['branchName'] as String? ?? '',
      createdDate: json['createdDate'] as String? ?? '',
      createdBy: json['createdBy'] as int? ?? 0,
      creatorName: json['creatorName'] as String?,
      modifiedDate: json['modifiedDate'] as String?,
      modifiedBy: json['modifiedBy'] as int? ?? 0,
      modifierName: json['modifierName'] as String?,
      userRole: json['userRole'] as int? ?? 0,
      customerID: json['customerID'] as int? ?? 0,
      token: json['token'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'userName': userName,
    'password': password,
    'userTypeId': userTypeId,
    'userTypeName': userTypeName,
    'memberName': memberName,
    'empId': empId,
    'isActive': isActive,
    'clientId': clientId,
    'isHaveSms': isHaveSms,
    'clientName': clientName,
    'compId': compId,
    'companyName': companyName,
    'branchId': branchId,
    'branchName': branchName,
    'createdDate': createdDate,
    'createdBy': createdBy,
    'creatorName': creatorName,
    'modifiedDate': modifiedDate,
    'modifiedBy': modifiedBy,
    'modifierName': modifierName,
    'userRole': userRole,
    'customerID': customerID,
    'token': token,
  };
}
