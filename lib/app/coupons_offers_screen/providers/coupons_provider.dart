import 'package:flutter/foundation.dart';
import '../models/coupon_offer_model.dart';

enum OfferCategory { all, bestSavings, freeDelivery, bankOffers }

extension OfferCategoryLabel on OfferCategory {
  String get label {
    switch (this) {
      case OfferCategory.all:
        return 'All Offers';
      case OfferCategory.bestSavings:
        return 'Best Savings';
      case OfferCategory.freeDelivery:
        return 'Free Delivery';
      case OfferCategory.bankOffers:
        return 'Bank Offers';
    }
  }
}

/// Holds all coupon-screen state and filtering logic.
/// Keeping this out of the widget tree makes the screen a pure
/// "render this state" layer, and makes the logic unit-testable
/// without pumping widgets.
class CouponsController extends ChangeNotifier {
  CouponsController({List<CouponModel>? coupons})
    : _coupons = coupons ?? _defaultCoupons;

  static const List<CouponModel> _defaultCoupons = [
    CouponModel(
      amount: '₹100',
      amountLabel: 'OFF',
      title: 'Flat ₹100 OFF',
      subtitle: 'On orders above ₹299',
      code: 'SVGrand100',
      badge: 'Best Seller',
      saveText: '₹100',
      type: CouponType.green,
    ),
    CouponModel(
      amount: '₹50',
      amountLabel: 'OFF',
      title: 'Flat ₹50 OFF',
      subtitle: 'On orders above ₹199',
      code: 'SVGrand50',
      badge: 'Popular',
      saveText: '₹50',
      type: CouponType.orange,
    ),
    CouponModel(
      amount: 'FREE',
      amountLabel: 'DELIVERY',
      title: 'Free Delivery',
      subtitle: 'On orders above ₹149',
      code: 'JIPPYFREE',
      badge: 'Free Delivery',
      saveText: '₹15',
      type: CouponType.purple,
    ),
    CouponModel(
      amount: '₹25',
      amountLabel: 'OFF',
      title: 'Flat ₹25 OFF',
      subtitle: 'On your first order',
      code: 'NEW25',
      badge: 'New User',
      saveText: '₹25',
      type: CouponType.blue,
    ),
  ];

  final List<CouponModel> _coupons;
  OfferCategory _selectedCategory = OfferCategory.all;
  String? _lastAppliedCode;

  OfferCategory get selectedCategory => _selectedCategory;

  String? get lastAppliedCode => _lastAppliedCode;

  List<CouponModel> get filteredCoupons {
    switch (_selectedCategory) {
      case OfferCategory.bestSavings:
        return _coupons
            .where(
              (c) => c.type == CouponType.green || c.type == CouponType.orange,
            )
            .toList();
      case OfferCategory.freeDelivery:
        return _coupons.where((c) => c.type == CouponType.purple).toList();
      case OfferCategory.bankOffers:
        return const [];
      case OfferCategory.all:
        return _coupons;
    }
  }

  /// Bank offers tab has no coupon cards of its own — only the bank
  /// offers section further down. Everything else shows both.
  bool get showCouponSection => _selectedCategory != OfferCategory.bankOffers;

  void selectCategory(OfferCategory category) {
    if (_selectedCategory == category) return;
    _selectedCategory = category;
    notifyListeners();
  }

  void applyCoupon(String code) {
    _lastAppliedCode = code;
    notifyListeners();
  }
}
