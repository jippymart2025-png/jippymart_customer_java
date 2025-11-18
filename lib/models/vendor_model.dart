import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jippymart_customer/models/admin_commission.dart';
import 'package:jippymart_customer/models/subscription_plan_model.dart';
import 'dart:convert' as jsons;

class VendorModel {
  String? author;
  bool? dineInActive;
  String? openDineTime;
  List<dynamic>? categoryID;
  String? id;
  String? categoryPhoto;
  List<dynamic>? restaurantMenuPhotos;
  List<WorkingHours>? workingHours;
  String? location;
  String? fcmToken;
  G? g;
  bool? hidephotos;
  bool? reststatus;
  bool? isOpen; // Manual toggle for restaurant open/close status
  Filters? filters;
  AdminCommission? adminCommission;
  String? photo;
  String? description;
  num? walletAmount;
  String? closeDineTime;
  String? zoneId;
  String? createdAt;
  double? longitude;
  bool? enabledDiveInFuture;
  String? restaurantCost;
  DeliveryCharge? deliveryCharge;
  String? authorProfilePic;
  String? authorName;
  String? phonenumber;
  List<SpecialDiscount>? specialDiscount;
  bool? specialDiscountEnable;
  GeoPoint? coordinates;
  num? reviewsSum;
  num? reviewsCount;
  List<dynamic>? photos;
  String? title;
  List<dynamic>? categoryTitle;
  double? latitude;
  String? subscriptionPlanId;
  Timestamp? subscriptionExpiryDate;
  SubscriptionPlanModel? subscriptionPlan;
  String? subscriptionTotalOrders;
  bool? isSelfDelivery;
  String? vType; // Vendor type: 'restaurant' or 'mart'
  double? distance; // Used for sorting/filtering, not from backend
  bool? isActive;

  VendorModel({
    this.author,
    this.dineInActive,
    this.openDineTime,
    this.categoryID,
    this.id,
    this.categoryPhoto,
    this.restaurantMenuPhotos,
    this.workingHours,
    this.location,
    this.fcmToken,
    this.g,
    this.hidephotos,
    this.reststatus,
    this.isOpen,
    this.filters,
    this.reviewsCount,
    this.photo,
    this.description,
    this.walletAmount,
    this.closeDineTime,
    this.zoneId,
    this.createdAt,
    this.longitude,
    this.enabledDiveInFuture,
    this.restaurantCost,
    this.deliveryCharge,
    this.adminCommission,
    this.authorProfilePic,
    this.authorName,
    this.phonenumber,
    this.specialDiscount,
    this.specialDiscountEnable,
    this.coordinates,
    this.reviewsSum,
    this.photos,
    this.title,
    this.categoryTitle,
    this.latitude,
    this.subscriptionPlanId,
    this.subscriptionExpiryDate,
    this.subscriptionPlan,
    this.subscriptionTotalOrders,
    this.isSelfDelivery,
    this.vType,
    this.distance,
    this.isActive,
  });

