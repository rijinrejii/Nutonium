import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/marketplace_models.dart';
import '../../../../shared/services/marketplace_service.dart';

// ─── Entry point ──────────────────────────────────────────────────────────────

class ShopInventoryScreen extends StatefulWidget {
  const ShopInventoryScreen({
    super.key,
    required this.shop,
    required this.onOpenCart,
  });

  final MarketplaceShop shop;
  final VoidCallback onOpenCart;

  @override
  State<ShopInventoryScreen> createState() => _ShopInventoryScreenState();
}

class _ShopInventoryScreenState extends State<ShopInventoryScreen> {
  final MarketplaceService _marketplace = MarketplaceService.instance;

  // Track qty selections per product before adding to cart
  final Map<String, int> _selections = {};

  static final _currency = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    final shop = widget.shop;

    return Scaffold(
      backgroundColor: AppPalette.parchment,
      body: Column(
        children: [
          // ── Hero header ──────────────────────────────────────────────────
          _ShopHero(shop: shop),

          // ── Product inventory grid ───────────────────────────────────────
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
              children: [
                // Shop stats row
                _StatsRow(shop: shop),
                const SizedBox(height: 20),

                // Section header
                Text(
                  'Available inventory',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  '${shop.products.length} products · ${shop.stockLevel.label}',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppPalette.muted),
                ),
                const SizedBox(height: 14),

                // Product cards
                ...shop.products.map(
                  (product) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ProductCard(
                      product: product,
                      shopKind: shop.kind,
                      qty: _selections[product.id] ?? 0,
                      onQtyChanged: (qty) =>
                          setState(() => _selections[product.id] = qty),
                      onAddToCart: () => _addToCart(product),
                    ),
                  ),
                ),

                // Tags section
                if (shop.tags.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: shop.tags
                        .map((tag) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppPalette.forest
                                    .withValues(alpha: 0.07),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                tag,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(color: AppPalette.forest),
                              ),
                            ))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),

      // ── Bottom action bar ──────────────────────────────────────────────
      bottomNavigationBar: ValueListenableBuilder<List<CartItem>>(
        valueListenable: _marketplace.cartItems,
        builder: (context, items, _) {
          final shopItems =
              items.where((i) => i.shopId == widget.shop.id).toList();
          final count = shopItems.length;
          final total =
              shopItems.fold<double>(0, (s, i) => s + i.total);

          return Container(
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              MediaQuery.of(context).padding.bottom + 12,
            ),
            decoration: BoxDecoration(
              color: AppPalette.card,
              border: Border(
                top: BorderSide(
                  color: AppPalette.forest.withValues(alpha: 0.08),
                ),
              ),
            ),
            child: count == 0
                ? OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Browse more shops'),
                  )
                : Row(
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$count item${count > 1 ? 's' : ''} in cart',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                    color: AppPalette.muted,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            Text(
                              _currency.format(total),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: AppPalette.forest,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          widget.onOpenCart();
                        },
                        icon: const Icon(Icons.shopping_bag_outlined,
                            size: 18),
                        label: const Text('Go to cart'),
                      ),
                    ],
                  ),
          );
        },
      ),
    );
  }

  void _addToCart(ShopProduct product) {
    _marketplace.addProductToCart(shop: widget.shop, product: product);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} added to cart.'),
        action: SnackBarAction(
          label: 'View cart',
          onPressed: () {
            Navigator.of(context).pop();
            widget.onOpenCart();
          },
        ),
      ),
    );
  }
}

// ─── Shop hero ────────────────────────────────────────────────────────────────

class _ShopHero extends StatelessWidget {
  const _ShopHero({required this.shop});
  final MarketplaceShop shop;

