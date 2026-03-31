import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../providers/app_providers.dart';

class MonetizationBanner extends ConsumerWidget {
  const MonetizationBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatState = ref.watch(chatControllerProvider);
    final monetization = ref.watch(monetizationServiceProvider);
    final banner = monetization.bannerAd;

    if (!chatState.adsConsent || chatState.isPremium || banner == null) {
      return const SizedBox.shrink();
    }

    return Container(
      alignment: Alignment.center,
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: SizedBox(
        width: banner.size.width.toDouble(),
        height: banner.size.height.toDouble(),
        child: AdWidget(ad: banner),
      ),
    );
  }
}
