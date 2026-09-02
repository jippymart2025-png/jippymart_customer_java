import 'dart:convert';

class ProductModel {
  int? fats;
  String? vendorID;
  bool? veg;
  bool? publish;
  List<dynamic>? addOnsTitle;
  int? calories;
  int? proteins;
  List<dynamic>? addOnsPrice;
  num? reviewsSum;
  bool? isProductFavourite;
  bool? takeawayOption;
  String? name;
  Map<String, dynamic>? reviewAttributes;
  Map<String, dynamic>? productSpecification;
  ItemAttribute? itemAttribute;
  String? id;
  int? quantity;
  int? grams;
  num? reviewsCount;
  String? disPrice;
  List<String>? photos;
  bool? nonveg;
  String? photo;
  String? price;
  String? merchantPrice;
  String? categoryID;
  String? description;
  DateTime? createdAt;
  bool? isAvailable;
  String? categoryTitle;
  List<ProductOption>? options;
  List<ProductAvailabilitySchedule>? availableTimings;
  dynamic activeDiscountsDto;

  // ============================================================
  // BACKWARDS / FORWARDS COMPATIBILITY GETTERS & SETTERS
  // ============================================================
  String? get productId => id;

  set productId(dynamic val) => id = val?.toString();

  String? get productName => name;

  set productName(String? val) => name = val;

  List<ProductOption>? get variants => options;

  set variants(List<ProductOption>? val) => options = val;

  bool? get isVeg => veg;

  set isVeg(bool? val) => veg = val;

  bool get hasActiveDiscount {
    if (activeDiscountsDto == null) return false;
    if (activeDiscountsDto is Map) {
      final map = activeDiscountsDto as Map;
      return map.isNotEmpty &&
          (map['discountAmount'] != null ||
              map['offerName'] != null ||
              map['couponCode'] != null ||
              map['planType'] != null);
    }
    return true;
  }

  String? get discountTitle {
    if (activeDiscountsDto is Map) {
      final map = activeDiscountsDto as Map;
      final offerName = map['offerName']?.toString();
      final planType = map['planType']?.toString();
      final priceType = map['priceType']?.toString();
      final discountAmount = map['discountAmount'];

      if (offerName != null && offerName.isNotEmpty) return offerName;
      if (planType != null && planType.isNotEmpty) return planType;
      if (discountAmount != null && priceType != null) {
        return priceType == 'FLAT'
            ? '₹$discountAmount OFF'
            : '$discountAmount% OFF';
      }
    }
    return 'SPECIAL OFFER';
  }

  ProductModel({
    this.fats,
    this.vendorID,
    this.veg,
    this.activeDiscountsDto,
    this.publish,
    this.addOnsTitle,
    this.calories,
    this.proteins,
    this.addOnsPrice,
    this.reviewsSum,
    this.isProductFavourite,
    this.takeawayOption,
    this.name,
    this.reviewAttributes,
    this.productSpecification,
    this.itemAttribute,
    this.id,
    this.quantity,
    this.grams,
    this.reviewsCount,
    this.disPrice,
    this.photos,
    this.nonveg,
    this.photo,
    this.price,
    this.merchantPrice,
    this.categoryID,
    this.description,
    this.createdAt,
    this.isAvailable,
    this.categoryTitle,
    this.options,
    this.availableTimings,
  });

  factory ProductModel.fromApiJson(Map<String, dynamic> json) {
    return ProductModel.fromJson(json);
  }

