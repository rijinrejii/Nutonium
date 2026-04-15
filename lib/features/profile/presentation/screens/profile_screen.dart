import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../icons/menu_icon.dart';
import '../../../auth/domain/entities/user.dart' as app_user;
import '../../domain/entities/retailer_profile.dart';
import '../../domain/entities/shop_location.dart';
import '../../domain/entities/wholesaler_profile.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.onMenuPress});

  /// Callback wired to the menu icon inside the profile header.
  final VoidCallback? onMenuPress;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  bool _isLoggingOut = false;
  app_user.User? _userData;
  RetailerProfile? _retailerProfile;
  WholesalerProfile? _wholesalerProfile;

  // ── Firestore helpers ──────────────────────────────────────────────────────

  DateTime _readDateTime(Object? value, {DateTime? fallback}) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return fallback ?? DateTime.now();
  }

  DateTime? _readNullableDateTime(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  Map<String, dynamic> _readMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), v));
    }
    return <String, dynamic>{};
  }

  // ── Data loading ───────────────────────────────────────────────────────────

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

      final data = userDoc.data()!;
      final role = UserRole.fromString(data['role'] ?? 'customer');

      _userData = app_user.User(
        id: firebaseUser.uid,
        email: data['email'] ?? '',
        phoneNumber: data['phoneNumber'],
        displayName: data['displayName'],
        photoUrl: data['photoUrl'],
        role: role,
        isProfileComplete: data['isProfileComplete'] ?? false,
        createdAt: _readDateTime(
          data['createdAt'],
          fallback: firebaseUser.metadata.creationTime,
        ),
        updatedAt: _readNullableDateTime(data['updatedAt']),
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
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    }
  }

  Future<void> _loadRetailerProfile(String uid) async {
    final doc = await FirebaseFirestore.instance
        .collection(FirestoreCollections.retailers)
        .doc(uid)
        .get();
    if (!doc.exists) return;
    final d = doc.data()!;
    final loc = _readMap(d['location']);
    _retailerProfile = RetailerProfile(
      userId: d['userId'],
      ownerName: d['ownerName'],
      shopName: d['shopName'],
      shopCategories: List<String>.from(d['shopCategories']),
      customCategory: d['customCategory'],
      location: ShopLocation(
        latitude: loc['latitude']?.toDouble() ?? 0.0,
        longitude: loc['longitude']?.toDouble() ?? 0.0,
        address: loc['address'] ?? '',
        city: loc['city'],
        state: loc['state'],
        pincode: loc['pincode'] ?? loc['pinCode'],
      ),
      gstNumber: d['gstNumber'],
      businessLicense: d['businessLicense'],
      createdAt: _readDateTime(d['createdAt']),
      updatedAt: _readNullableDateTime(d['updatedAt']),
    );
  }

  Future<void> _loadWholesalerProfile(String uid) async {
    final doc = await FirebaseFirestore.instance
        .collection(FirestoreCollections.wholesalers)
        .doc(uid)
        .get();
    if (!doc.exists) return;
    final d = doc.data()!;
    final loc = _readMap(d['location']);
    _wholesalerProfile = WholesalerProfile(
      userId: d['userId'],
      ownerName: d['ownerName'],
      companyName: d['companyName'],
      businessCategories: List<String>.from(d['businessCategories']),
      customCategory: d['customCategory'],
      location: ShopLocation(
        latitude: loc['latitude']?.toDouble() ?? 0.0,
        longitude: loc['longitude']?.toDouble() ?? 0.0,
        address: loc['address'] ?? '',
        city: loc['city'],
        state: loc['state'],
        pincode: loc['pincode'] ?? loc['pinCode'],
      ),
      gstNumber: d['gstNumber'],
      panNumber: d['panNumber'],
      businessLicense: d['businessLicense'],
      createdAt: _readDateTime(d['createdAt']),
      updatedAt: _readNullableDateTime(d['updatedAt']),
    );
  }

  // ── Logout ─────────────────────────────────────────────────────────────────

  Future<void> _logout() async {
    if (_isLoggingOut) return;
    FocusScope.of(context).unfocus();
    setState(() => _isLoggingOut = true);
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      if (mounted) {
        setState(() => _isLoggingOut = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  String _displayName() {
    if (_userData?.displayName?.isNotEmpty == true) {
      return _userData!.displayName!;
    }
    if (_retailerProfile != null) return _retailerProfile!.ownerName;
    if (_wholesalerProfile != null) return _wholesalerProfile!.ownerName;
    return 'User';
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppPalette.forest),
      );
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          // ── Dark header with menu icon overlaid in top-right corner ────
          _ProfileHeader(
            displayName: _displayName(),
            email: _userData?.email ?? '',
            photoUrl: _userData?.photoUrl,
            onMenuPress: widget.onMenuPress,
          ),

          // ── Scrollable menu sections ───────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
            child: Column(
              children: [
                // ACTIVITY
                _MenuSection(
                  title: 'ACTIVITY',
                  items: [
                    _MenuItem(
                      icon: Icons.favorite_border_rounded,
                      label: 'Liked Posts',
                      badge: 24,
                      onTap: () {},
                    ),
                    _MenuItem(
                      icon: Icons.bookmark_border_rounded,
                      label: 'Saved Items',
                      badge: 12,
                      onTap: () {},
                    ),
                    _MenuItem(
                      icon: Icons.shopping_bag_outlined,
                      label: 'My Orders',
                      badge: 3,
                      onTap: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // PREFERENCES
                _MenuSection(
                  title: 'PREFERENCES',
                  items: [
                    _MenuItem(
                      icon: Icons.settings_outlined,
                      label: 'Settings',
                      onTap: () {},
                    ),
                    _MenuItem(
                      icon: Icons.notifications_none_rounded,
                      label: 'Notifications',
                      onTap: () {},
                    ),
                    _MenuItem(
                      icon: Icons.credit_card_outlined,
                      label: 'Payment Methods',
                      onTap: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // SUPPORT
                _MenuSection(
                  title: 'SUPPORT',
                  items: [
                    _MenuItem(
                      icon: Icons.help_outline_rounded,
                      label: 'Help Center',
                      onTap: () {},
                    ),
                    _MenuItem(
                      icon: Icons.logout_rounded,
                      label: _isLoggingOut ? 'Signing out…' : 'Sign Out',
                      isDestructive: true,
                      onTap: _isLoggingOut ? null : _logout,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Profile Header ───────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.displayName,
    required this.email,
    required this.photoUrl,
    this.onMenuPress,
  });

  final String displayName;
  final String email;
  final String? photoUrl;
  final VoidCallback? onMenuPress;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Stack(
      children: [
        // ── Dark green background panel ──────────────────────────────────
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: AppPalette.forestDeep,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
          ),
          padding: EdgeInsets.fromLTRB(24, topPadding + 12, 24, 32),
          child: Column(
            children: [
              // Avatar
              _Avatar(photoUrl: photoUrl, displayName: displayName, size: 96),
              const SizedBox(height: 16),

              // Name
              Text(
                displayName,
                style:
                    Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
              ),
              const SizedBox(height: 4),

              // Email
              Text(
                email,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.60),
                    ),
              ),
              const SizedBox(height: 24),

              // Stats row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _StatItem(value: '127', label: 'Posts'),
                  _VerticalDivider(),
                  _StatItem(value: '2.4K', label: 'Followers'),
                  _VerticalDivider(),
                  _StatItem(value: '856', label: 'Following'),
                ],
              ),
            ],
          ),
        ),

        // ── Menu icon — overlaid on top-right of the header ──────────────
        if (onMenuPress != null)
          Positioned(
            top: topPadding + 4,
            right: 12,
            child: Material(
              color: Colors.white.withValues(alpha: 0.10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: InkWell(
                onTap: onMenuPress,
                borderRadius: BorderRadius.circular(16),
                child: const SizedBox(
                  width: 44,
                  height: 44,
                  child: Center(
                    child: MenuIcon(size: 22, color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Stat item ────────────────────────────────────────────────────────────────

class _StatItem extends StatelessWidget {
  const _StatItem({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.55),
                ),
          ),
        ],
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 32,
      color: Colors.white.withValues(alpha: 0.15),
    );
  }
}

// ─── Avatar ───────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.photoUrl,
    required this.displayName,
    this.size = 68,
  });

  final String? photoUrl;
  final String displayName;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppPalette.brass.withValues(alpha: 0.85),
      ),
      child: photoUrl != null && photoUrl!.isNotEmpty
          ? ClipOval(
              child: Image.network(photoUrl!, fit: BoxFit.cover),
            )
          : Center(
              child: Icon(
                Icons.person_rounded,
                color: AppPalette.forestDeep,
                size: size * 0.50,
              ),
            ),
    );
  }
}

// ─── Menu Section ─────────────────────────────────────────────────────────────

class _MenuSection extends StatelessWidget {
  const _MenuSection({required this.title, required this.items});

  final String title;
  final List<_MenuItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            title,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppPalette.muted,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  fontSize: 11,
                ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppPalette.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppPalette.forest.withValues(alpha: 0.07),
            ),
          ),
          child: Column(
            children: List.generate(items.length, (i) {
              final item = items[i];
              final isLast = i == items.length - 1;
              return Column(
                children: [
                  item,
                  if (!isLast)
                    Divider(
                      height: 1,
                      indent: 60,
                      endIndent: 16,
                      color: AppPalette.forest.withValues(alpha: 0.07),
                    ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }
}

// ─── Menu Item ────────────────────────────────────────────────────────────────

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
    this.badge,
    this.isDestructive = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final int? badge;
  final bool isDestructive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppPalette.danger : AppPalette.forest;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Icon container
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 14),

            // Label
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDestructive ? AppPalette.danger : null,
                    ),
              ),
            ),

            // Badge
            if (badge != null) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: AppPalette.brass,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$badge',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                ),
              ),
              const SizedBox(width: 8),
            ],

            // Chevron
            Icon(
              Icons.chevron_right_rounded,
              color: AppPalette.muted.withValues(alpha: 0.50),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Kept helpers (used by retailer/wholesaler sections if needed) ─────────────

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppPalette.forest.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: AppPalette.forest),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppPalette.muted,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TagsRow extends StatelessWidget {
  const _TagsRow({required this.label, required this.tags});

  final String label;
  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppPalette.muted,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: tags
                .map(
                  (tag) => Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppPalette.forest.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                          color: AppPalette.forest.withValues(alpha: 0.14)),
                    ),
                    child: Text(
                      tag,
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(
                            color: AppPalette.forest,
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