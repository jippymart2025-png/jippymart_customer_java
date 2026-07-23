import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';

// ===================== NAVIGATION / UI STATE =====================
final selectedIndexProvider = StateProvider<int>((ref) => 0);
final selectedOrderTabProvider = StateProvider<OrderMembership?>((ref) => null);
final searchQueryProvider = StateProvider<String>((ref) => '');
final selectedFilterProvider = StateProvider<String>((ref) => 'All');

// ===================== STATIC / SOURCE DATA =====================
final communityDataProvider = Provider<CommunityData>((ref) {
  return const CommunityData(
    name: 'Green Valley Apartments',
    location: 'Hyderabad, Telangana',
    established: 'Jan 2023',
    families: '248',
    activeOrders: '12',
    rating: '4.8',
    description:
        "We're a friendly neighborhood community. Let's come together to "
        'save more and build stronger connections.',
    guideline: 'Be respectful and kind to everyone.',
    images:
        "https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=1200",
  );
});

final groupOrdersProvider = Provider<List<GroupOrder>>((ref) {
  return const [
    GroupOrder(
      name: 'Biryani Night',
      restaurant: 'Paradise Biryani',
      joinedCount: 28,
      capacity: 50,
      discount: '15% OFF',
      image: '🍛',
      color: AppColors.accentOrange,
      membership: OrderMembership.joined,
    ),
    GroupOrder(
      name: 'Pizza Party',
      restaurant: 'La Pino',
      joinedCount: 12,
      capacity: 25,
      discount: '10% OFF',
      image: '🍕',
      color: AppColors.accentRed,
      membership: OrderMembership.mine,
    ),
    GroupOrder(
      name: 'Thali Sundar',
      restaurant: 'Sri Sai Tiffins',
      joinedCount: 12,
      capacity: 25,
      discount: '12% OFF',
      image: '🍽️',
      color: AppColors.accentGreen,
      membership: OrderMembership.open,
    ),
    GroupOrder(
      name: 'Healthy Bowl',
      restaurant: 'EatFit',
      joinedCount: 10,
      capacity: 20,
      discount: '8% OFF',
      image: '🥗',
      color: AppColors.accentPurple,
      membership: OrderMembership.open,
    ),
  ];
});

final restaurantsProvider = Provider<List<Restaurant>>((ref) {
  return const [
    Restaurant(
      name: 'Paradise Biryani',
      rating: 4.6,
      reviews: '2.3k',
      time: '30-40 mins',
      cuisine: 'Biryani, North Indian',
      discount: '15% OFF',
      image: '🍛',
      color: AppColors.accentOrange,
      isPopular: true,
    ),
    Restaurant(
      name: 'La Pino',
      rating: 4.5,
      reviews: '1.8k',
      time: '25-35 mins',
      cuisine: 'Pizza, Italian',
      discount: '10% OFF',
      image: '🍕',
      color: AppColors.accentRed,
      isVeg: true,
    ),
    Restaurant(
      name: 'Sri Sai Tiffins',
      rating: 4.7,
      reviews: '3.1k',
      time: '20-30 mins',
      cuisine: 'South Indian, Tiffins',
      discount: '12% OFF',
      image: '🍽️',
      color: AppColors.accentGreen,
      isVeg: true,
      isPopular: true,
    ),
    Restaurant(
      name: 'Faasos',
      rating: 4.4,
      reviews: '1.2k',
      time: '30-40 mins',
      cuisine: 'Wraps, Rolls',
      discount: '8% OFF',
      image: '🌯',
      color: AppColors.accentPurple,
    ),
    Restaurant(
      name: "McDonald's",
      rating: 4.3,
      reviews: '4.5k',
      time: '15-25 mins',
      cuisine: 'Burgers, Fast Food',
      discount: '20% OFF',
      image: '🍔',
      color: AppColors.accentYellow,
      isPopular: true,
    ),
  ];
});

// ===================== DERIVED / FILTERED DATA =====================
// Keeping filtering logic here (not in widgets) means the UI layer
// stays "dumb" — it just renders whatever the provider hands it.

final filteredGroupOrdersProvider = Provider<List<GroupOrder>>((ref) {
  final orders = ref.watch(groupOrdersProvider);
  final tab = ref.watch(selectedOrderTabProvider);
  if (tab == null) return orders;
  return orders.where((o) => o.membership == tab).toList();
});

final filteredRestaurantsProvider = Provider<List<Restaurant>>((ref) {
  final restaurants = ref.watch(restaurantsProvider);
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();
  final filter = ref.watch(selectedFilterProvider);

  return restaurants.where((r) {
    final matchesQuery =
        query.isEmpty ||
        r.name.toLowerCase().contains(query) ||
        r.cuisine.toLowerCase().contains(query);

    final matchesFilter = switch (filter) {
      'Popular' => r.isPopular,
      'Veg' => r.isVeg,
      'Non-Veg' => !r.isVeg,
      'Nearby' => true, // no geolocation source yet — placeholder pass-through
      _ => true,
    };

    return matchesQuery && matchesFilter;
  }).toList();
});
