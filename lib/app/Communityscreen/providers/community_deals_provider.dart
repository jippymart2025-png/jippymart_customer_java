import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/community_deal.dart';

/// Selected Category
final selectedCategoryProvider = StateProvider<DealCategory>(
  (ref) => DealCategory.all,
);

/// All Community Deals
final communityDealsProvider = Provider<List<CommunityDeal>>((ref) {
  return const [
    CommunityDeal(
      id: 1,
      name: "McDonald's",
      logo: "🍔",
      image:
          "https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=1200",
      category: DealCategory.restaurants,
      discount: "FLAT 20% OFF",
      subtitle: "On orders above ₹299",
      familiesUsed: 239,
      validToday: true,
      color: Colors.green,
    ),

    CommunityDeal(
      id: 2,
      name: "Behrouz Biryani",
      logo: "🍛",
      image:
          "https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=1200",
      category: DealCategory.restaurants,
      discount: "15% OFF",
      subtitle: "On all orders",
      familiesUsed: 180,
      validToday: false,
      color: Colors.orange,
    ),

    CommunityDeal(
      id: 3,
      name: "Faasos",
      logo: "🌯",
      image:
          "https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=1200",
      category: DealCategory.restaurants,
      discount: "10% OFF",
      subtitle: "On orders above ₹199",
      familiesUsed: 148,
      validToday: false,
      color: Colors.deepPurple,
    ),

    CommunityDeal(
      id: 4,
      name: "Domino's",
      logo: "🍕",
      image:
          "https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=1200",
      category: DealCategory.restaurants,
      discount: "FREE Garlic Bread",
      subtitle: "On orders above ₹399",
      familiesUsed: 301,
      validToday: true,
      color: Colors.blue,
    ),

    CommunityDeal(
      id: 5,
      name: "Blinkit",
      logo: "🛒",
      image:
          "https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=1200",
      category: DealCategory.grocery,
      discount: "Flat ₹100 OFF",
      subtitle: "On shopping above ₹999",
      familiesUsed: 412,
      validToday: true,
      color: Colors.green,
    ),

    CommunityDeal(
      id: 6,
      name: "Zepto",
      logo: "🥬",
      image:
          "https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=1200",
      category: DealCategory.grocery,
      discount: "20% OFF",
      subtitle: "Fresh Fruits & Vegetables",
      familiesUsed: 267,
      validToday: false,
      color: Colors.purple,
    ),

    CommunityDeal(
      id: 7,
      name: "BigBasket",
      logo: "🥦",
      image:
          "https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=1200",
      category: DealCategory.grocery,
      discount: "₹250 Cashback",
      subtitle: "On orders above ₹1500",
      familiesUsed: 122,
      validToday: true,
      color: Colors.green,
    ),

    CommunityDeal(
      id: 8,
      name: "DMart Ready",
      logo: "🧴",
      image:
          "https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=1200",
      category: DealCategory.essentials,
      discount: "Up to 30% OFF",
      subtitle: "Daily Essentials",
      familiesUsed: 198,
      validToday: true,
      color: Colors.red,
    ),

    CommunityDeal(
      id: 9,
      name: "Apollo Pharmacy",
      logo: "💊",
      image:
          "https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=1200",
      category: DealCategory.essentials,
      discount: "15% OFF",
      subtitle: "Healthcare Products",
      familiesUsed: 164,
      validToday: false,
      color: Colors.teal,
    ),
  ];
});

/// Filtered Deals
final filteredCommunityDealsProvider = Provider<List<CommunityDeal>>((ref) {
  final deals = ref.watch(communityDealsProvider);
  final selected = ref.watch(selectedCategoryProvider);

  if (selected == DealCategory.all) {
    return deals;
  }

  return deals.where((deal) {
    return deal.category == selected;
  }).toList();
});
