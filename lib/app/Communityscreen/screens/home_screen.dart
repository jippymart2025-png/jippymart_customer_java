import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../theme/responsive.dart';
import '../widgets/common/section_header.dart';
import '../widgets/home/community_deals_section.dart';
import '../widgets/home/community_info_card.dart';
import '../widgets/home/community_quick_links.dart';
import '../widgets/home/group_orders_section.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final community = ref.watch(communityDataProvider);
    final hPad = context.pagePadding;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Community',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        automaticallyImplyLeading: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
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
                CommunityInfoCard(community: community),
                const SizedBox(height: AppSpacing.lg),

                const CommunityQuickLinks(),
                const SizedBox(height: AppSpacing.xxl),

                SectionHeader(
                  title: 'Group Orders',
                  actionText: 'See All',
                  onAction: () {},
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
