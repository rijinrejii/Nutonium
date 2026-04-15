import 'package:flutter/material.dart';

enum ShopKind {
  retailer('Retailer'),
  wholesaler('Wholesaler');

  const ShopKind(this.label);

  final String label;
}

enum StockLevel {
  high('High stock', Color(0xFF2F7B57)),
  medium('Stable stock', Color(0xFFBF7F22)),
  low('Low stock', Color(0xFFB5483C));

  const StockLevel(this.label, this.color);

  final String label;
  final Color color;
}

enum PostKind {
  offer('Offer'),
  event('Event'),
  update('Update');

  const PostKind(this.label);

  final String label;
}

class ShopProduct {
  const ShopProduct({
    required this.id,
    required this.name,
    required this.variant,
    required this.price,
    required this.originalPrice,
    required this.minimumOrder,
    required this.inventoryUnits,
    required this.tagline,
  });

  final String id;
  final String name;
  final String variant;
  final double price;
  final double originalPrice;
  final int minimumOrder;
  final int inventoryUnits;
  final String tagline;
}

class MarketplaceShop {
  const MarketplaceShop({
    required this.id,
    required this.name,
    required this.ownerName,
    required this.kind,
    required this.address,
    required this.city,
    required this.state,
    required this.latitude,
    required this.longitude,
    required this.rating,
    required this.stockLevel,
    required this.turnaround,
    required this.tags,
    required this.highlight,
    required this.products,
    required this.liveOfferCount,
    required this.liveEventCount,
    required this.hasPreciseLocation,
  });

  final String id;
  final String name;
  final String ownerName;
  final ShopKind kind;
  final String address;
  final String city;
  final String state;
  final double latitude;
  final double longitude;
  final double rating;
  final StockLevel stockLevel;
  final String turnaround;
  final List<String> tags;
  final String highlight;
  final List<ShopProduct> products;
  final int liveOfferCount;
  final int liveEventCount;
  final bool hasPreciseLocation;

  String get placeLabel => '$city, $state';
}

class MarketplacePost {
  const MarketplacePost({
    required this.id,
    required this.shopId,
    required this.shopName,
    required this.shopKind,
    required this.kind,
    required this.title,
    required this.description,
    required this.createdAt,
    required this.locationLabel,
    required this.primaryCta,
    required this.secondaryCta,
    this.imageUrl,
    this.validUntil,
    this.eventDate,
    this.offerPrice,
    this.originalPrice,
    this.productId,
    this.likes = 0,
    this.comments = 0,
    this.pinned = false,
  });

  final String id;
  final String shopId;
  final String shopName;
  final ShopKind shopKind;
  final PostKind kind;
  final String title;
  final String description;
  final DateTime createdAt;
  final String locationLabel;
  final String primaryCta;
  final String secondaryCta;
  final String? imageUrl;
  final DateTime? validUntil;
  final DateTime? eventDate;
  final double? offerPrice;
  final double? originalPrice;
  final String? productId;
  final int likes;
  final int comments;
  final bool pinned;
}

class CartItem {
  const CartItem({
    required this.productId,
    required this.shopId,
    required this.shopName,
    required this.name,
    required this.variant,
    required this.unitPrice,
    required this.originalPrice,
    required this.quantity,
    required this.minimumOrder,
    required this.tagline,
  });

  final String productId;
  final String shopId;
  final String shopName;
  final String name;
  final String variant;
  final double unitPrice;
  final double originalPrice;
  final int quantity;
  final int minimumOrder;
  final String tagline;

  double get total => unitPrice * quantity;
  double get savings => (originalPrice - unitPrice) * quantity;

  CartItem copyWith({
    String? productId,
    String? shopId,
    String? shopName,
    String? name,
    String? variant,
    double? unitPrice,
    double? originalPrice,
    int? quantity,
    int? minimumOrder,
    String? tagline,
  }) {
    return CartItem(
      productId: productId ?? this.productId,
      shopId: shopId ?? this.shopId,
      shopName: shopName ?? this.shopName,
      name: name ?? this.name,
      variant: variant ?? this.variant,
      unitPrice: unitPrice ?? this.unitPrice,
      originalPrice: originalPrice ?? this.originalPrice,
      quantity: quantity ?? this.quantity,
      minimumOrder: minimumOrder ?? this.minimumOrder,
      tagline: tagline ?? this.tagline,
    );
  }
}

class MarketplaceUserContext {
  const MarketplaceUserContext({
    required this.userId,
    required this.shopId,
    required this.role,
    required this.displayName,
    required this.shopName,
    required this.locationLabel,
    required this.canPublish,
  });

  final String userId;
  final String shopId;
  final ShopKind? role;
  final String displayName;
  final String shopName;
  final String locationLabel;
  final bool canPublish;
}