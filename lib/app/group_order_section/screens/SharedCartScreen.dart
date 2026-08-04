import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jippymart_customer/models/group_order_checkout_model.dart';
import 'package:jippymart_customer/themes/app_them_data.dart';

import '../service/group_order_api_service.dart';
import 'SplitPaymentScreen.dart';

class SharedCartScreen extends StatefulWidget {
  final int groupOrdersInvitationId;
  final int hostCustomerId;
  final GroupOrderCheckoutModel? initialCheckout;

  const SharedCartScreen({
    super.key,
    required this.groupOrdersInvitationId,
    required this.hostCustomerId,
    this.initialCheckout,
  });

  @override
  State<SharedCartScreen> createState() => _SharedCartScreenState();
}

class _SharedCartScreenState extends State<SharedCartScreen> {
  GroupOrderCheckoutModel? _checkout;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkout = widget.initialCheckout;
    _loadCheckout();
  }

  Future<void> _loadCheckout() async {
    setState(() => _isLoading = true);

    final checkout = await GroupOrderApiService.groupOrderCheckOut(
      groupOrdersInvitationId: widget.groupOrdersInvitationId,
      hostCustomerId: widget.hostCustomerId,
    );

    if (!mounted) return;

    if (checkout == null) {
      setState(() {
        _isLoading = false;
      });

      Get.snackbar(
        "Checkout Failed",
        "Couldn't load the latest cart. Pull down to refresh.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    setState(() {
      _checkout = checkout;
      _isLoading = false;
    });
  }

  List<_SharedCartRow> get _rows {
    if (_checkout == null) return [];

    final rows = <_SharedCartRow>[];

    for (final delivery in _checkout!.deliveryCheckOutItems) {
      for (final member in delivery.groupOrderCheckoutItems) {
        for (final product in member.products) {
          rows.add(
            _SharedCartRow(
              memberName: member.customerName,
              productName: product.productName,
              quantity: product.quantity,
              lineTotal: product.onlinePrice * product.quantity,
              amountToPay: member.amountToPay,
            ),
          );
        }
      }
    }

    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final checkout = _checkout;
    final rows = _rows;
    int itemCount = 0;
    int memberCount = 0;

    if (checkout != null) {
      for (final delivery in checkout.deliveryCheckOutItems) {
        memberCount += delivery.groupOrderCheckoutItems.length;

        for (final member in delivery.groupOrderCheckoutItems) {
          for (final product in member.products) {
            itemCount += product.quantity;
          }
        }
      }
    }
    final deliveryTotal =
        checkout?.deliveryCheckOutItems.fold<double>(
          0,
          (sum, item) => sum + item.totalDeliveryCharge,
        ) ??
        0;
    final foodTax =
        checkout?.deliveryCheckOutItems.fold<double>(
          0,
          (sum, item) => sum + item.foodTax,
        ) ??
        0;
    final itemsSubtotal =
        checkout?.deliveryCheckOutItems.fold<double>(
          0,
          (sum, item) => sum + item.itemsTotal,
        ) ??
        0;
    final platformFee = checkout?.platformFee ?? 0;
    final surgeFee = checkout?.surgeFee ?? 0;
    final packagingFee = checkout?.packagingFee ?? 0;
    final taxes = foodTax + platformFee + surgeFee + packagingFee;
    final total =
        checkout?.totalNetAmount ?? (itemsSubtotal + deliveryTotal + taxes);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppThemeData.grey900,
            size: 18,
          ),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Shared Cart',
          style: TextStyle(
            fontFamily: AppThemeData.extraBold,
            color: AppThemeData.grey900,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading && checkout == null
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text("Loading shared cart..."),
                ],
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '$itemCount items • $memberCount people',
                      style: TextStyle(
                        fontFamily: AppThemeData.medium,
                        color: AppThemeData.grey500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: rows.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.shopping_cart_outlined,
                                size: 70,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "Shared cart is empty",
                                style: TextStyle(
                                  fontFamily: AppThemeData.semiBold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Ask your friends to add items.",
                                style: TextStyle(color: AppThemeData.grey500),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadCheckout,
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: rows.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 22),
                            itemBuilder: (context, index) {
                              final item = rows[index];
                              return Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: AppThemeData.primary50,
                                    child: Text(
                                      item.memberName.isNotEmpty
                                          ? item.memberName[0].toUpperCase()
                                          : '?',
                                      style: TextStyle(
                                        color: AppThemeData.primary300,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.memberName,
                                          style: TextStyle(
                                            fontFamily: AppThemeData.medium,
                                            color: AppThemeData.grey500,
                                            fontSize: 11.5,
                                          ),
                                        ),
                                        Text(
                                          '${item.productName} × ${item.quantity}',
                                          style: TextStyle(
                                            fontFamily: AppThemeData.semiBold,
                                            color: AppThemeData.grey900,
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '₹${item.amountToPay.toStringAsFixed(0)}',
                                        style: TextStyle(
                                          fontFamily: AppThemeData.semiBold,
                                          color: AppThemeData.grey900,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        'To Pay',
                                        style: TextStyle(
                                          fontFamily: AppThemeData.medium,
                                          color: AppThemeData.grey500,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: AppThemeData.grey100),
                    ),
                  ),
                  child: Column(
                    children: [
                      _summaryRow('Items subtotal', itemsSubtotal),
                      _summaryRow('Packaging Fee', packagingFee),

                      _summaryRow('Platform Fee', platformFee),

                      _summaryRow('Surge Fee', surgeFee),

                      _summaryRow('Food Tax', foodTax),

                      _summaryRow('Delivery', deliveryTotal),
                      const Divider(height: 18),
                      _summaryRow('Total', total, isBold: true),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ],
            ),
      bottomNavigationBar: checkout == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '₹${total.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontFamily: AppThemeData.extraBold,
                            color: AppThemeData.grey900,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6B2C),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      onPressed: rows.isEmpty
                          ? null
                          : () {
                              Get.to(
                                () => SplitPaymentScreen(totalAmount: total),
                              );
                            },
                      child: const Text(
                        'Split & Pay',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _summaryRow(String label, double amount, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: isBold ? AppThemeData.semiBold : AppThemeData.medium,
              color: isBold ? AppThemeData.grey900 : AppThemeData.grey500,
              fontSize: isBold ? 15 : 13.5,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w400,
            ),
          ),
          Text(
            '₹${amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontFamily: isBold ? AppThemeData.semiBold : AppThemeData.medium,
              color: isBold ? AppThemeData.grey900 : AppThemeData.grey800,
              fontSize: isBold ? 15 : 13.5,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _SharedCartRow {
  final String memberName;
  final String productName;
  final int quantity;
  final double lineTotal;
  final double amountToPay;

  _SharedCartRow({
    required this.memberName,
    required this.productName,
    required this.quantity,
    required this.lineTotal,
    required this.amountToPay,
  });
}
