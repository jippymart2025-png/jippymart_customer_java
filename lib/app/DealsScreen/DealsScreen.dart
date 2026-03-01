import 'package:jippymart_customer/app/home_screen/screen/home_screen/provider/home_provider.dart';
import 'package:jippymart_customer/app/restaurant_details_screen/provider/restaurant_details_provider.dart';
import 'package:jippymart_customer/app/restaurant_details_screen/restaurant_details_screen.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/constant/show_toast_dialog.dart';
import 'package:jippymart_customer/utils/utils/app_constant.dart';
import 'package:jippymart_customer/models/cart_product_model.dart';
import 'package:jippymart_customer/models/product_model.dart';
import 'package:jippymart_customer/models/vendor_model.dart';
import 'package:jippymart_customer/models/promotion_model.dart';
import 'package:jippymart_customer/models/BannerModel.dart';
import 'package:jippymart_customer/services/cart_provider.dart';
import 'package:jippymart_customer/services/location_service.dart';
import 'package:jippymart_customer/themes/app_them_data.dart';
import 'package:jippymart_customer/themes/responsive.dart';
import 'package:jippymart_customer/utils/fire_store_utils.dart';
import 'package:jippymart_customer/utils/network_image_widget.dart';
import 'package:jippymart_customer/utils/color_utils.dart';
import 'package:jippymart_customer/utils/utils/sql_storage_const.dart';
import 'package:jippymart_customer/utils/restaurant_status_utils.dart';
import 'package:jippymart_customer/app/auth_screen/phone_number_screen.dart';
import 'package:jippymart_customer/themes/custom_dialog_box.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:jippymart_customer/services/cache_manager.dart';
import 'package:jippymart_customer/services/api_queue_manager.dart';

import '../../models/user_model.dart';
import 'bannerdeals.dart';

// ── Responsive sizing helper ───────────────────────────────────────
// Immutable — safe to cache, no need to recompute on every build
@immutable
class _RS {
  final double sw;
  final double sh;

  const _RS({required this.sw, required this.sh});

  bool get isSmall => sw < 360;

  bool get isLarge => sw >= 600;

  int get gridCols => sw >= 600 ? 3 : 2;

  double get gridSpacing => isSmall ? 8.0 : 10.0;

  double get gridAspectRatio {
    if (sw >= 600) return 0.75;
    if (sw < 360) return 0.62;
    return 0.64;
  }

  double get hPad => isSmall ? 10.0 : (isLarge ? 16.0 : 12.0);

  double get nameFontSize => isSmall ? 12.0 : (isLarge ? 14.0 : 13.0);

  double get subFontSize => isSmall ? 10.0 : (isLarge ? 12.0 : 11.0);

  double get timeFontSize => isSmall ? 8.0 : (isLarge ? 10.0 : 9.0);

  double get originalPriceFontSize => isSmall ? 9.0 : (isLarge ? 11.0 : 10.0);

  double get specialPriceFontSize => isSmall ? 13.0 : (isLarge ? 15.0 : 14.0);

  double get discountBadgeFontSize => isSmall ? 7.0 : (isLarge ? 9.0 : 8.0);

  double get limitBadgeFontSize => isSmall ? 7.0 : (isLarge ? 9.0 : 8.0);

  double get closedFontSize => isSmall ? 10.0 : (isLarge ? 12.0 : 11.0);

  double get btnHeight => isSmall ? 28.0 : (isLarge ? 34.0 : 30.0);

  double get btnWidth => isSmall ? 28.0 : (isLarge ? 34.0 : 30.0);

  double get btnRadius => isSmall ? 7.0 : (isLarge ? 10.0 : 8.0);

  double get btnIconSize => isSmall ? 14.0 : (isLarge ? 18.0 : 16.0);

  double get qtyFontSize => isSmall ? 12.0 : (isLarge ? 14.0 : 13.0);

  double get qtyHPad => isSmall ? 6.0 : (isLarge ? 10.0 : 8.0);

  double get cardPad => isSmall ? 6.0 : (isLarge ? 10.0 : 8.0);

  double get vegIndicatorOuter => isSmall ? 13.0 : (isLarge ? 16.0 : 14.0);

  double get vegIndicatorInner => isSmall ? 8.0 : (isLarge ? 11.0 : 9.0);

  double get limitBadgeHPad => isSmall ? 4.0 : (isLarge ? 6.0 : 5.0);

  double get limitBadgeVPad => isSmall ? 1.0 : 2.0;

  double get limitBadgeRadius => isSmall ? 5.0 : 6.0;

