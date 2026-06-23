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
import '../wallet_screen/provider/wallet_provider.dart';
import '../wallet_screen/wallet_home_screen.dart';
import 'bannerdeals.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Brand tokens — single source of truth for every color in this feature.
// ─────────────────────────────────────────────────────────────────────────────
abstract final class _C {
  static const Color brand = Color(0xFFD12477);
  static const Color brandDark = Color(0xFFA81C5E);
  static const Color brandLight = Color(0xFFFCE8F3);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color bg = Color(0xFFF5F0FA);
  static const Color border = Color(0xFFEEE8F8);
  static const Color text1 = Color(0xFF13111A);
  static const Color text2 = Color(0xFF5A5668);
  static const Color text3 = Color(0xFF9B95A8);
  static const Color green = Color(0xFF1DB87A);
  static const Color red = Color(0xFFE84040);
  static const Color amber = Color(0xFFF5A623);
  static const Color overlay = Color(0x55000000);
  static const Color closedPill = Color(0xCC000000);

  // Wallet badge
  static const Color walletBg = Color(0xFFFFF7F0);
  static const Color walletBorder = Color(0xFFFFE4C0);
}

// ─────────────────────────────────────────────────────────────────────────────
// Responsive sizing — computed once per layout pass and cached.
// ─────────────────────────────────────────────────────────────────────────────
@immutable
final class _RS {
  final double sw, sh;

  const _RS({required this.sw, required this.sh});

  bool get _xs => sw < 360;

  bool get _lg => sw >= 600;

  // Layout
  double get hPad => _xs ? 12 : (_lg ? 16 : 12);

  double get cardWidth => _xs ? 120 : (_lg ? 155 : 136);

  double get cardImgH => _xs ? 80 : (_lg ? 108 : 92);

  double get prodScrollH => cardImgH + 120; // img + info area

  // Typography
  double get nameFs => _xs ? 11.5 : (_lg ? 13.5 : 12.5);

  double get specPriceFs => _xs ? 13 : (_lg ? 15 : 14);

  double get origPriceFs => _xs ? 8 : (_lg ? 10 : 9);

  double get badgeFs => _xs ? 7.5 : (_lg ? 9 : 8);

  double get saveLblFs => _xs ? 7 : (_lg ? 8.5 : 7.5);

  double get qtyFs => _xs ? 12 : (_lg ? 14 : 13);

  double get closedFs => _xs ? 10 : (_lg ? 12 : 11);

  // Add-to-cart button
  double get btnH => _xs ? 28 : (_lg ? 34 : 30);

  double get btnRadius => _xs ? 7 : (_lg ? 10 : 8);

  double get btnIconSz => _xs ? 13 : (_lg ? 16 : 14);

  // Veg dot
  double get vegOuter => _xs ? 14 : (_lg ? 17 : 15);

  double get vegInner => _xs ? 8 : (_lg ? 11 : 9.5);

  // Section
  double get restNameFs => _xs ? 13 : (_lg ? 15 : 14);

  double get metaFs => _xs ? 9 : (_lg ? 11 : 10);

  @override
  bool operator ==(Object o) => o is _RS && o.sw == sw && o.sh == sh;

  @override
  int get hashCode => Object.hash(sw, sh);
}

