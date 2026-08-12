import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../group_order_section/screens/group_order_navigation.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../common/OrderCard.dart';

class GroupOrdersScreen extends ConsumerWidget {
  const GroupOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(filteredGroupOrdersProvider);

    return Scaffold(
      backgroundColor: const Color(0xffF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Group Orders",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: FilledButton.icon(
              onPressed: () {
                openGroupOrderFlow(orderType: 'COMMUNITY_GROUP_ORDER');
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              icon: const Icon(Icons.add, size: 18),
              label: const Text("Create"),
            ),
          ),
        ],
      ),

      body: Column(
        children: [
          const SizedBox(height: 12),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: _OrderTabs(),
          ),

          const SizedBox(height: 18),

          Expanded(
            child: orders.isEmpty
                ? const _EmptyOrders()
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    physics: const BouncingScrollPhysics(),
                    itemCount: orders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (_, index) {
                      return OrderCard(order: orders[index], compact: true);
                    },
                  ),
          ),

          const _CreateGroupOrderBanner(),
        ],
      ),
    );
  }
}

class _OrderTabs extends ConsumerWidget {
  const _OrderTabs();

  static const tabs = <String, OrderMembership?>{
    "All Orders": null,
    "Joined": OrderMembership.joined,
    "My Orders": OrderMembership.mine,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedOrderTabProvider);

    return Row(
      children: tabs.entries.map((tab) {
        final active = selected == tab.value;

        return Padding(
          padding: const EdgeInsets.only(right: 24),
          child: InkWell(
            onTap: () {
              ref.read(selectedOrderTabProvider.notifier).state = tab.value;
            },
            child: Column(
              children: [
                Text(
                  tab.key,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: active ? Colors.green : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 6),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  height: 3,
                  width: 32,
                  decoration: BoxDecoration(
                    color: active ? Colors.green : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _CreateGroupOrderBanner extends StatelessWidget {
  const _CreateGroupOrderBanner();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            openGroupOrderFlow(orderType: 'COMMUNITY_GROUP_ORDER');
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xffEAF8ED),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.group_add,
                    color: Colors.green,
                    size: 28,
                  ),
                ),

                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Create a Group Order",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),

                      SizedBox(height: 4),

                      Text(
                        "Start a new order and invite your neighbors to join for bigger savings.",
                        style: TextStyle(color: Colors.black54, fontSize: 13),
                      ),
                    ],
                  ),
                ),

                const Icon(Icons.arrow_forward_ios_rounded, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyOrders extends StatelessWidget {
  const _EmptyOrders();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.groups_outlined, size: 70, color: Colors.grey),
          SizedBox(height: 12),
          Text(
            "No Group Orders Found",
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
          ),
        ],
      ),
    );
  }
}
