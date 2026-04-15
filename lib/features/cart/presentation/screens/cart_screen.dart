import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/marketplace_models.dart';
import '../../../../shared/services/marketplace_service.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({
    super.key,
    required this.onBrowseMarket,
    required this.onBrowseMap,
  });

  final VoidCallback onBrowseMarket;
  final VoidCallback onBrowseMap;

  static final MarketplaceService _marketplace = MarketplaceService.instance;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<CartItem>>(
      valueListenable: _marketplace.cartItems,
      builder: (context, items, _) {
        if (items.isEmpty) {
          return _EmptyCartState(
            onBrowseMarket: onBrowseMarket,
            onBrowseMap: onBrowseMap,
          );
        }

        final groupedItems = <String, List<CartItem>>{};
        for (final item in items) {
          groupedItems.putIfAbsent(item.shopName, () => <CartItem>[]).add(item);
        }

        final subtotal = items.fold<double>(0, (sum, item) => sum + item.total);
        final savings = items.fold<double>(
          0,
          (sum, item) => sum + item.savings,
        );
        final totalUnits =
            items.fold<int>(0, (sum, item) => sum + item.quantity);

        return ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
          children: [
            _CartSummaryCard(
              itemCount: items.length,
              totalUnits: totalUnits,
              shopCount: groupedItems.length,
              subtotal: subtotal,
              savings: savings,
            ),
            const SizedBox(height: 14),
            ...groupedItems.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ShopCartCard(
                  shopName: entry.key,
                  items: entry.value,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Procurement summary',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    _SummaryRow(label: 'Subtotal', value: _money(subtotal)),
                    const SizedBox(height: 8),
                    _SummaryRow(
                        label: 'Projected savings', value: _money(savings)),
                    const SizedBox(height: 8),
                    _SummaryRow(
                        label: 'Seller counters',
                        value: '${groupedItems.length}'),
                    const SizedBox(height: 14),
                    ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Procurement draft prepared. Checkout workflow can be connected next.',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.assignment_outlined, size: 18),
                      label: const Text('Prepare draft'),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: onBrowseMarket,
                            child: const Text('Add more items'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: onBrowseMap,
                            child: const Text('Open map'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: _marketplace.clearCart,
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Clear cart'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _EmptyCartState extends StatelessWidget {
  const _EmptyCartState({
    required this.onBrowseMarket,
    required this.onBrowseMap,
  });

  final VoidCallback onBrowseMarket;
  final VoidCallback onBrowseMap;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Container(
                  width: 82,
                  height: 82,
                  decoration: BoxDecoration(
                    color: AppPalette.forest.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.shopping_bag_outlined,
                    size: 36,
                    color: AppPalette.forest,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Your cart is clear',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Start from the market feed or the live map to collect Nutonium offers from retailers and wholesalers.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppPalette.muted,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: onBrowseMarket,
                  child: const Text('Browse market'),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: onBrowseMap,
                  child: const Text('Open seller map'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CartSummaryCard extends StatelessWidget {
  const _CartSummaryCard({
    required this.itemCount,
    required this.totalUnits,
    required this.shopCount,
    required this.subtotal,
    required this.savings,
  });

  final int itemCount;
  final int totalUnits;
  final int shopCount;
  final double subtotal;
  final double savings;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cart snapshot',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              'A running draft of your Nutonium sourcing plan.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppPalette.muted,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                    child:
                        _MetricTile(value: '$itemCount', label: 'line items')),
                const SizedBox(width: 10),
                Expanded(
                    child: _MetricTile(
                        value: '$totalUnits', label: 'total units')),
                const SizedBox(width: 10),
                Expanded(
                    child: _MetricTile(value: '$shopCount', label: 'shops')),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _ValueBanner(
                    label: 'Current total',
                    value: _money(subtotal),
                    tone: AppPalette.forest,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ValueBanner(
                    label: 'Savings',
                    value: _money(savings),
                    tone: AppPalette.warning,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ShopCartCard extends StatelessWidget {
  const _ShopCartCard({
    required this.shopName,
    required this.items,
  });

  final String shopName;
  final List<CartItem> items;

  @override
  Widget build(BuildContext context) {
    final shopTotal = items.fold<double>(0, (sum, item) => sum + item.total);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(shopName,
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 2),
                      Text(
                        '${items.length} item${items.length == 1 ? '' : 's'} from this seller',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppPalette.muted,
                            ),
                      ),
                    ],
                  ),
                ),
                Text(
                  _money(shopTotal),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppPalette.forest,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _CartItemTile(item: item),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartItemTile extends StatelessWidget {
  const _CartItemTile({required this.item});

  final CartItem item;

  @override
  Widget build(BuildContext context) {
    final marketplace = MarketplaceService.instance;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppPalette.forest.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      item.variant,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppPalette.muted,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.tagline,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  marketplace.removeFromCart(
                    shopId: item.shopId,
                    productId: item.productId,
                  );
                },
                icon: const Icon(Icons.close_rounded),
                tooltip: 'Remove item',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _QtyButton(
                icon: Icons.remove,
                onPressed: () {
                  marketplace.updateCartQuantity(
                    shopId: item.shopId,
                    productId: item.productId,
                    quantity: item.quantity - 1,
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  '${item.quantity}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              _QtyButton(
                icon: Icons.add,
                onPressed: () {
                  marketplace.updateCartQuantity(
                    shopId: item.shopId,
                    productId: item.productId,
                    quantity: item.quantity + 1,
                  );
                },
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _money(item.total),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppPalette.forest,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  Text(
                    '${_money(item.unitPrice)} each',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppPalette.muted,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 36,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: const Size(36, 36),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Icon(icon, size: 16),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppPalette.canvas,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppPalette.forest,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppPalette.muted,
                ),
          ),
        ],
      ),
    );
  }
}

class _ValueBanner extends StatelessWidget {
  const _ValueBanner({
    required this.label,
    required this.value,
    required this.tone,
  });

  final String label;
  final String value;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppPalette.muted,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: tone,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppPalette.muted,
                ),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

String _money(double value) {
  final isWhole = value == value.roundToDouble();
  return 'Rs ${value.toStringAsFixed(isWhole ? 0 : 2)}';
}
