import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../auth/domain/entities/user.dart' as app_user;
import '../../domain/entities/retailer_profile.dart';
import '../../domain/entities/shop_location.dart';
import '../../domain/entities/wholesaler_profile.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  app_user.User? _userData;
  RetailerProfile? _retailerProfile;
  WholesalerProfile? _wholesalerProfile;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) return;

      final userDoc = await FirebaseFirestore.instance
          .collection(FirestoreCollections.users)
          .doc(firebaseUser.uid)
          .get();

      if (!userDoc.exists) return;

      final userData = userDoc.data()!;
      final role = UserRole.fromString(userData['role'] ?? 'customer');

      _userData = app_user.User(
        id: firebaseUser.uid,
        email: userData['email'] ?? '',
        phoneNumber: userData['phoneNumber'],
        displayName: userData['displayName'],
        photoUrl: userData['photoUrl'],
        role: role,
        isProfileComplete: userData['isProfileComplete'] ?? false,
        createdAt: (userData['createdAt'] as Timestamp).toDate(),
        updatedAt: userData['updatedAt'] != null
            ? (userData['updatedAt'] as Timestamp).toDate()
            : null,
      );

      if (role == UserRole.retailer) {
        await _loadRetailerProfile(firebaseUser.uid);
      } else if (role == UserRole.wholesaler) {
        await _loadWholesalerProfile(firebaseUser.uid);
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadRetailerProfile(String userId) async {
    final doc = await FirebaseFirestore.instance
        .collection(FirestoreCollections.retailers)
        .doc(userId)
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      final location = data['location'] as Map<String, dynamic>;
      _retailerProfile = RetailerProfile(
        userId: data['userId'],
        ownerName: data['ownerName'],
        shopName: data['shopName'],
        shopCategories: List<String>.from(data['shopCategories']),
        customCategory: data['customCategory'],
        location: ShopLocation(
          latitude: location['latitude']?.toDouble() ?? 0.0,
          longitude: location['longitude']?.toDouble() ?? 0.0,
          address: location['address'] ?? '',
          city: location['city'],
          state: location['state'],
          pincode: location['pincode'] ?? location['pinCode'],
        ),
        gstNumber: data['gstNumber'],
        businessLicense: data['businessLicense'],
        createdAt: (data['createdAt'] as Timestamp).toDate(),
        updatedAt: data['updatedAt'] != null
            ? (data['updatedAt'] as Timestamp).toDate()
            : null,
      );
    }
  }

  Future<void> _loadWholesalerProfile(String userId) async {
    final doc = await FirebaseFirestore.instance
        .collection(FirestoreCollections.wholesalers)
        .doc(userId)
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      final location = data['location'] as Map<String, dynamic>;
      _wholesalerProfile = WholesalerProfile(
        userId: data['userId'],
        ownerName: data['ownerName'],
        companyName: data['companyName'],
        businessCategories: List<String>.from(data['businessCategories']),
        customCategory: data['customCategory'],
        location: ShopLocation(
          latitude: location['latitude']?.toDouble() ?? 0.0,
          longitude: location['longitude']?.toDouble() ?? 0.0,
          address: location['address'] ?? '',
          city: location['city'],
          state: location['state'],
          pincode: location['pincode'] ?? location['pinCode'],
        ),
        gstNumber: data['gstNumber'],
        panNumber: data['panNumber'],
        businessLicense: data['businessLicense'],
        createdAt: (data['createdAt'] as Timestamp).toDate(),
        updatedAt: data['updatedAt'] != null
            ? (data['updatedAt'] as Timestamp).toDate()
            : null,
      );
    }
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logged out successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getProfileName() {
    if (_retailerProfile != null) return _retailerProfile!.ownerName;
    if (_wholesalerProfile != null) return _wholesalerProfile!.ownerName;
    return 'User';
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      color: const Color(0xFFF5F7FB),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: Column(
          children: [
            _buildProfileHeader(primary),
            const SizedBox(height: 14),
            _buildQuickStats(primary),
            const SizedBox(height: 16),
            _buildSectionCard(
              title: 'Contact Information',
              icon: Icons.contact_phone,
              children: [
                if (_userData?.phoneNumber != null)
                  _buildInfoRow(Icons.phone_iphone, 'Phone', _userData!.phoneNumber!),
                if (_userData?.email.isNotEmpty ?? false)
                  _buildInfoRow(Icons.email_outlined, 'Email', _userData!.email),
              ],
            ),
            if (_userData?.role == UserRole.retailer && _retailerProfile != null)
              _buildRetailerProfileSection(),
            if (_userData?.role == UserRole.wholesaler && _wholesalerProfile != null)
              _buildWholesalerProfileSection(),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: () => _logout(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                  foregroundColor: Colors.red.shade700,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: Colors.red.shade200),
                  ),
                ),
                icon: const Icon(Icons.logout_rounded),
                label: const Text(
                  'Logout',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(Color primary) {
    final roleText = _userData?.role.displayName ?? 'Customer';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primary, const Color(0xFF8A7DFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white70, width: 2),
              color: Colors.white.withValues(alpha: 0.15),
            ),
            child: _userData?.photoUrl != null && _userData!.photoUrl!.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      _userData!.photoUrl!,
                      fit: BoxFit.cover,
                    ),
                  )
                : const Icon(Icons.person_rounded, size: 40, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _userData?.displayName ?? _getProfileName(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    roleText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _userData?.phoneNumber ?? _userData?.email ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(Color primary) {
    final profileComplete = _userData?.isProfileComplete == true ? 'Yes' : 'No';
    final profileType = _userData?.role.displayName ?? 'Customer';

    return Row(
      children: [
        Expanded(
          child: _buildStatTile(
            title: 'Profile Type',
            value: profileType,
            icon: Icons.verified_user_outlined,
            color: primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatTile(
            title: 'Completed',
            value: profileComplete,
            icon: Icons.task_alt_rounded,
            color: profileComplete == 'Yes' ? Colors.green : Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildStatTile({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRetailerProfileSection() {
    return Column(
      children: [
        _buildSectionCard(
          title: 'Shop Details',
          icon: Icons.storefront_outlined,
          children: [
            _buildInfoRow(Icons.store, 'Shop Name', _retailerProfile!.shopName),
            _buildInfoRow(Icons.person_outline, 'Owner', _retailerProfile!.ownerName),
            _buildCategoriesRow('Categories', _retailerProfile!.shopCategories),
            if (_retailerProfile!.customCategory != null)
              _buildInfoRow(
                Icons.category_outlined,
                'Custom Category',
                _retailerProfile!.customCategory!,
              ),
          ],
        ),
        _buildLocationSection(_retailerProfile!.location),
        if (_retailerProfile!.gstNumber != null ||
            _retailerProfile!.businessLicense != null)
          _buildSectionCard(
            title: 'Business Details',
            icon: Icons.badge_outlined,
            children: [
              if (_retailerProfile!.gstNumber != null)
                _buildInfoRow(Icons.numbers, 'GST Number', _retailerProfile!.gstNumber!),
              if (_retailerProfile!.businessLicense != null)
                _buildInfoRow(Icons.verified_outlined, 'License', _retailerProfile!.businessLicense!),
            ],
          ),
      ],
    );
  }

  Widget _buildWholesalerProfileSection() {
    return Column(
      children: [
        _buildSectionCard(
          title: 'Business Details',
          icon: Icons.apartment_outlined,
          children: [
            if (_wholesalerProfile!.companyName != null)
              _buildInfoRow(Icons.business, 'Company', _wholesalerProfile!.companyName!),
            _buildInfoRow(Icons.person_outline, 'Owner', _wholesalerProfile!.ownerName),
            _buildCategoriesRow('Categories', _wholesalerProfile!.businessCategories),
            if (_wholesalerProfile!.customCategory != null)
              _buildInfoRow(
                Icons.category_outlined,
                'Custom Category',
                _wholesalerProfile!.customCategory!,
              ),
          ],
        ),
        _buildLocationSection(_wholesalerProfile!.location),
        if (_wholesalerProfile!.gstNumber != null ||
            _wholesalerProfile!.panNumber != null ||
            _wholesalerProfile!.businessLicense != null)
          _buildSectionCard(
            title: 'Registration Details',
            icon: Icons.assignment_outlined,
            children: [
              if (_wholesalerProfile!.gstNumber != null)
                _buildInfoRow(Icons.numbers, 'GST Number', _wholesalerProfile!.gstNumber!),
              if (_wholesalerProfile!.panNumber != null)
                _buildInfoRow(Icons.credit_card, 'PAN Number', _wholesalerProfile!.panNumber!),
              if (_wholesalerProfile!.businessLicense != null)
                _buildInfoRow(Icons.verified_outlined, 'License', _wholesalerProfile!.businessLicense!),
            ],
          ),
      ],
    );
  }

  Widget _buildLocationSection(ShopLocation location) {
    return _buildSectionCard(
      title: 'Location',
      icon: Icons.location_on_outlined,
      children: [
        _buildInfoRow(Icons.location_on, 'Address', location.address),
        Row(
          children: [
            Expanded(
              child: _buildInfoRow(
                Icons.location_city,
                'City',
                location.city ?? 'N/A',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildInfoRow(
                Icons.map_outlined,
                'State',
                location.state ?? 'N/A',
              ),
            ),
          ],
        ),
        _buildInfoRow(Icons.pin_drop_outlined, 'PIN Code', location.pincode ?? 'N/A'),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF6C63FF), size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: const Color(0xFF6C63FF).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: const Color(0xFF6C63FF)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesRow(String label, List<String> categories) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.category_outlined, size: 16, color: Color(0xFF6C63FF)),
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: categories
                .map(
                  (category) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C63FF).withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: const Color(0xFF6C63FF).withValues(alpha: 0.20),
                      ),
                    ),
                    child: Text(
                      category,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF6C63FF),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
