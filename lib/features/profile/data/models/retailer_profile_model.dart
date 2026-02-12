import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/retailer_profile.dart';
import '../../domain/entities/shop_location.dart';
import 'shop_location_model.dart';

class RetailerProfileModel {
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

  RetailerProfileModel({
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

  factory RetailerProfileModel.fromJson(Map<String, dynamic> json) {
    return RetailerProfileModel(
      userId: json['userId'] as String,
      ownerName: json['ownerName'] as String,
      shopName: json['shopName'] as String,
      shopCategories: List<String>.from(json['shopCategories'] as List),
      customCategory: json['customCategory'] as String?,
      location: ShopLocationModel.fromJson(json['location'] as Map<String, dynamic>).toEntity(),
      gstNumber: json['gstNumber'] as String?,
      businessLicense: json['businessLicense'] as String?,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'ownerName': ownerName,
      'shopName': shopName,
      'shopCategories': shopCategories,
      'customCategory': customCategory,
      'location': ShopLocationModel.fromEntity(location).toJson(),
      'gstNumber': gstNumber,
      'businessLicense': businessLicense,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  RetailerProfile toEntity() {
    return RetailerProfile(
      userId: userId,
      ownerName: ownerName,
      shopName: shopName,
      shopCategories: shopCategories,
      customCategory: customCategory,
      location: location,
      gstNumber: gstNumber,
      businessLicense: businessLicense,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
