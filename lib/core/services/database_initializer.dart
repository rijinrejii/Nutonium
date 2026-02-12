// lib/core/services/database_initializer.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DatabaseInitializer {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  /// Initialize all required Firestore collections and indexes
  /// Call this once during app setup or on first launch
  Future<void> initializeDatabase() async {
    try {
      print('🚀 Starting database initialization...');

      // Check if collections already exist
      final postsSnapshot = await _firestore.collection('posts').limit(1).get();
      
      if (postsSnapshot.docs.isEmpty) {
        print('📦 Collections not found. Creating sample data...');
        await _createSampleData();
      } else {
        print('✅ Database already initialized');
      }

      print('✅ Database initialization complete');
    } catch (e) {
      print('❌ Database initialization failed: $e');
      rethrow;
    }
  }

  /// Create sample data for testing
  Future<void> _createSampleData() async {
    final batch = _firestore.batch();

    // Sample post data
    final postId = _firestore.collection('posts').doc().id;
    final userId = 'sample_retailer_001';
    final now = FieldValue.serverTimestamp();
    final expiryDate = Timestamp.fromDate(
      DateTime.now().add(const Duration(days: 3)),
    );

    // 1. Create post in main posts collection
    final postRef = _firestore.collection('posts').doc(postId);
    batch.set(postRef, {
      'postId': postId,
      'userId': userId,
      'userRole': 'retailer',
      'contentType': 'offer',
      'mediaType': 'poster',
      'mediaUrl': 'https://via.placeholder.com/400',
      'thumbnailUrl': null,
      'title': 'Sample Flash Sale - 50% Off',
      'description': 'Limited time offer - Database initialization sample',
      'originalPrice': 1000,
      'discountedPrice': 500,
      'discountPercentage': 50,
      'createdAt': now,
      'offerExpiryDate': expiryDate,
      'socialViewPeriodDays': null,
      'socialViewExpiryDate': null,
      'isActive': true,
      'isVisibleOnSocial': true,
      'isVisibleOnProfile': true,
      'viewCount': 0,
      'likeCount': 0,
      'shareCount': 0,
      'updatedAt': now,
    });

    // 2. Create entry in social_feed
    final socialFeedRef = _firestore.collection('social_feed').doc(postId);
    batch.set(socialFeedRef, {
      'postId': postId,
      'userId': userId,
      'userRole': 'retailer',
      'contentType': 'offer',
      'mediaType': 'poster',
      'mediaUrl': 'https://via.placeholder.com/400',
      'thumbnailUrl': null,
      'title': 'Sample Flash Sale - 50% Off',
      'description': 'Limited time offer - Database initialization sample',
      'originalPrice': 1000,
      'discountedPrice': 500,
      'discountPercentage': 50,
      'createdAt': now,
      'expiryDate': expiryDate,
      'viewCount': 0,
      'likeCount': 0,
      'shareCount': 0,
      'userName': 'Sample Tech Mart',
      'userPhotoUrl': null,
      'userLocation': 'Kollam, Kerala',
    });

    // 3. Create entry in user_posts subcollection
    final userPostRef = _firestore
        .collection('user_posts')
        .doc(userId)
        .collection('posts')
        .doc(postId);
    batch.set(userPostRef, {
      'postId': postId,
      'contentType': 'offer',
      'mediaType': 'poster',
      'mediaUrl': 'https://via.placeholder.com/400',
      'thumbnailUrl': null,
      'title': 'Sample Flash Sale - 50% Off',
      'description': 'Limited time offer - Database initialization sample',
      'isActive': true,
      'isExpired': false,
      'createdAt': now,
      'expiryDate': expiryDate,
      'viewCount': 0,
      'likeCount': 0,
      'shareCount': 0,
    });

    // 4. Create analytics entry
    final analyticsRef = _firestore.collection('post_analytics').doc(postId);
    batch.set(analyticsRef, {
      'postId': postId,
      'userId': userId,
      'dailyViews': {},
      'dailyLikes': {},
      'dailyShares': {},
      'totalViews': 0,
      'totalLikes': 0,
      'totalShares': 0,
      'peakViewDate': null,
      'createdAt': now,
      'lastViewedAt': now,
      'analyticsUpdatedAt': now,
    });

    // Commit all writes
    await batch.commit();
    print('✅ Sample data created successfully');
  }

  /// Helper method to create a new post with all required collections
  Future<String> createPost({
    required String userId,
    required String userRole,
    required String contentType,
    required String mediaType,
    required String mediaUrl,
    required String title,
    String? description,
    String? thumbnailUrl,
    double? originalPrice,
    double? discountedPrice,
    double? discountPercentage,
    DateTime? offerExpiryDate,
    int? socialViewPeriodDays,
    required String userName,
    String? userPhotoUrl,
    String? userLocation,
  }) async {
    final batch = _firestore.batch();
    final postId = _firestore.collection('posts').doc().id;
    final now = FieldValue.serverTimestamp();

    // Calculate expiry dates
    Timestamp? offerExpiry;
    Timestamp? socialExpiry;
    Timestamp? expiryDate;

    if (contentType == 'offer' && offerExpiryDate != null) {
      offerExpiry = Timestamp.fromDate(offerExpiryDate);
      expiryDate = offerExpiry;
    } else if (contentType == 'promotion' && socialViewPeriodDays != null) {
      socialExpiry = Timestamp.fromDate(
        DateTime.now().add(Duration(days: socialViewPeriodDays)),
      );
      expiryDate = socialExpiry;
    }

    // 1. Main post
    final postRef = _firestore.collection('posts').doc(postId);
    batch.set(postRef, {
      'postId': postId,
      'userId': userId,
      'userRole': userRole,
      'contentType': contentType,
      'mediaType': mediaType,
      'mediaUrl': mediaUrl,
      'thumbnailUrl': thumbnailUrl,
      'title': title,
      'description': description,
      'originalPrice': originalPrice,
      'discountedPrice': discountedPrice,
      'discountPercentage': discountPercentage,
      'createdAt': now,
      'offerExpiryDate': offerExpiry,
      'socialViewPeriodDays': socialViewPeriodDays,
      'socialViewExpiryDate': socialExpiry,
      'isActive': true,
      'isVisibleOnSocial': true,
      'isVisibleOnProfile': true,
      'viewCount': 0,
      'likeCount': 0,
      'shareCount': 0,
      'updatedAt': now,
    });

    // 2. Social feed entry
    final socialFeedRef = _firestore.collection('social_feed').doc(postId);
    batch.set(socialFeedRef, {
      'postId': postId,
      'userId': userId,
      'userRole': userRole,
      'contentType': contentType,
      'mediaType': mediaType,
      'mediaUrl': mediaUrl,
      'thumbnailUrl': thumbnailUrl,
      'title': title,
      'description': description,
      'originalPrice': originalPrice,
      'discountedPrice': discountedPrice,
      'discountPercentage': discountPercentage,
      'createdAt': now,
      'expiryDate': expiryDate,
      'viewCount': 0,
      'likeCount': 0,
      'shareCount': 0,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'userLocation': userLocation,
    });

    // 3. User posts subcollection
    final userPostRef = _firestore
        .collection('user_posts')
        .doc(userId)
        .collection('posts')
        .doc(postId);
    batch.set(userPostRef, {
      'postId': postId,
      'contentType': contentType,
      'mediaType': mediaType,
      'mediaUrl': mediaUrl,
      'thumbnailUrl': thumbnailUrl,
      'title': title,
      'description': description,
      'isActive': true,
      'isExpired': false,
      'createdAt': now,
      'expiryDate': expiryDate,
      'viewCount': 0,
      'likeCount': 0,
      'shareCount': 0,
    });

    // 4. Analytics
    final analyticsRef = _firestore.collection('post_analytics').doc(postId);
    batch.set(analyticsRef, {
      'postId': postId,
      'userId': userId,
      'dailyViews': {},
      'dailyLikes': {},
      'dailyShares': {},
      'totalViews': 0,
      'totalLikes': 0,
      'totalShares': 0,
      'peakViewDate': null,
      'createdAt': now,
      'lastViewedAt': now,
      'analyticsUpdatedAt': now,
    });

    await batch.commit();
    return postId;
  }

  /// Verify database structure
  Future<Map<String, bool>> verifyDatabaseStructure() async {
    final results = <String, bool>{};

    try {
      // Check posts collection
      final posts = await _firestore.collection('posts').limit(1).get();
      results['posts'] = posts.docs.isNotEmpty;

      // Check social_feed collection
      final socialFeed = await _firestore.collection('social_feed').limit(1).get();
      results['social_feed'] = socialFeed.docs.isNotEmpty;

      // Check user_posts collection
      final userPosts = await _firestore.collection('user_posts').limit(1).get();
      results['user_posts'] = userPosts.docs.isNotEmpty;

      // Check post_analytics collection
      final analytics = await _firestore.collection('post_analytics').limit(1).get();
      results['post_analytics'] = analytics.docs.isNotEmpty;

      print('📊 Database verification results:');
      results.forEach((collection, exists) {
        print('  ${exists ? "✅" : "❌"} $collection');
      });

      return results;
    } catch (e) {
      print('❌ Database verification failed: $e');
      return results;
    }
  }
}