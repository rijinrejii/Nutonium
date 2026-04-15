import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../models/marketplace_models.dart';

class MarketplaceService {
  MarketplaceService._();

  static final MarketplaceService instance = MarketplaceService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ValueNotifier<List<CartItem>> cartItems = ValueNotifier<List<CartItem>>(
    const [],
  );

  Future<List<MarketplaceShop>> loadNutoniumShops() async {
    final seeded = _seededShops();
    final seededById = {for (final shop in seeded) shop.id: shop};

    try {
      final retailerFuture = _firestore
          .collection(FirestoreCollections.retailers)
          .get();
      final wholesalerFuture = _firestore
          .collection(FirestoreCollections.wholesalers)
          .get();

      final snapshots = await Future.wait([retailerFuture, wholesalerFuture]);
      final remoteShops = <MarketplaceShop>[];

      for (final doc in snapshots[0].docs) {
        final shop = _shopFromFirestore(
          id: doc.id,
          kind: ShopKind.retailer,
          data: doc.data(),
        );
        if (shop != null) {
          remoteShops.add(shop);
        }
      }

      for (final doc in snapshots[1].docs) {
        final shop = _shopFromFirestore(
          id: doc.id,
          kind: ShopKind.wholesaler,
          data: doc.data(),
        );
        if (shop != null) {
          remoteShops.add(shop);
        }
      }

      if (remoteShops.isEmpty) {
        return seeded;
      }

      final merged = <MarketplaceShop>[
        ...remoteShops,
        ...seeded.where(
          (shop) => !remoteShops.any((item) => item.id == shop.id),
        ),
      ];

      return merged;
    } catch (_) {
      return seededById.values.toList();
    }
  }

  Future<List<MarketplacePost>> loadFeed() async {
    final seeded = _seededPosts();

    try {
      final snapshot = await _firestore
          .collection('social_feed')
          .orderBy('createdAt', descending: true)
          .limit(24)
          .get();

      if (snapshot.docs.isEmpty) {
        return seeded;
      }

      final remote = snapshot.docs
          .map((doc) => _postFromFirestore(doc.id, doc.data()))
          .whereType<MarketplacePost>()
          .toList();

      final knownIds = remote.map((post) => post.id).toSet();
      final merged = [
        ...remote,
        ...seeded.where((post) => !knownIds.contains(post.id)),
      ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return merged;
    } catch (_) {
      return seeded;
    }
  }

  Future<MarketplaceUserContext?> loadCurrentUserContext() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return null;
    }

