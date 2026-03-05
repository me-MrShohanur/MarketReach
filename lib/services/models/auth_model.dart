class AuthUser {
  final int userId;
  final String userName;
  final String memberName;
  final String userTypeName;
  final int compId;
  final String companyName;
  final int branchId;
  final String branchName;
  final int clientId;
  // Add more fields later if needed (languageCode, isActive, ...)

  AuthUser({
    required this.userId,
    required this.userName,
    required this.memberName,
    required this.userTypeName,
    required this.compId,
    required this.companyName,
    required this.branchId,
    required this.branchName,
    required this.clientId,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      userId: json['userId'] as int,
      userName: json['userName'] as String,
      memberName: json['memberName'] as String? ?? '',
      userTypeName: json['userTypeName'] as String? ?? 'Unknown',
      compId: json['compId'] as int? ?? 0,
      companyName: json['companyName'] as String? ?? '',
      branchId: json['branchId'] as int? ?? 0,
      branchName: json['branchName'] as String? ?? '',
      clientId: json['clientId'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'userName': userName,
    'memberName': memberName,
    'userTypeName': userTypeName,
    'compId': compId,
    'companyName': companyName,
    'branchId': branchId,
    'branchName': branchName,
    'clientId': clientId,
  };
}