  VendorModel.fromJson(Map<String, dynamic> json) {
    author = json['author'];
    dineInActive = json['dine_in_active'];
    openDineTime = json['openDineTime'];
    if (json['categoryID'] != null) {
      if (json['categoryID'] is List) {
        categoryID = json['categoryID'];
      } else if (json['categoryID'] is String) {
        // Handle string that should be a list
        try {
          final categoryString = json['categoryID'] as String;
          final parsedCategories = jsons.json.decode(categoryString);
          if (parsedCategories is List) {
            categoryID = parsedCategories;
          } else {
            categoryID = [json['categoryID']];
          }
        } catch (e) {
          categoryID = [json['categoryID']];
        }
      } else {
        categoryID = [json['categoryID']];
      }
    } else {
      categoryID = [];
    }
    id = json['id'];
    categoryPhoto = json['categoryPhoto'];
    restaurantMenuPhotos = json['restaurantMenuPhotos'] ?? [];

    // Handle workingHours
    if (json['workingHours'] != null) {
      workingHours = <WorkingHours>[];
      if (json['workingHours'] is List) {
        json['workingHours'].forEach((v) {
          workingHours!.add(WorkingHours.fromJson(v));
        });
      }
    }

    location = json['location'];
    fcmToken = json['fcmToken'];
    g = json['g'] != null ? G.fromJson(json['g']) : null;
    hidephotos = json['hidephotos'];
    reststatus = json['reststatus'];

    // FIX: Check both 'isOpen' and 'is_open' fields
    isOpen = json['isOpen'] ?? json['is_open'] ?? true;

    filters = json['filters'] != null
        ? Filters.fromJson(json['filters'])
        : null;
    reviewsCount = json['reviewsCount'] ?? 0.0;
    photo = json['photo'];
    description = json['description'];
    walletAmount = json['walletAmount'];
    closeDineTime = json['closeDineTime'];
    zoneId = json['zoneId'];
    createdAt = json['createdAt']?.toString();
    // Handle longitude - could be double or String
    // ✅ Handle longitude
    if (json['longitude'] != null) {
      longitude = json['longitude'] is double
          ? json['longitude']
          : double.tryParse(json['longitude'].toString());
    }
    if (json['coordinates'] != null) {
      final coord = json['coordinates'];
      if (coord is GeoPoint) {
        coordinates = coord;
      } else if (coord is Map &&
          coord['latitude'] != null &&
          coord['longitude'] != null) {
        coordinates = GeoPoint(
          (coord['latitude'] as num).toDouble(),
          (coord['longitude'] as num).toDouble(),
        );
      } else {
        print("⚠️ Invalid coordinates format: $coord");
      }
    }
    enabledDiveInFuture = json['enabledDiveInFuture'];
    restaurantCost = json['restaurantCost']?.toString();
    if (json['DeliveryCharge'] != null && json['DeliveryCharge'] is Map) {
      deliveryCharge = DeliveryCharge.fromJson(json['DeliveryCharge']);
    } else {
      deliveryCharge = null;
    }
    // **FIX: Handle adminCommission - could be Map or JSON String**
    if (json['adminCommission'] != null) {
      if (json['adminCommission'] is Map) {
        // If it's already a Map (from Firebase)
        adminCommission = AdminCommission.fromJson(json['adminCommission']);
      } else if (json['adminCommission'] is String) {
        // If it's a JSON String (from API)
        try {
          final commissionString = json['adminCommission'] as String;
          final commissionMap = jsons.json.decode(commissionString);
          adminCommission = AdminCommission.fromJson(commissionMap);
        } catch (e) {
          print('Error parsing adminCommission string: $e');
          adminCommission = null;
        }
      }
    } else {
      adminCommission = null;
    }

    authorProfilePic = json['authorProfilePic'];
    authorName = json['authorName'];
    phonenumber = json['phonenumber'];

    // Handle specialDiscount
    if (json['specialDiscount'] != null && json['specialDiscount'] is List) {
      specialDiscount = <SpecialDiscount>[];
      json['specialDiscount'].forEach((v) {
        specialDiscount!.add(SpecialDiscount.fromJson(v));
      });
    }

    specialDiscountEnable = json['specialDiscountEnable'];
    reviewsSum = json['reviewsSum'] ?? 0.0;
    // Handle photos - could be List or String
    if (json['photos'] != null) {
      if (json['photos'] is List) {
        photos = json['photos'];
      } else if (json['photos'] is String) {
        // Try to parse the string as JSON array
        try {
          final photosString = json['photos'] as String;
          final parsedPhotos = jsons.json.decode(photosString);
          if (parsedPhotos is List) {
            photos = parsedPhotos;
          } else {
            photos = [];
          }
        } catch (e) {
          print('Error parsing photos string: $e');
          photos = [];
        }
      } else {
        photos = [];
      }
    } else {
      photos = [];
    }
    title = json['title'];
    if (json['coordinates'] != null) {
      final coord = json['coordinates'];
      if (coord is GeoPoint) {
        coordinates = coord;
      } else if (coord is Map &&
          coord['latitude'] != null &&
          coord['longitude'] != null) {
        coordinates = GeoPoint(
          (coord['latitude'] as num).toDouble(),
          (coord['longitude'] as num).toDouble(),
        );
      } else {
        print("⚠️ Invalid coordinates format: $coord");
      }
    }
    // ❌ Remove or comment out this line:
    // coordinates = json['coordinates'];

    // Handle categoryTitle - could be List or String
    if (json['categoryTitle'] != null) {
      if (json['categoryTitle'] is List) {
        categoryTitle = json['categoryTitle'];
      } else {
        categoryTitle = [json['categoryTitle']];
      }
    } else {
      categoryTitle = [];
    }

    // Handle latitude - could be double or String
    if (json['latitude'] != null) {
      latitude = json['latitude'] is double
          ? json['latitude']
          : double.tryParse(json['latitude'].toString());
    }

    subscriptionPlanId = json['subscriptionPlanId'];

    // Handle subscriptionExpiryDate
    subscriptionExpiryDate = _parseTimestamp(json['subscriptionExpiryDate']);

    subscriptionPlan = json['subscription_plan'] != null
        ? SubscriptionPlanModel.fromJson(json['subscription_plan'])
        : null;

    subscriptionTotalOrders = json['subscriptionTotalOrders'];
    isSelfDelivery = json['isSelfDelivery'] ?? false;
    vType = json['vType'];

    // Handle distance - could be double or String
    if (json['distance'] != null) {
      distance = json['distance'] is double
          ? json['distance']
          : double.tryParse(json['distance'].toString());
    }

    // FIX: Check both 'isActive' and 'is_active' fields
    isActive = json['isActive'] ?? json['is_active'] ?? true;
  }