  @override
  Widget build(BuildContext context) {
    final initials = shop.name
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0] : '')
        .join()
        .toUpperCase();

    return Container(
      decoration: const BoxDecoration(color: AppPalette.forest),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Back button row
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded,
                        color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.ios_share_outlined,
                        color: Colors.white),
                    onPressed: () {},
                  ),
                ],
              ),
            ),

            // Shop info
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: AppPalette.brass.withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        initials,
                        style:
                            Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          shop.name,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                color: Colors.white,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${shop.kind.label}  ·  ${shop.placeLabel}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.7),
                                  ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            // Rating
                            _HeroBadge(
                                icon: Icons.star_rounded,
                                label: shop.rating.toStringAsFixed(1)),
                            const SizedBox(width: 6),
                            // Stock
                            _HeroBadge(
                              icon: Icons.circle,
                              label: shop.stockLevel.label,
                              iconColor: shop.stockLevel.color,
                            ),
                            const SizedBox(width: 6),
                            // Turnaround
                            _HeroBadge(
                                icon: Icons.schedule_rounded,
                                label: shop.turnaround),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  const _HeroBadge({
    required this.icon,
    required this.label,
    this.iconColor,
  });
  final IconData icon;
  final String label;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 11,
              color: iconColor ?? Colors.white.withValues(alpha: 0.9)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Stats row ────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.shop});
  final MarketplaceShop shop;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            value: '${shop.liveOfferCount}',
            label: 'live offers',
            icon: Icons.local_offer_outlined,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            value: '${shop.products.length}',
            label: 'products',
            icon: Icons.inventory_2_outlined,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            value: '${shop.liveEventCount}',
            label: 'events',
            icon: Icons.event_outlined,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
  });
  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppPalette.card,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: AppPalette.forest.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: AppPalette.forest),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppPalette.forest,
                ),
          ),
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: AppPalette.muted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Product card ────────────────────────────────────────────────────────────

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.shopKind,
    required this.qty,
    required this.onQtyChanged,
    required this.onAddToCart,
  });

  final ShopProduct product;
  final ShopKind shopKind;
  final int qty;
  final void Function(int qty) onQtyChanged;
  final VoidCallback onAddToCart;

  static final _currency = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    final discount = product.originalPrice - product.price;
    final pct = (discount / product.originalPrice * 100).round();
    final isLowStock = product.inventoryUnits < 10;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPalette.card,
        borderRadius: BorderRadius.circular(22),
        border:
            Border.all(color: AppPalette.forest.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon container
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppPalette.forest.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  shopKind == ShopKind.wholesaler
                      ? Icons.warehouse_outlined
                      : Icons.storefront_outlined,
                  color: AppPalette.forest,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            product.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        if (pct > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppPalette.success
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '$pct% off',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: AppPalette.success,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      product.variant,
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: AppPalette.muted),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      product.tagline,
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
          const SizedBox(height: 12),

          // Price + inventory
          Row(
            children: [
              Text(
                _currency.format(product.price),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppPalette.forest,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(width: 8),
              Text(
                _currency.format(product.originalPrice),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppPalette.muted,
                      decoration: TextDecoration.lineThrough,
                    ),
              ),
              const Spacer(),
              // Inventory units indicator
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (isLowStock ? AppPalette.warning : AppPalette.success)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${product.inventoryUnits} units',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isLowStock
                            ? AppPalette.warning
                            : AppPalette.success,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),
          Text(
            'Min order: ${product.minimumOrder} unit${product.minimumOrder > 1 ? 's' : ''}',
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: AppPalette.muted),
          ),

          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Qty selector + Add to cart
          Row(
            children: [
              _QtySelector(
                qty: qty,
                minQty: product.minimumOrder,
                maxQty: product.inventoryUnits,
                onChanged: onQtyChanged,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onAddToCart,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 44),
                  ),
                  icon: const Icon(Icons.add_shopping_cart_rounded,
                      size: 16),
                  label: const Text('Add to cart'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Qty selector ─────────────────────────────────────────────────────────────

class _QtySelector extends StatelessWidget {
  const _QtySelector({
    required this.qty,
    required this.minQty,
    required this.maxQty,
    required this.onChanged,
  });
  final int qty;
  final int minQty;
  final int maxQty;
  final void Function(int) onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppPalette.parchment,
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: AppPalette.forest.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _QtyBtn(
            icon: Icons.remove_rounded,
            onTap: qty > 0
                ? () => onChanged((qty - 1).clamp(0, maxQty))
                : null,
          ),
          SizedBox(
            width: 36,
            child: Text(
              '$qty',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppPalette.forest,
                  ),
            ),
          ),
          _QtyBtn(
            icon: Icons.add_rounded,
            onTap: qty < maxQty
                ? () => onChanged((qty + 1).clamp(0, maxQty))
                : null,
          ),
        ],
      ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  const _QtyBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 18,
          color: onTap != null ? AppPalette.forest : AppPalette.muted,
        ),
      ),
    );
  }
}