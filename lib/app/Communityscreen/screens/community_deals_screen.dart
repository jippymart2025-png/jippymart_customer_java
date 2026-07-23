import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/community_deals_provider.dart';
import '../widgets/deals/deal_card.dart';
import '../widgets/deals/deal_filter_tabs.dart';

class CommunityDealsScreen extends ConsumerWidget {
  const CommunityDealsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deals = ref.watch(filteredCommunityDealsProvider);

    return Scaffold(
      backgroundColor: const Color(0xffF6F7FB),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        centerTitle: false,
        title: const Text(
          "Today's Community Deals",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
      ),

      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
            child: const DealFilterTabs(),
          ),

          Expanded(
            child: deals.isEmpty
                ? const _EmptyDeals()
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    physics: const BouncingScrollPhysics(),
                    itemCount: deals.length,
                    itemBuilder: (context, index) {
                      final deal = deals[index];

                      return DealCard(
                        deal: deal,
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Opening ${deal.name}")),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _EmptyDeals extends StatelessWidget {
  const _EmptyDeals();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_offer_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 10),
            const Text(
              "No Deals Found",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "Try selecting another category.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}
