import 'shop_location.dart';

class WholesalerProfile {
  final String userId;
  final String ownerName;
  final String? companyName;
  final List<String> businessCategories;
  final String? customCategory;
  final ShopLocation location;
  final String? gstNumber;
  final String? panNumber;
  final String? businessLicense;
  final DateTime createdAt;
  final DateTime? updatedAt;

  WholesalerProfile({
    required this.userId,
    required this.ownerName,
    this.companyName,
    required this.businessCategories,
    this.customCategory,
    required this.location,
    this.gstNumber,
    this.panNumber,
    this.businessLicense,
    required this.createdAt,
    this.updatedAt,
  });

  WholesalerProfile copyWith({
    String? userId,
    String? ownerName,
    String? companyName,
    List<String>? businessCategories,
    String? customCategory,
    ShopLocation? location,
    String? gstNumber,
    String? panNumber,
    String? businessLicense,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WholesalerProfile(
      userId: userId ?? this.userId,
      ownerName: ownerName ?? this.ownerName,
      companyName: companyName ?? this.companyName,
      businessCategories: businessCategories ?? this.businessCategories,
      customCategory: customCategory ?? this.customCategory,
      location: location ?? this.location,
      gstNumber: gstNumber ?? this.gstNumber,
      panNumber: panNumber ?? this.panNumber,
      businessLicense: businessLicense ?? this.businessLicense,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}