  // In VendorModel.fromJson method, add these lines if needed:
  factory VendorModel.fromApiJson(Map<String, dynamic> json) {
    return VendorModel(
      id: json['id'],
      title: json['title'],
      zoneId: json['zoneId'],
      latitude: json['latitude'] is double
          ? json['latitude']
          : double.tryParse(json['latitude'].toString()),
      longitude: json['longitude'] is double
          ? json['longitude']
          : double.tryParse(json['longitude'].toString()),
      distance: json['distance'] is double
          ? json['distance']
          : double.tryParse(json['distance'].toString()),
      vType: json['vType'],
      // FIX: Check both field names in API JSON
      isActive: json['isActive'] ?? json['is_active'] ?? true,
      isOpen: json['isOpen'] ?? json['is_open'] ?? true,
      subscriptionPlan: json['subscriptionPlan'],
      subscriptionTotalOrders: json['subscriptionTotalOrders'],
      subscriptionExpiryDate: json['subscriptionExpiryDate'],
      reviewsCount: json['reviewsCount'],
      reviewsSum: json['reviewsSum'],
      // reviewsAverage: json['reviewsAverage'],
      restaurantCost: json['restaurantCost']?.toString(),
      createdAt: DateTime.parse(json['createdAt']).toString(),
      photo: json['photo'],
      location: json['location'],
      enabledDiveInFuture: json['enabledDiveInFuture'],
      description: json['description'],
      phonenumber: json['phonenumber'],
      adminCommission: json['adminCommission'] != null
          ? AdminCommission.fromJson(json['adminCommission'])
          : null,
      specialDiscountEnable: json['specialDiscountEnable'],
    );
  }

