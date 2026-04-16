import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:jippymart_customer/constant/show_toast_dialog.dart';
import 'package:jippymart_customer/themes/app_them_data.dart';
import 'package:jippymart_customer/utils/fire_store_utils.dart';

class OrderReviewService {
  OrderReviewService._();
  static final OrderReviewService instance = OrderReviewService._();

  bool _isChecking = false;
  bool _isDialogOpen = false;

  Future<void> checkAndShowReviewPopup(BuildContext context) async {
    if (_isChecking || _isDialogOpen) return;
    _isChecking = true;
    try {
      final data = await _getEligibilityWithRetry();
      final eligibleData = _extractEligiblePayload(data);
      if (eligibleData == null) return;

      final isEligible = eligibleData['eligible'] == true;
      if (!isEligible) return;

      final orderId =
          (eligibleData['orderId'] ?? eligibleData['orderid'] ?? '').toString();
      final vendorId =
          (eligibleData['vendorId'] ?? eligibleData['VendorId'] ?? '')
              .toString();
      final driverIdRaw = eligibleData['driverId'] ?? eligibleData['driver_id'];
      final driverId = driverIdRaw == null ? null : driverIdRaw.toString();

      if (orderId.isEmpty || vendorId.isEmpty) return;
      if (!context.mounted) return;

      _isDialogOpen = true;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        isDismissible: false,
        enableDrag: false,
        backgroundColor: Colors.transparent,
        builder: (_) => _OrderReviewSheet(
          orderId: orderId,
          vendorId: vendorId,
          driverId: driverId,
        ),
      );
    } catch (e) {
      // Silent fail to avoid blocking app flow.
      debugPrint('OrderReviewService error: $e');
    } finally {
      _isChecking = false;
      _isDialogOpen = false;
    }
  }

  Future<Map<String, dynamic>?> _getEligibilityWithRetry() async {
    var data = await FireStoreUtils.getReviewEligibility();
    if (data != null) return data;
    await Future.delayed(const Duration(seconds: 2));
    data = await FireStoreUtils.getReviewEligibility();
    return data;
  }

  Map<String, dynamic>? _extractEligiblePayload(Map<String, dynamic>? data) {
    if (data == null) return null;

    // Shape A: { eligible, orderId, vendorId, driverId }
    if (data.containsKey('eligible')) return data;

    // Shape B: { review: { eligible, ... } }
    final review = data['review'];
    if (review is Map<String, dynamic> && review.containsKey('eligible')) {
      return review;
    }

    // Shape C: { data: { eligible, ... } } (double nested backend wrappers)
    final nestedData = data['data'];
    if (nestedData is Map<String, dynamic> &&
        nestedData.containsKey('eligible')) {
      return nestedData;
    }

    // Shape D: { delivery: { eligible, ... }, food: {...} } -> take delivery first
    final delivery = data['delivery'];
    if (delivery is Map<String, dynamic> && delivery['eligible'] == true) {
      return Map<String, dynamic>.from(delivery);
    }
    final food = data['food'];
    if (food is Map<String, dynamic> && food['eligible'] == true) {
      return Map<String, dynamic>.from(food);
    }

    // Shape E: { orders: [ {eligible...}, ... ] } -> latest only (first)
    final orders = data['orders'];
    if (orders is List && orders.isNotEmpty) {
      final first = orders.first;
      if (first is Map<String, dynamic>) return first;
    }
    return null;
  }
}

class _OrderReviewSheet extends StatefulWidget {
  const _OrderReviewSheet({
    required this.orderId,
    required this.vendorId,
    this.driverId,
  });

  final String orderId;
  final String vendorId;
  final String? driverId;

  @override
  State<_OrderReviewSheet> createState() => _OrderReviewSheetState();
}

class _OrderReviewSheetState extends State<_OrderReviewSheet> {
  double _rating = 0;
  bool _isSubmitting = false;
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit(String action) async {
    if (_isSubmitting) return;
    if (action == 'submit' && _rating < 1) {
      ShowToastDialog.showToast('Please select a rating');
      return;
    }

    setState(() => _isSubmitting = true);
    final ok = await FireStoreUtils.submitOrderReview(
      orderId: widget.orderId,
      vendorId: widget.vendorId,
      driverId: widget.driverId,
      action: action,
      rating: action == 'submit' ? _rating.round() : null,
      comment: action == 'submit' ? _commentController.text : null,
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (ok) {
      Navigator.of(context).pop();
      if (action == 'submit') {
        ShowToastDialog.showToast('Thanks for your feedback');
      }
    } else {
      ShowToastDialog.showToast('Unable to save feedback. Try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return AnimatedPadding(
      duration: const Duration(milliseconds: 150),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: AppThemeData.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppThemeData.grey200,
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'How was your order?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppThemeData.grey900,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Please rate your latest delivered order',
                style: TextStyle(
                  fontSize: 13,
                  color: AppThemeData.grey500,
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: RatingBar.builder(
                  initialRating: _rating,
                  minRating: 1,
                  allowHalfRating: false,
                  itemCount: 5,
                  itemSize: 34,
                  itemPadding: const EdgeInsets.symmetric(horizontal: 3),
                  itemBuilder: (context, _) =>
                      const Icon(Icons.star, color: AppThemeData.warning300),
                  onRatingUpdate: (value) => setState(() => _rating = value),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _commentController,
                minLines: 2,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Add a comment (optional)',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSubmitting ? null : () => _submit('skip'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(46),
                        side: const BorderSide(color: AppThemeData.grey300),
                      ),
                      child: const Text('Skip'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : () => _submit('submit'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(46),
                        backgroundColor: AppThemeData.primary300,
                        foregroundColor: Colors.white,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Submit'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
