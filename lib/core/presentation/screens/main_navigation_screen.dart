import 'package:flutter/material.dart';

import '../../../features/camera/presentation/screens/camera_capture_screen.dart';
import '../../../features/cart/presentation/screens/cart_screen.dart';
import '../../../features/map/presentation/screens/map_screen.dart';
import '../../../features/profile/presentation/screens/profile_screen.dart';
import '../../../features/social/presentation/screens/social_screen.dart';
import '../../../shared/services/marketplace_service.dart';
import '../../../shared/widgets/navigation/bottom_navigation.dart';
import '../../../shared/widgets/navigation/top_bar.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  final GlobalKey<SocialScreenState> _socialScreenKey =
      GlobalKey<SocialScreenState>();
  final MarketplaceService _marketplace = MarketplaceService.instance;

  int _currentIndex = 0;
  String? _selectedMapShopId;

  (String, String) get _pageMeta {
    switch (_currentIndex) {
      case 1:
        return (
          'Cart',
          'Build your procurement draft, adjust units, and close the best margin.',
        );
      case 2:
        return (
          'Nutonium Map',
          'Track live stock points, compare sellers, and move straight into a purchase.',
        );
      default:
        return (
          'Nutonium Market',
          'Offers, events, and trade intelligence from retailers and wholesalers.',
        );
    }
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _openMapForShop(String shopId) {
    setState(() {
      _selectedMapShopId = shopId;
      _currentIndex = 2;
    });
  }

  void _openCart() {
    setState(() {
      _currentIndex = 1;
    });
  }

  Future<void> _handleCameraPress() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CameraCaptureScreen()),
    );
  }

  Future<void> _handleQrPress() async {
    final applied = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _TradeCodeSheet(),
    );

    if (applied == null || applied.trim().isEmpty) return;

    final code = applied.trim().toUpperCase();
    final mappings = <String, (String, String)>{
      'HARBOR-CORE': ('harbor-traders', 'harbor-core-drum'),
      'HARBOR-ROLL': ('harbor-traders', 'harbor-rollout-kit'),
      'CROWN-SHELF': ('crown-retail-depot', 'crown-shelf-pack'),
      'CROWN-TRIAL': ('crown-retail-depot', 'crown-trial-case'),
      'CAPITAL-CORE': ('capital-supply-house', 'capital-core-drum'),
      'MALABAR-TRIAL': ('malabar-select', 'malabar-trial-case'),
    };

    final mapping = mappings[code];
    if (mapping == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unknown trade code. Try one from the list.'),
        ),
      );
      return;
    }

    final shop = _marketplace.findSeededShop(mapping.$1);
    final product = _marketplace.findProduct(mapping.$2);
    if (shop == null || product == null) return;

    _marketplace.addProductToCart(shop: shop, product: product);
    if (!mounted) return;

    _openCart();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${product.name} added from trade code $code.')),
    );
  }

  Future<void> _handleMenuPress() async {
    final selected = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const _QuickMenuSheet(),
    );

    if (selected == null) return;

    switch (selected) {
      case 0:
        _onTabTapped(1);
      case 1:
        _onTabTapped(2);
      case 2:
        _onTabTapped(3);
      default:
        _onTabTapped(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final meta = _pageMeta;
    final isProfile = _currentIndex == 3;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        top: !isProfile,
        child: Column(
          children: [
            if (!isProfile)
              TopBar(
                title: meta.$1,
                subtitle: meta.$2,
                onSearchPress:
                    _currentIndex == 0 ? _handleSearchPress : null,
                onQrPress: _currentIndex == 0 ? _handleQrPress : null,
                onCameraPress:
                    _currentIndex == 0 ? _handleCameraPress : null,
                onMenuPress: _handleMenuPress,
              ),
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: [
                  SocialScreen(
                    key: _socialScreenKey,
                    onLocateShop: _openMapForShop,
                    onOpenCart: _openCart,
                  ),
                  CartScreen(
                    onBrowseMarket: () => _onTabTapped(0),
                    onBrowseMap: () => _onTabTapped(2),
                  ),
                  MapScreen(
                    highlightedShopId: _selectedMapShopId,
                    onOpenCart: _openCart,
                  ),
                  ProfileScreen(onMenuPress: _handleMenuPress),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: ValueListenableBuilder<List<dynamic>>(
        valueListenable: _marketplace.cartItems,
        builder: (context, items, _) {
          return CustomBottomNavigation(
            currentIndex: _currentIndex,
            onTap: _onTabTapped,
            cartCount: items.length,
          );
        },
      ),
    );
  }

  void _handleSearchPress() {
    _socialScreenKey.currentState?.startSearch();
  }
}

// ─── Trade code sheet ─────────────────────────────────────────────────────────

class _TradeCodeSheet extends StatefulWidget {
  const _TradeCodeSheet();

  @override
  State<_TradeCodeSheet> createState() => _TradeCodeSheetState();
}

class _TradeCodeSheetState extends State<_TradeCodeSheet> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Trade code handoff',
                  style: theme.textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                'Paste the code from a retailer or wholesaler to pull the mapped Nutonium SKU straight into the cart.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color:
                      theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _controller,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Trade code',
                  hintText: 'Example: HARBOR-CORE',
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: const [
                  _CodeHint('HARBOR-CORE'),
                  _CodeHint('CROWN-SHELF'),
                  _CodeHint('CAPITAL-CORE'),
                  _CodeHint('MALABAR-TRIAL'),
                ],
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: () =>
                    Navigator.of(context).pop(_controller.text),
                child: const Text('Apply code'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CodeHint extends StatelessWidget {
  const _CodeHint(this.code);
  final String code;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .primary
            .withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        code,
        style: Theme.of(context)
            .textTheme
            .labelMedium
            ?.copyWith(fontWeight: FontWeight.w800),
      ),
    );
  }
}

// ─── Quick menu sheet ─────────────────────────────────────────────────────────

class _QuickMenuSheet extends StatelessWidget {
  const _QuickMenuSheet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _MenuTile(
                icon: Icons.shopping_bag_outlined,
                title: 'Open procurement cart',
                subtitle: 'Adjust quantities and close the order.',
                onTap: () => Navigator.of(context).pop(0),
              ),
              _MenuTile(
                icon: Icons.place_outlined,
                title: 'Open shop map',
                subtitle: 'Inspect every live Nutonium stock point.',
                onTap: () => Navigator.of(context).pop(1),
              ),
              _MenuTile(
                icon: Icons.person_outline,
                title: 'Open profile',
                subtitle: 'Check business details and account state.',
                onTap: () => Navigator.of(context).pop(2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: theme.colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}