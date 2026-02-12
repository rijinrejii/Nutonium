// lib/core/constants/app_constants.dart

enum UserRole {
  customer,
  retailer,
  wholesaler;

  String get displayName {
    switch (this) {
      case UserRole.customer:
        return 'Customer';
      case UserRole.retailer:
        return 'Retailer';
      case UserRole.wholesaler:
        return 'Wholesaler/Startup';
    }
  }

  String get value {
    switch (this) {
      case UserRole.customer:
        return 'customer';
      case UserRole.retailer:
        return 'retailer';
      case UserRole.wholesaler:
        return 'wholesaler';
    }
  }

  static UserRole fromString(String value) {
    switch (value) {
      case 'customer':
        return UserRole.customer;
      case 'retailer':
        return UserRole.retailer;
      case 'wholesaler':
        return UserRole.wholesaler;
      default:
        return UserRole.customer;
    }
  }
}

// Collection names for Firestore
class FirestoreCollections {
  static const String users = 'users';
  static const String retailers = 'retailers';
  static const String wholesalers = 'wholesalers';
  static const String posts = 'posts';
}

// Storage keys
class StorageKeys {
  static const String userRole = 'user_role';
  static const String userId = 'user_id';
  static const String isProfileComplete = 'is_profile_complete';
}