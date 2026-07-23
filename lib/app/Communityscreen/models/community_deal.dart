import 'package:flutter/material.dart';

/// Deal Categories
enum DealCategory { all, restaurants, grocery, essentials }

extension DealCategoryExtension on DealCategory {
  String get title {
    switch (this) {
      case DealCategory.all:
        return 'All Deals';
      case DealCategory.restaurants:
        return 'Restaurants';
      case DealCategory.grocery:
        return 'Grocery';
      case DealCategory.essentials:
        return 'Essentials';
    }
  }
}

/// Community Deal Model
class CommunityDeal {
  final int id;

  /// Restaurant / Store Name
  final String name;

  /// Logo Image
  final String logo;

  /// Banner Image
  final String image;

  /// Category
  final DealCategory category;

  /// Discount Text
  final String discount;

  /// Example:
  /// "On orders above ₹299"
  final String subtitle;

  /// Number of families used
  final int familiesUsed;

  /// Badge
  final bool validToday;

  /// Button Text
  final String buttonText;

  /// Theme Color
  final Color color;

  const CommunityDeal({
    required this.id,
    required this.name,
    required this.logo,
    required this.image,
    required this.category,
    required this.discount,
    required this.subtitle,
    required this.familiesUsed,
    this.validToday = true,
    this.buttonText = 'Order Now',
    this.color = Colors.green,
  });

  CommunityDeal copyWith({
    int? id,
    String? name,
    String? logo,
    String? image,
    DealCategory? category,
    String? discount,
    String? subtitle,
    int? familiesUsed,
    bool? validToday,
    String? buttonText,
    Color? color,
  }) {
    return CommunityDeal(
      id: id ?? this.id,
      name: name ?? this.name,
      logo: logo ?? this.logo,
      image: image ?? this.image,
      category: category ?? this.category,
      discount: discount ?? this.discount,
      subtitle: subtitle ?? this.subtitle,
      familiesUsed: familiesUsed ?? this.familiesUsed,
      validToday: validToday ?? this.validToday,
      buttonText: buttonText ?? this.buttonText,
      color: color ?? this.color,
    );
  }

  factory CommunityDeal.fromJson(Map<String, dynamic> json) {
    return CommunityDeal(
      id: json['id'],
      name: json['name'],
      logo: json['logo'],
      image: json['image'],
      category: DealCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => DealCategory.all,
      ),
      discount: json['discount'],
      subtitle: json['subtitle'],
      familiesUsed: json['familiesUsed'],
      validToday: json['validToday'] ?? true,
      buttonText: json['buttonText'] ?? 'Order Now',
      color: Colors.green,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'logo': logo,
      'image': image,
      'category': category.name,
      'discount': discount,
      'subtitle': subtitle,
      'familiesUsed': familiesUsed,
      'validToday': validToday,
      'buttonText': buttonText,
    };
  }
}