  // Add helper methods:
  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is num) return value.toInt();
    return null;
  }

  static String? _parseString(dynamic value) {
    if (value == null) return null;
    return value.toString();
  }

  static List<String>? _parseStringList(dynamic value) {
    if (value == null) return null;
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return null;
  }

  static List<dynamic>? _parsePriceList(dynamic value) {
    if (value == null) return null;
    if (value is List) return value;
    return null;
  }

  static ItemAttribute? _parseItemAttribute(dynamic value) {
    if (value == null) return null;
    if (value is Map<String, dynamic>) {
      return ItemAttribute.fromJson(value);
    }
    return null;
  }

  static Map<String, dynamic>? _parseMap(dynamic value) {
    if (value == null) return null;
    if (value is Map<String, dynamic>) return value;
    return null;
  }

  static num? _parseNum(dynamic value) {
    if (value == null) return null;
    if (value is num) return value;
    if (value is String) return num.tryParse(value);
    return null;
  }

  static String? _parsePrice(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is int) return value.toString();
    if (value is double) return value.toString();
    if (value is num) return value.toString();
    return null;
  }

  static bool? _parseNullableBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is num) return value == 1;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == '1' || normalized == 'true') return true;
      if (normalized == '0' || normalized == 'false') return false;
    }
    return null;
  }

  /// Parse `options` field from API / JSON into a strongly-typed list.
  static List<ProductOption>? _parseOptions(dynamic value) {
    if (value == null) return null;
    try {
      if (value is List) {
        return value
            .whereType<Map<String, dynamic>>()
            .map((e) => ProductOption.fromJson(e))
            .toList();
      }
      if (value is String) {
        final decoded = json.decode(value);
        if (decoded is List) {
          return decoded
              .whereType<Map<String, dynamic>>()
              .map((e) => ProductOption.fromJson(e))
              .toList();
        }
      }
    } catch (e) {
      print('⚠️ Failed to parse product options: $e');
    }
    return null;
  }

  ProductModel.fromJson(Map<String, dynamic> json) {
    try {
      final isAvailableNow = _parseNullableBool(json['is_available_now']);
      final isAvailableLegacy =
          _parseNullableBool(json['isAvailable']) ??
          _parseNullableBool(json['is_available']);
      final resolvedIsAvailable = isAvailableNow ?? isAvailableLegacy ?? true;
      // FIX: Use helper method to parse int fields that might come as String
      fats = _parseInt(json['fats']);
      vendorID = _parseString(json['vendorID'] ?? json['vendor_id']);
      // Convert int (0/1) to bool for boolean fields - handle string "1"/"0" as well
      veg =
          json['isVeg'] == true ||
          json['is_veg'] == true ||
          json['veg'] == 1 ||
          json['veg'] == true ||
          json['veg'] == "1" ||
          json['veg'] == "true";
      publish =
          json['publish'] == 1 ||
          json['publish'] == true ||
          json['publish'] == "1" ||
          json['publish'] == "true";

      // Parse addOnsTitle - handle both string and list formats
      addOnsTitle = _parseJsonStringToList(json['addOnsTitle']) ?? [];

      // FIX: Use helper method to parse int fields that might come as String
      calories = _parseInt(json['calories']);
      proteins = _parseInt(json['proteins']);

      // Parse addOnsPrice - handle both string and list formats
      addOnsPrice = _parseJsonStringToList(json['addOnsPrice']) ?? [];

      reviewsSum = _parseNum(json['reviewsSum']) ?? 0.0;
      // Convert int (0/1) to bool for boolean fields - handle string "1"/"0" as well
      takeawayOption =
          json['takeawayOption'] == 1 ||
          json['takeawayOption'] == true ||
          json['takeawayOption'] == "1" ||
          json['takeawayOption'] == "true";
      name = _parseString(
        json['productName'] ?? json['name'] ?? json['product_name'],
      );
      reviewAttributes = json['reviewAttributes'] is Map<String, dynamic>
          ? json['reviewAttributes']
          : null;
      // Parse product_specification - handle both string and map formats
      productSpecification = _parseJsonStringToMap(
        json['product_specification'],
      );
      // Handle item_attribute field - it can be Map or List
      if (json['item_attribute'] != null) {
        try {
          if (json['item_attribute'] is Map<String, dynamic>) {
            itemAttribute = ItemAttribute.fromJson(json['item_attribute']);
          } else if (json['item_attribute'] is List) {
            itemAttribute = null;
            for (final e in json['item_attribute'] as List) {
              if (e is Map) {
                try {
                  itemAttribute = ItemAttribute.fromJson(
                    Map<String, dynamic>.from(e),
                  );
                  break;
                } catch (_) {}
              }
            }
          } else {
            itemAttribute = null;
          }
        } catch (e) {
          print(
            '⚠️ Error parsing item_attribute for product ${json['id']}: $e',
          );
          itemAttribute = null;
        }
      } else {
        itemAttribute = null;
      }
      // FIX: Use helper method to parse int fields that might come as String
      id = _parseString(json['productId'] ?? json['id'] ?? json['product_id']);
      quantity = _parseInt(json['quantity']) ?? -1;
      grams = _parseInt(json['grams']);
      reviewsCount = _parseNum(json['reviewsCount']) ?? 0.0;

      // FIX: Handle both string and int for disPrice
      disPrice =
          _parsePrice(json['disPrice']) ??
          _parsePrice(json['discount_price']) ??
          "0";
      // Parse photos - handle both string and list formats
      photos =
          _parseJsonStringToList<String>(json['photos'])?.cast<String>() ?? [];
      nonveg =
          json['isVeg'] == false ||
          json['is_veg'] == false ||
          json['nonveg'] == 1 ||
          json['nonveg'] == true ||
          json['nonveg'] == "1" ||
          json['nonveg'] == "true";
      photo = _parseString(
        json['imageLink'] ?? json['thumbnail'] ?? json['image'],
      );
      // FIX: Handle both string and int for price
      price =
          _parsePrice(json['onlinePrice']) ??
          _parsePrice(json['original_price']) ??
          "0";
      merchantPrice =
          _parsePrice(json['merchantPrice']) ??
          _parsePrice(json['merchant_price']) ??
          _parsePrice(json['original_price']) ??
          _parsePrice(json['price']) ??
          "0";
      categoryID = _parseString(
        json['categoryId'] ?? json['categoryID'] ?? json['category_id'],
      );
      categoryTitle = _parseString(
        json['categoryName'] ?? json['categoryTitle'] ?? json['category_title'],
      );
      description = _parseString(json['description']);
      createdAt = _parseDate(json['createdAt']);
      isProductFavourite = _parseNullableBool(
        json['isProductFavourite'] ?? json['is_favourite'],
      );
      activeDiscountsDto =
          json['activeDiscountsDto'] ?? json['activeDiscounts'];
      // Convert int (0/1) to bool for boolean fields - handle string "1"/"0" as well
      isAvailable = resolvedIsAvailable;
      // Parse simple options / variants list if present
      final parsedOptions = _parseOptions(json['options'] ?? json['variants']);
      options = parsedOptions;

      // New API: variants may mix MAIN options and ADD add-ons.
      // Split add-on variants into addOnsTitle/addOnsPrice so the existing
      // add-ons flow (selection + pricing + cart extras) keeps working.
      if (parsedOptions != null && parsedOptions.isNotEmpty) {
        final mainOptions = <ProductOption>[];
        final addOnOptions = <ProductOption>[];
        for (final option in parsedOptions) {
          if (option.isAddOn) {
            addOnOptions.add(option);
          } else {
            mainOptions.add(option);
          }
        }
        options = mainOptions.isNotEmpty ? mainOptions : null;
        if (addOnOptions.isNotEmpty) {
          final mergedTitles =
              json['addOnsTitle'] == null ||
                  json['addOnsTitle'].toString().isEmpty
              ? <dynamic>[]
              : List<dynamic>.from(
                  _parseJsonStringToList(json['addOnsTitle']) ?? [],
                );
          final mergedPrices =
              json['addOnsPrice'] == null ||
                  json['addOnsPrice'].toString().isEmpty
              ? <dynamic>[]
              : List<dynamic>.from(
                  _parseJsonStringToList(json['addOnsPrice']) ?? [],
                );
          for (final addOn in addOnOptions) {
            if (addOn.variantName == null || addOn.variantName!.isEmpty)
              continue;
            if (!mergedTitles.contains(addOn.variantName)) {
              mergedTitles.add(addOn.variantName);
              mergedPrices.add(addOn.price ?? '0');
            }
          }
          addOnsTitle = mergedTitles;
          addOnsPrice = mergedPrices;
        }
      }

      availableTimings =
          _parseProductTimings(
            json['productTimings'] ?? json['product_timings'],
          ) ??
          _parseAvailableTimings(
            json['available_timings'] ?? json['availableTimings'],
          );
    } catch (e, stackTrace) {
      print('❌ Error parsing ProductModel from JSON: $e');
      print('❌ Stack trace: $stackTrace');
      print('❌ Problematic JSON keys: ${json.keys.toList()}');
      id = _parseString(json['id']);
      name = _parseString(json['name']) ?? 'Unknown Product';
      price = _parsePrice(json['price']) ?? "0";
      disPrice = _parsePrice(json['disPrice']) ?? "0";
      // Re-throw to let caller handle it if needed
      // Don't re-throw to allow partial product creation
    }
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      try {
        String clean = value.replaceAll('"', '');
        return DateTime.tryParse(clean);
      } catch (_) {}
    }
    return null;
  }

  // Helper method to parse JSON string to List
  static List<T>? _parseJsonStringToList<T>(dynamic value) {
    if (value == null) return null;

    if (value is List<T>) {
      return value;
    } else if (value is String) {
      try {
        final parsed = json.decode(value);
        if (parsed is List) {
          // Cast each element to T if possible
          return parsed.cast<T>();
        }
      } catch (e) {
        print('⚠️ Failed to parse JSON string to List: $value');
      }
    }
    return null;
  }

  // Helper method to parse JSON string to Map
  static Map<String, dynamic>? _parseJsonStringToMap(dynamic value) {
    if (value == null) return null;

    if (value is Map<String, dynamic>) {
      return value;
    } else if (value is String) {
      try {
        final parsed = json.decode(value);
        if (parsed is Map<String, dynamic>) {
          return parsed;
        }
      } catch (e) {
        print('⚠️ Failed to parse JSON string to Map: $value');
      }
    }
    return null;
  }

  static List<ProductAvailabilitySchedule>? _parseAvailableTimings(
    dynamic value,
  ) {
    if (value == null) return null;
    try {
      final parsed = value is String ? json.decode(value) : value;
      if (parsed is! List) return null;
      return parsed
          .whereType<Map>()
          .map(
            (e) => ProductAvailabilitySchedule.fromJson(
              Map<String, dynamic>.from(e),
            ),
          )
          .toList();
    } catch (e) {
      print('⚠️ Failed to parse available_timings: $e');
      return null;
    }
  }

  /// Converts outlet API `productTimings` [{day, startTime, endTime}] into
  /// the schedule format used by the UI availability checks.
  static List<ProductAvailabilitySchedule>? _parseProductTimings(
    dynamic value,
  ) {
    if (value == null) return null;
    if (value is! List || value.isEmpty) return null;

    final grouped = <String, List<ProductAvailabilityTimeslot>>{};

    for (final item in value) {
      if (item is! Map) continue;
      final day = item['day']?.toString();
      final startTime = item['startTime']?.toString();
      final endTime = item['endTime']?.toString();
      if (day == null || day.isEmpty) continue;

      grouped
          .putIfAbsent(day, () => [])
          .add(ProductAvailabilityTimeslot(from: startTime, to: endTime));
    }

    if (grouped.isEmpty) return null;

    return grouped.entries
        .map(
          (entry) => ProductAvailabilitySchedule(
            day: entry.key,
            timeslot: entry.value,
          ),
        )
        .toList();
  }

  bool get isAvailableAtCurrentTime {
    final timings = availableTimings;
    if (timings == null || timings.isEmpty) return true;

    final now = DateTime.now();
    final today = _weekdayName(now.weekday);
    final todaySchedule = timings.firstWhere(
      (entry) => entry.day?.toLowerCase() == today.toLowerCase(),
      orElse: () => ProductAvailabilitySchedule(day: today, timeslot: []),
    );

    final slots = todaySchedule.timeslot;
    if (slots == null || slots.isEmpty) return false;

    final currentMinutes = now.hour * 60 + now.minute;
    for (final slot in slots) {
      final fromMinutes = _parseTimeToMinutes(slot.from);
      final toMinutes = _parseTimeToMinutes(slot.to);
      if (fromMinutes == null || toMinutes == null) continue;

      if (fromMinutes <= toMinutes) {
        if (currentMinutes >= fromMinutes && currentMinutes <= toMinutes) {
          return true;
        }
      } else if (currentMinutes >= fromMinutes || currentMinutes <= toMinutes) {
        return true;
      }
    }

    return false;
  }

  static int? _parseTimeToMinutes(String? value) {
    if (value == null || value.isEmpty) return null;
    final parts = value.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return hour * 60 + minute;
  }

  static String _weekdayName(int weekday) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[(weekday - 1).clamp(0, 6)];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['fats'] = fats;
    data['vendorID'] = vendorID;
    data['veg'] = veg;
    data['publish'] = publish;

    // Convert lists back to JSON strings if needed by API
    data['addOnsTitle'] = addOnsTitle != null ? json.encode(addOnsTitle) : "[]";

    data['calories'] = calories;
    data['proteins'] = proteins;

    // Convert lists back to JSON strings if needed by API
    data['addOnsPrice'] = addOnsPrice != null ? json.encode(addOnsPrice) : "[]";

    data['reviewsSum'] = reviewsSum;
    data['takeawayOption'] = takeawayOption;
    data['name'] = name;
    data['reviewAttributes'] = reviewAttributes;
    data['product_specification'] = productSpecification != null
        ? json.encode(productSpecification)
        : "[]";

    if (itemAttribute != null) {
      data['item_attribute'] = itemAttribute?.toJson();
    }
    data['id'] = id;
    data['quantity'] = quantity;
    data['grams'] = grams;
    data['reviewsCount'] = reviewsCount;
    data['disPrice'] = disPrice;

    // Convert photos list back to JSON string if needed by API
    data['photos'] = photos != null ? json.encode(photos) : "[]";

    data['nonveg'] = nonveg;
    data['imageLink'] = photo;
    data['price'] = price;
    data['merchant_price'] = merchantPrice;
    data['categoryID'] = categoryID;
    data['description'] = description;
    data['createdAt'] = createdAt;
    data['isAvailable'] = isAvailable;
    data['is_available_now'] = isAvailable == true ? 1 : 0;
    data['available_timings'] = availableTimings
        ?.map((e) => e.toJson())
        .toList();

    if (options != null) {
      data['options'] = options!.map((e) => e.toJson()).toList();
    }

    return data;
  }
}

