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
import 'package:jippymart_customer/utils/fire_store_utils.dart';
import 'package:jippymart_customer/utils/network_image_widget.dart';
import 'package:jippymart_customer/utils/utils/sql_storage_const.dart';
import 'package:jippymart_customer/utils/restaurant_status_utils.dart';
import 'package:jippymart_customer/app/auth_screen/phone_number_screen.dart';
import 'package:jippymart_customer/themes/custom_dialog_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:jippymart_customer/services/cache_manager.dart';
import 'package:jippymart_customer/services/api_queue_manager.dart';

import '../../models/user_model.dart';
import 'bannerdeals.dart';

// ── Brand Colors ──────────────────────────────────────────────────
class _DC {
  static const Color brand = Color(0xFFD12477);
  static const Color brandDark = Color(0xFFA81C5E);
  static const Color brandLight = Color(0xFFFCE8F3);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surface2 = Color(0xFFF7F5FB);
  static const Color bg = Color(0xFFF2EFF9);
  static const Color text1 = Color(0xFF13111A);
  static const Color text2 = Color(0xFF5A5668);
  static const Color text3 = Color(0xFF9B95A8);
  static const Color green = Color(0xFF1DB87A);
  static const Color red = Color(0xFFE84040);
  static const Color amber = Color(0xFFF5A623);
  static const Color closedOverlay = Color(0x55000000);
  static const Color closedPill = Color(0xCC000000);
}

// ── Responsive Sizing ─────────────────────────────────────────────
@immutable
class _RS {
  final double sw, sh;

  const _RS({required this.sw, required this.sh});

  bool get isSmall => sw < 360;

  bool get isLarge => sw >= 600;

  int get gridCols => sw >= 600 ? 3 : 2;

  double get gridSpacing => isSmall ? 10.0 : 12.0;

  double get gridAspectRatio {
    if (sw >= 600) return 0.72;
    if (sw < 360) return 0.60;
    return 0.62;
  }

  double get hPad => isSmall ? 12.0 : (isLarge ? 18.0 : 14.0);

  double get nameFontSize => isSmall ? 12.0 : (isLarge ? 14.0 : 13.0);

  double get subFontSize => isSmall ? 10.0 : (isLarge ? 12.0 : 11.0);

  double get specialPriceFontSize => isSmall ? 13.0 : (isLarge ? 15.0 : 14.0);

  double get originalPriceFontSize => isSmall ? 9.0 : (isLarge ? 11.0 : 10.0);

  double get discountBadgeFontSize => isSmall ? 7.5 : (isLarge ? 9.5 : 8.5);

  double get limitBadgeFontSize => isSmall ? 7.0 : (isLarge ? 9.0 : 8.0);

  double get btnHeight => isSmall ? 30.0 : (isLarge ? 36.0 : 32.0);

  double get btnWidth => isSmall ? 30.0 : (isLarge ? 36.0 : 32.0);

  double get btnRadius => isSmall ? 8.0 : (isLarge ? 11.0 : 9.0);

  double get btnIconSize => isSmall ? 14.0 : (isLarge ? 18.0 : 16.0);

  double get qtyFontSize => isSmall ? 12.0 : (isLarge ? 14.0 : 13.0);

  double get qtyHPad => isSmall ? 6.0 : (isLarge ? 10.0 : 8.0);

  double get cardPad => isSmall ? 8.0 : (isLarge ? 11.0 : 9.0);

  double get vegOuter => isSmall ? 14.0 : (isLarge ? 17.0 : 15.0);

  double get vegInner => isSmall ? 8.0 : (isLarge ? 11.0 : 9.5);

  double get closedFontSize => isSmall ? 10.0 : (isLarge ? 12.0 : 11.0);

  @override
  bool operator ==(Object o) => o is _RS && o.sw == sw && o.sh == sh;

  @override
  int get hashCode => Object.hash(sw, sh);
}

// ── Delivery Time Ticker ──────────────────────────────────────────
class _DeliveryTicker extends StatefulWidget {
  final String deliveryTime;

  const _DeliveryTicker({required this.deliveryTime});

  @override
  State<_DeliveryTicker> createState() => _DeliveryTickerState();
}

