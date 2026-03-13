import 'package:marketing/services/auth_service.dart';
import 'package:marketing/services/models/auth_model.dart';

class CurrentUser {
  CurrentUser._();

  static AuthUser? _user;

  static Future<void> load() async {
    _user = await AuthService().getUser();
  }

  static void clear() {
    _user = null;
  }

  static int get userId => _user?.userId ?? 0;
  static String get userName => _user?.userName ?? '';
  static String get password => _user?.password ?? '';
  static int get userTypeId => _user?.userTypeId ?? 0;
  static String get userTypeName => _user?.userTypeName ?? '';
  static String get memberName => _user?.memberName ?? '';
  static int get empId => _user?.empId ?? 0;
  static bool get isActive => _user?.isActive ?? false;
  static int get clientId => _user?.clientId ?? 0;
  static bool? get isHaveSms => _user?.isHaveSms;
  static String get clientName => _user?.clientName ?? '';
  static int get compId => _user?.compId ?? 0;
  static String get companyName => _user?.companyName ?? '';
  static int get branchId => _user?.branchId ?? 0;
  static String get branchName => _user?.branchName ?? '';
  static String get createdDate => _user?.createdDate ?? '';
  static int get createdBy => _user?.createdBy ?? 0;
  static String? get creatorName => _user?.creatorName;
  static String? get modifiedDate => _user?.modifiedDate;
  static int get modifiedBy => _user?.modifiedBy ?? 0;
  static String? get modifierName => _user?.modifierName;
  static int get userRole => _user?.userRole ?? 0;
  static int get customerID => _user?.customerID ?? 0;
  static String get token => _user?.token ?? '';
}
