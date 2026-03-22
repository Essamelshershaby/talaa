// نوع من البيانات بيحددلي قيمه محدده 
enum UserRole {
  owner,      // المالك/المدير
  accountant, // المحاسب
  member,     // المهندسين والأعضاء
}
// هنا انا بدي لكل قيمه وظائف جديده 
extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.owner:
        return 'المالك / المدير العام';
      case UserRole.accountant:
        return 'المحاسب';
      case UserRole.member:
        return 'مهندس / عضو';
    }
  }
// هنا بحدد لكل صلاحيه رقم علشان اقدر اقارن بنهم
  int get level {
    switch (this) {
      case UserRole.member:
        return 1;
      case UserRole.accountant:
        return 2;
      case UserRole.owner:
        return 3;
    }
  }
// دي بتتحقق من صلاحيه معينه او اعلي منها
  bool hasPermission(UserRole requiredRole) {
    return level >= requiredRole.level;
  }
// دي داله بتحولي النص الي في قاعده البيانات الي انمي
  static UserRole fromString(String role) {
    switch (role) {
      case 'owner':
        return UserRole.owner;
      case 'accountant':
        return UserRole.accountant;
      case 'member':
        return UserRole.member;
      default:
        return UserRole.member;
    }
  }
// دي بتحول الانمي الي نص علشان يتخزن في قاعه البيانات
  String toStorageString() {
    return toString().split('.').last;
  }
}