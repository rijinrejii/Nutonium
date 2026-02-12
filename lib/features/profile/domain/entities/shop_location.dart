class ShopLocation {
  final double latitude;
  final double longitude;
  final String address;
  final String? city;
  final String? state;
  final String? pincode;

  ShopLocation({
    required this.latitude,
    required this.longitude,
    required this.address,
    this.city,
    this.state,
    this.pincode,
  });

  ShopLocation copyWith({
    double? latitude,
    double? longitude,
    String? address,
    String? city,
    String? state,
    String? pincode,
  }) {
    return ShopLocation(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
    );
  }
}