class ProductAvailabilitySchedule {
  String? day;
  List<ProductAvailabilityTimeslot>? timeslot;

  ProductAvailabilitySchedule({this.day, this.timeslot});

  factory ProductAvailabilitySchedule.fromJson(Map<String, dynamic> json) {
    return ProductAvailabilitySchedule(
      day: ProductModel._parseString(json['day']),
      timeslot: (json['timeslot'] as List?)
          ?.whereType<Map>()
          .map(
            (e) => ProductAvailabilityTimeslot.fromJson(
              Map<String, dynamic>.from(e),
            ),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'day': day, 'timeslot': timeslot?.map((e) => e.toJson()).toList()};
  }
}

class ProductAvailabilityTimeslot {
  String? from;
  String? to;

  ProductAvailabilityTimeslot({this.from, this.to});

  factory ProductAvailabilityTimeslot.fromJson(Map<String, dynamic> json) {
    return ProductAvailabilityTimeslot(
      from: ProductModel._parseString(json['from']),
      to: ProductModel._parseString(json['to']),
    );
  }

  Map<String, dynamic> toJson() {
    return {'from': from, 'to': to};
  }
}

typedef ProductVariant = ProductOption;

class ProductOption {
  String? id;
  String? title;
  String? subtitle;
  String? price;
  bool? isAvailable;
  String? originalPrice;
  bool? isFeatured;
  String? groupName;
  String? priceType;

