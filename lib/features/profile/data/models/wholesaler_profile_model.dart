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

  Map<String, dynamic> toMap() {
    return {
      'address': address,
      'city': city,
      'state': state,
      'pinCode': pinCode,
      'latitude': latitude ?? 0.0,
      'longitude': longitude ?? 0.0,
    };
  }

  factory ShopLocation.fromMap(Map<String, dynamic> map) {
    return ShopLocation(
      address: map['address'] ?? '',
      city: map['city'] ?? '',
      state: map['state'] ?? '',
      pinCode: map['pinCode'] ?? map['pincode'] ?? '',
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
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
}