class _DeliveryTickerState extends State<_DeliveryTicker> {
  bool _showFast = false;
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(
      const Duration(seconds: 4),
      (_) => mounted ? setState(() => _showFast = !_showFast) : null,
    );
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      switchInCurve: Curves.easeIn,
      switchOutCurve: Curves.easeOut,
      transitionBuilder: (child, anim) =>
          FadeTransition(opacity: anim, child: child),
      child: _showFast
          ? Row(
              key: const ValueKey('fast'),
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.delivery_dining_rounded, size: 11, color: _DC.brand),
                const SizedBox(width: 3),
                Text(
                  'Fast delivery',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _DC.brand,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            )
          : Row(
              key: const ValueKey('time'),
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.access_time_rounded, size: 10, color: _DC.text3),
                const SizedBox(width: 3),
                Text(
                  widget.deliveryTime,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: _DC.text3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
    );
  }
}

// ── Main Screen ───────────────────────────────────────────────────
class DealsScreen extends StatefulWidget {
  const DealsScreen({super.key});

  @override
  State<DealsScreen> createState() => _DealsScreenState();
}

class _DealsScreenState extends State<DealsScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  bool _isLoading = true;
  List<PromotionModel> _promotionsList = [];
  List<BannerModel> _dealsBanners = [];
  String? _currentZoneId;
  HomeProvider? _homeProvider;
  int _selectedCategoryIndex = 0;

  static const Duration _networkTimeout = Duration(seconds: 10);
  static const Duration _cacheDuration = Duration(minutes: 3);

  final Map<String, ProductModel> _productCache = {};
  final Map<String, VendorModel> _vendorCache = {};
  final Map<String, bool> _restaurantStatusCache = {};

  DateTime? _lastLoadTime;
  int _retryCount = 0;
  static const int _maxRetries = 1;
  Timer? _zoneDebounce;
  _RS? _cachedRS;

  late AnimationController _headerAnim;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;

  // final List<String> _categories = [
  //   'All Deals',
  //   'Food',
  //   'Grocery',
  //   'Beverages',
  //   'Snacks',
  //   'Offers',
  // ];

  /// Prefer [Constant.selectedZone], fall back to [Constant.selectedLocation.zoneId]
  /// so deals refresh when zone is updated either way (e.g. automatic GPS/zone API).
  String? _effectiveZoneId() {
    final fromZone = Constant.selectedZone?.id?.trim();
    if (fromZone != null && fromZone.isNotEmpty) return fromZone;
    final fromLocation = Constant.selectedLocation.zoneId?.trim();
    if (fromLocation != null && fromLocation.isNotEmpty) return fromLocation;
    return null;
  }

  void _onHomeProviderNotify() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _checkAndReloadIfZoneChanged();
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentZoneId = _effectiveZoneId();

    _headerAnim = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _headerFade = CurvedAnimation(
      parent: _headerAnim,
      curve: const Interval(0, 0.7, curve: Curves.easeOut),
    );
    _headerSlide = Tween<Offset>(begin: const Offset(0, -0.4), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _headerAnim,
            curve: const Interval(0.1, 0.8, curve: Curves.easeOutCubic),
          ),
        );

    _loadAllDataWithCache();
    _headerAnim.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _homeProvider = Provider.of<HomeProvider>(context, listen: false);
      _homeProvider!.addListener(_onHomeProviderNotify);
    });
  }

  @override
  void dispose() {
    _homeProvider?.removeListener(_onHomeProviderNotify);
    WidgetsBinding.instance.removeObserver(this);
    _zoneDebounce?.cancel();
    _headerAnim.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => mounted ? _checkAndReloadIfZoneChanged() : null,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkAndReloadIfZoneChanged();
  }

  void _checkAndReloadIfZoneChanged() {
    final newZoneId = _effectiveZoneId();
    if (newZoneId != null &&
        newZoneId.isNotEmpty &&
        newZoneId != _currentZoneId) {
      _zoneDebounce?.cancel();
      _zoneDebounce = Timer(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        final confirmed = _effectiveZoneId();
        if (confirmed != null &&
            confirmed.isNotEmpty &&
            confirmed == newZoneId) {
          final previousZoneId = _currentZoneId;
          _currentZoneId = newZoneId;
          _lastLoadTime = null;
          if (previousZoneId != null &&
              previousZoneId.isNotEmpty &&
              previousZoneId != newZoneId) {
            CacheManager().remove('deals_banners_$previousZoneId');
            CacheManager().remove('promotions_$previousZoneId');
          }
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
      if (zoneId == null || zoneId.isEmpty)
        zoneId = await _getCurrentZoneIdWithRetry();
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
    } catch (_) {
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
    } catch (_) {
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
      if (zoneId == null || zoneId.isEmpty)
        zoneId = await _getCurrentZoneIdWithRetry();
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
    } catch (_) {
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
        final j = json.decode(response.body);
        if (j['success'] == true) {
          return (j['data'] as List)
              .take(15)
              .map((e) => BannerModel.fromJson(e))
              .toList();
        }
      }
      return [];
    } on TimeoutException {
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<void> _loadPromotionsData() async {
    try {
      String? zoneId = _currentZoneId;
      if (zoneId == null || zoneId.isEmpty)
        zoneId = await _getCurrentZoneIdWithRetry();
      if (zoneId == null || zoneId.isEmpty) {
        if (mounted) setState(() => _promotionsList = []);
        return;
      }
      final cacheKey = 'promotions_$zoneId';
      final data = await CacheManager().getOrSet<List<Map<String, dynamic>>>(
        cacheKey,
        () => ApiQueueManager().enqueue<List<Map<String, dynamic>>>(
          priority: RequestPriority.normal,
          key: cacheKey,
          request: () => FireStoreUtils.getAllActivePromotions(zoneId: zoneId!),
        ),
        type: CacheType.general,
      );
      if (data.isNotEmpty) {
        final promos = data
            .take(100)
            .map((p) => PromotionModel.fromJson(p))
            .where((promo) => promo.isAvailable)
            .toList();
        final vendorIds = promos
            .map((p) => p.restaurantId)
            .where((id) => id.isNotEmpty)
            .toSet()
            .toList();
        await _preCacheVendors(vendorIds);
        final sorted = await _sortByStatus(promos);
        if (mounted) setState(() => _promotionsList = sorted);
      } else {
        if (mounted) setState(() => _promotionsList = []);
      }
    } catch (_) {
      if (mounted) setState(() => _promotionsList = []);
    }
  }

  Future<void> _preCacheVendors(List<String> ids) async {
    for (final id in ids) {
      if (!_vendorCache.containsKey(id)) {
        try {
          final v = await FireStoreUtils.getVendorById(id);
          if (v != null) {
            _vendorCache[id] = v;
            _restaurantStatusCache[id] = RestaurantStatusUtils.canAcceptOrders(
              v,
            );
          }
        } catch (_) {}
      }
    }
  }

  Future<List<PromotionModel>> _sortByStatus(
    List<PromotionModel> promos,
  ) async {
    if (promos.isEmpty) return promos;
    try {
      final entries = promos.map((p) {
        final id = p.restaurantId;
        bool open = true;
        if (_restaurantStatusCache.containsKey(id)) {
          open = _restaurantStatusCache[id]!;
        } else if (_vendorCache.containsKey(id)) {
          open = RestaurantStatusUtils.canAcceptOrders(_vendorCache[id]!);
          _restaurantStatusCache[id] = open;
        }
        return MapEntry(p, open);
      }).toList();
      entries.sort((a, b) => b.value ? 1 : -1);
      return entries.map((e) => e.key).toList();
    } catch (_) {
      return promos;
    }
  }

  Future<String?> _getCurrentZoneIdWithRetry() async {
    for (int i = 0; i < 2; i++) {
      try {
        final z = await _getCurrentZoneId();
        if (z != null && z.isNotEmpty) return z;
      } catch (_) {}
      await Future.delayed(const Duration(milliseconds: 500));
    }
    return _effectiveZoneId();
  }

  Future<String?> _getCurrentZoneId() async {
    try {
      final pos = await LocationService.getCurrentLocation(
        showLoader: false,
        showError: false,
      );
      if (pos != null) {
        final zoneId = await HomeProvider.detectZoneId(
          pos.latitude,
          pos.longitude,
        );
        if (zoneId != null && zoneId.isNotEmpty) {
          Constant.selectedLocation.location = UserLocation(
            latitude: pos.latitude,
            longitude: pos.longitude,
          );
          Constant.selectedLocation.zoneId = zoneId;
          try {
            final zm = await HomeProvider.getCurrentZone(
              pos.latitude,
              pos.longitude,
            );
            if (zm != null && zm.success == true && zm.zone != null) {
              final dz = HomeProvider.convertToOldZoneModel(zm);
              if (dz != null) {
                Constant.selectedZone = dz;
                Constant.isZoneAvailable = zm.isZoneAvailable == true;
              }
            }
          } catch (_) {}
          return zoneId;
        }
      }
    } catch (_) {}
    return _effectiveZoneId();
  }

  Future<Map<String, String>> _getHeaders() async => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // ── Build ──────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final newRS = _RS(sw: size.width, sh: size.height);
    if (_cachedRS != newRS) _cachedRS = newRS;
    final rs = _cachedRS!;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        // Keep status bar merged with Deals header gradient.
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemStatusBarContrastEnforced: false,
      ),
      child: Scaffold(
        backgroundColor: _DC.bg,
        body: Column(
          children: [
            _buildAppBar(rs),
            // _buildCategoryTabs(),
            Expanded(
              child: _isLoading
                  ? _buildLoader()
                  : _promotionsList.isEmpty
                  ? _buildEmpty()
                  : RefreshIndicator(
                      onRefresh: _refreshAllData,
                      color: _DC.brand,
                      child: CustomScrollView(
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        slivers: [
                          if (_dealsBanners.isNotEmpty)
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  14,
                                  16,
                                  14,
                                  4,
                                ),
                                child: DealsBannerView(banners: _dealsBanners),
                              ),
                            ),
                          SliverToBoxAdapter(child: _buildSectionHeader(rs)),
                          SliverPadding(
                            padding: EdgeInsets.fromLTRB(
                              rs.hPad,
                              0,
                              rs.hPad,
                              24,
                            ),
                            sliver: SliverGrid(
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: rs.gridCols,
                                    crossAxisSpacing: rs.gridSpacing,
                                    mainAxisSpacing: rs.gridSpacing,
                                    childAspectRatio: rs.gridAspectRatio,
                                  ),
                              delegate: SliverChildBuilderDelegate(
                                (ctx, i) => RepaintBoundary(
                                  child: _PromotionCard(
                                    key: ValueKey(_promotionsList[i].productId),
                                    promotion: _promotionsList[i],
                                    productCache: _productCache,
                                    vendorCache: _vendorCache,
                                    restaurantStatusCache:
                                        _restaurantStatusCache,
                                    rs: rs,
                                    animIndex: i,
                                  ),
                                ),
                                childCount: _promotionsList.length,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(_RS rs) {
    return SlideTransition(
      position: _headerSlide,
      child: FadeTransition(
        opacity: _headerFade,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFD12477), Color(0xFFB01E66), Color(0xFF8E1552)],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Stack(
              children: [
                // Decorative circles
                Positioned(
                  top: -40,
                  right: -30,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0x14FFFFFF),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -50,
                  left: -20,
                  child: Container(
                    width: 130,
                    height: 130,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0x0DFFFFFF),
                    ),
                  ),
                ),
                Positioned(
                  top: 20,
                  right: 60,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0x33FFFFFF),
                    ),
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Title block
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Deals Zone',
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                    height: 1.1,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '🔥 HOT',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white.withOpacity(0.95),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.6),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  Constant.selectedZone?.name?.isNotEmpty ==
                                          true
                                      ? '${Constant.selectedZone!.name} · Limited time offers'
                                      : 'Limited time exclusive deals',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withOpacity(0.75),
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Glowing accent line
                            Container(
                              height: 3,
                              width: 50,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(2),
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white,
                                    Colors.white.withOpacity(0.4),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.5),
                                    blurRadius: 6,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Count badge
                      if (_promotionsList.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${_promotionsList.length}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  height: 1.1,
                                ),
                              ),
                              Text(
                                'deals',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white.withOpacity(0.8),
                                  fontWeight: FontWeight.w500,
                                ),
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
        ),
      ),
    );
  }

  // Widget _buildCategoryTabs() {
  //   return Container(
  //     color: _DC.surface,
  //     child: Column(
  //       children: [
  //         SizedBox(
  //           height: 48,
  //           child: ListView.separated(
  //             scrollDirection: Axis.horizontal,
  //             padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
  //             itemCount: _categories.length,
  //             separatorBuilder: (_, __) => const SizedBox(width: 8),
  //             itemBuilder: (ctx, i) {
  //               final active = _selectedCategoryIndex == i;
  //               return GestureDetector(
  //                 onTap: () => setState(() => _selectedCategoryIndex = i),
  //                 child: AnimatedContainer(
  //                   duration: const Duration(milliseconds: 200),
  //                   padding: const EdgeInsets.symmetric(
  //                     horizontal: 16,
  //                     vertical: 6,
  //                   ),
  //                   decoration: BoxDecoration(
  //                     color: active ? _DC.brand : _DC.surface2,
  //                     borderRadius: BorderRadius.circular(20),
  //                     border: Border.all(
  //                       color: active ? _DC.brand : const Color(0xFFE8E4F0),
  //                       width: 1.5,
  //                     ),
  //                     boxShadow: active
  //                         ? [
  //                             BoxShadow(
  //                               color: _DC.brand.withOpacity(0.28),
  //                               blurRadius: 10,
  //                               offset: const Offset(0, 3),
  //                             ),
  //                           ]
  //                         : null,
  //                   ),
  //                   // child: Text(
  //                   //   _categories[i],
  //                   //   style: TextStyle(
  //                   //     fontSize: 12.5,
  //                   //     fontWeight: FontWeight.w600,
  //                   //     color: active ? Colors.white : _DC.text2,
  //                   //     letterSpacing: 0.1,
  //                   //   ),
  //                   // ),
  //                 ),
  //               );
  //             },
  //           ),
  //         ),
  //         Container(height: 1, color: const Color(0xFFF0EDF8)),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildSectionHeader(_RS rs) {
    return Padding(
      padding: EdgeInsets.fromLTRB(rs.hPad, 18, rs.hPad, 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: _DC.brand,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'Hot Deals',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: _DC.text1,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: _DC.brandLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${_promotionsList.length} items',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _DC.brand,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoader() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _DC.brandLight,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: _DC.brand,
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Loading deals...',
            style: TextStyle(
              fontSize: 13,
              color: _DC.text3,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _DC.brandLight,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Center(
              child: Text('🎁', style: TextStyle(fontSize: 36)),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No deals right now',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _DC.text1,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Check back soon for exciting offers!',
            style: TextStyle(fontSize: 13, color: _DC.text3),
          ),
        ],
      ),
    );
  }
}