  static Timestamp? _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return null;
    if (timestamp is Timestamp) return timestamp;
    if (timestamp is String) {
      // Handle string timestamp format from API
      try {
        return Timestamp.fromDate(DateTime.parse(timestamp));
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['author'] = author;
    data['dine_in_active'] = dineInActive;
    data['openDineTime'] = openDineTime;
    data['categoryID'] = categoryID;
    data['id'] = id;
    data['categoryPhoto'] = categoryPhoto;
    data['restaurantMenuPhotos'] = restaurantMenuPhotos;
    data['subscriptionPlanId'] = subscriptionPlanId;
    data['subscriptionExpiryDate'] = subscriptionExpiryDate;
    data['subscription_plan'] = subscriptionPlan?.toJson();
    data['subscriptionTotalOrders'] = subscriptionTotalOrders;
    if (workingHours != null) {
      data['workingHours'] = workingHours!.map((v) => v.toJson()).toList();
    }
    data['location'] = location;
    data['fcmToken'] = fcmToken;
    if (g != null) {
      data['g'] = g!.toJson();
    }
    data['hidephotos'] = hidephotos;
    data['reststatus'] = reststatus;
    data['isOpen'] = isOpen;
    if (filters != null) {
      data['filters'] = filters!.toJson();
    }
    data['reviewsCount'] = reviewsCount;
    data['photo'] = photo;
    data['description'] = description;
    data['walletAmount'] = walletAmount;
    data['closeDineTime'] = closeDineTime;
    data['zoneId'] = zoneId;
    data['createdAt'] = createdAt;
    data['longitude'] = longitude;
    data['enabledDiveInFuture'] = enabledDiveInFuture;
    data['restaurantCost'] = restaurantCost;
    if (deliveryCharge != null) {
      data['DeliveryCharge'] = deliveryCharge!.toJson();
    }
    if (adminCommission != null) {
      data['adminCommission'] = adminCommission!.toJson();
    }
    data['authorProfilePic'] = authorProfilePic;
    data['authorName'] = authorName;
    data['phonenumber'] = phonenumber;
    if (specialDiscount != null) {
      data['specialDiscount'] = specialDiscount!
          .map((v) => v.toJson())
          .toList();
    }
    data['specialDiscountEnable'] = specialDiscountEnable;
    data['coordinates'] = coordinates;
    data['reviewsSum'] = reviewsSum;
    data['photos'] = photos;
    data['title'] = title;
    data['categoryTitle'] = categoryTitle;
    data['latitude'] = latitude;
    data['isSelfDelivery'] = isSelfDelivery ?? false;
    data['vType'] = vType;
    data['distance'] = distance;
    data['isActive'] = isActive;
    return data;
  }
}

class WorkingHours {
  String? day;
  List<Timeslot>? timeslot;

  WorkingHours({this.day, this.timeslot});

