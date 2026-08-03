import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import '../models/models.dart';
import '../providers/community_provider.dart';
import '../theme/app_theme.dart';
import '../theme/responsive.dart';
import '../widgets/common/section_header.dart';
import '../widgets/create_order/GroupOrdersScreen.dart';
import '../widgets/home/community_deals_section.dart';
import '../widgets/home/community_info_card.dart';
import '../widgets/home/community_quick_links.dart';
import '../widgets/home/group_orders_section.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final community = ref.watch(selectedCommunityProvider);

    if (community == null) {
      return const Scaffold(body: Center(child: Text("No Community Selected")));
    }
    final hPad = context.pagePadding;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          community.zoneName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        automaticallyImplyLeading: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Get.back(),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: hPad,
            vertical: AppSpacing.lg,
          ),
          child: ResponsiveCenter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CommunityInfoCard(
                  community: CommunityData(
                    name: community.zoneName,
                    location: community.zoneType,
                    established: '',
                    families: '--',
                    activeOrders: '--',
                    rating: '--',
                    description: '',
                    guideline: '',
                    images: '',
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                const CommunityQuickLinks(),
                const SizedBox(height: AppSpacing.xxl),

                SectionHeader(
                  title: 'Active Group Orders',
                  actionText: 'See All',
                  onAction: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const GroupOrdersScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.md),

                const GroupOrdersSection(),
                const SizedBox(height: AppSpacing.xl),

                /// Today's Community Deals
                SectionHeader(
                  title: "Today's Community Deals",
                  actionText: "View All",
                  onAction: () {},
                ),
                const SizedBox(height: AppSpacing.md),
                const CommunityDealsSection(),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