  double get detailSpacing1 => isSmall ? 2.0 : 3.0;

  double get detailSpacing2 => isSmall ? 4.0 : 5.0;

  double get detailSpacing3 => 1.0;

  // Equality so we only rebuild grid when screen size actually changes
  @override
  bool operator ==(Object other) =>
      other is _RS && other.sw == sw && other.sh == sh;

  @override
  int get hashCode => Object.hash(sw, sh);
}
// ──────────────────────────────────────────────────────────────────

/// First shows delivery time; after 4 seconds replaces it with "Fast delivery" (same as home).
class _TimeThenFastDeliveryWidget extends StatefulWidget {
  final String deliveryTime;

  const _TimeThenFastDeliveryWidget({required this.deliveryTime});

  @override
  State<_TimeThenFastDeliveryWidget> createState() =>
      _TimeThenFastDeliveryWidgetState();
}

class _TimeThenFastDeliveryWidgetState
    extends State<_TimeThenFastDeliveryWidget> {
  bool _showFastDelivery = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted) {
        setState(() => _showFastDelivery = !_showFastDelivery);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        switchInCurve: Curves.easeIn,
        switchOutCurve: Curves.easeOut,
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: _showFastDelivery
            ? Row(
                key: const ValueKey<String>('fast'),
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.delivery_dining,
                    size: 10,
                    color: AppThemeData.primary300,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    'Fast delivery',
                    style: TextStyle(
                      fontSize: 10,
                      fontFamily: AppThemeData.medium,
                      color: AppThemeData.primary300,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              )
            : Text(
                key: const ValueKey<String>('time'),
                widget.deliveryTime,
                style: TextStyle(
                  fontSize: 10,
                  fontFamily: AppThemeData.medium,
                  color: AppThemeData.primary300,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────

class DealsScreen extends StatefulWidget {
  const DealsScreen({super.key});

  @override
  State<DealsScreen> createState() => _DealsScreenState();
}

class _DealsScreenState extends State<DealsScreen> with WidgetsBindingObserver {
  bool _isLoading = true;
  List<PromotionModel> _promotionsList = [];
  List<BannerModel> _dealsBanners = [];
  String? _currentZoneId;

  static const Duration _networkTimeout = Duration(seconds: 10);
  static const Duration _cacheDuration = Duration(minutes: 3);

  // Shared caches passed by reference to cards — zero duplication
  final Map<String, ProductModel> _productCache = {};
  final Map<String, VendorModel> _vendorCache = {};
  final Map<String, bool> _restaurantStatusCache = {};

  DateTime? _lastLoadTime;
  int _retryCount = 0;
  static const int _maxRetries = 1;
  Timer? _zoneChangeDebounceTimer;

  // Cache _RS so it isn't recomputed on every HomeProvider notify
  _RS? _cachedRS;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentZoneId = Constant.selectedZone?.id;
    _loadAllDataWithCache();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _zoneChangeDebounceTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _checkAndReloadIfZoneChanged();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkAndReloadIfZoneChanged();
  }

  void _checkAndReloadIfZoneChanged() {
    final newZoneId = Constant.selectedZone?.id;
    if (newZoneId != null &&
        newZoneId.isNotEmpty &&
        newZoneId != _currentZoneId) {
      _zoneChangeDebounceTimer?.cancel();
      _zoneChangeDebounceTimer = Timer(const Duration(milliseconds: 500), () {
        if (mounted && newZoneId == Constant.selectedZone?.id) {
          _currentZoneId = newZoneId;
          _productCache.clear();
          _vendorCache.clear();
          _restaurantStatusCache.clear();
          _loadAllData();
        }
      });
    }
  }

  Future<void> _loadAllDataWithCache() async {
    final now = DateTime.now();
    if (_lastLoadTime != null &&
        now.difference(_lastLoadTime!) < _cacheDuration) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    await _loadAllData();
  }

  Future<void> _refreshAllData() async {
    try {
      String? zoneId = _currentZoneId;
      if (zoneId == null || zoneId.isEmpty) {
        zoneId = await _getCurrentZoneIdWithRetry();
      }
      if (zoneId != null && zoneId.isNotEmpty) {
        CacheManager().remove('deals_banners_$zoneId');
        CacheManager().remove('promotions_$zoneId');
      }
      _lastLoadTime = null;
      _productCache.clear();
      _vendorCache.clear();
      _restaurantStatusCache.clear();
      _retryCount = 0;
      await _loadAllData();
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadAllData() async {
    if (_isLoading && _retryCount > 0) return;
    if (mounted) setState(() => _isLoading = true);
    try {
      await _loadDealsBanners();
      await _loadPromotionsData();
      _lastLoadTime = DateTime.now();
      _retryCount = 0;
    } catch (e) {
      if (_retryCount < _maxRetries) {
        _retryCount++;
        await Future.delayed(Duration(seconds: _retryCount));
        if (mounted) await _loadAllData();
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadDealsBanners() async {
    try {
      String? zoneId = _currentZoneId;
      if (zoneId == null || zoneId.isEmpty) {
        zoneId = await _getCurrentZoneIdWithRetry();
      }
      if (zoneId == null || zoneId.isEmpty) {
        if (mounted) setState(() => _dealsBanners = []);
        return;
      }
      final cacheKey = 'deals_banners_$zoneId';
      final banners = await CacheManager().getOrSetBanners<List<BannerModel>>(
        cacheKey,
        () => ApiQueueManager().enqueue<List<BannerModel>>(
          priority: RequestPriority.normal,
          key: cacheKey,
          request: () => _fetchDealsBanners(zoneId!),
        ),
      );
      if (mounted) setState(() => _dealsBanners = banners);
    } catch (e) {
      if (mounted) setState(() => _dealsBanners = []);
    }
  }

  Future<List<BannerModel>> _fetchDealsBanners(String zoneId) async {
    try {
      final url = '${AppConst.baseUrl}menu-items/banners/deals?zone_id=$zoneId';
      final headers = await _getHeaders();
      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(_networkTimeout);
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true) {
          final data = jsonResponse['data'] as List;
          return data
              .take(15)
              .map((item) => BannerModel.fromJson(item))
              .toList();
        }
      }
      return [];
    } on TimeoutException {
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<void> _loadPromotionsData() async {
    try {
      String? zoneId = _currentZoneId;
      if (zoneId == null || zoneId.isEmpty) {
        zoneId = await _getCurrentZoneIdWithRetry();
      }
      if (zoneId == null || zoneId.isEmpty) {
        if (mounted) setState(() => _promotionsList = []);
        return;
      }
      final cacheKey = 'promotions_$zoneId';
      final promotionsData = await CacheManager()
          .getOrSet<List<Map<String, dynamic>>>(
            cacheKey,
            () => ApiQueueManager().enqueue<List<Map<String, dynamic>>>(
              priority: RequestPriority.normal,
              key: cacheKey,
              request: () =>
                  FireStoreUtils.getAllActivePromotions(zoneId: zoneId!),
            ),
            type: CacheType.general,
          );
      if (promotionsData.isNotEmpty) {
        final promotions = promotionsData
            .take(100)
            .map((p) => PromotionModel.fromJson(p))
            .toList();
        final vendorIds = promotions
            .map((p) => p.restaurantId)
            .where((id) => id.isNotEmpty)
            .toSet()
            .toList();
        await _preCacheVendors(vendorIds);
        final sorted = await _sortPromotionsByRestaurantStatus(promotions);
        if (mounted) setState(() => _promotionsList = sorted);
      } else {
        if (mounted) setState(() => _promotionsList = []);
      }
    } catch (e) {
      if (mounted) setState(() => _promotionsList = []);
    }
  }

  Future<void> _preCacheVendors(List<String> vendorIds) async {
    for (final vendorId in vendorIds) {
      if (!_vendorCache.containsKey(vendorId)) {
        try {
          final vendor = await FireStoreUtils.getVendorById(vendorId);
          if (vendor != null) {
            _vendorCache[vendorId] = vendor;
            _restaurantStatusCache[vendorId] =
                RestaurantStatusUtils.canAcceptOrders(vendor);
          }
        } catch (_) {}
      }
    }
  }

  Future<List<PromotionModel>> _sortPromotionsByRestaurantStatus(
    List<PromotionModel> promotions,
  ) async {
    if (promotions.isEmpty) return promotions;
    try {
      final statuses = promotions.map((promo) {
        final id = promo.restaurantId;
        bool isOpen = true;
        if (_restaurantStatusCache.containsKey(id)) {
          isOpen = _restaurantStatusCache[id]!;
        } else if (_vendorCache.containsKey(id)) {
          isOpen = RestaurantStatusUtils.canAcceptOrders(_vendorCache[id]!);
          _restaurantStatusCache[id] = isOpen;
        }
        return MapEntry(promo, isOpen);
      }).toList();
      statuses.sort((a, b) => b.value ? 1 : -1);
      return statuses.map((e) => e.key).toList();
    } catch (_) {
      return promotions;
    }
  }

  Future<String?> _getCurrentZoneIdWithRetry() async {
    for (int attempt = 0; attempt < 2; attempt++) {
      try {
        final zoneId = await _getCurrentZoneId();
        if (zoneId != null && zoneId.isNotEmpty) return zoneId;
      } catch (_) {}
      await Future.delayed(const Duration(milliseconds: 500));
    }
    return Constant.selectedZone?.id;
  }

  Future<String?> _getCurrentZoneId() async {
    try {
      final position = await LocationService.getCurrentLocation(
        showLoader: false,
        showError: false,
      );
      if (position != null) {
        final zoneId = await HomeProvider.detectZoneId(
          position.latitude,
          position.longitude,
        );
        if (zoneId != null && zoneId.isNotEmpty) {
          Constant.selectedLocation.location = UserLocation(
            latitude: position.latitude,
            longitude: position.longitude,
          );
          Constant.selectedLocation.zoneId = zoneId;
          try {
            final zoneModel = await HomeProvider.getCurrentZone(
              position.latitude,
              position.longitude,
            );
            if (zoneModel != null &&
                zoneModel.success == true &&
                zoneModel.zone != null) {
              final detectedZone = HomeProvider.convertToOldZoneModel(
                zoneModel,
              );
              if (detectedZone != null) {
                Constant.selectedZone = detectedZone;
                Constant.isZoneAvailable = zoneModel.isZoneAvailable == true;
              }
            }
          } catch (_) {}
          return zoneId;
        }
      }
    } catch (_) {}
    return Constant.selectedZone?.id;
  }

  Future<Map<String, String>> _getHeaders() async => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // ── Build ──────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    // Compute _RS once and cache — only update when screen size changes
    final size = MediaQuery.sizeOf(context);
    final newRS = _RS(sw: size.width, sh: size.height);
    if (_cachedRS != newRS) _cachedRS = newRS;
    final rs = _cachedRS!;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: const _AnimatedAppBar(),
      ),
      body: Stack(
        children: [
          // Decorative background circles
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppThemeData.primary300.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 150,
            left: -80,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppThemeData.primary200.withValues(alpha: 0.10),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Main content
          // FIX: Removed outer Consumer<HomeProvider> — it was causing entire
          // screen rebuild (including all cards) on every cart/location event.
          // Zone changes are handled by _checkAndReloadIfZoneChanged() instead.
          if (_isLoading)
            Constant.loader()
          else if (_promotionsList.isEmpty)
            Constant.showEmptyView(message: "No deals available at the moment.")
          else
            RefreshIndicator(
              onRefresh: _refreshAllData,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // Banners
                  SliverToBoxAdapter(
                    child: _dealsBanners.isEmpty
                        ? const SizedBox.shrink()
                        : Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                            child: DealsBannerView(banners: _dealsBanners),
                          ),
                  ),

                  // Promotions grid
                  SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: rs.hPad),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: rs.gridCols,
                        crossAxisSpacing: rs.gridSpacing,
                        mainAxisSpacing: rs.gridSpacing,
                        childAspectRatio: rs.gridAspectRatio,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => RepaintBoundary(
                          // RepaintBoundary isolates each card's repaint
                          child: _PromotionCard(
                            key: ValueKey(_promotionsList[index].productId),
                            promotion: _promotionsList[index],
                            productCache: _productCache,
                            vendorCache: _vendorCache,
                            restaurantStatusCache: _restaurantStatusCache,
                            rs: rs,
                          ),
                        ),
                        childCount: _promotionsList.length,
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 20)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _PromotionCard extends StatefulWidget {
  final PromotionModel promotion;
  final Map<String, ProductModel> productCache;
  final Map<String, VendorModel> vendorCache;
  final Map<String, bool> restaurantStatusCache;
  final _RS rs;

  const _PromotionCard({
    super.key,
    required this.promotion,
    required this.productCache,
    required this.vendorCache,
    required this.restaurantStatusCache,
    required this.rs,
  });

  @override
  State<_PromotionCard> createState() => _PromotionCardState();
}

class _PromotionCardState extends State<_PromotionCard> {
  ProductModel? _productModel;
  VendorModel? _vendorModel;
  bool _isRestaurantOpen = true;
  bool _isLoadingProduct = true;

  // Cached image URL — validated once, not on every build
  String? _validatedImageUrl;

  _RS get rs => widget.rs;

  @override
  void initState() {
    super.initState();
    _loadCachedData();
  }

  void _loadCachedData() {
    _productModel = widget.productCache[widget.promotion.productId];
    _vendorModel = widget.vendorCache[widget.promotion.restaurantId];

    final restaurantId = widget.promotion.restaurantId;
    if (widget.restaurantStatusCache.containsKey(restaurantId)) {
      _isRestaurantOpen = widget.restaurantStatusCache[restaurantId]!;
    } else if (_vendorModel != null) {
      _isRestaurantOpen = RestaurantStatusUtils.canAcceptOrders(_vendorModel!);
      widget.restaurantStatusCache[restaurantId] = _isRestaurantOpen;
    }

    if (_productModel != null) {
      _validatedImageUrl = _validateImageUrl(_productModel!.photo);
      _isLoadingProduct = false;
    } else if (widget.promotion.productId.isNotEmpty) {
      _loadProduct();
    } else {
      _isLoadingProduct = false;
    }

    if (_vendorModel == null && widget.promotion.restaurantId.isNotEmpty) {
      _loadVendor();
    }
  }

  // FIX: Image URL validation moved OUT of build() — runs once, not every frame
  String? _validateImageUrl(String? photo) {
    if (photo == null) return null;
    final trimmed = photo.trim();
    if (trimmed.isEmpty ||
        trimmed == 'null' ||
        trimmed == 'Null' ||
        trimmed == 'NULL')
      return null;
    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      return null;
    }
    try {
      final uri = Uri.parse(trimmed);
      return (uri.hasScheme && uri.hasAuthority) ? trimmed : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadProduct() async {
    final productId = widget.promotion.productId;
    if (productId.isEmpty) {
      if (mounted) setState(() => _isLoadingProduct = false);
      return;
    }
    try {
      final product = await FireStoreUtils.getProductById(productId);
      if (mounted && product != null) {
        widget.productCache[productId] = product;
        setState(() {
          _productModel = product;
          _validatedImageUrl = _validateImageUrl(product.photo);
          _isLoadingProduct = false;
        });
      } else if (mounted) {
        setState(() => _isLoadingProduct = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingProduct = false);
    }
  }

  Future<void> _loadVendor() async {
    final restaurantId = widget.promotion.restaurantId;
    if (restaurantId.isEmpty) return;
    try {
      final vendor = await FireStoreUtils.getVendorById(restaurantId);
      if (mounted && vendor != null) {
        widget.vendorCache[restaurantId] = vendor;
        final isOpen = RestaurantStatusUtils.canAcceptOrders(vendor);
        widget.restaurantStatusCache[restaurantId] = isOpen;
        setState(() {
          _vendorModel = vendor;
          _isRestaurantOpen = isOpen;
        });
      }
    } catch (_) {}
  }

  // FIX: Called once per build, result stored — not called twice
  int _findCartItemQuantity() {
    final productId = widget.promotion.productId;
    if (productId.isEmpty) return 0;
    return HomeProvider.cartItem
        .where(
          (item) =>
              item.id != null &&
              (item.id == productId || item.id!.startsWith('$productId~')),
        )
        .fold<int>(0, (sum, item) => sum + (item.quantity ?? 0));
  }

  String _formatRoundedPrice(dynamic price) {
    try {
      final v = price is num
          ? price.toDouble()
          : double.tryParse(price.toString()) ?? 0.0;
      final symbol = Constant.currencyModel?.symbol ?? '₹';
      final atRight = Constant.currencyModel?.symbolAtRight ?? false;
      return atRight ? '${v.round()} $symbol' : '$symbol ${v.round()}';
    } catch (_) {
      return Constant.amountShow(amount: price.toString());
    }
  }

  String _calculateDiscountPercentage(
    dynamic originalPrice,
    dynamic specialPrice,
  ) {
    try {
      final orig = originalPrice is num
          ? originalPrice.toDouble()
          : double.tryParse(originalPrice.toString()) ?? 0.0;
      final spec = specialPrice is num
          ? specialPrice.toDouble()
          : double.tryParse(specialPrice.toString()) ?? 0.0;
      if (orig <= 0 || orig <= spec) return '';
      final pct = ((orig - spec) / orig * 100).round();
      return pct > 0 ? '$pct% OFF' : '';
    } catch (_) {
      return '';
    }
  }

  Future<void> _addToCart({required bool isIncrement}) async {
    if (!_isRestaurantOpen) {
      ShowToastDialog.showToast("Restaurant is currently closed".tr);
      return;
    }
    final isLoggedIn = await SqlStorageConst.isUserLoggedIn();
    if (!isLoggedIn) {
      _showLoginRequiredDialog();
      return;
    }
    if (_productModel == null) {
      ShowToastDialog.showToast("Product not available".tr);
      return;
    }

    final productId = widget.promotion.productId;
    final restaurantId = widget.promotion.restaurantId;
    final specialPrice = widget.promotion.specialPrice;
    final itemLimit = widget.promotion.itemLimit;
    final currentQty = _findCartItemQuantity();

    if (isIncrement) {
      if (itemLimit > 0 && currentQty >= itemLimit) {
        ShowToastDialog.showToast(
          "Maximum $itemLimit items allowed for this promotional offer".tr,
        );
        return;
      }
      if ((_productModel!.quantity ?? 0) != -1 &&
          currentQty >= (_productModel!.quantity ?? 0)) {
        ShowToastDialog.showToast("Out of stock".tr);
        return;
      }
    }

    VendorModel? vendorModel = _vendorModel;
    if (vendorModel == null) {
      try {
        vendorModel = await FireStoreUtils.getVendorById(restaurantId);
        if (vendorModel == null) {
          ShowToastDialog.showToast("Restaurant not found".tr);
          return;
        }
        widget.vendorCache[restaurantId] = vendorModel;
      } catch (_) {
        ShowToastDialog.showToast("Error loading restaurant".tr);
        return;
      }
    }

    final price = Constant.productCommissionPrice(
      vendorModel,
      specialPrice.toString(),
    );
    final discountPrice = Constant.productCommissionPrice(
      vendorModel,
      _productModel!.price.toString(),
    );
    final newQuantity = isIncrement ? currentQty + 1 : currentQty - 1;

    final cartProduct = CartProductModel(
      id: productId,
      name: _productModel?.name ?? widget.promotion.productTitle,
      photo: _productModel?.photo ?? '',
      price: price,
      discountPrice: discountPrice,
      vendorID: restaurantId,
      vendorName: vendorModel.title ?? '',
      categoryId: _productModel?.categoryID ?? '',
      quantity: newQuantity,
      extrasPrice: '0',
      extras: [],
      variantInfo: null,
      promoId: productId,
    );

    try {
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      if (isIncrement) {
        final success = await cartProvider.addToCart(
          context,
          cartProduct,
          newQuantity,
        );
        if (!success) ShowToastDialog.showToast("Failed to add to cart".tr);
      } else {
        final matchingItems = HomeProvider.cartItem
            .where(
              (item) =>
                  item.id != null &&
                  (item.id == productId || item.id!.startsWith('$productId~')),
            )
            .toList();
        if (matchingItems.isNotEmpty) {
          final cartItemId = matchingItems.first.id!;
          if (newQuantity > 0) {
            final updateProduct = CartProductModel(
              id: cartItemId,
              name: cartProduct.name,
              photo: cartProduct.photo,
              price: cartProduct.price,
              discountPrice: cartProduct.discountPrice,
              vendorID: cartProduct.vendorID,
              vendorName: cartProduct.vendorName,
              categoryId: cartProduct.categoryId,
              quantity: newQuantity,
              extrasPrice: cartProduct.extrasPrice,
              extras: cartProduct.extras,
              variantInfo: cartProduct.variantInfo,
              promoId: cartProduct.promoId,
            );
            await cartProvider.addToCart(context, updateProduct, newQuantity);
          } else {
            await cartProvider.updateCartItemQuantity(cartItemId, 0);
          }
        } else {
          ShowToastDialog.showToast("Item not found in cart".tr);
        }
      }
    } catch (_) {
      ShowToastDialog.showToast(
        isIncrement ? "Failed to add to cart".tr : "Failed to update cart".tr,
      );
    }
  }

  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      builder: (_) => CustomDialogBox(
        title: "Login Required".tr,
        descriptions:
            "Please login to add items to your cart and continue shopping.".tr,
        positiveString: "Login".tr,
        negativeString: "Cancel".tr,
        positiveClick: () {
          Get.back();
          Get.to(() => PhoneNumberScreen());
        },
        negativeClick: () => Get.back(),
        img: Image.asset(
          'assets/images/ic_launcher.png',
          height: 50,
          width: 50,
        ),
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────
  // FIX: Removed Consumer2<RestaurantDetailsProvider, HomeProvider> — it was
  // causing every card to rebuild whenever ANY restaurant or home event fired.
  // Cart state is already handled by the outer Consumer<CartProvider>.
  @override
  Widget build(BuildContext context) {
    // Only listen to CartProvider — the only thing that changes card UI at runtime
    return Consumer<CartProvider>(
      builder: (context, _, __) {
        // Compute qty ONCE — used for both isInCart and display
        final cartQty = _findCartItemQuantity();
        final isInCart = cartQty > 0;
        final isRestaurantClosed = !_isRestaurantOpen;

        final specialPrice = widget.promotion.specialPrice;
        final itemLimit = widget.promotion.itemLimit;

        return Opacity(
          opacity: isRestaurantClosed ? 0.5 : 1.0,
          child: Container(
            decoration: BoxDecoration(
              color: AppThemeData.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  spreadRadius: 1,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  // ── Card body ──────────────────────────────────
                  Column(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Image (flex 5) ─────────────────────────
                      Flexible(
                        flex: 5,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                              ),
                              child: Container(
                                color: AppThemeData.grey100,
                                child: _isLoadingProduct
                                    ? Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppThemeData.primary300,
                                        ),
                                      )
                                    : _validatedImageUrl != null
                                    ? NetworkImageWidget(
                                        imageUrl: _validatedImageUrl!,
                                        width: double.infinity,
                                        height: double.infinity,
                                        fit: BoxFit.fill,
                                      )
                                    : Center(
                                        child: Icon(
                                          Icons.local_offer,
                                          size: 30,
                                          color: AppThemeData.primary300,
                                        ),
                                      ),
                              ),
                            ),

                            // Veg / non-veg indicator
                            if (_productModel != null)
                              Positioned(
                                top: 6,
                                left: 6,
                                child: Container(
                                  width: rs.vegIndicatorOuter,
                                  height: rs.vegIndicatorOuter,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(3),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.10,
                                        ),
                                        blurRadius: 3,
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Container(
                                      width: rs.vegIndicatorInner,
                                      height: rs.vegIndicatorInner,
                                      decoration: BoxDecoration(
                                        color: (_productModel!.veg == true)
                                            ? Colors.green
                                            : Colors.red,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                            // Item limit badge
                            if (itemLimit > 0)
                              Positioned(
                                top: 6,
                                right: 6,
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: rs.limitBadgeHPad,
                                    vertical: rs.limitBadgeVPad,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(
                                      rs.limitBadgeRadius,
                                    ),
                                  ),
                                  child: Text(
                                    "Limit $itemLimit".tr,
                                    style: TextStyle(
                                      fontSize: rs.limitBadgeFontSize,
                                      color: Colors.white,
                                      fontFamily: AppThemeData.semiBold,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      // ── Details (flex 4) ───────────────────────
                      Flexible(
                        flex: 4,
                        child: Padding(
                          padding: EdgeInsets.all(rs.cardPad),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top group
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.promotion.productTitle,
                                    style: TextStyle(
                                      color: AppThemeData.grey900,
                                      fontSize: rs.nameFontSize,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: AppThemeData.bold,
                                      height: 1.2,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: rs.detailSpacing1),
                                  if (widget
                                      .promotion
                                      .restaurantTitle
                                      .isNotEmpty)
                                    Text(
                                      widget.promotion.restaurantTitle,
                                      style: TextStyle(
                                        color: AppThemeData.grey600,
                                        fontSize: rs.subFontSize,
                                        fontFamily: AppThemeData.regular,
                                        height: 1.2,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  SizedBox(height: rs.detailSpacing1),
                                  SizedBox(
                                    height: 13,
                                    child: _TimeThenFastDeliveryWidget(
                                      deliveryTime: _vendorModel != null
                                          ? Constant.getDeliveryTimeText(
                                              _vendorModel!,
                                            )
                                          : '25-30 mins',
                                    ),
                                  ),
                                ],
                              ),

                              // Bottom: price + button
                              // FIX: prices stacked vertically so they never
                              // compete with the button for horizontal space.
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  // Price column — Expanded takes all leftover space
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Special price — bold, always on top
                                        Text(
                                          _formatRoundedPrice(specialPrice),
                                          style: TextStyle(
                                            fontSize: rs.specialPriceFontSize,
                                            color: AppThemeData.grey900,
                                            fontFamily: AppThemeData.bold,
                                            fontWeight: FontWeight.w800,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        // Original price on its own line — no
                                        // horizontal competition with the button
                                        if (_productModel?.price != null &&
                                            _productModel!.price!.isNotEmpty)
                                          Text(
                                            _formatRoundedPrice(
                                              _productModel!.price,
                                            ),
                                            style: TextStyle(
                                              fontSize:
                                                  rs.originalPriceFontSize,
                                              color: AppThemeData.grey500,
                                              fontFamily: AppThemeData.regular,
                                              decoration:
                                                  TextDecoration.lineThrough,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        // Discount badge
                                        if (_productModel?.price != null &&
                                            _productModel!.price!.isNotEmpty)
                                          Builder(
                                            builder: (_) {
                                              final pct =
                                                  _calculateDiscountPercentage(
                                                    _productModel!.price,
                                                    specialPrice,
                                                  );
                                              if (pct.isEmpty)
                                                return const SizedBox.shrink();
                                              return Padding(
                                                padding: EdgeInsets.only(
                                                  top: rs.detailSpacing3,
                                                ),
                                                child: Container(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 4,
                                                    vertical: rs.detailSpacing3,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.green.shade50,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          3,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    pct,
                                                    style: TextStyle(
                                                      fontSize: rs
                                                          .discountBadgeFontSize,
                                                      color:
                                                          Colors.green.shade700,
                                                      fontFamily:
                                                          AppThemeData.semiBold,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                      ],
                                    ),
                                  ),

                                  SizedBox(width: rs.detailSpacing2),

                                  // Button — fixed size, always fully visible
                                  _buildCartButton(
                                    isInCart: isInCart,
                                    cartQty: cartQty,
                                    isRestaurantClosed: isRestaurantClosed,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Closed overlay
                  if (isRestaurantClosed)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.30),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.70),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "Restaurant Closed".tr,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: rs.closedFontSize,
                                fontWeight: FontWeight.bold,
                                fontFamily: AppThemeData.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Extracted cart button — keeps build() readable ────────────
  Widget _buildCartButton({
    required bool isInCart,
    required int cartQty,
    required bool isRestaurantClosed,
  }) {
    final activeColor = isRestaurantClosed
        ? AppThemeData.grey400
        : AppThemeData.primary300;

    final decoration = BoxDecoration(
      color: activeColor,
      borderRadius: BorderRadius.circular(rs.btnRadius),
      boxShadow: [
        BoxShadow(
          color: activeColor.withValues(alpha: 0.30),
          blurRadius: 3,
          offset: const Offset(0, 1),
        ),
      ],
    );

    if (!isInCart) {
      // Simple add button
      return Container(
        height: rs.btnHeight,
        width: rs.btnWidth,
        decoration: decoration,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isRestaurantClosed
                ? null
                : () => _addToCart(isIncrement: true),
            borderRadius: BorderRadius.circular(rs.btnRadius),
            child: Center(
              child: Icon(Icons.add, size: rs.btnIconSize, color: Colors.white),
            ),
          ),
        ),
      );
    }

    // Quantity stepper
    return Container(
      height: rs.btnHeight,
      decoration: decoration,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isRestaurantClosed
                  ? null
                  : () => _addToCart(isIncrement: false),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(rs.btnRadius),
                bottomLeft: Radius.circular(rs.btnRadius),
              ),
              child: SizedBox(
                width: rs.btnWidth,
                height: rs.btnHeight,
                child: Icon(
                  Icons.remove,
                  size: rs.btnIconSize,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: rs.qtyHPad),
            child: Text(
              cartQty.toString(),
              style: TextStyle(
                fontSize: rs.qtyFontSize,
                fontFamily: AppThemeData.bold,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isRestaurantClosed
                  ? null
                  : () => _addToCart(isIncrement: true),
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(rs.btnRadius),
                bottomRight: Radius.circular(rs.btnRadius),
              ),
              child: SizedBox(
                width: rs.btnWidth,
                height: rs.btnHeight,
                child: Icon(
                  Icons.add,
                  size: rs.btnIconSize,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Animated AppBar ────────────────────────────────────────────────

class _AnimatedAppBar extends StatefulWidget {
  const _AnimatedAppBar();

  @override
  State<_AnimatedAppBar> createState() => _AnimatedAppBarState();
}

class _AnimatedAppBarState extends State<_AnimatedAppBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    _slideAnimation = Tween<double>(begin: -30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
      ),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.fromRGBO(209, 36, 119, 1.0),
            Color.fromRGBO(209, 36, 119, 0.95),
            Color.fromRGBO(209, 36, 119, 0.9),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(209, 36, 119, 0.3),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const SizedBox(width: 12),
              Expanded(
                child: AnimatedBuilder(
                  animation: _fadeAnimation,
                  builder: (context, _) => Opacity(
                    opacity: _fadeAnimation.value,
                    child: Transform.translate(
                      offset: Offset(0, _slideAnimation.value),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Deals Zone".tr,
                            style: TextStyle(
                              fontFamily: AppThemeData.bold,
                              fontSize: 22,
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.30),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            height: 3,
                            width: 60,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white,
                                  Colors.white.withValues(alpha: 0.50),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withValues(alpha: 0.50),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
