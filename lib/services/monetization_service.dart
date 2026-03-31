import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class MonetizationService extends ChangeNotifier {
  MonetizationService() {
    _purchaseSubscription = _inAppPurchase.purchaseStream.listen(
      _handlePurchaseUpdates,
      onError: (_) {
        _isBusy = false;
        _purchaseCompleter?.complete(false);
        _restoreCompleter?.complete(false);
        _purchaseCompleter = null;
        _restoreCompleter = null;
        notifyListeners();
      },
    );
  }

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;

  bool _initialized = false;
  bool _isBusy = false;
  bool _storeAvailable = false;
  bool _premiumEntitlement = false;
  List<ProductDetails> _products = const [];
  BannerAd? _bannerAd;
  bool _bannerReady = false;
  RewardedAd? _rewardedAd;
  bool _rewardedReady = false;
  String? _lastError;
  Completer<bool>? _purchaseCompleter;
  Completer<bool>? _restoreCompleter;

  bool get initialized => _initialized;
  bool get isBusy => _isBusy;
  bool get storeAvailable => _storeAvailable;
  bool get premiumEntitlement => _premiumEntitlement;
  List<ProductDetails> get products => _products;
  BannerAd? get bannerAd => _bannerReady ? _bannerAd : null;
  bool get rewardedReady => _rewardedReady;
  String? get lastError => _lastError;
  bool get hasConfiguredProducts => _productIds().isNotEmpty;
  bool get hasConfiguredAdUnits =>
      _isNonEmpty(dotenv.env['ADMOB_BANNER_ANDROID']) ||
      _isNonEmpty(dotenv.env['ADMOB_BANNER_IOS']) ||
      _isNonEmpty(dotenv.env['ADMOB_REWARDED_ANDROID']) ||
      _isNonEmpty(dotenv.env['ADMOB_REWARDED_IOS']);
  bool get supportsAds =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  bool _adsConsentEnabled = false;

  Future<void> initialize({
    required bool premiumEnabled,
    required bool adsEnabled,
  }) async {
    _premiumEntitlement = premiumEnabled;
    _adsConsentEnabled = adsEnabled;
    if (_initialized) {
      notifyListeners();
      return;
    }

    _initialized = true;
    _lastError = null;

    if (supportsAds && _adsConsentEnabled && hasConfiguredAdUnits) {
      await MobileAds.instance.initialize();
      _loadBannerAd();
      _loadRewardedAd();
    }

    _storeAvailable = await _inAppPurchase.isAvailable();
    if (_storeAvailable && hasConfiguredProducts) {
      await _refreshProducts();
    }

    notifyListeners();
  }

  void updatePremiumEntitlement(bool enabled) {
    _premiumEntitlement = enabled;
    if (enabled) {
      _disposeBannerAd();
    } else if (_initialized && supportsAds && _bannerAd == null) {
      _loadBannerAd();
    }
    notifyListeners();
  }

  Future<void> updateAdsConsent(bool enabled) async {
    _adsConsentEnabled = enabled;
    if (!_initialized || !supportsAds) {
      notifyListeners();
      return;
    }

    if (!_adsConsentEnabled || !hasConfiguredAdUnits) {
      _disposeBannerAd();
      _rewardedAd?.dispose();
      _rewardedAd = null;
      _rewardedReady = false;
      notifyListeners();
      return;
    }

    await MobileAds.instance.initialize();
    if (!_premiumEntitlement && _bannerAd == null) {
      _loadBannerAd();
    }
    if (_rewardedAd == null) {
      _loadRewardedAd();
    }
    notifyListeners();
  }

  Future<void> refresh() async {
    if (_storeAvailable && hasConfiguredProducts) {
      await _refreshProducts();
    }
    if (supportsAds && _adsConsentEnabled && hasConfiguredAdUnits) {
      if (_bannerAd == null && !_premiumEntitlement) {
        _loadBannerAd();
      }
      if (_rewardedAd == null) {
        _loadRewardedAd();
      }
    }
  }

  Future<bool> purchaseProduct(ProductDetails product) async {
    if (!_storeAvailable || !hasConfiguredProducts || _isBusy) return false;

    _isBusy = true;
    _lastError = null;
    _purchaseCompleter?.complete(false);
    _purchaseCompleter = Completer<bool>();
    notifyListeners();

    final started = await _inAppPurchase.buyNonConsumable(
      purchaseParam: PurchaseParam(productDetails: product),
    );
    if (!started) {
      _isBusy = false;
      _purchaseCompleter?.complete(false);
      _purchaseCompleter = null;
      notifyListeners();
      return false;
    }

    try {
      return await _purchaseCompleter!.future.timeout(
        const Duration(seconds: 45),
        onTimeout: () => false,
      );
    } finally {
      _isBusy = false;
      _purchaseCompleter = null;
      notifyListeners();
    }
  }

  Future<bool> restorePurchases() async {
    if (!_storeAvailable || !hasConfiguredProducts || _isBusy) return false;

    _isBusy = true;
    _lastError = null;
    _restoreCompleter?.complete(false);
    _restoreCompleter = Completer<bool>();
    notifyListeners();

    await _inAppPurchase.restorePurchases();

    try {
      return await _restoreCompleter!.future.timeout(
        const Duration(seconds: 20),
        onTimeout: () => _premiumEntitlement,
      );
    } finally {
      _isBusy = false;
      _restoreCompleter = null;
      notifyListeners();
    }
  }

  Future<bool> showRewardedAd({required VoidCallback onReward}) async {
    if (!_adsConsentEnabled || !hasConfiguredAdUnits) {
      return false;
    }
    final ad = _rewardedAd;
    if (ad == null || !_rewardedReady) {
      _loadRewardedAd();
      return false;
    }

    final completer = Completer<bool>();
    _rewardedAd = null;
    _rewardedReady = false;
    notifyListeners();

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        if (!completer.isCompleted) {
          completer.complete(true);
        }
        _loadRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        if (!completer.isCompleted) {
          completer.complete(false);
        }
        _loadRewardedAd();
      },
    );

    ad.show(
      onUserEarnedReward: (_, __) {
        onReward();
      },
    );

    return completer.future;
  }

  Future<void> _refreshProducts() async {
    final ids = _productIds();
    if (ids.isEmpty) {
      _products = const [];
      notifyListeners();
      return;
    }

    final response = await _inAppPurchase.queryProductDetails(ids);
    if (response.error != null) {
      _lastError = response.error!.message;
      _products = const [];
      notifyListeners();
      return;
    }

    _products = response.productDetails.toList()
      ..sort((a, b) => a.rawPrice.compareTo(b.rawPrice));
    notifyListeners();
  }

  Set<String> _productIds() {
    const keys = [
      'IAP_PREMIUM_MONTHLY',
      'IAP_PREMIUM_YEARLY',
      'IAP_PREMIUM_LIFETIME',
    ];

    final ids = <String>{};
    for (final key in keys) {
      final value = (dotenv.env[key] ?? '').trim();
      if (value.isNotEmpty) {
        ids.add(value);
      }
    }
    return ids;
  }

  void _handlePurchaseUpdates(List<PurchaseDetails> updates) {
    var unlocked = false;
    var sawRestoreEvent = false;

    for (final purchase in updates) {
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        unlocked = true;
        sawRestoreEvent =
            sawRestoreEvent || purchase.status == PurchaseStatus.restored;
      } else if (purchase.status == PurchaseStatus.error) {
        _lastError = purchase.error?.message;
      } else if (purchase.status == PurchaseStatus.canceled) {
        _lastError = null;
      }

      if (purchase.pendingCompletePurchase) {
        _inAppPurchase.completePurchase(purchase);
      }
    }

    if (unlocked) {
      _premiumEntitlement = true;
      _disposeBannerAd();
      _purchaseCompleter?.complete(true);
      _restoreCompleter?.complete(true);
    } else if (sawRestoreEvent) {
      _restoreCompleter?.complete(false);
    }

    _isBusy = false;
    notifyListeners();
  }

  void _loadBannerAd() {
    if (!supportsAds || !_adsConsentEnabled || !hasConfiguredAdUnits) return;
    if (_premiumEntitlement) return;
    if (_bannerAd != null) return;

    final ad = BannerAd(
      adUnitId: _bannerAdUnitId(),
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          _bannerAd = ad as BannerAd;
          _bannerReady = true;
          notifyListeners();
        },
        onAdFailedToLoad: (ad, _) {
          ad.dispose();
          _bannerAd = null;
          _bannerReady = false;
          notifyListeners();
        },
      ),
    );

    _bannerAd = ad;
    _bannerReady = false;
    ad.load();
  }

  void _loadRewardedAd() {
    if (!supportsAds || !_adsConsentEnabled || !hasConfiguredAdUnits) return;
    if (_rewardedAd != null) return;

    RewardedAd.load(
      adUnitId: _rewardedAdUnitId(),
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _rewardedReady = true;
          notifyListeners();
        },
        onAdFailedToLoad: (_) {
          _rewardedAd = null;
          _rewardedReady = false;
          notifyListeners();
        },
      ),
    );
  }

  void _disposeBannerAd() {
    _bannerAd?.dispose();
    _bannerAd = null;
    _bannerReady = false;
  }

  String _bannerAdUnitId() {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return (dotenv.env['ADMOB_BANNER_IOS'] ?? '').trim().isNotEmpty
          ? dotenv.env['ADMOB_BANNER_IOS']!.trim()
          : 'ca-app-pub-3940256099942544/2934735716';
    }
    return (dotenv.env['ADMOB_BANNER_ANDROID'] ?? '').trim().isNotEmpty
        ? dotenv.env['ADMOB_BANNER_ANDROID']!.trim()
        : 'ca-app-pub-3940256099942544/6300978111';
  }

  String _rewardedAdUnitId() {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return (dotenv.env['ADMOB_REWARDED_IOS'] ?? '').trim().isNotEmpty
          ? dotenv.env['ADMOB_REWARDED_IOS']!.trim()
          : 'ca-app-pub-3940256099942544/1712485313';
    }
    return (dotenv.env['ADMOB_REWARDED_ANDROID'] ?? '').trim().isNotEmpty
        ? dotenv.env['ADMOB_REWARDED_ANDROID']!.trim()
        : 'ca-app-pub-3940256099942544/5224354917';
  }

  @override
  void dispose() {
    _purchaseSubscription?.cancel();
    _disposeBannerAd();
    _rewardedAd?.dispose();
    super.dispose();
  }

  bool _isNonEmpty(String? value) => (value ?? '').trim().isNotEmpty;
}
