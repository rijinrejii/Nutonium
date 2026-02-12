import '../../domain/entities/shop_location.dart';

class ShopLocationModel {
  final double latitude;
  final double longitude;
  final String address;
  final String? city;
  final String? state;
  final String? pincode;

  ShopLocationModel({
    required this.latitude,
    required this.longitude,
    required this.address,
    this.city,
    this.state,
    this.pincode,
  });

  factory ShopLocationModel.fromEntity(ShopLocation location) {
    return ShopLocationModel(
      latitude: location.latitude,
      longitude: location.longitude,
      address: location.address,
      city: location.city,
      state: location.state,
      pincode: location.pincode,
    );
  }

  factory ShopLocationModel.fromJson(Map<String, dynamic> json) {
    return ShopLocationModel(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      address: json['address'] as String,
      city: json['city'] as String?,
      state: json['state'] as String?,
      pincode: json['pincode'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'city': city,
      'state': state,
      'pincode': pincode,
    };
  }

  ShopLocation toEntity() {
    return ShopLocation(
      latitude: latitude,
      longitude: longitude,
      address: address,
      city: city,
      state: state,
      pincode: pincode,
    );
  }
}