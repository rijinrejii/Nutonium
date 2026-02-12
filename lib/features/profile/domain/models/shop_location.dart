// lib/features/profile/domain/models/shop_location.dart

class ShopLocation {
  final String address;
  final String city;
  final String state;
  final String pinCode;
  final double? latitude;
  final double? longitude;

  ShopLocation({
    required this.address,
    required this.city,
    required this.state,
    required this.pinCode,
    this.latitude,
    this.longitude,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'address': address,
      'city': city,
      'state': state,
      'pinCode': pinCode,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  // Create from Map (Firestore data)
  factory ShopLocation.fromMap(Map<String, dynamic> map) {
    return ShopLocation(
      address: map['address'] as String,
      city: map['city'] as String,
      state: map['state'] as String,
      pinCode: map['pinCode'] as String,
      latitude: map['latitude'] as double?,
      longitude: map['longitude'] as double?,
    );
  }

  ShopLocation copyWith({
    String? address,
    String? city,
    String? state,
    String? pinCode,
    double? latitude,
    double? longitude,
  }) {
    return ShopLocation(
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      pinCode: pinCode ?? this.pinCode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  // Get formatted address string
  String get fullAddress {
    return '$address, $city, $state - $pinCode';
  }

  // Get short address (city and state)
  String get shortAddress {
    return '$city, $state';
  }
}