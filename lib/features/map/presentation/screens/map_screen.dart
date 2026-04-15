import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/marketplace_models.dart';
import '../../../../shared/services/marketplace_service.dart';
import 'package:nutonium/features/social/presentation/screens/shop_inventory_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({
    super.key,
    this.highlightedShopId,
    required this.onOpenCart,
  });

  final String? highlightedShopId;
  final VoidCallback onOpenCart;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MarketplaceService _marketplace = MarketplaceService.instance;
  final MapController _mapController = MapController();
  bool _mapReady = false;

  List<MarketplaceShop> _shops = const [];
  bool _isLoading = true;
  String? _error;
  String _activeFilter = 'all';
  String? _selectedShopId;

  // Kerala bounding box centre
  static const LatLng _keralaCenter = LatLng(10.5276, 76.2144);
  static const double _defaultZoom = 7.4;

  @override
  void initState() {
    super.initState();
    _loadShops();
  }

  @override
  void didUpdateWidget(covariant MapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.highlightedShopId != oldWidget.highlightedShopId &&
        widget.highlightedShopId != null) {
      _selectShop(widget.highlightedShopId!);
    }
  }

  Future<void> _loadShops() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _mapReady = false;
    });

    try {
      final shops = await _marketplace.loadNutoniumShops();
      if (!mounted) return;

      setState(() {
        _shops = shops;
        _selectedShopId = widget.highlightedShopId ?? shops.firstOrNull?.id;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  List<MarketplaceShop> get _visibleShops {
    switch (_activeFilter) {
      case 'retailers':
        return _shops.where((s) => s.kind == ShopKind.retailer).toList();
      case 'wholesalers':
        return _shops.where((s) => s.kind == ShopKind.wholesaler).toList();
      case 'ready':
        return _shops.where((s) => s.stockLevel != StockLevel.low).toList();
      default:
        return _shops;
    }
  }

  MarketplaceShop? get _selectedShop {
    return _visibleShops.where((s) => s.id == _selectedShopId).firstOrNull ??
        _shops.where((s) => s.id == _selectedShopId).firstOrNull;
  }

  void _selectShop(String shopId) {
    setState(() => _selectedShopId = shopId);
    final shop = _shops.where((s) => s.id == shopId).firstOrNull;
    if (shop != null && _mapReady) {
      _moveTo(shop);
    }
  }

  void _moveTo(MarketplaceShop shop) {
    if (!_mapReady) return;
    try {
      _mapController.move(
          LatLng(shop.latitude, shop.longitude), 11.0);
    } catch (_) {}
  }

  void _addStarterPack(MarketplaceShop shop) {
    final starter = shop.products.firstOrNull;
    if (starter == null) return;
    _marketplace.addProductToCart(shop: shop, product: starter);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${starter.name} added from ${shop.name}.')),
    );
    widget.onOpenCart();
  }

  void _openShopInventory(MarketplaceShop shop) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ShopInventoryScreen(
          shop: shop,
          onOpenCart: widget.onOpenCart,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppPalette.forest));
    }

    if (_error != null) {
      return _ErrorState(error: _error!, onRetry: _loadShops);
    }

    final visibleShops = _visibleShops;
    final selectedShop = _selectedShop ?? visibleShops.firstOrNull;
    final readyCount =
        _shops.where((s) => s.stockLevel != StockLevel.low).length;

    return RefreshIndicator(
      onRefresh: _loadShops,
      color: AppPalette.forest,
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
        children: [
          _MapHero(
            totalShops: _shops.length,
            readyCount: readyCount,
            wholesalerCount:
                _shops.where((s) => s.kind == ShopKind.wholesaler).length,
          ),
          const SizedBox(height: 12),
          _MapFilterRail(
            activeFilter: _activeFilter,
            onChanged: (value) {
              setState(() {
                _activeFilter = value;
                _selectedShopId = _visibleShops.firstOrNull?.id ??
                    _shops.firstOrNull?.id;
              });
            },
          ),
          const SizedBox(height: 14),

          // ── Kerala map ──────────────────────────────────────────────────
          Container(
            height: 400,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: AppPalette.forest.withValues(alpha: 0.10),
              ),
            ),
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    // Kerala centre
                    initialCenter: _keralaCenter,
                    initialZoom: _defaultZoom,
                    // Soft bounds around Kerala
                    cameraConstraint: CameraConstraint.containCenter(
                      bounds: LatLngBounds(
                        const LatLng(7.9, 74.5),
                        const LatLng(12.8, 78.0),
                      ),
                    ),
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.pinchZoom |
                          InteractiveFlag.drag |
                          InteractiveFlag.doubleTapZoom,
                    ),
                    onMapReady: () {
                      setState(() => _mapReady = true);
                      final shop = selectedShop;
                      if (shop != null) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _moveTo(shop);
                        });
                      }
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.nutonium.app',
                    ),
                    MarkerLayer(
                      markers: visibleShops
                          .map((shop) => Marker(
                                point:
                                    LatLng(shop.latitude, shop.longitude),
                                width: 84,
                                height: 84,
                                child: GestureDetector(
                                  onTap: () => _selectShop(shop.id),
                                  child: _MapMarker(
                                    shop: shop,
                                    selected: _selectedShopId == shop.id,
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  ],
                ),

                // "Kerala map" label pill
                Positioned(
                  left: 12,
                  top: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppPalette.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Nutonium · Kerala',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: AppPalette.forest,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Selected shop panel overlay
                if (selectedShop != null)
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 12,
                    child: _SelectedShopPanel(
                      shop: selectedShop,
                      onAddStarterPack: () => _addStarterPack(selectedShop),
                      onViewInventory: () =>
                          _openShopInventory(selectedShop),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // ── Shop list ─────────────────────────────────────────────────
          Text(
            '${visibleShops.length} seller${visibleShops.length != 1 ? 's' : ''} on map',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          ...visibleShops.map(
            (shop) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ShopTile(
                shop: shop,
                selected: _selectedShopId == shop.id,
                onTap: () => _selectShop(shop.id),
                onAddStarterPack: () => _addStarterPack(shop),
                onViewInventory: () => _openShopInventory(shop),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Hero ─────────────────────────────────────────────────────────────────────

class _MapHero extends StatelessWidget {
  const _MapHero({
    required this.totalShops,
    required this.readyCount,
    required this.wholesalerCount,
  });

  final int totalShops;
  final int readyCount;
  final int wholesalerCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppPalette.card,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppPalette.forest.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Kerala seller map',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(
                      'Live stock points across Kochi, Ernakulam, Kozhikode, Thiruvananthapuram and more.',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppPalette.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _MapStat(value: '$totalShops', label: 'mapped sellers'),
              const SizedBox(width: 10),
              _MapStat(value: '$readyCount', label: 'ready stock'),
              const SizedBox(width: 10),
              _MapStat(value: '$wholesalerCount', label: 'bulk desks'),
            ],
          ),
        ],
      ),
    );
  }
}

class _MapStat extends StatelessWidget {
  const _MapStat({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: AppPalette.parchment,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: AppPalette.muted),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Filter rail ──────────────────────────────────────────────────────────────

class _MapFilterRail extends StatelessWidget {
  const _MapFilterRail({
    required this.activeFilter,
    required this.onChanged,
  });

  final String activeFilter;
  final void Function(String) onChanged;

  @override
  Widget build(BuildContext context) {
    final filters = [
      ('all', 'All'),
      ('ready', 'Ready stock'),
      ('retailers', 'Retailers'),
      ('wholesalers', 'Wholesale'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final selected = activeFilter == f.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(f.$2),
              selected: selected,
              onSelected: (_) => onChanged(f.$1),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Map marker ───────────────────────────────────────────────────────────────

class _MapMarker extends StatelessWidget {
  const _MapMarker({required this.shop, required this.selected});
  final MarketplaceShop shop;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = shop.stockLevel.color;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: selected ? 48 : 38,
          height: selected ? 48 : 38,
          decoration: BoxDecoration(
            color: selected ? AppPalette.forest : color,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white,
              width: selected ? 3 : 2,
            ),
            boxShadow: [
              BoxShadow(
                color: (selected ? AppPalette.forest : color)
                    .withValues(alpha: 0.35),
                blurRadius: selected ? 18 : 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(
            shop.kind == ShopKind.wholesaler
                ? Icons.warehouse_outlined
                : Icons.storefront_outlined,
            color: Colors.white,
            size: selected ? 24 : 20,
          ),
        ),
        Container(
          width: 2,
          height: 10,
          color: selected ? AppPalette.forest : color,
        ),
      ],
    );
  }
}

// ─── Selected shop panel ──────────────────────────────────────────────────────

class _SelectedShopPanel extends StatelessWidget {
  const _SelectedShopPanel({
    required this.shop,
    required this.onAddStarterPack,
    required this.onViewInventory,
  });

  final MarketplaceShop shop;
  final VoidCallback onAddStarterPack;
  final VoidCallback onViewInventory;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppPalette.forest.withValues(alpha: 0.14),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: shop.stockLevel.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  shop.kind == ShopKind.wholesaler
                      ? Icons.warehouse_outlined
                      : Icons.storefront_outlined,
                  color: shop.stockLevel.color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shop.name,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${shop.placeLabel}  ·  ${shop.stockLevel.label}',
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: AppPalette.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: onAddStarterPack,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, 38),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                ),
                child: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onViewInventory,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 36),
                  ),
                  icon: const Icon(Icons.inventory_2_outlined, size: 14),
                  label: const Text('View inventory'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 36),
                  ),
                  icon: const Icon(Icons.directions_rounded, size: 14),
                  label: const Text('Directions'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Shop tile ────────────────────────────────────────────────────────────────

class _ShopTile extends StatelessWidget {
  const _ShopTile({
    required this.shop,
    required this.selected,
    required this.onTap,
    required this.onAddStarterPack,
    required this.onViewInventory,
  });

  final MarketplaceShop shop;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onAddStarterPack;
  final VoidCallback onViewInventory;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? AppPalette.forest.withValues(alpha: 0.04)
              : AppPalette.card,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected
                ? AppPalette.forest
                : AppPalette.forest.withValues(alpha: 0.08),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color:
                        shop.stockLevel.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    shop.kind == ShopKind.wholesaler
                        ? Icons.warehouse_outlined
                        : Icons.storefront_outlined,
                    color: shop.stockLevel.color,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              shop.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: shop.stockLevel.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${shop.kind.label}  ·  ${shop.placeLabel}',
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(color: AppPalette.muted),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        shop.turnaround,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppPalette.muted),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: shop.tags
                            .map(
                              (tag) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppPalette.forest
                                      .withValues(alpha: 0.07),
                                  borderRadius:
                                      BorderRadius.circular(999),
                                ),
                                child: Text(
                                  tag,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(color: AppPalette.forest),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onViewInventory,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 36),
                    ),
                    icon: const Icon(Icons.inventory_2_outlined, size: 14),
                    label: const Text('Inventory'),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: onAddStarterPack,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: const Text('Quick add'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Error state ─────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error, required this.onRetry});
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
            const Icon(Icons.map_outlined, size: 56, color: AppPalette.muted),
            const SizedBox(height: 16),
            Text('Could not load map data',
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

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}