import 'dart:convert';

class CartProductModel {
  String? id;
  String? categoryId;
  String? name;
  String? photo;
  String? price;
  String? discountPrice;
  String? merchantPrice;
  String? vendorID;
  String? vendorName;
  int? quantity;
  String? extrasPrice;
  List<dynamic>? extras;
  VariantInfo? variantInfo;
  String? promoId; // Add missing promo_id field

  CartProductModel({
    this.id,
    this.categoryId,
    this.name,
    this.photo,
    this.price,
    this.discountPrice,
    this.merchantPrice,
    this.vendorID,
    this.vendorName,
    this.quantity,
    this.extrasPrice,
    this.variantInfo,
    this.extras,
    this.promoId, // Add to constructor
  });

  CartProductModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    categoryId = json['category_id'];
    name = json['name'];
    photo = json['photo'];
    price = json['price'] ?? "0.0";
    discountPrice = json['discountPrice'] ?? "0.0";
    merchantPrice = json['merchant_price'];
    vendorID = json['vendorID'];
    vendorName = json['vendorName'];
    quantity = json['quantity'];
    extrasPrice = json['extras_price'];
    promoId = json['promo_id']; // Parse promo_id from JSON

    extras = json['extras'] == "null" || json['extras'] == null
        ? null
        : "String" == json['extras'].runtimeType.toString()
        ? List<dynamic>.from(jsonDecode(json['extras']))
        : List<dynamic>.from(json['extras']);

    try {
      final vi = json['variant_info'];
      if (vi == null || vi == "null") {
        variantInfo = null;
      } else if (vi is String) {
        variantInfo = VariantInfo.fromJson(
            Map<String, dynamic>.from(jsonDecode(vi) as Map));
      } else if (vi is Map<String, dynamic>) {
        variantInfo = VariantInfo.fromJson(vi);
      } else if (vi is Map) {
        variantInfo = VariantInfo.fromJson(Map<String, dynamic>.from(vi));
      } else {
        variantInfo = null;
      }
    } catch (_) {
      variantInfo = null;
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['category_id'] = categoryId;
    data['name'] = name;
    data['photo'] = photo;
    data['price'] = price;
    data['discountPrice'] = discountPrice;
    data['merchant_price'] = merchantPrice;
    data['vendorID'] = vendorID;
    data['vendorName'] = vendorName;
    data['quantity'] = quantity;
    data['extras_price'] = extrasPrice;
    data['extras'] = extras;
    data['promo_id'] =
        promoId ?? ''; // Add promo_id to JSON with default empty string
    if (variantInfo != null) {
      data['variant_info'] = variantInfo?.toJson(); // Handle null value
    }
    return data;
  }
}

class VariantInfo {
  String? variantId;
  String? variantPrice;
  String? variantSku;
  String? variantImage;
  dynamic variantOptions; // Changed to dynamic to handle both Map and List

  VariantInfo({
    this.variantId,
    this.variantPrice,
    this.variantSku,
    this.variantImage,
    this.variantOptions,
  });

  VariantInfo.fromJson(Map<String, dynamic> json) {
    try {
      variantId = json['variant_id']?.toString() ?? '';
      variantPrice = json['variant_price']?.toString() ?? '';
      variantSku = json['variant_sku']?.toString() ?? '';
      variantImage = json['variant_image']?.toString() ?? '';

      // Handle variant_options - it could be Map, List, or null
      final optionsData = json['variant_options'];
      if (optionsData != null) {
        if (optionsData is Map) {
          variantOptions = Map<String, dynamic>.from(optionsData);
        } else if (optionsData is List) {
          variantOptions = List<dynamic>.from(optionsData);
        } else if (optionsData is String) {
          // Try to parse if it's a JSON string
          try {
            final decoded = jsonDecode(optionsData);
            if (decoded is Map) {
              variantOptions = Map<String, dynamic>.from(decoded);
            } else if (decoded is List) {
              variantOptions = List<dynamic>.from(decoded);
            } else {
              variantOptions = optionsData;
            }
          } catch (e) {
            variantOptions = optionsData;
          }
        } else {
          variantOptions = optionsData;
        }
      } else {
        variantOptions = {};
      }
    } catch (e) {
      print('Error parsing VariantInfo: $e');
      print('Problematic variant data: $json');
      // Set default values on error
      variantId = '';
      variantPrice = '';
      variantSku = '';
      variantImage = '';
      variantOptions = {};
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['variant_id'] = variantId;
    data['variant_price'] = variantPrice;
    data['variant_sku'] = variantSku;
    data['variant_image'] = variantImage;
    data['variant_options'] = variantOptions;
    return data;
  }
}
