import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/marketplace_models.dart';
import '../../../../shared/services/marketplace_service.dart';
import 'shop_inventory_screen.dart';

// ─── Public API ────────────────────────────────────────────────────────────────

class SocialScreen extends StatefulWidget {
  const SocialScreen({
    super.key,
    required this.onLocateShop,
    required this.onOpenCart,
  });

  final void Function(String shopId) onLocateShop;
  final VoidCallback onOpenCart;

  @override
  State<SocialScreen> createState() => SocialScreenState();
}

// ─── State (public so GlobalKey works from MainNavigationScreen) ───────────────

class SocialScreenState extends State<SocialScreen> {
  final MarketplaceService _marketplace = MarketplaceService.instance;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  List<MarketplacePost> _allPosts = const [];
  List<MarketplaceShop> _shops = const [];
  bool _isLoading = true;
  String? _error;
  String _activeFilter = 'all'; // all | offers | events | updates
  bool _isSearching = false;
  String _searchQuery = '';

  // Locally tracked likes per post id
  final Map<String, bool> _liked = {};

  @override
  void initState() {
    super.initState();
    _load();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  // Called by MainNavigationScreen via GlobalKey
  void startSearch() {
    setState(() => _isSearching = true);
    _searchFocus.requestFocus();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _marketplace.loadFeed(),
        _marketplace.loadNutoniumShops(),
      ]);
      if (!mounted) return;
      setState(() {
        _allPosts = results[0] as List<MarketplacePost>;
        _shops = results[1] as List<MarketplaceShop>;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<MarketplacePost> get _visiblePosts {
    var posts = _allPosts;

    // Filter by tab
    switch (_activeFilter) {
      case 'offers':
        posts = posts.where((p) => p.kind == PostKind.offer).toList();
      case 'events':
        posts = posts.where((p) => p.kind == PostKind.event).toList();
      case 'updates':
        posts = posts.where((p) => p.kind == PostKind.update).toList();
    }

    // Search
    if (_searchQuery.isNotEmpty) {
      posts = posts.where((p) {
        return p.title.toLowerCase().contains(_searchQuery) ||
            p.shopName.toLowerCase().contains(_searchQuery) ||
            p.description.toLowerCase().contains(_searchQuery) ||
            p.locationLabel.toLowerCase().contains(_searchQuery);
      }).toList();
    }

    // Pinned first
    final pinned = posts.where((p) => p.pinned).toList();
    final rest = posts.where((p) => !p.pinned).toList();
    return [...pinned, ...rest];
  }

  MarketplaceShop? _shopFor(String shopId) {
    try {
      return _shops.firstWhere((s) => s.id == shopId);
    } catch (_) {
      return null;
    }
  }

  void _openShopInventory(String shopId) {
    final shop = _shopFor(shopId);
    if (shop == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ShopInventoryScreen(
          shop: shop,
          onOpenCart: widget.onOpenCart,
        ),
      ),
    );
  }

  void _handlePrimaryCta(MarketplacePost post) {
    if (post.kind == PostKind.offer) {
      final shop = _shopFor(post.shopId);
      if (shop == null || post.productId == null) return;
      final product = _marketplace.findProduct(post.productId!);
      if (product == null) return;
      _marketplace.addProductToCart(shop: shop, product: product);
      widget.onOpenCart();
    } else {
      // event → open shop inventory
      _openShopInventory(post.shopId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Filter rail / search bar ────────────────────────────────────────
        _buildFilterBar(context),

        // ── Content ────────────────────────────────────────────────────────
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppPalette.forest))
              : _error != null
                  ? _ErrorView(error: _error!, onRetry: _load)
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppPalette.forest,
                      child: _buildFeed(context),
                    ),
        ),
      ],
    );
  }

  Widget _buildFilterBar(BuildContext context) {
    if (_isSearching) {
      return Container(
        color: AppPalette.card,
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocus,
                textInputAction: TextInputAction.search,
                decoration: const InputDecoration(
                  hintText: 'Search offers, shops, events…',
                  prefixIcon: Icon(Icons.search_rounded, size: 20),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () {
                setState(() {
                  _isSearching = false;
                  _searchQuery = '';
                  _searchController.clear();
                  _searchFocus.unfocus();
                });
              },
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
    }

    return Container(
      color: AppPalette.card,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Row(
          children: [
            _FilterChip(
                label: 'All',
                active: _activeFilter == 'all',
                onTap: () => setState(() => _activeFilter = 'all')),
            const SizedBox(width: 8),
            _FilterChip(
                label: 'Offers',
                active: _activeFilter == 'offers',
                onTap: () => setState(() => _activeFilter = 'offers')),
            const SizedBox(width: 8),
            _FilterChip(
                label: 'Events',
                active: _activeFilter == 'events',
                onTap: () => setState(() => _activeFilter = 'events')),
            const SizedBox(width: 8),
            _FilterChip(
                label: 'Updates',
                active: _activeFilter == 'updates',
                onTap: () => setState(() => _activeFilter = 'updates')),
            const SizedBox(width: 8),
            _FilterChip(
                label: 'Retail',
                active: _activeFilter == 'retail',
                onTap: () => setState(() => _activeFilter = 'retail')),
          ],
        ),
      ),
    );
  }

  Widget _buildFeed(BuildContext context) {
    final posts = _visiblePosts;

    if (posts.isEmpty) {
      return _EmptyFeedView(
        query: _searchQuery,
        onClear: () {
          setState(() {
            _searchQuery = '';
            _searchController.clear();
            _activeFilter = 'all';
          });
        },
      );
    }

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 32),
      itemCount: posts.length,
      separatorBuilder: (_, __) =>
          Divider(height: 1, color: AppPalette.forest.withValues(alpha: 0.07)),
      itemBuilder: (context, index) {
        final post = posts[index];
        final shop = _shopFor(post.shopId);
        final isLiked = _liked[post.id] ?? false;

        return _PostCard(
          post: post,
          shop: shop,
          isLiked: isLiked,
          onAvatarTap: () => _openShopInventory(post.shopId),
          onShopNameTap: () => _openShopInventory(post.shopId),
          onLike: () => setState(() => _liked[post.id] = !isLiked),
          onPrimaryCta: () => _handlePrimaryCta(post),
          onLocate: () => widget.onLocateShop(post.shopId),
        );
      },
    );
  }
}

