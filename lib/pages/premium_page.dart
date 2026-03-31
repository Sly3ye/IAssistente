import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_strings.dart';
import '../providers/app_providers.dart';

class PremiumPage extends ConsumerWidget {
  const PremiumPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatState = ref.watch(chatControllerProvider);
    final monetization = ref.watch(monetizationServiceProvider);
    final strings = AppStrings.ofCode(chatState.preferredLanguageCode);

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
          if (!monetization.storeAvailable || monetization.products.isEmpty)
            ListTile(title: Text(strings.noProductsConfigured)),
          for (final product in monetization.products)
            Card(
              child: ListTile(
                title: Text(product.title),
                subtitle: Text(product.description),
                trailing: FilledButton(
                  onPressed: monetization.isBusy
                      ? null
                      : () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final success = await monetization.purchaseProduct(
                            product,
                          );
                          if (success) {
                            await ref
                                .read(chatControllerProvider.notifier)
                                .setPremiumStatus(true);
                            monetization.updatePremiumEntitlement(true);
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
                  child: Text(product.price),
                ),
              ),
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