  WorkingHours.fromJson(Map<String, dynamic> json) {
    day = json['day'];
    if (json['timeslot'] != null) {
      timeslot = <Timeslot>[];
      json['timeslot'].forEach((v) {
        timeslot!.add(Timeslot.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['day'] = day;
    if (timeslot != null) {
      data['timeslot'] = timeslot!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Timeslot {
  String? to;
  String? from;

  Timeslot({this.to, this.from});

  Timeslot.fromJson(Map<String, dynamic> json) {
    to = json['to'];
    from = json['from'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['to'] = to;
    data['from'] = from;
    return data;
  }
}

class G {
  String? geohash;
  GeoPoint? geopoint;

  G({this.geohash, this.geopoint});

  G.fromJson(Map<String, dynamic> json) {
    geohash = json['geohash'];
    if (json['geopoint'] != null) {
      if (json['geopoint'] is GeoPoint) {
        geopoint = json['geopoint'];
      } else if (json['geopoint'] is Map) {
        final map = json['geopoint'] as Map;
        geopoint = GeoPoint(
          (map['latitude'] as num).toDouble(),
          (map['longitude'] as num).toDouble(),
        );
      }
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['geohash'] = geohash;
    data['geopoint'] = geopoint;
    return data;
  }
}

class Filters {
  String? goodForLunch;
  String? outdoorSeating;
  String? liveMusic;
  String? vegetarianFriendly;
  String? goodForDinner;
  String? goodForBreakfast;
  String? freeWiFi;
  String? takesReservations;

  Filters({
    this.goodForLunch,
    this.outdoorSeating,
    this.liveMusic,
    this.vegetarianFriendly,
    this.goodForDinner,
    this.goodForBreakfast,
    this.freeWiFi,
    this.takesReservations,
  });

  Filters.fromJson(Map<String, dynamic> json) {
    goodForLunch = json['Good for Lunch'];
    outdoorSeating = json['Outdoor Seating'];
    liveMusic = json['Live Music'];
    vegetarianFriendly = json['Vegetarian Friendly'];
    goodForDinner = json['Good for Dinner'];
    goodForBreakfast = json['Good for Breakfast'];
    freeWiFi = json['Free Wi-Fi'];
    takesReservations = json['Takes Reservations'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['Good for Lunch'] = goodForLunch;
    data['Outdoor Seating'] = outdoorSeating;
    data['Live Music'] = liveMusic;
    data['Vegetarian Friendly'] = vegetarianFriendly;
    data['Good for Dinner'] = goodForDinner;
    data['Good for Breakfast'] = goodForBreakfast;
    data['Free Wi-Fi'] = freeWiFi;
    data['Takes Reservations'] = takesReservations;
    return data;
  }
}

class DeliveryCharge {
  num? minimumDeliveryChargesWithinKm;
  num? minimumDeliveryCharges;
  num? deliveryChargesPerKm;
  bool? vendorCanModify;
  num? itemTotalThreshold;
  num? baseDeliveryCharge;
  num? freeDeliveryDistanceKm;
  num? perKmChargeAboveFreeDistance;

  DeliveryCharge({
    this.minimumDeliveryChargesWithinKm,
    this.minimumDeliveryCharges,
    this.deliveryChargesPerKm,
    this.vendorCanModify,
    this.itemTotalThreshold,
    this.baseDeliveryCharge,
    this.freeDeliveryDistanceKm,
    this.perKmChargeAboveFreeDistance,
  });

  DeliveryCharge.fromJson(Map<String, dynamic> json) {
    minimumDeliveryChargesWithinKm = json['minimum_delivery_charges_within_km'];
    minimumDeliveryCharges = json['minimum_delivery_charges'];
    deliveryChargesPerKm = json['delivery_charges_per_km'];
    vendorCanModify = json['vendor_can_modify'];
    itemTotalThreshold = json['item_total_threshold'];
    baseDeliveryCharge = json['base_delivery_charge'];
    freeDeliveryDistanceKm = json['free_delivery_distance_km'];
    perKmChargeAboveFreeDistance = json['per_km_charge_above_free_distance'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['minimum_delivery_charges_within_km'] = minimumDeliveryChargesWithinKm;
    data['minimum_delivery_charges'] = minimumDeliveryCharges;
    data['delivery_charges_per_km'] = deliveryChargesPerKm;
    data['vendor_can_modify'] = vendorCanModify;
    data['item_total_threshold'] = itemTotalThreshold;
    data['base_delivery_charge'] = baseDeliveryCharge;
    data['free_delivery_distance_km'] = freeDeliveryDistanceKm;
    data['per_km_charge_above_free_distance'] = perKmChargeAboveFreeDistance;
    return data;
  }
}

class SpecialDiscount {
  String? day;
  List<SpecialDiscountTimeslot>? timeslot;

  SpecialDiscount({this.day, this.timeslot});

  SpecialDiscount.fromJson(Map<String, dynamic> json) {
    day = json['day'];
    if (json['timeslot'] != null) {
      timeslot = <SpecialDiscountTimeslot>[];
      json['timeslot'].forEach((v) {
        timeslot!.add(SpecialDiscountTimeslot.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['day'] = day;
    if (timeslot != null) {
      data['timeslot'] = timeslot!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class SpecialDiscountTimeslot {
  String? discount;
  String? discountType;
  String? to;
  String? type;
  String? from;

  SpecialDiscountTimeslot({
    this.discount,
    this.discountType,
    this.to,
    this.type,
    this.from,
  });

  SpecialDiscountTimeslot.fromJson(Map<String, dynamic> json) {
    discount = json['discount'];
    discountType = json['discount_type'];
    to = json['to'];
    type = json['type'];
    from = json['from'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['discount'] = discount;
    data['discount_type'] = discountType;
    data['to'] = to;
    data['type'] = type;
    data['from'] = from;
    return data;
  }
}