// ── Promotion Card ────────────────────────────────────────────────
class _PromotionCard extends StatefulWidget {
  final PromotionModel promotion;
  final Map<String, ProductModel> productCache;
  final Map<String, VendorModel> vendorCache;
  final Map<String, bool> restaurantStatusCache;
  final _RS rs;
  final int animIndex;

  const _PromotionCard({
    super.key,
    required this.promotion,
    required this.productCache,
    required this.vendorCache,
    required this.restaurantStatusCache,
    required this.rs,
    required this.animIndex,
  });

  @override
  State<_PromotionCard> createState() => _PromotionCardState();
}

class _PromotionCardState extends State<_PromotionCard>
    with SingleTickerProviderStateMixin {
  ProductModel? _product;
  VendorModel? _vendor;
  bool _isOpen = true;
  bool _loadingProduct = true;
  String? _imgUrl;

  late AnimationController _entryAnim;
  late Animation<double> _entryFade;
  late Animation<Offset> _entrySlide;

  _RS get rs => widget.rs;

  @override
  void initState() {
    super.initState();
    _entryAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    final delay = (widget.animIndex * 55).clamp(0, 400);
    _entryFade = CurvedAnimation(
      parent: _entryAnim,
      curve: const Interval(0, 0.7, curve: Curves.easeOut),
    );
    _entrySlide = Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _entryAnim,
            curve: const Interval(0.1, 0.9, curve: Curves.easeOutCubic),
          ),
        );
    Future.delayed(
      Duration(milliseconds: delay),
      () => mounted ? _entryAnim.forward() : null,
    );
    _loadCachedData();
  }

  @override
  void dispose() {
    _entryAnim.dispose();
    super.dispose();
  }

  void _loadCachedData() {
    _product = widget.productCache[widget.promotion.productId];
    _vendor = widget.vendorCache[widget.promotion.restaurantId];

    final rId = widget.promotion.restaurantId;
    if (widget.restaurantStatusCache.containsKey(rId)) {
      _isOpen = widget.restaurantStatusCache[rId]!;
    } else if (_vendor != null) {
      _isOpen = RestaurantStatusUtils.canAcceptOrders(_vendor!);
      widget.restaurantStatusCache[rId] = _isOpen;
    }

    if (_product != null) {
      _imgUrl = _validateImg(_product!.photo);
      _loadingProduct = false;
    } else if (widget.promotion.productId.isNotEmpty) {
      _loadProduct();
    } else {
      _loadingProduct = false;
    }

    if (_vendor == null && widget.promotion.restaurantId.isNotEmpty)
      _loadVendor();
  }

  String? _validateImg(String? photo) {
    if (photo == null) return null;
    final t = photo.trim();
    if (t.isEmpty || t == 'null' || t == 'Null' || t == 'NULL') return null;
    if (!t.startsWith('http://') && !t.startsWith('https://')) return null;
    try {
      final u = Uri.parse(t);
      return (u.hasScheme && u.hasAuthority) ? t : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadProduct() async {
    final id = widget.promotion.productId;
    if (id.isEmpty) {
      if (mounted) setState(() => _loadingProduct = false);
      return;
    }
    try {
      final p = await FireStoreUtils.getProductById(id);
      if (mounted && p != null) {
        widget.productCache[id] = p;
        setState(() {
          _product = p;
          _imgUrl = _validateImg(p.photo);
          _loadingProduct = false;
        });
      } else if (mounted) {
        setState(() => _loadingProduct = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loadingProduct = false);
    }
  }

  Future<void> _loadVendor() async {
    final id = widget.promotion.restaurantId;
    if (id.isEmpty) return;
    try {
      final v = await FireStoreUtils.getVendorById(id);
      if (mounted && v != null) {
        widget.vendorCache[id] = v;
        final open = RestaurantStatusUtils.canAcceptOrders(v);
        widget.restaurantStatusCache[id] = open;
        setState(() {
          _vendor = v;
          _isOpen = open;
        });
      }
    } catch (_) {}
  }

  int _cartQty() {
    final id = widget.promotion.productId;
    final vendorId = widget.promotion.restaurantId;
    if (id.isEmpty) return 0;
    if (vendorId.isEmpty) return 0;
    return context.read<CartProvider>().quantityFor(
      vendorId: vendorId,
      productId: id,
    );
  }

  String _fmtPrice(dynamic price) {
    try {
      final v = price is num
          ? price.toDouble()
          : double.tryParse(price.toString()) ?? 0.0;
      final sym = Constant.currencyModel?.symbol ?? '₹';
      final right = Constant.currencyModel?.symbolAtRight ?? false;
      return right ? '${v.round()} $sym' : '$sym ${v.round()}';
    } catch (_) {
      return Constant.amountShow(amount: price.toString());
    }
  }

  String _discPct(dynamic orig, dynamic spec) {
    try {
      final o = orig is num
          ? orig.toDouble()
          : double.tryParse(orig.toString()) ?? 0.0;
      final s = spec is num
          ? spec.toDouble()
          : double.tryParse(spec.toString()) ?? 0.0;
      if (o <= 0 || o <= s) return '';
      final pct = ((o - s) / o * 100).round();
      return pct > 0 ? '$pct% OFF' : '';
    } catch (_) {
      return '';
    }
  }

  Future<void> _addToCart({required bool increment}) async {
    if (!_isOpen) {
      ShowToastDialog.showToast("Restaurant is currently closed".tr);
      return;
    }
    final loggedIn = await SqlStorageConst.isUserLoggedIn();
    if (!loggedIn) {
      _showLoginDialog();
      return;
    }
    if (_product == null) {
      ShowToastDialog.showToast("Product not available".tr);
      return;
    }

    final pid = widget.promotion.productId;
    final rid = widget.promotion.restaurantId;
    final spec = widget.promotion.specialPrice;
    final limit = widget.promotion.itemLimit;
    final qty = _cartQty();

    if (increment) {
      if (limit > 0 && qty >= limit) {
        ShowToastDialog.showToast(
          "Maximum $limit items allowed for this offer".tr,
        );
        return;
      }
      if ((_product!.quantity ?? 0) != -1 && qty >= (_product!.quantity ?? 0)) {
        ShowToastDialog.showToast("Out of stock".tr);
        return;
      }
    }

    VendorModel? vendor = _vendor;
    if (vendor == null) {
      try {
        vendor = await FireStoreUtils.getVendorById(rid);
        if (vendor == null) {
          ShowToastDialog.showToast("Restaurant not found".tr);
          return;
        }
        widget.vendorCache[rid] = vendor;
      } catch (_) {
        ShowToastDialog.showToast("Error loading restaurant".tr);
        return;
      }
    }

    final price = Constant.productCommissionPrice(vendor, spec.toString());
    final discPrice = Constant.productCommissionPrice(
      vendor,
      _product!.price.toString(),
    );
    final newQty = increment ? qty + 1 : qty - 1;

    final cartItem = CartProductModel(
      id: pid,
      name: _product?.name ?? widget.promotion.productTitle,
      photo: _product?.photo ?? '',
      price: price,
      discountPrice: discPrice,
      vendorID: rid,
      vendorName: vendor.title ?? '',
      categoryId: _product?.categoryID ?? '',
      quantity: newQty,
      extrasPrice: '0',
      extras: [],
      variantInfo: null,
      promoId: pid,
    );

    try {
      final cp = Provider.of<CartProvider>(context, listen: false);
      if (increment) {
        final ok = await cp.addToCart(context, cartItem, newQty);
        if (!ok) ShowToastDialog.showToast("Failed to add to cart".tr);
      } else {
        final existing = HomeProvider.cartItem.cast<CartProductModel?>().firstWhere(
          (item) =>
              item?.id != null &&
              (item!.id == pid || item.id!.startsWith('$pid~')),
          orElse: () => null,
        );
        if (existing != null && existing.id != null) {
          final cid = existing.id!;
          if (newQty > 0) {
            await cp.addToCart(
              context,
              CartProductModel(
                id: cid,
                name: cartItem.name,
                photo: cartItem.photo,
                price: cartItem.price,
                discountPrice: cartItem.discountPrice,
                vendorID: cartItem.vendorID,
                vendorName: cartItem.vendorName,
                categoryId: cartItem.categoryId,
                quantity: newQty,
                extrasPrice: cartItem.extrasPrice,
                extras: cartItem.extras,
                variantInfo: cartItem.variantInfo,
                promoId: cartItem.promoId,
              ),
              newQty,
            );
          } else {
            await cp.updateCartItemQuantity(cid, 0);
          }
        }
      }
    } catch (_) {
      ShowToastDialog.showToast(
        increment ? "Failed to add to cart".tr : "Failed to update cart".tr,
      );
    }
  }

  void _showLoginDialog() {
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

  // ── Build ──────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final qty = context.select<CartProvider, int>(
      (cart) => cart.quantityFor(
        vendorId: widget.promotion.restaurantId,
        productId: widget.promotion.productId,
      ),
    );
    final inCart = qty > 0;
    final closed = !_isOpen;
    final spec = widget.promotion.specialPrice;
    final limit = widget.promotion.itemLimit;

    return FadeTransition(
      opacity: _entryFade,
      child: SlideTransition(
        position: _entrySlide,
        child: Opacity(
          opacity: closed ? 0.55 : 1.0,
          child: Container(
            decoration: BoxDecoration(
              color: _DC.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2D1B4E).withOpacity(0.09),
                  blurRadius: 14,
                  spreadRadius: 0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Image ──────────────────────────────
                      Flexible(
                        flex: 5,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // Image
                            Container(
                              color: const Color(0xFFF5F2FB),
                              child: _loadingProduct
                                  ? const Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: _DC.brand,
                                      ),
                                    )
                                  : _imgUrl != null
                                  ? NetworkImageWidget(
                                      imageUrl: _imgUrl!,
                                      width: double.infinity,
                                      height: double.infinity,
                                      fit: BoxFit.fill,
                                    )
                                  : Center(
                                      child: Icon(
                                        Icons.local_offer_rounded,
                                        size: 32,
                                        color: _DC.brand.withOpacity(0.4),
                                      ),
                                    ),
                            ),

                            // Bottom gradient for legibility
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              height: 40,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [
                                      Colors.black.withOpacity(0.22),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // Veg/Non-veg badge
                            if (_product != null)
                              Positioned(
                                top: 7,
                                left: 7,
                                child: Container(
                                  width: rs.vegOuter,
                                  height: rs.vegOuter,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(4),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.12),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Container(
                                      width: rs.vegInner,
                                      height: rs.vegInner,
                                      decoration: BoxDecoration(
                                        color: (_product!.veg == true)
                                            ? _DC.green
                                            : _DC.red,
                                        borderRadius: BorderRadius.circular(
                                          2.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                            // Discount badge
                            if (_product?.price != null &&
                                _product!.price!.isNotEmpty)
                              Positioned(
                                top: 7,
                                right: 7,
                                child: Builder(
                                  builder: (_) {
                                    final pct = _discPct(_product!.price, spec);
                                    if (pct.isEmpty)
                                      return const SizedBox.shrink();
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFFD12477),
                                            Color(0xFFFF5E8F),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                        boxShadow: [
                                          BoxShadow(
                                            color: _DC.brand.withOpacity(0.35),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        pct,
                                        style: TextStyle(
                                          fontSize: rs.discountBadgeFontSize,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),

                            // Item limit badge
                            if (limit > 0)
                              Positioned(
                                bottom: 6,
                                left: 6,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.62),
                                    borderRadius: BorderRadius.circular(7),
                                  ),
                                  child: Text(
                                    'Limit $limit',
                                    style: TextStyle(
                                      fontSize: rs.limitBadgeFontSize,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      // ── Details ────────────────────────────
                      Flexible(
                        flex: 4,
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            rs.cardPad,
                            rs.cardPad,
                            rs.cardPad,
                            rs.cardPad - 1,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Product name
                              Text(
                                widget.promotion.productTitle,
                                style: TextStyle(
                                  fontSize: rs.nameFontSize,
                                  fontWeight: FontWeight.w800,
                                  color: _DC.text1,
                                  letterSpacing: -0.2,
                                  height: 1.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),

                              // Restaurant name
                              if (widget.promotion.restaurantTitle.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    widget.promotion.restaurantTitle,
                                    style: TextStyle(
                                      fontSize: rs.subFontSize,
                                      color: _DC.text3,
                                      fontWeight: FontWeight.w400,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),

                              // Delivery time
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: SizedBox(
                                  height: 14,
                                  child: _DeliveryTicker(
                                    deliveryTime: _vendor != null
                                        ? Constant.getDeliveryTimeText(_vendor!)
                                        : '25-30 mins',
                                  ),
                                ),
                              ),

                              // Price row + button
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          _fmtPrice(spec),
                                          style: TextStyle(
                                            fontSize: rs.specialPriceFontSize,
                                            fontWeight: FontWeight.w800,
                                            color: _DC.text1,
                                            letterSpacing: -0.3,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (_product?.price != null &&
                                            _product!.price!.isNotEmpty)
                                          Text(
                                            _fmtPrice(_product!.price),
                                            style: TextStyle(
                                              fontSize:
                                                  rs.originalPriceFontSize,
                                              color: _DC.text3,
                                              fontWeight: FontWeight.w400,
                                              decoration:
                                                  TextDecoration.lineThrough,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  _buildCartBtn(
                                    inCart: inCart,
                                    qty: qty,
                                    closed: closed,
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
                  if (closed)
                    Positioned.fill(
                      child: Container(
                        color: _DC.closedOverlay,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: _DC.closedPill,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Closed',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: rs.closedFontSize,
                                fontWeight: FontWeight.w700,
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
        ),
      ),
    );
  }

  Widget _buildCartBtn({
    required bool inCart,
    required int qty,
    required bool closed,
  }) {
    if (closed) {
      return Container(
        width: rs.btnWidth,
        height: rs.btnHeight,
        decoration: BoxDecoration(
          color: const Color(0xFFEDE8F8),
          borderRadius: BorderRadius.circular(rs.btnRadius),
        ),
        child: Icon(
          Icons.lock_outline_rounded,
          size: rs.btnIconSize - 2,
          color: _DC.text3,
        ),
      );
    }

    if (!inCart) {
      return GestureDetector(
        onTap: () => _addToCart(increment: true),
        child: Container(
          width: rs.btnWidth,
          height: rs.btnHeight,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFD12477), Color(0xFFFF5E8F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(rs.btnRadius),
            boxShadow: [
              BoxShadow(
                color: _DC.brand.withOpacity(0.36),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(
            Icons.add_rounded,
            size: rs.btnIconSize,
            color: Colors.white,
          ),
        ),
      );
    }

    // Stepper
    return Container(
      height: rs.btnHeight,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFD12477), Color(0xFFFF5E8F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(rs.btnRadius),
        boxShadow: [
          BoxShadow(
            color: _DC.brand.withOpacity(0.36),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => _addToCart(increment: false),
            child: SizedBox(
              width: rs.btnWidth,
              height: rs.btnHeight,
              child: Icon(
                Icons.remove_rounded,
                size: rs.btnIconSize,
                color: Colors.white,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: rs.qtyHPad),
            child: Text(
              '$qty',
              style: TextStyle(
                fontSize: rs.qtyFontSize,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => _addToCart(increment: true),
            child: SizedBox(
              width: rs.btnWidth,
              height: rs.btnHeight,
              child: Icon(
                Icons.add_rounded,
                size: rs.btnIconSize,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
