import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jippymart_customer/themes/app_them_data.dart';

import 'OrderConfirmedScreen.dart';
import 'create_group_orders_model.dart';

class SplitPaymentScreen extends StatefulWidget {
  final double totalAmount;

  const SplitPaymentScreen({super.key, required this.totalAmount});

  @override
  State<SplitPaymentScreen> createState() => _SplitPaymentScreenState();
}

class _SplitPaymentScreenState extends State<SplitPaymentScreen> {
  late List<GroupMember> _members;

  @override
  void initState() {
    super.initState();
    // TODO: replace with real per-member share data for this group.
    _members = [
      GroupMember(
        id: '1',
        name: 'Rahul',
        avatarUrl: 'https://i.pravatar.cc/100?img=1',
        amountOwed: 320,
        isPaid: true,
      ),
      GroupMember(
        id: '2',
        name: 'Priya',
        avatarUrl: 'https://i.pravatar.cc/100?img=2',
        amountOwed: 450,
        isPaid: true,
      ),
      GroupMember(
        id: '3',
        name: 'Sneha',
        avatarUrl: 'https://i.pravatar.cc/100?img=5',
        amountOwed: 190,
      ),
      GroupMember(
        id: '4',
        name: 'Akash',
        avatarUrl: 'https://i.pravatar.cc/100?img=6',
        amountOwed: 190,
      ),
      GroupMember(
        id: '5',
        name: 'You',
        avatarUrl: 'https://i.pravatar.cc/100?img=7',
        amountOwed: 190,
      ),
    ];
  }

  double get _yourShare =>
      _members.firstWhere((m) => m.name == 'You').amountOwed;

  void _markPaid(String id) {
    setState(() {
      _members = _members
          .map(
            (m) => m.id == id
                ? GroupMember(
                    id: m.id,
                    name: m.name,
                    avatarUrl: m.avatarUrl,
                    amountOwed: m.amountOwed,
                    isPaid: true,
                  )
                : m,
          )
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
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
          'Split Payment',
          style: TextStyle(
            fontFamily: AppThemeData.extraBold,
            color: AppThemeData.grey900,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total to be paid',
              style: TextStyle(
                fontFamily: AppThemeData.medium,
                color: AppThemeData.grey500,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '₹${widget.totalAmount.toStringAsFixed(0)}',
              style: TextStyle(
                fontFamily: AppThemeData.extraBold,
                color: AppThemeData.grey900,
                fontSize: 26,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.separated(
                itemCount: _members.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final m = _members[index];
                  return Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundImage: NetworkImage(m.avatarUrl),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          m.name,
                          style: TextStyle(
                            fontFamily: AppThemeData.semiBold,
                            color: AppThemeData.grey900,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        '₹${m.amountOwed.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontFamily: AppThemeData.medium,
                          color: AppThemeData.grey800,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 14),
                      _statusChip(m),
                    ],
                  );
                },
              ),
            ),
            Text(
              'Payment secured by UPI',
              style: TextStyle(
                fontFamily: AppThemeData.medium,
                color: AppThemeData.grey500,
                fontSize: 11.5,
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B2C),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              onPressed: () {
                // TODO: trigger real UPI payment here, then mark paid on success.
                _markPaid(_members.firstWhere((m) => m.name == 'You').id);
                Get.to(() => const OrderConfirmedScreen());
              },
              child: Text(
                'Pay Now  ₹${_yourShare.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusChip(GroupMember m) {
    if (m.isPaid) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFE6F8EC),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          'Paid',
          style: TextStyle(
            color: Color(0xFF2EBD59),
            fontWeight: FontWeight.w700,
            fontSize: 12.5,
          ),
        ),
      );
    }
    return InkWell(
      onTap: () => _markPaid(m.id),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFF6B2C)),
        ),
        child: const Text(
          'Pay',
          style: TextStyle(
            color: Color(0xFFFF6B2C),
            fontWeight: FontWeight.w700,
            fontSize: 12.5,
          ),
        ),
      ),
    );
  }
}
