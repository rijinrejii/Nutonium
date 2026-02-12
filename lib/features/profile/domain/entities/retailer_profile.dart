import 'shop_location.dart';

class RetailerProfile {
  final String userId;
  final String ownerName;
  final String shopName;
  final List<String> shopCategories;
  final String? customCategory;
  final ShopLocation location;
  final String? gstNumber;
  final String? businessLicense;
  final DateTime createdAt;
  final DateTime? updatedAt;

  RetailerProfile({
    required this.userId,
    required this.ownerName,
    required this.shopName,
    required this.shopCategories,
    this.customCategory,
    required this.location,
    this.gstNumber,
    this.businessLicense,
    required this.createdAt,
    this.updatedAt,
  });

  RetailerProfile copyWith({
    String? userId,
    String? ownerName,
    String? shopName,
    List<String>? shopCategories,
    String? customCategory,
    ShopLocation? location,
    String? gstNumber,
    String? businessLicense,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RetailerProfile(
      userId: userId ?? this.userId,
      ownerName: ownerName ?? this.ownerName,
      shopName: shopName ?? this.shopName,
      shopCategories: shopCategories ?? this.shopCategories,
      customCategory: customCategory ?? this.customCategory,
      location: location ?? this.location,
      gstNumber: gstNumber ?? this.gstNumber,
      businessLicense: businessLicense ?? this.businessLicense,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}