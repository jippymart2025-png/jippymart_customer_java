import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import 'package:jippymart_customer/app/auth_screen/phone_number_screen.dart';
import 'package:jippymart_customer/app/home_screen/screen/home_screen/provider/home_provider.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/constant/show_toast_dialog.dart';
import 'package:jippymart_customer/models/cart_product_model.dart';
import 'package:jippymart_customer/models/product_model.dart';
import 'package:jippymart_customer/models/promotion_model.dart';
import 'package:jippymart_customer/models/vendor_model.dart';
import 'package:jippymart_customer/services/cart_provider.dart';
import 'package:jippymart_customer/themes/custom_dialog_box.dart';
import 'package:jippymart_customer/utils/fire_store_utils.dart';
import 'package:jippymart_customer/utils/network_image_widget.dart';
import 'package:jippymart_customer/utils/restaurant_status_utils.dart';
import 'package:jippymart_customer/utils/utils/sql_storage_const.dart';

import '../../../core/responsive.dart';
import 'appbar.dart';

/// A single promotion card shown inside a restaurant's horizontal
/// deals scroll. Owns its own lazy product/vendor loading, cart
/// state, and add/increment/decrement actions.
class PromotionCard extends StatefulWidget {
  const PromotionCard({
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
  final Responsive rs;
  final int animIndex;

  @override
  State<PromotionCard> createState() => _PromotionCardState();
}

class _PromotionCardState extends State<PromotionCard>
    with SingleTickerProviderStateMixin {
  ProductModel? _product;
  VendorModel? _vendor;
  bool _isOpen = true;
  bool _loadingProduct = true;
  String? _imgUrl;

  late final AnimationController _entryCtrl;
  late final Animation<double> _entryFade;
  late final Animation<Offset> _entrySlide;

  Responsive get rs => widget.rs;

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

  // ── Data helpers ────────────────────────────────────────────────────

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
    } catch (_) {
      // Silently keep showing the promotion with unknown open-status;
      // _isOpen defaults to true so the card stays usable.
    }
  }

  // ── Cart helpers ────────────────────────────────────────────────────

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

  // ── Price formatters ────────────────────────────────────────────────

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

  // ── Build ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Scoped rebuild — only this card re-renders on cart change.
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
                color: C.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: C.border),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ProductImage(
                          rs: rs,
                          imgUrl: _imgUrl,
                          loading: _loadingProduct,
                          isVeg: _product?.veg,
                          discPct: discPct,
                          limit: limit,
                          closed: closed,
                        ),
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
                                    color: C.text1,
                                    height: 1.15,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
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
                                        color: C.text1,
                                      ),
                                    ),
                                    if (origRaw != null &&
                                        origRaw.isNotEmpty) ...[
                                      const SizedBox(width: 3),
                                      Text(
                                        _fmt(origRaw),
                                        style: TextStyle(
                                          fontSize: rs.origPriceFs,
                                          color: C.text3,
                                          decoration:
                                              TextDecoration.lineThrough,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                if (origRaw != null &&
                                    origRaw.isNotEmpty &&
                                    discPct.isNotEmpty)
                                  Text(
                                    'You save ${_fmt(_calcSave(spec, origRaw))}',
                                    style: TextStyle(
                                      fontSize: rs.saveLblFs,
                                      color: C.brand,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
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
                    if (closed)
                      Positioned.fill(
                        child: Container(
                          color: C.overlay,
                          alignment: Alignment.center,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: C.closedPill,
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

// ─────────────────────────────────────────────────────────────────────
// Product image sub-widget
// ─────────────────────────────────────────────────────────────────────
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

  final Responsive rs;
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
          Container(
            color: const Color(0xFFF5F0FA),
            child: loading
                ? const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: C.brand,
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
                      color: C.brand.withOpacity(0.4),
                    ),
                  ),
          ),
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
                      color: isVeg! ? C.green : C.red,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),
          if (discPct.isNotEmpty)
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                decoration: BoxDecoration(
                  color: C.brand,
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

// ─────────────────────────────────────────────────────────────────────
// Add / stepper button — pure presentational widget
// ─────────────────────────────────────────────────────────────────────
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

  final Responsive rs;
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
          color: C.text3,
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
            border: Border.all(color: C.brand, width: 1.5),
            borderRadius: BorderRadius.circular(rs.btnRadius),
          ),
          alignment: Alignment.center,
          child: Text(
            '+ ADD',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: C.brand,
            ),
          ),
        ),
      );
    }

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
            color: C.brand.withOpacity(0.28),
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
