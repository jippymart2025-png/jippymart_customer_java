// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
//
// import '../providers/providers.dart';
// import '../theme/app_theme.dart';
// import '../theme/responsive.dart';
// import '../widgets/common/responsive_grid.dart';
// import '../widgets/create_order/filter_chips.dart';
// import '../widgets/create_order/restaurant_list_item.dart';
// import '../widgets/create_order/restaurant_search_bar.dart';
//
// class CreateGroupOrderScreen extends ConsumerWidget {
//   const CreateGroupOrderScreen({super.key});
//
//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final restaurants = ref.watch(filteredRestaurantsProvider);
//     final hPad = context.pagePadding;
//
//     return SafeArea(
//       child: SingleChildScrollView(
//         padding: EdgeInsets.symmetric(horizontal: hPad, vertical: AppSpacing.lg),
//         child: ResponsiveCenter(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   const Text('Create Group Order', style: AppText.headline),
//                   // Rail already gives desktop/tablet a way back to Home,
//                   // so the close button is only needed on the mobile tab bar.
//                   if (context.isMobile)
//                     IconButton(
//                       onPressed: () =>
//                           ref.read(selectedIndexProvider.notifier).state = 0,
//                       icon: const Icon(Icons.close_rounded),
//                       color: AppColors.textSecondary,
//                     ),
//                 ],
//               ),
//               const SizedBox(height: AppSpacing.xl),
//               const RestaurantSearchBar(),
//               const SizedBox(height: AppSpacing.lg),
//               const FilterChipsRow(),
//               const SizedBox(height: AppSpacing.xl),
//               if (restaurants.isEmpty)
//                 const _NoResults()
//               else
//                 ResponsiveGrid(
//                   maxCrossAxisExtent: 480,
//                   mainAxisExtent: 140,
//                   children: restaurants
//                       .map((r) => RestaurantListItem(restaurant: r))
//                       .toList(),
//                 ),
//               const SizedBox(height: AppSpacing.xl),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// class _NoResults extends StatelessWidget {
//   const _NoResults();
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.symmetric(vertical: 48),
//       alignment: Alignment.center,
//       child: Column(
//         children: [
//           const Icon(Icons.search_off_rounded, color: AppColors.textMuted, size: 32),
//           const SizedBox(height: AppSpacing.sm),
//           const Text('No restaurants match your search', style: AppText.body),
//         ],
//       ),
//     );
//   }
// }
