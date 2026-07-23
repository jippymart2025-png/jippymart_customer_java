import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/models/vendor_model.dart';

class SelectedRestaurant {
  final String id;
  final String name;
  final String imageUrl;
  final String rating;
  final String etaLabel;

  SelectedRestaurant({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.rating,
    required this.etaLabel,
  });

  factory SelectedRestaurant.fromVendorModel(VendorModel vendor) {
    final count = int.tryParse(vendor.reviewsCount?.toString() ?? '0') ?? 0;
    final sum = double.tryParse(vendor.reviewsSum?.toString() ?? '0') ?? 0.0;
    final ratingValue = count == 0
        ? 0.0
        : (sum / count).clamp(0.0, 5.0);

    return SelectedRestaurant(
      id: vendor.id ?? '',
      name: vendor.title ?? 'Restaurant',
      imageUrl: vendor.photo ?? '',
      rating: ratingValue.toStringAsFixed(1),
      etaLabel: Constant.getDeliveryTimeText(vendor),
    );
  }
}

class GroupMember {
  final String id;
  final String name;
  final String avatarUrl;
  final double amountOwed;
  final bool isPaid;
  final bool isHost;

  GroupMember({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.amountOwed,
    this.isPaid = false,
    this.isHost = false,
  });
}

class GroupCartItem {
  final String id;
  final String name;
  final String imageUrl;
  final int quantity;
  final double price;
  final String addedByName;
  final String addedByAvatarUrl;
  final String? note;

  GroupCartItem({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.quantity,
    required this.price,
    required this.addedByName,
    required this.addedByAvatarUrl,
    this.note,
  });

  double get total => price * quantity;
}

class GroupActivityEvent {
  final String memberName;
  final String avatarUrl;
  final String action; // e.g. "added", "is browsing"
  final String detail; // e.g. item name
  final String timeAgo;
  final bool isLive;

  GroupActivityEvent({
    required this.memberName,
    required this.avatarUrl,
    required this.action,
    required this.detail,
    required this.timeAgo,
    this.isLive = false,
  });
}

enum OrderStepStatus { completed, current, upcoming }

class OrderTrackingStep {
  final String title;
  final String timeLabel;
  final OrderStepStatus status;

  OrderTrackingStep({
    required this.title,
    required this.timeLabel,
    required this.status,
  });
}
