import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jippymart_customer/themes/app_them_data.dart';

import 'SplitPaymentScreen.dart';
import 'create_group_orders_model.dart';

class SharedCartScreen extends StatelessWidget {
  const SharedCartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: replace this dummy list with the real shared-cart data
    // (e.g. from a provider / Firestore listener for this group).
    final items = [
      GroupCartItem(
        id: '1',
        name: 'Chicken Burger',
        imageUrl: 'https://i.pravatar.cc/100?img=11',
        quantity: 2,
        price: 160,
        addedByName: 'Rahul',
        addedByAvatarUrl: 'https://i.pravatar.cc/100?img=1',
        note: 'Extra cheese',
      ),
      GroupCartItem(
        id: '2',
        name: 'Veg Pizza',
        imageUrl: 'https://i.pravatar.cc/100?img=12',
        quantity: 1,
        price: 450,
        addedByName: 'Priya',
        addedByAvatarUrl: 'https://i.pravatar.cc/100?img=2',
        note: 'Medium size',
      ),
      GroupCartItem(
        id: '3',
        name: 'Garlic Bread',
        imageUrl: 'https://i.pravatar.cc/100?img=13',
        quantity: 1,
        price: 120,
        addedByName: 'Sneha',
        addedByAvatarUrl: 'https://i.pravatar.cc/100?img=5',
      ),
      GroupCartItem(
        id: '4',
        name: 'Coke',
        imageUrl: 'https://i.pravatar.cc/100?img=14',
        quantity: 2,
        price: 45,
        addedByName: 'Akash',
        addedByAvatarUrl: 'https://i.pravatar.cc/100?img=6',
      ),
    ];

    final subtotal = items.fold<double>(0, (sum, i) => sum + i.total);
    const deliveryFee = 40.0;
    const taxes = 130.0;
    final total = subtotal + deliveryFee + taxes;

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
        actions: [
          IconButton(
            icon: Icon(Icons.ios_share_rounded, color: AppThemeData.grey900),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${items.length} items • 6 people',
                style: TextStyle(
                  fontFamily: AppThemeData.medium,
                  color: AppThemeData.grey500,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 22),
              itemBuilder: (context, index) {
                final item = items[index];
                return Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: NetworkImage(item.addedByAvatarUrl),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.addedByName,
                            style: TextStyle(
                              fontFamily: AppThemeData.medium,
                              color: AppThemeData.grey500,
                              fontSize: 11.5,
                            ),
                          ),
                          Text(
                            '${item.name}${item.quantity > 1 ? ' x${item.quantity}' : ''}',
                            style: TextStyle(
                              fontFamily: AppThemeData.semiBold,
                              color: AppThemeData.grey900,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (item.note != null)
                            Text(
                              item.note!,
                              style: TextStyle(
                                fontFamily: AppThemeData.medium,
                                color: AppThemeData.grey500,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      '₹${item.total.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontFamily: AppThemeData.semiBold,
                        color: AppThemeData.grey900,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: AppThemeData.grey100)),
            ),
            child: Column(
              children: [
                _summaryRow('Subtotal', subtotal),
                _summaryRow('Delivery Fee', deliveryFee),
                _summaryRow('Taxes & Charges', taxes),
                const Divider(height: 18),
                _summaryRow('Total', total, isBold: true),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
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
                  GestureDetector(
                    onTap: () {},
                    child: Text(
                      'View details',
                      style: TextStyle(
                        fontFamily: AppThemeData.medium,
                        color: AppThemeData.grey500,
                        fontSize: 12,
                        decoration: TextDecoration.underline,
                      ),
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
                onPressed: () {
                  Get.to(() => SplitPaymentScreen(totalAmount: total));
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
