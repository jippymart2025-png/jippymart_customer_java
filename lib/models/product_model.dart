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
  bool? takeawayOption;
  String? name;
  Map<String, dynamic>? reviewAttributes;
  Map<String, dynamic>? productSpecification;
  ItemAttribute? itemAttribute;
  int? id;
  int? quantity;
  int? grams;
  num? reviewsCount;
  String? disPrice;
  List<String>? photos;
  bool? nonveg;
  String? photo;
  String? price;
  String? categoryID;
  String? description;
  DateTime? createdAt;
  bool? isAvailable;
  String? categoryTitle;

  ProductModel({
    this.fats,
    this.vendorID,
    this.veg,
    this.publish,
    this.addOnsTitle,
    this.calories,
    this.proteins,
    this.addOnsPrice,
    this.reviewsSum,
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
    this.categoryID,
    this.description,
    this.createdAt,
    this.isAvailable,
    this.categoryTitle,
  });

  // Factory constructor for API JSON
  // In ProductModel.fromJson, replace the problematic section:
  factory ProductModel.fromApiJson(Map<String, dynamic> json) {
    try {
      final parsedId = _parseInt(json['id'] ?? json['product_id']);
      return ProductModel(
        id: parsedId,
        name: _parseString(json['name']),
        description: _parseString(json['description']),
        categoryID: _parseString(json['category_id']),
        categoryTitle: _parseString(json['category_title']),
        isAvailable: json['is_available'] == true || json['is_available'] == 1,
        nonveg: json['nonveg'] == true || json['nonveg'] == 1,
        veg: json['veg'] == true || json['veg'] == 1,
        photo: _parseString(json['photo']),
        photos: _parseStringList(json['photos']),
        addOnsTitle: _parseStringList(json['add_ons_title']),
        addOnsPrice: _parsePriceList(json['add_ons_price']),
        itemAttribute: _parseItemAttribute(json['item_attribute']),
        productSpecification: _parseMap(json['product_specification']),
        reviewsCount: _parseNum(json['reviews_count']),
        reviewsSum: _parseNum(json['reviews_sum']),
        quantity: _parseInt(json['quantity']) ?? -1,
        price: _parsePrice(json['original_price']) ?? '0',
        disPrice: _parsePrice(json['discount_price']) ?? '0',
      );
    } catch (e) {
      print('❌ Error parsing product JSON: $e');
      print('❌ Problematic JSON: $json');
      return ProductModel(); // Return empty product instead of crashing
    }
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

  ProductModel.fromJson(Map<String, dynamic> json) {
    try {
      // FIX: Use helper method to parse int fields that might come as String
      fats = _parseInt(json['fats']);
      vendorID = _parseString(json['vendorID']);
      // Convert int (0/1) to bool for boolean fields - handle string "1"/"0" as well
      veg = json['veg'] == 1 || json['veg'] == true || json['veg'] == "1" || json['veg'] == "true";
      publish = json['publish'] == 1 || json['publish'] == true || json['publish'] == "1" || json['publish'] == "true";

      // Parse addOnsTitle - handle both string and list formats
      addOnsTitle = _parseJsonStringToList(json['addOnsTitle']);

      // FIX: Use helper method to parse int fields that might come as String
      calories = _parseInt(json['calories']);
      proteins = _parseInt(json['proteins']);

      // Parse addOnsPrice - handle both string and list formats
      addOnsPrice = _parseJsonStringToList(json['addOnsPrice']);

      reviewsSum = _parseNum(json['reviewsSum']) ?? 0.0;
      // Convert int (0/1) to bool for boolean fields - handle string "1"/"0" as well
      takeawayOption =
          json['takeawayOption'] == 1 || json['takeawayOption'] == true || json['takeawayOption'] == "1" || json['takeawayOption'] == "true";
      name = _parseString(json['name']);
      reviewAttributes = json['reviewAttributes'] is Map<String, dynamic> ? json['reviewAttributes'] : null;
      // Parse product_specification - handle both string and map formats
      productSpecification = _parseJsonStringToMap(json['product_specification']);
      // Handle item_attribute field - it can be Map or List
      if (json['item_attribute'] != null) {
        try {
          if (json['item_attribute'] is Map<String, dynamic>) {
            itemAttribute = ItemAttribute.fromJson(json['item_attribute']);
          } else if (json['item_attribute'] is List) {
            print('⚠️ Product ${json['id']}: item_attribute is List, skipping...');
            itemAttribute = null;
          } else {
            itemAttribute = null;
          }
        } catch (e) {
          print('⚠️ Error parsing item_attribute for product ${json['id']}: $e');
          itemAttribute = null;
        }
      } else {
        itemAttribute = null;
      }
      // FIX: Use helper method to parse int fields that might come as String
      id = _parseInt(json['id'] ?? json['product_id']);
      quantity = _parseInt(json['quantity']);
      grams = _parseInt(json['grams']);
      reviewsCount = _parseNum(json['reviewsCount']) ?? 0.0;

      // FIX: Handle both string and int for disPrice
      disPrice = _parsePrice(json['disPrice']) ?? "0";
      // Parse photos - handle both string and list formats
      photos = _parseJsonStringToList<String>(json['photos'])?.cast<String>();
      nonveg = json['nonveg'] == 1 || json['nonveg'] == true || json['nonveg'] == "1" || json['nonveg'] == "true";
      photo = _parseString(json['photo']);
      // FIX: Handle both string and int for price
      price = _parsePrice(json['price']) ?? "0";
      categoryID = _parseString(json['categoryID']);
      description = _parseString(json['description']);
      createdAt = _parseDate(json['createdAt']);
      // Convert int (0/1) to bool for boolean fields - handle string "1"/"0" as well
      isAvailable = json['isAvailable'] == 1 || json['isAvailable'] == true || json['isAvailable'] == "1" || json['isAvailable'] == "true";
    } catch (e, stackTrace) {
      print('❌ Error parsing ProductModel from JSON: $e');
      print('❌ Stack trace: $stackTrace');
      print('❌ Problematic JSON keys: ${json.keys.toList()}');
      // Set default values to prevent null pointer exceptions
      id = _parseInt(json['id']);
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
    data['photo'] = photo;
    data['price'] = price;
    data['categoryID'] = categoryID;
    data['description'] = description;
    data['createdAt'] = createdAt;
    data['isAvailable'] = isAvailable;

    return data;
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