// ─────────────────────────────────────────────────────────────────────────────
// Shimmer mixin — drives a single shared animation across skeleton widgets.
// ─────────────────────────────────────────────────────────────────────────────
mixin _ShimmerMixin<T extends StatefulWidget>
    on State<T>, SingleTickerProviderStateMixin<T> {
  late AnimationController shimmerCtrl;
  late Animation<double> shimmerAnim;

  Color get shimmerBase => const Color(0xFFEDE8F8);

  Color get shimmerLight => const Color(0xFFD9D3F0);

  Color get shimmerColor =>
      Color.lerp(shimmerBase, shimmerLight, shimmerAnim.value)!;

  @override
  void initState() {
    super.initState();
    shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    shimmerAnim = CurvedAnimation(parent: shimmerCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    shimmerCtrl.dispose();
    super.dispose();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Delivery time ticker — alternates between time and "Fast delivery"
// ─────────────────────────────────────────────────────────────────────────────
class _DeliveryTicker extends StatefulWidget {
  const _DeliveryTicker({required this.deliveryTime});

  final String deliveryTime;

  @override
  State<_DeliveryTicker> createState() => _DeliveryTickerState();
}

class _DeliveryTickerState extends State<_DeliveryTicker> {
  bool _showFast = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted) setState(() => _showFast = !_showFast);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
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
      child: _showFast ? _fastRow() : _timeRow(),
    );
  }

  Widget _fastRow() => Row(
    key: const ValueKey('fast'),
    mainAxisSize: MainAxisSize.min,
    children: [
      const Icon(Icons.delivery_dining_rounded, size: 11, color: _C.brand),
      const SizedBox(width: 3),
      const Text(
        'Fast delivery',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: _C.brand,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    ],
  );

  Widget _timeRow() => Row(
    key: const ValueKey('time'),
    mainAxisSize: MainAxisSize.min,
    children: [
      const Icon(Icons.access_time_rounded, size: 10, color: _C.text3),
      const SizedBox(width: 3),
      Text(
        widget.deliveryTime,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: _C.text3,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Skeleton widgets
// ─────────────────────────────────────────────────────────────────────────────
class _SkeletonBox extends StatefulWidget {
  const _SkeletonBox({
    required this.width,
    required this.height,
    this.radius = 8,
  });

  final double width, height, radius;

  @override
  State<_SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<_SkeletonBox>
    with SingleTickerProviderStateMixin, _ShimmerMixin {
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: shimmerAnim,
    builder: (_, __) => Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: shimmerColor,
        borderRadius: BorderRadius.circular(widget.radius),
      ),
    ),
  );
}

class _SkeletonRestaurantCard extends StatefulWidget {
  const _SkeletonRestaurantCard({required this.rs});

  final _RS rs;

  @override
  State<_SkeletonRestaurantCard> createState() =>
      _SkeletonRestaurantCardState();
}

class _SkeletonRestaurantCardState extends State<_SkeletonRestaurantCard>
    with SingleTickerProviderStateMixin, _ShimmerMixin {
  @override
  Widget build(BuildContext context) {
    final rs = widget.rs;
    return AnimatedBuilder(
      animation: shimmerAnim,
      builder: (_, __) {
        final c = shimmerColor;
        return Container(
          margin: EdgeInsets.fromLTRB(rs.hPad, 0, rs.hPad, 14),
          decoration: BoxDecoration(
            color: _C.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _C.border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F2D1B4E),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 140,
                          height: 13,
                          decoration: BoxDecoration(
                            color: c,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: 100,
                          height: 10,
                          decoration: BoxDecoration(
                            color: c,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: rs.prodScrollH,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  itemCount: 3,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (_, __) => Container(
                    width: rs.cardWidth,
                    decoration: BoxDecoration(
                      color: c,
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Category filter chips data
// ─────────────────────────────────────────────────────────────────────────────
// class _Cat {
//   const _Cat(this.label, this.icon);
//
//   final String label;
//   final IconData icon;
// }
//
// const List<_Cat> _kCats = [
//   _Cat('All', Icons.local_fire_department_rounded),
//   _Cat('Biryani', Icons.rice_bowl_rounded),
//   _Cat('Burger', Icons.lunch_dining_rounded),
//   _Cat('Pizza', Icons.local_pizza_rounded),
//   _Cat('Drinks', Icons.local_drink_rounded),
//   _Cat('Desserts', Icons.cake_rounded),
// ];

// ─────────────────────────────────────────────────────────────────────────────
// Main DealsScreen
// ─────────────────────────────────────────────────────────────────────────────
class DealsScreen extends StatefulWidget {
  const DealsScreen({super.key});

  @override
  State<DealsScreen> createState() => _DealsScreenState();
}

class _DealsScreenState extends State<DealsScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  // ── loading / data state ──────────────────────────────────────────────────
  bool _isLoading = false;
  bool _isWaitingForZone = true;

  List<PromotionModel> _promotionsList = [];
  List<BannerModel> _dealsBanners = [];

  // ── caches ───────────────────────────────────────────────────────────────
  final Map<String, ProductModel> _productCache = {};
  final Map<String, VendorModel> _vendorCache = {};
  final Map<String, bool> _restaurantStatusCache = {};

  // ── zone tracking ────────────────────────────────────────────────────────
  String? _currentZoneId;
  HomeProvider? _homeProvider;

  // ── UI state ─────────────────────────────────────────────────────────────
  int _selectedCat = 0;
  _RS? _cachedRS;

  // ── constants ────────────────────────────────────────────────────────────
  static const Duration _networkTimeout = Duration(seconds: 10);
  static const Duration _cacheDuration = Duration(minutes: 3);
  static const int _maxRetries = 1;

  int _retryCount = 0;
  DateTime? _lastLoadTime;

  // ── timers ────────────────────────────────────────────────────────────────
  Timer? _zoneDebounce;
  Timer? _zonePollTimer;

  // ── animations ────────────────────────────────────────────────────────────
  late AnimationController _headerAnim;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;

  // ═══════════════════════════════════════════════════════════════════════════
  // Zone helpers
  // ═══════════════════════════════════════════════════════════════════════════

  String? _effectiveZoneId() {
    final a = Constant.selectedZone?.id?.trim();
    if (a != null && a.isNotEmpty) return a;
    final b = Constant.selectedLocation.zoneId?.trim();
    if (b != null && b.isNotEmpty) return b;
    return null;
  }

  void _startZonePoller() {
    _zonePollTimer?.cancel();
    _zonePollTimer = Timer.periodic(const Duration(milliseconds: 300), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      final zid = _effectiveZoneId();
      if (zid != null && zid.isNotEmpty) {
        t.cancel();
        _zonePollTimer = null;
        _currentZoneId = zid;
        _loadAllData();
      }
    });
    // Hard timeout — stop waiting after 8 s
    Future.delayed(const Duration(seconds: 8), () {
      if (!mounted || !_isWaitingForZone) return;
      _zonePollTimer?.cancel();
      _zonePollTimer = null;
      if (mounted)
        setState(() {
          _isWaitingForZone = false;
          _isLoading = false;
        });
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Lifecycle
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentZoneId = _effectiveZoneId();

    // Header slide-in animation
    _headerAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _headerFade = CurvedAnimation(
      parent: _headerAnim,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    );
    _headerSlide =
        Tween<Offset>(begin: const Offset(0, -0.35), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _headerAnim,
            curve: const Interval(0.1, 0.8, curve: Curves.easeOutCubic),
          ),
        );
    _headerAnim.forward();

    if (_currentZoneId != null && _currentZoneId!.isNotEmpty) {
      _loadWithCache();
    } else {
      _startZonePoller();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _homeProvider = Provider.of<HomeProvider>(context, listen: false);
      _homeProvider!.addListener(_onHomeProviderUpdate);
    });
  }

  @override
  void dispose() {
    _zonePollTimer?.cancel();
    _zoneDebounce?.cancel();
    _homeProvider?.removeListener(_onHomeProviderUpdate);
    WidgetsBinding.instance.removeObserver(this);
    _headerAnim.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _checkZoneChanged();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkZoneChanged();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Zone-change detection
  // ═══════════════════════════════════════════════════════════════════════════

  void _onHomeProviderUpdate() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _checkZoneChanged();
      if (!_isLoading && !_isWaitingForZone && _promotionsList.isEmpty) {
        final z = _effectiveZoneId();
        if (z != null && z.isNotEmpty) {
          _zonePollTimer?.cancel();
          _zonePollTimer = null;
          _loadAllData();
        }
      }
    });
  }

  void _checkZoneChanged() {
    final newId = _effectiveZoneId();
    if (newId == null || newId.isEmpty || newId == _currentZoneId) return;

    _zoneDebounce?.cancel();
    _zoneDebounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      final confirmed = _effectiveZoneId();
      if (confirmed == null || confirmed != newId) return;

      final prev = _currentZoneId;
      _currentZoneId = newId;
      _lastLoadTime = null;

      if (prev != null && prev.isNotEmpty) {
        CacheManager().remove('deals_banners_$prev');
        CacheManager().remove('promotions_$prev');
      }

      _productCache.clear();
      _vendorCache.clear();
      _restaurantStatusCache.clear();
      _loadAllData();
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Data loading
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _loadWithCache() async {
    final now = DateTime.now();
    if (_lastLoadTime != null &&
        now.difference(_lastLoadTime!) < _cacheDuration &&
        _promotionsList.isNotEmpty) {
      if (mounted)
        setState(() {
          _isLoading = false;
          _isWaitingForZone = false;
        });
      return;
    }
    await _loadAllData();
  }

  Future<void> _pullToRefresh() async {
    try {
      final z = _currentZoneId ?? _effectiveZoneId();
      if (z != null) {
        CacheManager().remove('deals_banners_$z');
        CacheManager().remove('promotions_$z');
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
      await Future.wait([_loadBanners(), _loadPromotions()]);
      _lastLoadTime = DateTime.now();
      _retryCount = 0;
    } catch (_) {
      if (_retryCount < _maxRetries) {
        _retryCount++;
        await Future.delayed(Duration(seconds: _retryCount));
        if (mounted) await _loadAllData();
      }
    } finally {
      if (mounted)
        setState(() {
          _isLoading = false;
          _isWaitingForZone = false;
        });
    }
  }

  Future<void> _loadBanners() async {
    final z = _currentZoneId ?? _effectiveZoneId();
    if (z == null || z.isEmpty) return;

    try {
      final key = 'deals_banners_$z';
      final banners = await CacheManager().getOrSetBanners<List<BannerModel>>(
        key,
        () => ApiQueueManager().enqueue<List<BannerModel>>(
          priority: RequestPriority.normal,
          key: key,
          request: () => _fetchBannersFromApi(z),
        ),
      );
      if (mounted) setState(() => _dealsBanners = banners);
    } catch (_) {
      if (mounted) setState(() => _dealsBanners = []);
    }
  }

  Future<List<BannerModel>> _fetchBannersFromApi(String zoneId) async {
    try {
      final url = '${AppConst.baseUrl}menu-items/banners/deals?zone_id=$zoneId';
      final res = await http
          .get(
            Uri.parse(url),
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(_networkTimeout);

      if (res.statusCode == 200) {
        final j = json.decode(res.body) as Map<String, dynamic>;
        if (j['success'] == true) {
          return (j['data'] as List)
              .take(15)
              .map((e) => BannerModel.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
    } on TimeoutException {
      // fall through
    } catch (_) {
      // fall through
    }
    return [];
  }

  Future<void> _loadPromotions() async {
    final z = _currentZoneId ?? _effectiveZoneId();
    if (z == null || z.isEmpty) return;
    _currentZoneId = z;

    try {
      final key = 'promotions_$z';
      final data = await CacheManager().getOrSet<List<Map<String, dynamic>>>(
        key,
        () => ApiQueueManager().enqueue<List<Map<String, dynamic>>>(
          priority: RequestPriority.normal,
          key: key,
          request: () => FireStoreUtils.getAllActivePromotions(zoneId: z),
        ),
        type: CacheType.general,
      );

      if (data.isEmpty) {
        if (mounted) setState(() => _promotionsList = []);
        return;
      }

      final promos = data
          .take(100)
          .map((p) => PromotionModel.fromJson(p))
          .where((p) => p.isAvailable)
          .toList();

      // Pre-warm vendor cache for all vendors at once
      final vendorIds = promos
          .map((p) => p.restaurantId)
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();
      await _preCacheVendors(vendorIds);

      final sorted = await _sortByOpenStatus(promos);
      if (mounted) setState(() => _promotionsList = sorted);
    } catch (_) {
      if (mounted) setState(() => _promotionsList = []);
    }
  }

  Future<void> _preCacheVendors(List<String> ids) async {
    await Future.wait(
      ids.where((id) => !_vendorCache.containsKey(id)).map((id) async {
        try {
          final v = await FireStoreUtils.getVendorById(id);
          if (v != null) {
            _vendorCache[id] = v;
            _restaurantStatusCache[id] = RestaurantStatusUtils.canAcceptOrders(
              v,
            );
          }
        } catch (_) {}
      }),
    );
  }

  Future<List<PromotionModel>> _sortByOpenStatus(
    List<PromotionModel> promos,
  ) async {
    if (promos.isEmpty) return promos;
    try {
      return promos..sort((a, b) {
        bool openA =
            _restaurantStatusCache[a.restaurantId] ??
            (_vendorCache.containsKey(a.restaurantId)
                ? RestaurantStatusUtils.canAcceptOrders(
                    _vendorCache[a.restaurantId]!,
                  )
                : true);
        bool openB =
            _restaurantStatusCache[b.restaurantId] ??
            (_vendorCache.containsKey(b.restaurantId)
                ? RestaurantStatusUtils.canAcceptOrders(
                    _vendorCache[b.restaurantId]!,
                  )
                : true);
        if (openA == openB) return 0;
        return openA ? -1 : 1;
      });
    } catch (_) {
      return promos;
    }
  }

  // Group promotions by vendor for section rendering
  Map<String, List<PromotionModel>> _groupByVendor() {
    final map = <String, List<PromotionModel>>{};
    for (final p in _promotionsList) {
      map.putIfAbsent(p.restaurantId, () => []).add(p);
    }
    return map;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Build
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final rs = _RS(sw: size.width, sh: size.height);
    _cachedRS = rs;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemStatusBarContrastEnforced: false,
      ),
      child: Scaffold(
        backgroundColor: _C.bg,
        body: Column(
          children: [
            // ── App Bar ──────────────────────────────────────────────────
            SlideTransition(
              position: _headerSlide,
              child: FadeTransition(
                opacity: _headerFade,
                child: _AppBar(rs: rs),
              ),
            ),

            // ── Category Filter Row ──────────────────────────────────────
            // _CategoryRow(
            //   selected: _selectedCat,
            //   onSelect: (i) => setState(() => _selectedCat = i),
            // ),

            // ── Body ─────────────────────────────────────────────────────
            Expanded(
              child: _isWaitingForZone || _isLoading
                  ? _SkeletonBody(rs: rs)
                  : _promotionsList.isEmpty
                  ? const _EmptyState()
                  : RefreshIndicator(
                      onRefresh: _pullToRefresh,
                      color: _C.brand,
                      child: _ContentList(
                        rs: rs,
                        dealsBanners: _dealsBanners,
                        grouped: _groupByVendor(),
                        productCache: _productCache,
                        vendorCache: _vendorCache,
                        restaurantStatusCache: _restaurantStatusCache,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// App Bar
// ─────────────────────────────────────────────────────────────────────────────
class _AppBar extends StatelessWidget {
  const _AppBar({required this.rs});

  final _RS rs;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      color: _C.surface,
      padding: EdgeInsets.fromLTRB(rs.hPad, top + 10, rs.hPad, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Text(
                      'Jippy Deals',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: _C.text1,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text('🔥', style: TextStyle(fontSize: 20)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  Constant.selectedZone?.name?.isNotEmpty == true
                      ? '${Constant.selectedZone!.name} · Best deals, bigger savings!'
                      : 'Best deals, bigger savings!',
                  style: const TextStyle(fontSize: 11, color: _C.text3),
                ),
              ],
            ),
          ),
          // const SizedBox(width: 12),
          // _WalletButton(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Wallet button
// ─────────────────────────────────────────────────────────────────────────────
// class _WalletButton extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Consumer<WalletProvider>(
//       builder: (context, wp, _) {
//         if (Constant.userModel == null) return const SizedBox.shrink();
//
//         final rupees = wp.moneyBalanceRupees;
//         final loading = wp.loadingWallet;
//         final display = loading
//             ? '...'
//             : rupees == rupees.truncateToDouble()
//             ? '₹${rupees.toInt()}'
//             : '₹${rupees.toStringAsFixed(1)}';
//
//         return GestureDetector(
//           onTap: () => Get.to(() => const WalletHomeScreen()),
//           child: Container(
//             padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
//             decoration: BoxDecoration(
//               color: _C.walletBg,
//               border: Border.all(color: _C.walletBorder),
//               borderRadius: BorderRadius.circular(14),
//             ),
//             child: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Container(
//                   width: 28,
//                   height: 28,
//                   decoration: BoxDecoration(
//                     color: AppThemeData.danger300,
//                     shape: BoxShape.circle,
//                   ),
//                   child: const Icon(
//                     Icons.account_balance_wallet_rounded,
//                     color: Colors.white,
//                     size: 14,
//                   ),
//                 ),
//                 const SizedBox(width: 7),
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Text(
//                       display,
//                       style: const TextStyle(
//                         fontSize: 12.5,
//                         fontWeight: FontWeight.w700,
//                       ),
//                     ),
//                     const Text('Jippy Coins', style: TextStyle(fontSize: 10)),
//                   ],
//                 ),
//                 const SizedBox(width: 4),
//                 const Icon(
//                   Icons.chevron_right_rounded,
//                   size: 16,
//                   color: _C.text3,
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
// }

// ─────────────────────────────────────────────────────────────────────────────
// Category filter row
// ─────────────────────────────────────────────────────────────────────────────
// class _CategoryRow extends StatelessWidget {
//   const _CategoryRow({required this.selected, required this.onSelect});
//
//   final int selected;
//   final ValueChanged<int> onSelect;
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       color: _C.surface,
//       padding: const EdgeInsets.fromLTRB(0, 6, 0, 10),
//       child: SizedBox(
//         height: 36,
//         child: ListView.separated(
//           scrollDirection: Axis.horizontal,
//           padding: const EdgeInsets.symmetric(horizontal: 16),
//           itemCount: _kCats.length,
//           separatorBuilder: (_, __) => const SizedBox(width: 8),
//           itemBuilder: (_, i) {
//             final active = selected == i;
//             return GestureDetector(
//               onTap: () => onSelect(i),
//               child: AnimatedContainer(
//                 duration: const Duration(milliseconds: 200),
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 14,
//                   vertical: 7,
//                 ),
//                 decoration: BoxDecoration(
//                   color: active ? _C.brand : _C.surface,
//                   border: Border.all(
//                     color: active ? _C.brand : _C.border,
//                     width: 1.5,
//                   ),
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//                 child: Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Icon(
//                       _kCats[i].icon,
//                       size: 13,
//                       color: active ? Colors.white : _C.text2,
//                     ),
//                     const SizedBox(width: 5),
//                     Text(
//                       _kCats[i].label,
//                       style: TextStyle(
//                         fontSize: 12,
//                         fontWeight: FontWeight.w600,
//                         color: active ? Colors.white : _C.text2,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   }
// }

// ─────────────────────────────────────────────────────────────────────────────
// Skeleton body
// ─────────────────────────────────────────────────────────────────────────────
class _SkeletonBody extends StatelessWidget {
  const _SkeletonBody({required this.rs});

  final _RS rs;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const NeverScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(rs.hPad, 14, rs.hPad, 0),
            child: Container(
              height: 170,
              decoration: BoxDecoration(
                color: const Color(0xFFEDE8F8),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(rs.hPad, 20, rs.hPad, 10),
            child: _SkeletonBox(width: 180, height: 16),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (_, __) => _SkeletonRestaurantCard(rs: rs),
            childCount: 2,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Content list
// ─────────────────────────────────────────────────────────────────────────────
class _ContentList extends StatelessWidget {
  const _ContentList({
    required this.rs,
    required this.dealsBanners,
    required this.grouped,
    required this.productCache,
    required this.vendorCache,
    required this.restaurantStatusCache,
  });

  final _RS rs;
  final List<BannerModel> dealsBanners;
  final Map<String, List<PromotionModel>> grouped;
  final Map<String, ProductModel> productCache;
  final Map<String, VendorModel> vendorCache;
  final Map<String, bool> restaurantStatusCache;

  String _restaurantName(String vendorId, List<PromotionModel> promos) {
    final title = vendorCache[vendorId]?.title?.trim();
    if (title != null && title.isNotEmpty) return title;
    final promoTitle = promos.first.restaurantTitle.trim();
    if (promoTitle.isNotEmpty) return promoTitle;
    return vendorId;
  }

  @override
  Widget build(BuildContext context) {
    final vendorIds = grouped.keys.toList()
      ..sort(
        (a, b) => _restaurantName(a, grouped[a]!).toLowerCase().compareTo(
          _restaurantName(b, grouped[b]!).toLowerCase(),
        ),
      );

    return CustomScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        // ── Banner carousel ──────────────────────────────────────────────
        if (dealsBanners.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(rs.hPad, 14, rs.hPad, 0),
              child: DealsBannerView(banners: dealsBanners),
            ),
          ),

        // ── Section heading ───────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(rs.hPad, 20, rs.hPad, 10),
            child: Row(
              children: [
                const Text(
                  'Restaurants with deals',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _C.text1,
                    letterSpacing: -0.2,
                  ),
                ),
                const Spacer(),
                // "See all" — wire up navigation as needed
                GestureDetector(
                  onTap: () {},
                  child: const Text(
                    'See all',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _C.brand,
                    ),
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: _C.brand,
                ),
              ],
            ),
          ),
        ),

        // ── Restaurant sections ───────────────────────────────────────────
        SliverList(
          delegate: SliverChildBuilderDelegate((ctx, i) {
            final vid = vendorIds[i];
            final promos = grouped[vid]!;
            final vendor = vendorCache[vid];
            final isOpen = restaurantStatusCache[vid] ?? true;
            return RepaintBoundary(
              child: _RestaurantSection(
                key: ValueKey(vid),
                vendorId: vid,
                vendor: vendor,
                promotions: promos,
                isOpen: isOpen,
                productCache: productCache,
                vendorCache: vendorCache,
                restaurantStatusCache: restaurantStatusCache,
                rs: rs,
              ),
            );
          }, childCount: vendorIds.length),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _C.brandLight,
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
              color: _C.text1,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Check back soon for exciting offers!',
            style: TextStyle(fontSize: 13, color: _C.text3),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Restaurant section (header + horizontal product scroll)
// ─────────────────────────────────────────────────────────────────────────────
class _RestaurantSection extends StatelessWidget {
  const _RestaurantSection({
    super.key,
    required this.vendorId,
    required this.vendor,
    required this.promotions,
    required this.isOpen,
    required this.productCache,
    required this.vendorCache,
    required this.restaurantStatusCache,
    required this.rs,
  });

  final String vendorId;
  final VendorModel? vendor;
  final List<PromotionModel> promotions;
  final bool isOpen;
  final Map<String, ProductModel> productCache;
  final Map<String, VendorModel> vendorCache;
  final Map<String, bool> restaurantStatusCache;
  final _RS rs;

  String get _name =>
      vendor?.title ??
      (promotions.isNotEmpty ? promotions.first.restaurantTitle : 'Restaurant');

  String get _deliveryTime =>
      vendor != null ? Constant.getDeliveryTimeText(vendor!) : '30–35 mins';

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(rs.hPad, 0, rs.hPad, 10),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _C.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x122D1B4E),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          GestureDetector(
            onTap: () {
              if (vendor == null) return;
              final p = Provider.of<RestaurantDetailsProvider>(
                context,
                listen: false,
              );
              p.initFunction(vendorModels: vendor!);
              Get.to(() => const RestaurantDetailsScreen());
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
              child: Row(
                children: [
                  _VendorLogo(vendor: vendor),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _name,
                          style: TextStyle(
                            fontSize: rs.restNameFs,
                            fontWeight: FontWeight.w800,
                            color: _C.text1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          runSpacing: 3,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            // Rating chip
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _C.green,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.star_rounded,
                                    size: 10,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 2),
                                  Text(
                                    '4.5',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _DeliveryTicker(deliveryTime: _deliveryTime),
                            // Row(
                            //   mainAxisSize: MainAxisSize.min,
                            //   children: const [
                            //     Icon(
                            //       Icons.delivery_dining_rounded,
                            //       size: 11,
                            //       color: _C.green,
                            //     ),
                            //     SizedBox(width: 3),
                            //     // Text(
                            //     //   'Free Delivery',
                            //     //   style: TextStyle(
                            //     //     fontSize: 10,
                            //     //     color: _C.green,
                            //     //     fontWeight: FontWeight.w600,
                            //     //   ),
                            //     // ),
                            //   ],
                            // ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _C.brandLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${promotions.length} deals ›',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _C.brand,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Horizontal product scroll
          SizedBox(
            height: rs.prodScrollH,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              itemCount: promotions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (ctx, i) => RepaintBoundary(
                child: _PromotionCard(
                  key: ValueKey(promotions[i].productId),
                  promotion: promotions[i],
                  productCache: productCache,
                  vendorCache: vendorCache,
                  restaurantStatusCache: restaurantStatusCache,
                  rs: rs,
                  animIndex: i,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Vendor logo circle
class _VendorLogo extends StatelessWidget {
  const _VendorLogo({required this.vendor});

  final VendorModel? vendor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: _C.brandLight,
        shape: BoxShape.circle,
        border: Border.all(color: _C.border, width: 1.5),
      ),
      child: ClipOval(
        child: vendor?.photo != null && vendor!.photo!.isNotEmpty
            ? Image.network(
                vendor!.photo!,
                width: 44,
                height: 44,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const _FoodPlaceholder(),
              )
            : const _FoodPlaceholder(),
      ),
    );
  }
}

class _FoodPlaceholder extends StatelessWidget {
  const _FoodPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _C.brandLight,
      alignment: Alignment.center,
      child: const Icon(Icons.fastfood_rounded, size: 20, color: _C.brand),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Promotion card (item in horizontal scroll)
// ─────────────────────────────────────────────────────────────────────────────
class _PromotionCard extends StatefulWidget {
  const _PromotionCard({
    super.key,
    required this.promotion,
    required this.productCache,
    required this.vendorCache,
    required this.restaurantStatusCache,
    required this.rs,
    required this.animIndex,
  });

  final PromotionModel promotion;
  final Map<String, ProductModel> productCache;
  final Map<String, VendorModel> vendorCache;
  final Map<String, bool> restaurantStatusCache;
  final _RS rs;
  final int animIndex;

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

  late AnimationController _entryCtrl;
  late Animation<double> _entryFade;
  late Animation<Offset> _entrySlide;

  _RS get rs => widget.rs;

  @override
  void initState() {
    super.initState();

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _entryFade = CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0, 0.7, curve: Curves.easeOut),
    );
    _entrySlide = Tween<Offset>(begin: const Offset(0.15, 0), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _entryCtrl,
            curve: const Interval(0.1, 0.9, curve: Curves.easeOutCubic),
          ),
        );

    final delay = (widget.animIndex * 50).clamp(0, 300);
    Future.delayed(Duration(milliseconds: delay), () {
      if (mounted) _entryCtrl.forward();
    });

    _loadFromCache();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  // ── Data helpers ──────────────────────────────────────────────────────────

  void _loadFromCache() {
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
      _imgUrl = _safeImgUrl(_product!.photo);
      _loadingProduct = false;
    } else if (widget.promotion.productId.isNotEmpty) {
      _fetchProduct();
    } else {
      _loadingProduct = false;
    }

    if (_vendor == null && widget.promotion.restaurantId.isNotEmpty) {
      _fetchVendor();
    }
  }

  String? _safeImgUrl(String? raw) {
    if (raw == null) return null;
    final t = raw.trim();
    if (t.isEmpty || t.toLowerCase() == 'null') return null;
    if (!t.startsWith('http://') && !t.startsWith('https://')) return null;
    try {
      final u = Uri.parse(t);
      return u.hasScheme && u.hasAuthority ? t : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _fetchProduct() async {
    final id = widget.promotion.productId;
    if (id.isEmpty) {
      if (mounted) setState(() => _loadingProduct = false);
      return;
    }
    try {
      final p = await FireStoreUtils.getProductById(id);
      if (mounted) {
        if (p != null) widget.productCache[id] = p;
        setState(() {
          _product = p;
          _imgUrl = p != null ? _safeImgUrl(p.photo) : null;
          _loadingProduct = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingProduct = false);
    }
  }

  Future<void> _fetchVendor() async {
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

  // ── Cart helpers ──────────────────────────────────────────────────────────

  int _cartQty() {
    final pid = widget.promotion.productId;
    final rid = widget.promotion.restaurantId;
    if (pid.isEmpty || rid.isEmpty) return 0;
    return context.read<CartProvider>().quantityFor(
      vendorId: rid,
      productId: pid,
    );
  }

  Future<void> _handleTap({required bool increment}) async {
    if (!_isOpen) {
      ShowToastDialog.showToast('Restaurant is currently closed'.tr);
      return;
    }
    if (!await SqlStorageConst.isUserLoggedIn()) {
      _showLoginDialog();
      return;
    }
    if (_product == null) {
      ShowToastDialog.showToast('Product not available'.tr);
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
          'Maximum $limit items allowed for this deal'.tr,
        );
        return;
      }
      final stock = _product!.quantity ?? 0;
      if (stock != -1 && qty >= stock) {
        ShowToastDialog.showToast('Out of stock'.tr);
        return;
      }
    }

    // Ensure vendor is loaded
    VendorModel? vendor = _vendor;
    if (vendor == null) {
      try {
        vendor = await FireStoreUtils.getVendorById(rid);
        if (vendor == null) {
          ShowToastDialog.showToast('Restaurant not found'.tr);
          return;
        }
        widget.vendorCache[rid] = vendor;
      } catch (_) {
        ShowToastDialog.showToast('Error loading restaurant'.tr);
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
        if (!ok) ShowToastDialog.showToast('Failed to add to cart'.tr);
      } else {
        final existing = HomeProvider.cartItem
            .cast<CartProductModel?>()
            .firstWhere(
              (item) =>
                  item?.id == pid || (item?.id?.startsWith('$pid~') ?? false),
              orElse: () => null,
            );
        if (existing?.id != null) {
          if (newQty > 0) {
            await cp.addToCart(
              context,
              CartProductModel(
                id: existing!.id!,
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
            await cp.updateCartItemQuantity(existing!.id!, 0);
          }
        }
      }
    } catch (_) {
      ShowToastDialog.showToast(
        increment ? 'Failed to add to cart'.tr : 'Failed to update cart'.tr,
      );
    }
  }

  void _showLoginDialog() {
    showDialog(
      context: context,
      builder: (_) => CustomDialogBox(
        title: 'Login Required'.tr,
        descriptions:
            'Please login to add items to your cart and continue shopping.'.tr,
        positiveString: 'Login'.tr,
        negativeString: 'Cancel'.tr,
        positiveClick: () {
          Get.back();
          Get.to(() => PhoneNumberScreen());
        },
        negativeClick: Get.back,
        img: Image.asset(
          'assets/images/ic_launcher.png',
          height: 50,
          width: 50,
        ),
      ),
    );
  }

  // ── Price formatters ──────────────────────────────────────────────────────

  String _fmt(dynamic price) {
    try {
      final v = price is num
          ? price.toDouble()
          : double.tryParse('$price') ?? 0.0;
      final sym = Constant.currencyModel?.symbol ?? '₹';
      final rhs = Constant.currencyModel?.symbolAtRight ?? false;
      return rhs ? '${v.round()} $sym' : '$sym ${v.round()}';
    } catch (_) {
      return Constant.amountShow(amount: price.toString());
    }
  }

  String _discPct(dynamic orig, dynamic spec) {
    try {
      final o = orig is num ? orig.toDouble() : double.tryParse('$orig') ?? 0.0;
      final s = spec is num ? spec.toDouble() : double.tryParse('$spec') ?? 0.0;
      if (o <= 0 || o <= s) return '';
      final pct = ((o - s) / o * 100).round();
      return pct > 0 ? '$pct% OFF' : '';
    } catch (_) {
      return '';
    }
  }

  dynamic _calcSave(dynamic spec, dynamic orig) {
    try {
      final o = orig is num ? orig.toDouble() : double.tryParse('$orig') ?? 0.0;
      final s = spec is num ? spec.toDouble() : double.tryParse('$spec') ?? 0.0;
      return (o - s).round();
    } catch (_) {
      return 0;
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Scoped rebuild — only this card re-renders on cart change
    final qty = context.select<CartProvider, int>(
      (cp) => cp.quantityFor(
        vendorId: widget.promotion.restaurantId,
        productId: widget.promotion.productId,
      ),
    );

    final inCart = qty > 0;
    final closed = !_isOpen;
    final spec = widget.promotion.specialPrice;
    final limit = widget.promotion.itemLimit;
    final origRaw = _product?.price;
    final discPct = (origRaw != null && origRaw.isNotEmpty)
        ? _discPct(origRaw, spec)
        : '';

    return FadeTransition(
      opacity: _entryFade,
      child: SlideTransition(
        position: _entrySlide,
        child: Opacity(
          opacity: closed ? 0.55 : 1.0,
          child: SizedBox(
            width: rs.cardWidth,
            child: Container(
              decoration: BoxDecoration(
                color: _C.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _C.border),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Product image ────────────────────────────
                        _ProductImage(
                          rs: rs,
                          imgUrl: _imgUrl,
                          loading: _loadingProduct,
                          isVeg: _product?.veg,
                          discPct: discPct,
                          limit: limit,
                          closed: closed,
                        ),

                        // ── Info ─────────────────────────────────────
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(8, 7, 8, 7),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  widget.promotion.productTitle,
                                  style: TextStyle(
                                    fontSize: rs.nameFs,
                                    fontWeight: FontWeight.w700,
                                    color: _C.text1,
                                    height: 1.15,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),

                                // Prices
                                Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      _fmt(spec),
                                      style: TextStyle(
                                        fontSize: rs.specPriceFs,
                                        fontWeight: FontWeight.w800,
                                        color: _C.text1,
                                      ),
                                    ),
                                    if (origRaw != null &&
                                        origRaw.isNotEmpty) ...[
                                      const SizedBox(width: 3),
                                      Text(
                                        _fmt(origRaw),
                                        style: TextStyle(
                                          fontSize: rs.origPriceFs,
                                          color: _C.text3,
                                          decoration:
                                              TextDecoration.lineThrough,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),

                                // Save label
                                if (origRaw != null &&
                                    origRaw.isNotEmpty &&
                                    discPct.isNotEmpty)
                                  Text(
                                    'You save ${_fmt(_calcSave(spec, origRaw))}',
                                    style: TextStyle(
                                      fontSize: rs.saveLblFs,
                                      color: _C.brand,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),

                                // Add / stepper / locked button
                                _AddButton(
                                  rs: rs,
                                  inCart: inCart,
                                  qty: qty,
                                  closed: closed,
                                  onAdd: () => _handleTap(increment: true),
                                  onIncrease: () => _handleTap(increment: true),
                                  onDecrease: () =>
                                      _handleTap(increment: false),
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
                          color: _C.overlay,
                          alignment: Alignment.center,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: _C.closedPill,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Closed',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: rs.closedFs,
                                fontWeight: FontWeight.w700,
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
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Product image sub-widget
// ─────────────────────────────────────────────────────────────────────────────
class _ProductImage extends StatelessWidget {
  const _ProductImage({
    required this.rs,
    required this.imgUrl,
    required this.loading,
    required this.isVeg,
    required this.discPct,
    required this.limit,
    required this.closed,
  });

  final _RS rs;
  final String? imgUrl;
  final bool loading;
  final bool? isVeg;
  final String discPct;
  final int limit;
  final bool closed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: rs.cardWidth,
      height: rs.cardImgH,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Image or placeholder
          Container(
            color: const Color(0xFFF5F0FA),
            child: loading
                ? const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _C.brand,
                      ),
                    ),
                  )
                : imgUrl != null
                ? NetworkImageWidget(
                    imageUrl: imgUrl!,
                    width: rs.cardWidth,
                    height: rs.cardImgH,
                    fit: BoxFit.cover,
                  )
                : Center(
                    child: Icon(
                      Icons.local_offer_rounded,
                      size: 26,
                      color: _C.brand.withOpacity(0.4),
                    ),
                  ),
          ),

          // Bottom gradient
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 28,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withOpacity(0.18), Colors.transparent],
                ),
              ),
            ),
          ),

          // Veg / non-veg dot
          if (isVeg != null)
            Positioned(
              top: 6,
              left: 6,
              child: Container(
                width: rs.vegOuter,
                height: rs.vegOuter,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: const [
                    BoxShadow(color: Color(0x1F000000), blurRadius: 4),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: rs.vegInner,
                    height: rs.vegInner,
                    decoration: BoxDecoration(
                      color: isVeg! ? _C.green : _C.red,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),

          // Discount badge
          if (discPct.isNotEmpty)
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                decoration: BoxDecoration(
                  color: _C.brand,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  discPct,
                  style: TextStyle(
                    fontSize: rs.badgeFs,
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),

          // Limit badge
          if (limit > 0)
            Positioned(
              bottom: 5,
              left: 5,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  'Limit $limit',
                  style: TextStyle(
                    fontSize: rs.badgeFs,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Add / stepper button — pure presentational widget
// ─────────────────────────────────────────────────────────────────────────────
class _AddButton extends StatelessWidget {
  const _AddButton({
    required this.rs,
    required this.inCart,
    required this.qty,
    required this.closed,
    required this.onAdd,
    required this.onIncrease,
    required this.onDecrease,
  });

  final _RS rs;
  final bool inCart, closed;
  final int qty;
  final VoidCallback onAdd, onIncrease, onDecrease;

  @override
  Widget build(BuildContext context) {
    if (closed) {
      return Container(
        width: double.infinity,
        height: rs.btnH,
        decoration: BoxDecoration(
          color: const Color(0xFFEDE8F8),
          borderRadius: BorderRadius.circular(rs.btnRadius),
        ),
        alignment: Alignment.center,
        child: Icon(
          Icons.lock_outline_rounded,
          size: rs.btnIconSz,
          color: _C.text3,
        ),
      );
    }

    if (!inCart) {
      return GestureDetector(
        onTap: onAdd,
        child: Container(
          width: double.infinity,
          height: rs.btnH,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: _C.brand, width: 1.5),
            borderRadius: BorderRadius.circular(rs.btnRadius),
          ),
          alignment: Alignment.center,
          child: Text(
            '+ ADD',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: _C.brand,
            ),
          ),
        ),
      );
    }

    // Stepper
    return Container(
      height: rs.btnH,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFD12477), Color(0xFFFF5E8F)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(rs.btnRadius),
        boxShadow: [
          BoxShadow(
            color: _C.brand.withOpacity(0.28),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: onDecrease,
              child: SizedBox(
                height: rs.btnH,
                child: Icon(
                  Icons.remove_rounded,
                  size: rs.btnIconSz,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Text(
            '$qty',
            style: TextStyle(
              fontSize: rs.qtyFs,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: onIncrease,
              child: SizedBox(
                height: rs.btnH,
                child: Icon(
                  Icons.add_rounded,
                  size: rs.btnIconSz,
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
