import 'package:flutter/material.dart';

/// Membership state of a group order relative to the current user.
/// Backing the "Joined" / "My Orders" tabs with real data instead of
/// tabs that render but never actually filter anything.
enum OrderMembership { open, joined, mine }

@immutable
class CommunityData {
  final String name;
  final String location;
  final String established;
  final String families;
  final String activeOrders;
  final String rating;
  final String description;
  final String guideline;
  final String images;

  const CommunityData({
    required this.name,
    required this.location,
    required this.established,
    required this.families,
    required this.activeOrders,
    required this.rating,
    required this.description,
    required this.guideline,
    required this.images,
  });
}

@immutable
class GroupOrder {
  final String name;
  final String restaurant;
  final int joinedCount;
  final int capacity;
  final String discount;
  final String image;
  final Color color;
  final OrderMembership membership;

  const GroupOrder({
    required this.name,
    required this.restaurant,
    required this.joinedCount,
    required this.capacity,
    required this.discount,
    required this.image,
    required this.color,
    this.membership = OrderMembership.open,
  });

  String get countLabel => '$joinedCount / $capacity';

  double get progress => capacity == 0 ? 0 : joinedCount / capacity;
}

@immutable
class Restaurant {
  final String name;
  final double rating;
  final String reviews;
  final String time;
  final String cuisine;
  final String discount;
  final String image;
  final Color color;
  final bool isVeg;
  final bool isPopular;

  const Restaurant({
    required this.name,
    required this.rating,
    required this.reviews,
    required this.time,
    required this.cuisine,
    required this.discount,
    required this.image,
    required this.color,
    this.isVeg = false,
    this.isPopular = false,
  });
}
