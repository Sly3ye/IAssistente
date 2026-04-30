import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../l10n/app_strings.dart';
import '../providers/app_providers.dart';

class PremiumPage extends ConsumerWidget {
  const PremiumPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatState = ref.watch(chatControllerProvider);
    final monetization = ref.watch(monetizationServiceProvider);
    final runtimeConfig = ref.watch(appRuntimeConfigProvider);
    final strings = AppStrings.ofCode(chatState.preferredLanguageCode);

    if (!runtimeConfig.paywallEnabled) {
      return Scaffold(
        appBar: AppBar(title: Text(strings.premium)),
        body: Center(child: Text(strings.premiumTemporarilyUnavailable)),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(strings.premium)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chatState.isPremium
                        ? strings.premiumActive
                        : strings.premiumInactive,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(strings.premiumQuota(chatState.dailyTokenLimit)),
                  const SizedBox(height: 8),
                  Text(strings.premiumBody),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (!monetization.hasConfiguredProducts)
            ListTile(title: Text(strings.noProductsConfigured))
          else if (!monetization.storeAvailable)
            ListTile(title: Text(strings.storeUnavailable))
          else if (monetization.products.isEmpty)
            ListTile(title: Text(strings.purchaseUnavailable)),
          if ((monetization.lastError ?? '').trim().isNotEmpty)
            Card(
              color: Colors.red.shade50,
              child: ListTile(
                leading: Icon(Icons.error_outline, color: Colors.red.shade700),
                title: Text(monetization.lastError!),
              ),
            ),
          for (final product in monetization.products)
            _ProductCard(
              product: product,
              isBusy: monetization.isBusy,
              onBuy: () async {
                final messenger = ScaffoldMessenger.of(context);
                final success = await monetization.purchaseProduct(product);
                if (success) {
                  await ref
                      .read(chatControllerProvider.notifier)
                      .setPremiumStatus(true);
                  monetization.updatePremiumEntitlement(true);
                  await ref
                      .read(observabilityServiceProvider)
                      .logEvent(
                        'purchase_completed',
                        parameters: {'product_id': product.id},
                      );
                } else {
                  await ref
                      .read(observabilityServiceProvider)
                      .logEvent(
                        'purchase_failed',
                        parameters: {'product_id': product.id},
                      );
                }
                if (!context.mounted) return;
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? strings.purchaseSuccess(product.title)
                          : strings.purchaseUnavailable,
                    ),
                  ),
                );
              },
            ),
          const SizedBox(height: 12),
          FilledButton.tonal(
            onPressed: monetization.isBusy
                ? null
                : () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final restored = await monetization.restorePurchases();
                    if (restored) {
                      await ref
                          .read(chatControllerProvider.notifier)
                          .setPremiumStatus(true);
                      monetization.updatePremiumEntitlement(true);
                      await ref
                          .read(observabilityServiceProvider)
                          .logEvent('purchase_restored');
                    }
                    if (!context.mounted) return;
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          restored
                              ? strings.purchasesRestored
                              : strings.purchaseUnavailable,
                        ),
                      ),
                    );
                  },
            child: Text(strings.restorePurchases),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.isBusy,
    required this.onBuy,
  });

  final ProductDetails product;
  final bool isBusy;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.price,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? const Color(0xFF9FD9CB)
                          : const Color(0xFF0F5B52),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (product.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      product.description,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 14),
            FilledButton(
              onPressed: isBusy ? null : onBuy,
              child: isBusy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.shopping_bag_outlined),
            ),
          ],
        ),
      ),
    );
  }
}