    try {
      final userDoc = await _firestore
          .collection(FirestoreCollections.users)
          .doc(currentUser.uid)
          .get();

      if (!userDoc.exists) {
        return MarketplaceUserContext(
          userId: currentUser.uid,
          shopId: currentUser.uid,
          role: null,
          displayName: currentUser.displayName ?? 'Guest buyer',
          shopName: 'Nutonium buyer',
          locationLabel: 'Marketplace',
          canPublish: false,
        );
      }

      final data = userDoc.data()!;
      final role = UserRole.fromString((data['role'] ?? 'customer') as String);
      final displayName = (data['displayName'] as String?)?.trim();

      if (role == UserRole.customer) {
        return MarketplaceUserContext(
          userId: currentUser.uid,
          shopId: currentUser.uid,
          role: null,
          displayName: displayName?.isNotEmpty == true ? displayName! : 'Buyer',
          shopName: 'Nutonium buyer',
          locationLabel: 'Marketplace',
          canPublish: false,
        );
      }

      final collection = role == UserRole.retailer
          ? FirestoreCollections.retailers
          : FirestoreCollections.wholesalers;
      final profileDoc = await _firestore
          .collection(collection)
          .doc(currentUser.uid)
          .get();
      final profileData = profileDoc.data() ?? <String, dynamic>{};
      final location = (profileData['location'] as Map<String, dynamic>?) ?? {};

      final shopName = role == UserRole.retailer
          ? ((profileData['shopName'] as String?)?.trim() ?? 'Retail counter')
          : ((profileData['companyName'] as String?)?.trim().isNotEmpty ??
                false)
          ? (profileData['companyName'] as String).trim()
          : 'Wholesale desk';
      final ownerName = (profileData['ownerName'] as String?)?.trim();
      final city = (location['city'] as String?)?.trim();
      final state = (location['state'] as String?)?.trim();
      final locationLabel = [
        if (city != null && city.isNotEmpty) city,
        if (state != null && state.isNotEmpty) state,
      ].join(', ');

      return MarketplaceUserContext(
        userId: currentUser.uid,
        shopId: currentUser.uid,
        role: role == UserRole.retailer
            ? ShopKind.retailer
            : ShopKind.wholesaler,
        displayName: displayName?.isNotEmpty == true
            ? displayName!
            : (ownerName?.isNotEmpty == true
                  ? ownerName!
                  : 'Marketplace seller'),
        shopName: shopName,
        locationLabel: locationLabel.isEmpty ? 'Marketplace' : locationLabel,
        canPublish: true,
      );
    } catch (_) {
      return MarketplaceUserContext(
        userId: currentUser.uid,
        shopId: currentUser.uid,
        role: null,
        displayName: currentUser.displayName ?? 'Buyer',
        shopName: 'Nutonium buyer',
        locationLabel: 'Marketplace',
        canPublish: false,
      );
    }
  }

  Future<void> publishPost({
    required MarketplaceUserContext author,
    required PostKind kind,
    required String title,
    required String description,
    String? productId,
    double? offerPrice,
    double? originalPrice,
    DateTime? validUntil,
    DateTime? eventDate,
  }) async {
    final socialRef = _firestore.collection('social_feed').doc();
    final postRef = _firestore
        .collection(FirestoreCollections.posts)
        .doc(socialRef.id);
    final batch = _firestore.batch();
    final now = FieldValue.serverTimestamp();

    final payload = <String, dynamic>{
      'postId': socialRef.id,
      'shopId': author.shopId,
      'userId': author.userId,
      'userRole': author.role == ShopKind.wholesaler
          ? 'wholesaler'
          : 'retailer',
      'contentType': kind.name,
      'title': title,
      'description': description,
      'shopName': author.shopName,
      'userName': author.shopName,
      'locationLabel': author.locationLabel,
      'userLocation': author.locationLabel,
      'createdAt': now,
      'imageUrl': null,
      'mediaUrl': null,
      'offerPrice': offerPrice,
      'discountedPrice': offerPrice,
      'originalPrice': originalPrice,
      'productId': productId,
      'validUntil': validUntil == null ? null : Timestamp.fromDate(validUntil),
      'expiryDate': validUntil == null ? null : Timestamp.fromDate(validUntil),
      'eventDate': eventDate == null ? null : Timestamp.fromDate(eventDate),
      'likeCount': 0,
      'commentCount': 0,
      'shareCount': 0,
      'isActive': true,
      'isVisibleOnSocial': true,
    };

    batch.set(socialRef, payload);
    batch.set(postRef, payload);
    await batch.commit();
  }

  void addProductToCart({
    required MarketplaceShop shop,
    required ShopProduct product,
    int quantity = 1,
  }) {
    final minimumQuantity = quantity < product.minimumOrder
        ? product.minimumOrder
        : quantity;
    final items = [...cartItems.value];
    final index = items.indexWhere(
      (item) => item.shopId == shop.id && item.productId == product.id,
    );

    if (index == -1) {
      items.add(
        CartItem(
          productId: product.id,
          shopId: shop.id,
          shopName: shop.name,
          name: product.name,
          variant: product.variant,
          unitPrice: product.price,
          originalPrice: product.originalPrice,
          quantity: minimumQuantity,
          minimumOrder: product.minimumOrder,
          tagline: product.tagline,
        ),
      );
    } else {
      final existing = items[index];
      items[index] = existing.copyWith(
        quantity: existing.quantity + minimumQuantity,
      );
    }

    cartItems.value = items;
  }

  void updateCartQuantity({
    required String shopId,
    required String productId,
    required int quantity,
  }) {
    final items = [...cartItems.value];
    final index = items.indexWhere(
      (item) => item.shopId == shopId && item.productId == productId,
    );
    if (index == -1) {
      return;
    }

    final item = items[index];
    if (quantity <= 0) {
      items.removeAt(index);
    } else {
      final normalized = quantity < item.minimumOrder
          ? item.minimumOrder
          : quantity;
      items[index] = item.copyWith(quantity: normalized);
    }
    cartItems.value = items;
  }

  void removeFromCart({required String shopId, required String productId}) {
    cartItems.value = cartItems.value
        .where((item) => item.shopId != shopId || item.productId != productId)
        .toList();
  }

  void clearCart() {
    cartItems.value = const [];
  }

  ShopProduct? findProduct(String productId) {
    for (final shop in _seededShops()) {
      for (final product in shop.products) {
        if (product.id == productId) {
          return product;
        }
      }
    }
    return null;
  }

  MarketplaceShop? findSeededShop(String shopId) {
    for (final shop in _seededShops()) {
      if (shop.id == shopId) {
        return shop;
      }
    }
    return null;
  }

  MarketplaceShop? _shopFromFirestore({
    required String id,
    required ShopKind kind,
    required Map<String, dynamic> data,
  }) {
    final location = (data['location'] as Map<String, dynamic>?) ?? {};
    final city = (location['city'] as String?)?.trim();
    final state = (location['state'] as String?)?.trim();
    final address = (location['address'] as String?)?.trim();

    if ((address == null || address.isEmpty) &&
        (city == null || city.isEmpty) &&
        (state == null || state.isEmpty)) {
      return null;
    }

    final latitude = (location['latitude'] as num?)?.toDouble();
    final longitude = (location['longitude'] as num?)?.toDouble();
    final guessedCoordinates = _coordinatesForCity(city);
    final resolvedLatitude = (latitude != null && latitude != 0)
        ? latitude
        : guessedCoordinates?.$1 ?? 10.0159;
    final resolvedLongitude = (longitude != null && longitude != 0)
        ? longitude
        : guessedCoordinates?.$2 ?? 76.3419;

    final categories = kind == ShopKind.retailer
        ? List<String>.from(data['shopCategories'] ?? const <String>[])
        : List<String>.from(data['businessCategories'] ?? const <String>[]);
    final extraCategory = (data['customCategory'] as String?)?.trim();
    if (extraCategory != null && extraCategory.isNotEmpty) {
      categories.add(extraCategory);
    }

    final name = kind == ShopKind.retailer
        ? ((data['shopName'] as String?)?.trim() ?? 'Retail outlet')
        : ((data['companyName'] as String?)?.trim().isNotEmpty ?? false)
        ? (data['companyName'] as String).trim()
        : 'Wholesale house';

    return MarketplaceShop(
      id: id,
      name: name,
      ownerName: (data['ownerName'] as String?)?.trim() ?? 'Marketplace seller',
      kind: kind,
      address: address ?? 'Marketplace registered address',
      city: city?.isNotEmpty == true ? city! : 'Unknown city',
      state: state?.isNotEmpty == true ? state! : 'India',
      latitude: resolvedLatitude,
      longitude: resolvedLongitude,
      rating: 4.6,
      stockLevel: kind == ShopKind.wholesaler
          ? StockLevel.high
          : StockLevel.medium,
      turnaround: kind == ShopKind.wholesaler
          ? 'Dispatch in 12 hrs'
          : 'Shelf pickup today',
      tags: categories.take(3).toList(),
      highlight: kind == ShopKind.wholesaler
          ? 'Bulk Nutonium lanes for retail supply.'
          : 'Walk-in counter with Nutonium shelf-ready packs.',
      products: _productsForKind(kind, name),
      liveOfferCount: kind == ShopKind.wholesaler ? 2 : 1,
      liveEventCount: 1,
      hasPreciseLocation:
          latitude != null &&
          longitude != null &&
          latitude != 0 &&
          longitude != 0,
    );
  }

  MarketplacePost? _postFromFirestore(String id, Map<String, dynamic> data) {
    final shopName =
        (data['shopName'] as String?) ??
        (data['userName'] as String?) ??
        'Nutonium partner';
    final roleValue = (data['userRole'] as String?) ?? 'retailer';
    final contentType = (data['contentType'] as String?) ?? 'update';
    final eventDate = _asDateTime(data['eventDate']);
    final validUntil =
        _asDateTime(data['expiryDate']) ?? _asDateTime(data['validUntil']);

    return MarketplacePost(
      id: id,
      shopId: (data['shopId'] as String?) ?? (data['userId'] as String?) ?? id,
      shopName: shopName,
      shopKind: roleValue == 'wholesaler'
          ? ShopKind.wholesaler
          : ShopKind.retailer,
      kind: switch (contentType) {
        'offer' => PostKind.offer,
        'event' => PostKind.event,
        _ => PostKind.update,
      },
      title: (data['title'] as String?) ?? 'Nutonium market update',
      description: (data['description'] as String?) ?? '',
      createdAt: _asDateTime(data['createdAt']) ?? DateTime.now(),
      locationLabel:
          (data['locationLabel'] as String?) ??
          (data['userLocation'] as String?) ??
          'Marketplace',
      primaryCta: contentType == 'event' ? 'Reserve seat' : 'Add to cart',
      secondaryCta: 'Locate shop',
      imageUrl: (data['imageUrl'] as String?) ?? (data['mediaUrl'] as String?),
      validUntil: validUntil,
      eventDate: eventDate,
      offerPrice:
          (data['offerPrice'] as num?)?.toDouble() ??
          (data['discountedPrice'] as num?)?.toDouble(),
      originalPrice: (data['originalPrice'] as num?)?.toDouble(),
      productId: data['productId'] as String?,
      likes: (data['likeCount'] as num?)?.toInt() ?? 0,
      comments: (data['commentCount'] as num?)?.toInt() ?? 0,
      pinned: data['pinned'] as bool? ?? false,
    );
  }

  DateTime? _asDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    return null;
  }

  (double, double)? _coordinatesForCity(String? city) {
    if (city == null || city.trim().isEmpty) {
      return null;
    }

    switch (city.trim().toLowerCase()) {
      case 'kochi':
      case 'ernakulam':
        return (9.9312, 76.2673);
      case 'kollam':
        return (8.8932, 76.6141);
      case 'thiruvananthapuram':
      case 'trivandrum':
        return (8.5241, 76.9366);
      case 'thrissur':
        return (10.5276, 76.2144);
      case 'kozhikode':
      case 'calicut':
        return (11.2588, 75.7804);
      case 'bangalore':
      case 'bengaluru':
        return (12.9716, 77.5946);
      case 'chennai':
        return (13.0827, 80.2707);
      case 'hyderabad':
        return (17.3850, 78.4867);
      case 'mumbai':
        return (19.0760, 72.8777);
      default:
        return null;
    }
  }

  List<ShopProduct> _productsForKind(ShopKind kind, String shopName) {
    if (kind == ShopKind.wholesaler) {
      return const [
        ShopProduct(
          id: 'core-drum',
          name: 'Nutonium Core',
          variant: '25 kg trade drum',
          price: 8600,
          originalPrice: 9300,
          minimumOrder: 2,
          inventoryUnits: 36,
          tagline: 'Best for multi-store replenishment.',
        ),
        ShopProduct(
          id: 'activation-kit',
          name: 'Nutonium Activation Kit',
          variant: 'Retail launch bundle',
          price: 4200,
          originalPrice: 4700,
          minimumOrder: 1,
          inventoryUnits: 14,
          tagline: 'Includes aisle strips and event collateral.',
        ),
      ];
    }

    return [
      ShopProduct(
        id: '${shopName.toLowerCase().replaceAll(' ', '-')}-shelf-pack',
        name: 'Nutonium Shelf Pack',
        variant: '24 ready-to-sell units',
        price: 1490,
        originalPrice: 1690,
        minimumOrder: 1,
        inventoryUnits: 18,
        tagline: 'Fast moving retail starter pack.',
      ),
      ShopProduct(
        id: '${shopName.toLowerCase().replaceAll(' ', '-')}-trial-case',
        name: 'Nutonium Trial Case',
        variant: '12 sampler units',
        price: 820,
        originalPrice: 960,
        minimumOrder: 1,
        inventoryUnits: 22,
        tagline: 'Strong conversion item for first-time buyers.',
      ),
    ];
  }

  List<MarketplaceShop> _seededShops() {
    return const [
      MarketplaceShop(
        id: 'harbor-traders',
        name: 'Harbor Traders',
        ownerName: 'Rasheed M',
        kind: ShopKind.wholesaler,
        address: 'Willingdon Island trade yard',
        city: 'Kochi',
        state: 'Kerala',
        latitude: 9.9672,
        longitude: 76.2590,
        rating: 4.9,
        stockLevel: StockLevel.high,
        turnaround: 'Dispatch in 8 hrs',
        tags: ['FMCG', 'Bulk supply', 'Priority lanes'],
        highlight: 'Known for dependable Nutonium bulk turns for chain stores.',
        products: [
          ShopProduct(
            id: 'harbor-core-drum',
            name: 'Nutonium Core',
            variant: '25 kg trade drum',
            price: 8600,
            originalPrice: 9300,
            minimumOrder: 2,
            inventoryUnits: 42,
            tagline: 'Built for regional replenishment runs.',
          ),
          ShopProduct(
            id: 'harbor-rollout-kit',
            name: 'Nutonium Rollout Kit',
            variant: 'Launch bundle + shelf assets',
            price: 4450,
            originalPrice: 4950,
            minimumOrder: 1,
            inventoryUnits: 11,
            tagline: 'For new retail doors and event tables.',
          ),
        ],
        liveOfferCount: 2,
        liveEventCount: 1,
        hasPreciseLocation: true,
      ),
      MarketplaceShop(
        id: 'crown-retail-depot',
        name: 'Crown Retail Depot',
        ownerName: 'Maya Joseph',
        kind: ShopKind.retailer,
        address: 'MG Road signature arcade',
        city: 'Ernakulam',
        state: 'Kerala',
        latitude: 9.9794,
        longitude: 76.2812,
        rating: 4.7,
        stockLevel: StockLevel.medium,
        turnaround: 'Pickup in 30 mins',
        tags: ['Walk-in', 'Shelf ready', 'Demo corner'],
        highlight: 'Flagship retail counter for premium Nutonium display.',
        products: [
          ShopProduct(
            id: 'crown-shelf-pack',
            name: 'Nutonium Shelf Pack',
            variant: '24 ready-to-sell units',
            price: 1490,
            originalPrice: 1690,
            minimumOrder: 1,
            inventoryUnits: 18,
            tagline: 'Display-ready assortment for fast movers.',
          ),
          ShopProduct(
            id: 'crown-trial-case',
            name: 'Nutonium Trial Case',
            variant: '12 sampler units',
            price: 820,
            originalPrice: 960,
            minimumOrder: 1,
            inventoryUnits: 24,
            tagline: 'Ideal for first purchase conversion.',
          ),
        ],
        liveOfferCount: 1,
        liveEventCount: 1,
        hasPreciseLocation: true,
      ),
      MarketplaceShop(
        id: 'capital-supply-house',
        name: 'Capital Supply House',
        ownerName: 'Neha Nair',
        kind: ShopKind.wholesaler,
        address: 'Pattom distributor row',
        city: 'Thiruvananthapuram',
        state: 'Kerala',
        latitude: 8.5298,
        longitude: 76.9470,
        rating: 4.8,
        stockLevel: StockLevel.high,
        turnaround: 'Dispatch tonight',
        tags: ['Institutional', 'B2B desk', 'Fast dispatch'],
        highlight: 'Strong Nutonium coverage for south-zone retail operators.',
        products: [
          ShopProduct(
            id: 'capital-core-drum',
            name: 'Nutonium Core',
            variant: '25 kg trade drum',
            price: 8720,
            originalPrice: 9400,
            minimumOrder: 2,
            inventoryUnits: 30,
            tagline: 'High-volume lane for repeat purchase cycles.',
          ),
          ShopProduct(
            id: 'capital-activation-kit',
            name: 'Nutonium Activation Kit',
            variant: 'Counter launch set',
            price: 4180,
            originalPrice: 4680,
            minimumOrder: 1,
            inventoryUnits: 9,
            tagline: 'Supports launch days and sampling events.',
          ),
        ],
        liveOfferCount: 2,
        liveEventCount: 0,
        hasPreciseLocation: true,
      ),
      MarketplaceShop(
        id: 'malabar-select',
        name: 'Malabar Select',
        ownerName: 'Ameen K',
        kind: ShopKind.retailer,
        address: 'SM Street heritage lane',
        city: 'Kozhikode',
        state: 'Kerala',
        latitude: 11.2504,
        longitude: 75.7772,
        rating: 4.6,
        stockLevel: StockLevel.low,
        turnaround: 'Pickup by evening',
        tags: ['Boutique retail', 'Limited run', 'Premium shelf'],
        highlight: 'Limited Nutonium allocation with premium event hosting.',
        products: [
          ShopProduct(
            id: 'malabar-shelf-pack',
            name: 'Nutonium Shelf Pack',
            variant: '24 ready-to-sell units',
            price: 1520,
            originalPrice: 1710,
            minimumOrder: 1,
            inventoryUnits: 7,
            tagline: 'Sharper shelf mix for premium counters.',
          ),
          ShopProduct(
            id: 'malabar-trial-case',
            name: 'Nutonium Trial Case',
            variant: '12 sampler units',
            price: 835,
            originalPrice: 980,
            minimumOrder: 1,
            inventoryUnits: 10,
            tagline: 'Short-run sampler for walk-in discovery.',
          ),
        ],
        liveOfferCount: 1,
        liveEventCount: 2,
        hasPreciseLocation: true,
      ),
    ];
  }

  List<MarketplacePost> _seededPosts() {
    final now = DateTime.now();
    return [
      MarketplacePost(
        id: 'feed-01',
        shopId: 'harbor-traders',
        shopName: 'Harbor Traders',
        shopKind: ShopKind.wholesaler,
        kind: PostKind.offer,
        title: 'Trade corridor pricing on Nutonium Core drums',
        description:
            'Chain stores ordering 4 or more drums get launch collateral and preferred dispatch scheduling this week.',
        createdAt: now.subtract(const Duration(hours: 2)),
        locationLabel: 'Kochi, Kerala',
        primaryCta: 'Add to cart',
        secondaryCta: 'Locate shop',
        validUntil: now.add(const Duration(days: 4)),
        offerPrice: 8600,
        originalPrice: 9300,
        productId: 'harbor-core-drum',
        likes: 146,
        comments: 18,
        pinned: true,
      ),
      MarketplacePost(
        id: 'feed-02',
        shopId: 'crown-retail-depot',
        shopName: 'Crown Retail Depot',
        shopKind: ShopKind.retailer,
        kind: PostKind.event,
        title: 'Counter event: live Nutonium tasting from 5 PM',
        description:
            'Retail buyers can sample the current lineup, review shelf kits, and book a same-day starter pack pickup.',
        createdAt: now.subtract(const Duration(hours: 5)),
        locationLabel: 'Ernakulam, Kerala',
        primaryCta: 'Reserve seat',
        secondaryCta: 'Locate shop',
        eventDate: DateTime(now.year, now.month, now.day + 1, 17),
        likes: 78,
        comments: 11,
      ),
      MarketplacePost(
        id: 'feed-03',
        shopId: 'capital-supply-house',
        shopName: 'Capital Supply House',
        shopKind: ShopKind.wholesaler,
        kind: PostKind.update,
        title: 'South-zone replenishment lane is open',
        description:
            'Retailers in Trivandrum and Kollam can lock dispatch windows for weekend delivery before tonight 8 PM.',
        createdAt: now.subtract(const Duration(hours: 9)),
        locationLabel: 'Thiruvananthapuram, Kerala',
        primaryCta: 'View stock',
        secondaryCta: 'Locate shop',
        likes: 59,
        comments: 7,
      ),
      MarketplacePost(
        id: 'feed-04',
        shopId: 'malabar-select',
        shopName: 'Malabar Select',
        shopKind: ShopKind.retailer,
        kind: PostKind.offer,
        title: 'Weekend boutique allocation on trial cases',
        description:
            'A short-run Nutonium sampler drop for premium counters. Add now before the allocation closes.',
        createdAt: now.subtract(const Duration(hours: 16)),
        locationLabel: 'Kozhikode, Kerala',
        primaryCta: 'Add to cart',
        secondaryCta: 'Locate shop',
        validUntil: now.add(const Duration(days: 2)),
        offerPrice: 835,
        originalPrice: 980,
        productId: 'malabar-trial-case',
        likes: 98,
        comments: 14,
      ),
    ];
  }
}