// ─── Post card ────────────────────────────────────────────────────────────────

class _PostCard extends StatelessWidget {
  const _PostCard({
    required this.post,
    required this.shop,
    required this.isLiked,
    required this.onAvatarTap,
    required this.onShopNameTap,
    required this.onLike,
    required this.onPrimaryCta,
    required this.onLocate,
  });

  final MarketplacePost post;
  final MarketplaceShop? shop;
  final bool isLiked;
  final VoidCallback onAvatarTap;
  final VoidCallback onShopNameTap;
  final VoidCallback onLike;
  final VoidCallback onPrimaryCta;
  final VoidCallback onLocate;

  static final _currency = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  static final _dateFormat = DateFormat('d MMM, h:mm a');

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Color get _kindColor {
    switch (post.kind) {
      case PostKind.offer:
        return AppPalette.success;
      case PostKind.event:
        return AppPalette.brass;
      case PostKind.update:
        return AppPalette.forest;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initials = post.shopName
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0] : '')
        .join()
        .toUpperCase();

    return Container(
      color: AppPalette.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                // Avatar → shop inventory
                GestureDetector(
                  onTap: onAvatarTap,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppPalette.forest,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppPalette.brass.withValues(alpha: 0.4),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        initials,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: onShopNameTap,
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                post.shopName,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            _KindBadge(
                              kind: post.kind,
                              color: _kindColor,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${post.locationLabel}  ·  ${_timeAgo(post.createdAt)}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppPalette.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Stock badge if shop available
                if (shop != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color:
                          shop!.stockLevel.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: shop!.stockLevel.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          shop!.stockLevel.label,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: shop!.stockLevel.color,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Visual hero (gradient placeholder) ────────────────────────────
          _PostHero(post: post),

          // ── Body ─────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pinned badge
                if (post.pinned) ...[
                  Row(
                    children: [
                      const Icon(Icons.push_pin_rounded,
                          size: 13, color: AppPalette.brass),
                      const SizedBox(width: 4),
                      Text(
                        'Pinned offer',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppPalette.brass,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                ],

                Text(
                  post.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  post.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppPalette.muted,
                    height: 1.45,
                  ),
                ),

                // Price row for offers
                if (post.offerPrice != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        _currency.format(post.offerPrice),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: AppPalette.forest,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (post.originalPrice != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          _currency.format(post.originalPrice),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppPalette.muted,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppPalette.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${(((post.originalPrice! - post.offerPrice!) / post.originalPrice!) * 100).round()}% off',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppPalette.success,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],

                // Event date row
                if (post.eventDate != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.event_rounded,
                          size: 15, color: AppPalette.brass),
                      const SizedBox(width: 6),
                      Text(
                        _dateFormat.format(post.eventDate!),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppPalette.muted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],

                // Valid until
                if (post.validUntil != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.timer_outlined,
                          size: 13, color: AppPalette.muted),
                      const SizedBox(width: 4),
                      Text(
                        'Valid until ${DateFormat('d MMM').format(post.validUntil!)}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppPalette.muted,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // ── Actions ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: onPrimaryCta,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 42),
                    ),
                    child: Text(post.primaryCta),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onLocate,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 42),
                    ),
                    child: Text(post.secondaryCta),
                  ),
                ),
              ],
            ),
          ),

          // ── Engagement bar ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            child: Row(
              children: [
                GestureDetector(
                  onTap: onLike,
                  child: Row(
                    children: [
                      Icon(
                        isLiked
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        size: 20,
                        color: isLiked ? AppPalette.danger : AppPalette.muted,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${post.likes + (isLiked ? 1 : 0)}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color:
                              isLiked ? AppPalette.danger : AppPalette.muted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 18),
                Row(
                  children: [
                    Icon(Icons.chat_bubble_outline_rounded,
                        size: 18, color: AppPalette.muted),
                    const SizedBox(width: 5),
                    Text(
                      '${post.comments}',
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: AppPalette.muted),
                    ),
                  ],
                ),
                const Spacer(),
                GestureDetector(
                  onTap: onAvatarTap,
                  child: Row(
                    children: [
                      Text(
                        'View inventory',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppPalette.forest,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 3),
                      const Icon(Icons.arrow_forward_rounded,
                          size: 14, color: AppPalette.forest),
                    ],
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

// ─── Post hero ────────────────────────────────────────────────────────────────

class _PostHero extends StatelessWidget {
  const _PostHero({required this.post});
  final MarketplacePost post;

  // Deterministic gradient per shop id
  static final List<List<Color>> _gradients = [
    [const Color(0xFF173327), const Color(0xFF2F7B57)],
    [const Color(0xFF1B2A4A), const Color(0xFF3B6BA0)],
    [const Color(0xFF3B2406), const Color(0xFFBF7F22)],
    [const Color(0xFF2A1A0A), const Color(0xFF8B5E3C)],
    [const Color(0xFF1A2740), const Color(0xFF2F5D8A)],
  ];

  static const _icons = [
    Icons.inventory_2_outlined,
    Icons.storefront_outlined,
    Icons.local_offer_outlined,
    Icons.event_outlined,
    Icons.warehouse_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    final idx = post.shopId.hashCode.abs() % _gradients.length;
    final gradient = _gradients[idx];
    final icon = _icons[idx];

    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
      ),
      child: Stack(
        children: [
          // Decorative pattern
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            left: -20,
            bottom: -40,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          // Center icon
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(icon, color: Colors.white, size: 32),
                ),
                const SizedBox(height: 10),
                if (post.kind == PostKind.offer && post.shopKind != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      post.shopKind.label.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
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

// ─── Kind badge ──────────────────────────────────────────────────────────────

class _KindBadge extends StatelessWidget {
  const _KindBadge({required this.kind, required this.color});
  final PostKind kind;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        kind.label.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

// ─── Filter chip ─────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.active,
    required this.onTap,
  });
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppPalette.forest : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active
                ? AppPalette.forest
                : AppPalette.forest.withValues(alpha: 0.15),
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: active ? Colors.white : AppPalette.muted,
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
    );
  }
}

// ─── Empty / error states ────────────────────────────────────────────────────

class _EmptyFeedView extends StatelessWidget {
  const _EmptyFeedView({required this.query, required this.onClear});
  final String query;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded,
                size: 56, color: AppPalette.muted.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text(
              query.isEmpty
                  ? 'No posts in this category'
                  : 'No results for "$query"',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different filter or clear the search.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppPalette.muted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            OutlinedButton(onPressed: onClear, child: const Text('Clear')),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});
  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded,
                size: 56, color: AppPalette.muted),
            const SizedBox(height: 16),
            Text('Could not load feed',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(error,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppPalette.muted),
                textAlign: TextAlign.center),
            const SizedBox(height: 18),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}