  // Compatibility getters/setters for ProductVariant
  String? get variantId => id;

  set variantId(dynamic val) => id = val?.toString();

  String? get variantName => subtitle ?? title;

  set variantName(String? val) {
    title = val;
    subtitle = val;
  }

  String? get variantPrice => price;

  set variantPrice(String? val) => price = val;

  String? get merchantPrice => originalPrice ?? price;

  set merchantPrice(String? val) => originalPrice = val;

  String? get variantSku => subtitle ?? title;

  set variantSku(String? val) => subtitle = val;

  /// True when this variant is an add-on (priceType ADD or "Add-ons" group).
  bool get isAddOn =>
      (priceType?.toUpperCase() == 'ADD') ||
      (groupName?.toLowerCase().contains('add') ?? false);

  /// True when this variant is a main selectable option.
  bool get isMain => !isAddOn;

  ProductOption({
    this.id,
    this.title,
    this.subtitle,
    this.price,
    this.isAvailable,
    this.originalPrice,
    this.isFeatured,
    this.groupName,
    this.priceType,
  });

  factory ProductOption.fromJson(Map<String, dynamic> json) {
    return ProductOption(
      id: ProductModel._parseString(
        json['variantId'] ??
            json['variant_id'] ??
            json['optionId'] ??
            json['option_id'] ??
            json['id'],
      ),
      title: ProductModel._parseString(json['variantName'] ?? json['title']),
      subtitle: ProductModel._parseString(
        json['subtitle'] ?? json['variantName'] ?? json['title'],
      ),
      price:
          ProductModel._parsePrice(
            json['onlinePrice'] ??
                json['variantPrice'] ??
                json['variant_price'] ??
                json['optionPrice'] ??
                json['price'],
          ) ??
          '0',
      isAvailable:
          ProductModel._parseNullableBool(
            json['isAvailable'] ?? json['is_available'],
          ) ??
          true,
      originalPrice:
          ProductModel._parsePrice(
            json['merchantPrice'] ??
                json['merchant_price'] ??
                json['original_price'] ??
                json['originalPrice'] ??
                json['price'] ??
                json['variantPrice'] ??
                json['variant_price'],
          ) ??
          '0',
      isFeatured:
          ProductModel._parseNullableBool(
            json['isFeatured'] ?? json['is_featured'],
          ) ??
          false,
      groupName: ProductModel._parseString(
        json['groupName'] ?? json['group_name'],
      ),
      priceType: ProductModel._parseString(
        json['priceType'] ?? json['price_type'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'price': price,
      'is_available': isAvailable,
      'original_price': originalPrice,
      'is_featured': isFeatured,
      'group_name': groupName,
      'price_type': priceType,
    };
  }
}

class ItemAttribute {
  List<Attributes>? attributes;
  List<Variants>? variants;

  ItemAttribute({this.attributes, this.variants});

  ItemAttribute.fromJson(Map<String, dynamic> json) {
    if (json['attributes'] != null) {
      attributes = <Attributes>[];
      json['attributes'].forEach((v) {
        attributes?.add(Attributes.fromJson(v));
      });
    }
    if (json['variants'] != null) {
      variants = <Variants>[];
      json['variants'].forEach((v) {
        variants?.add(Variants.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (attributes != null) {
      data['attributes'] = attributes?.map((v) => v.toJson()).toList();
    }
    if (variants != null) {
      data['variants'] = variants?.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Attributes {
  String? attributeId;
  List<String>? attributeOptions;

  Attributes({this.attributeId, this.attributeOptions});

  Attributes.fromJson(Map<String, dynamic> json) {
    attributeId = json['attribute_id'];
    attributeOptions = json['attribute_options'].cast<String>();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['attribute_id'] = attributeId;
    data['attribute_options'] = attributeOptions;
    return data;
  }
}

class Variants {
  String? variantId;
  String? variantImage;
  String? variantPrice;
  String? variantQuantity;
  String? variantSku;

  Variants({
    this.variantId,
    this.variantImage,
    this.variantPrice,
    this.variantQuantity,
    this.variantSku,
  });

  Variants.fromJson(Map<String, dynamic> json) {
    variantId = json['variant_id'];
    variantImage = json['variant_image'];
    variantPrice = json['variant_price'] ?? '0';
    variantQuantity = json['variant_quantity'] ?? '0';
    variantSku = json['variant_sku'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['variant_id'] = variantId;
    data['variant_image'] = variantImage;
    data['variant_price'] = variantPrice;
    data['variant_quantity'] = variantQuantity;
    data['variant_sku'] = variantSku;
    return data;
  }
}

class ReviewsAttribute {
  num? reviewsCount;
  num? reviewsSum;

  ReviewsAttribute({this.reviewsCount, this.reviewsSum});

  ReviewsAttribute.fromJson(Map<String, dynamic> json) {
    reviewsCount = json['reviewsCount'] ?? 0;
    reviewsSum = json['reviewsSum'] ?? 0;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['reviewsCount'] = reviewsCount;
    data['reviewsSum'] = reviewsSum;
    return data;
  }
}
