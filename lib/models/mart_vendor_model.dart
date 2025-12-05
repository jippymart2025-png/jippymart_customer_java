import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jippymart_customer/models/admin_commission.dart';
import 'dart:convert' as jsons;

class MartVendorModel {
  String? id;
  String? title;
  String? description;
  String? location;
  String? phonenumber;
  String? countryCode;
  String? zoneId;
  String? vType;
  String? author;
  String? authorName;
  String? authorProfilePic;

  // Location & Coordinates
  double? latitude;
  double? longitude;
  GeoPoint? coordinates;

  // Business Settings
  bool? isOpen;
  bool? enabledDelivery;
  bool? hidephotos;
  bool? specialDiscountEnable;

  // Categories
  List<String>? categoryID;
  List<String>? categoryTitle;

  // Working Hours
  List<MartWorkingHours>? workingHours;

  // Special Discounts
  List<MartSpecialDiscount>? specialDiscount;

  // Admin Commission
  AdminCommission? adminCommission;

  // Timestamps
  Timestamp? createdAt;

  // Photos
  String? photo;
  List<String>? photos;

  // Filters (for future use)
  Map<String, String>? filters;

  // Subscription (for future use)
  String? subscriptionPlanId;
  Timestamp? subscriptionExpiryDate;
  String? subscriptionTotalOrders;

  // Additional Fields
  String? openDineTime;
  String? closeDineTime;
  num? restaurantCost;
  List<String>? restaurantMenuPhotos;

  MartVendorModel({
    this.id,
    this.title,
    this.description,
    this.location,
    this.phonenumber,
    this.countryCode,
    this.zoneId,
    this.vType,
    this.author,
    this.authorName,
    this.authorProfilePic,
    this.latitude,
    this.longitude,
    this.coordinates,
    this.isOpen,
    this.enabledDelivery,
    this.hidephotos,
    this.specialDiscountEnable,
    this.categoryID,
    this.categoryTitle,
    this.workingHours,
    this.specialDiscount,
    this.adminCommission,
    this.createdAt,
    this.photo,
    this.photos,
    this.filters,
    this.subscriptionPlanId,
    this.subscriptionExpiryDate,
    this.subscriptionTotalOrders,
    this.openDineTime,
    this.closeDineTime,
    this.restaurantCost,
    this.restaurantMenuPhotos,
  });

  MartVendorModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    title = json['title'];
    description = json['description'];
    location = json['location'];
    phonenumber = json['phonenumber']?.toString();
    countryCode = json['countryCode'];
    zoneId = json['zoneId'];
    vType = json['vType'];
    author = json['author'];
    authorName = json['authorName'];
    authorProfilePic = json['authorProfilePic'];

    latitude = json['latitude'] is num
        ? json['latitude']?.toDouble()
        : double.tryParse(json['latitude']?.toString() ?? '');
    longitude = json['longitude'] is num
        ? json['longitude']?.toDouble()
        : double.tryParse(json['longitude']?.toString() ?? '');

    // FIX: Properly handle coordinates
    if (json['coordinates'] != null) {
      if (json['coordinates'] is GeoPoint) {
        coordinates = json['coordinates'];
      } else if (json['coordinates'] is Map) {
        final coordsMap = json['coordinates'] as Map<String, dynamic>;
        final lat = coordsMap['latitude'] is num
            ? coordsMap['latitude']?.toDouble()
            : double.tryParse(coordsMap['latitude']?.toString() ?? '');
        final lng = coordsMap['longitude'] is num
            ? coordsMap['longitude']?.toDouble()
            : double.tryParse(coordsMap['longitude']?.toString() ?? '');

        if (lat != null && lng != null) {
          coordinates = GeoPoint(lat, lng);
        }
      }
    }

    // FIX: Boolean field handling - handle both bool and int types
    isOpen = _parseBool(json['isOpen']);
    enabledDelivery = _parseBool(json['enabledDelivery']);
    hidephotos = _parseBool(json['hidephotos']);
    specialDiscountEnable = _parseBool(json['specialDiscountEnable']);

    // Categories
    if (json['categoryID'] != null) {
      categoryID = List<String>.from(json['categoryID']);
    }
    if (json['categoryTitle'] != null) {
      categoryTitle = List<String>.from(json['categoryTitle']);
    }

    // Working Hours
    if (json['workingHours'] != null) {
      workingHours = <MartWorkingHours>[];
      json['workingHours'].forEach((v) {
        workingHours!.add(MartWorkingHours.fromJson(v));
      });
    }

    // Special Discounts
    if (json['specialDiscount'] != null) {
      specialDiscount = <MartSpecialDiscount>[];
      json['specialDiscount'].forEach((v) {
        specialDiscount!.add(MartSpecialDiscount.fromJson(v));
      });
    }

    // Admin Commission - Handle both Map and JSON String
    if (json['adminCommission'] != null) {
      if (json['adminCommission'] is Map) {
        // If it's already a Map (from Firebase or parsed JSON)
        adminCommission = AdminCommission.fromJson(json['adminCommission']);
      } else if (json['adminCommission'] is String) {
        // If it's a JSON String (from API)
        try {
          final commissionString = json['adminCommission'] as String;
          final commissionMap = jsons.json.decode(commissionString) as Map<String, dynamic>;
          adminCommission = AdminCommission.fromJson(commissionMap);
        } catch (e) {
          print('⚠️ Error parsing adminCommission string in MartVendorModel: $e');
          adminCommission = null;
        }
      } else {
        adminCommission = null;
      }
    } else {
      adminCommission = null;
    }

    // Timestamps - handle both String and Timestamp
    if (json['createdAt'] != null) {
      if (json['createdAt'] is String) {
        try {
          createdAt = Timestamp.fromDate(DateTime.parse(json['createdAt']));
        } catch (e) {
          print('⚠️ Error parsing createdAt: $e');
          createdAt = null;
        }
      } else if (json['createdAt'] is Timestamp) {
        createdAt = json['createdAt'];
      }
    }

    // Photos
    photo = json['photo'];
    if (json['photos'] != null) {
      photos = List<String>.from(json['photos']);
    }

    // Filters
    if (json['filters'] != null) {
      filters = Map<String, String>.from(json['filters']);
    }

    // Subscription
    subscriptionPlanId = json['subscriptionPlanId'];

    // Handle subscriptionExpiryDate similar to createdAt
    if (json['subscriptionExpiryDate'] != null) {
      if (json['subscriptionExpiryDate'] is String) {
        try {
          subscriptionExpiryDate = Timestamp.fromDate(
            DateTime.parse(json['subscriptionExpiryDate']),
          );
        } catch (e) {
          print('⚠️ Error parsing subscriptionExpiryDate: $e');
          subscriptionExpiryDate = null;
        }
      } else if (json['subscriptionExpiryDate'] is Timestamp) {
        subscriptionExpiryDate = json['subscriptionExpiryDate'];
      }
    }

    subscriptionTotalOrders = json['subscriptionTotalOrders']?.toString();

    // Additional Fields
    openDineTime = json['openDineTime'];
    closeDineTime = json['closeDineTime'];
    restaurantCost = json['restaurantCost'] is num
        ? json['restaurantCost']
        : (json['restaurantCost'] != null
              ? num.tryParse(json['restaurantCost'].toString())
              : null);
    if (json['restaurantMenuPhotos'] != null) {
      restaurantMenuPhotos = List<String>.from(json['restaurantMenuPhotos']);
    }
  }

  // Helper method to parse boolean values from both bool and int
  bool? _parseBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['title'] = title;
    data['description'] = description;
    data['location'] = location;
    data['phonenumber'] = phonenumber;
    data['countryCode'] = countryCode;
    data['zoneId'] = zoneId;
    data['vType'] = vType;
    data['author'] = author;
    data['authorName'] = authorName;
    data['authorProfilePic'] = authorProfilePic;

    // Location & Coordinates - FIXED
    data['latitude'] = latitude;
    data['longitude'] = longitude;

    // FIX: Convert GeoPoint back to Map for JSON serialization
    if (coordinates != null) {
      data['coordinates'] = {
        'latitude': coordinates!.latitude,
        'longitude': coordinates!.longitude,
      };
    } else {
      data['coordinates'] = null;
    }
    // Business Settings
    data['isOpen'] = isOpen;
    data['enabledDelivery'] = enabledDelivery;
    data['hidephotos'] = hidephotos;
    data['specialDiscountEnable'] = specialDiscountEnable;

    // Categories
    data['categoryID'] = categoryID;
    data['categoryTitle'] = categoryTitle;

    // Working Hours
    if (workingHours != null) {
      data['workingHours'] = workingHours!.map((v) => v.toJson()).toList();
    }

    // Special Discounts
    if (specialDiscount != null) {
      data['specialDiscount'] = specialDiscount!
          .map((v) => v.toJson())
          .toList();
    }

    // Admin Commission
    if (adminCommission != null) {
      data['adminCommission'] = adminCommission!.toJson();
    }

    // Timestamps
    data['createdAt'] = createdAt;

    // Photos
    data['photo'] = photo;
    data['photos'] = photos;

    // Filters
    data['filters'] = filters;

    // Subscription
    data['subscriptionPlanId'] = subscriptionPlanId;
    data['subscriptionExpiryDate'] = subscriptionExpiryDate;
    data['subscriptionTotalOrders'] = subscriptionTotalOrders;

    // Additional Fields
    data['openDineTime'] = openDineTime;
    data['closeDineTime'] = closeDineTime;
    data['restaurantCost'] = restaurantCost;
    data['restaurantMenuPhotos'] = restaurantMenuPhotos;

    return data;
  }

  // Helper methods
  bool get isMartVendor => vType == 'mart';

  bool get isOpenForBusiness => isOpen == true;

  bool get supportsDelivery => enabledDelivery == true;

  // Backward compatibility - map 'name' to 'title'
  String? get name => title;

  String get displayName => title ?? 'Unknown Mart';

  String get displayLocation => location ?? 'Location not specified';

  String get displayPhone => phonenumber ?? 'Phone not available';

  // Check if mart is currently open based on working hours
  bool get isCurrentlyOpen {
    if (!isOpenForBusiness) return false;
    if (workingHours == null || workingHours!.isEmpty)
      return true; // Assume open if no hours specified

    final now = DateTime.now();
    final currentDay = _getDayName(now.weekday);

    final todayHours = workingHours!.firstWhere(
      (hours) => hours.day == currentDay,
      orElse: () => MartWorkingHours(day: currentDay, timeslot: []),
    );

    if (todayHours.timeslot == null || todayHours.timeslot!.isEmpty)
      return true;

    final currentTime =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    return todayHours.timeslot!.any((slot) {
      final from = slot.from ?? '00:00';
      final to = slot.to ?? '23:59';
      return _isTimeBetween(currentTime, from, to);
    });
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Monday';
      case DateTime.tuesday:
        return 'Tuesday';
      case DateTime.wednesday:
        return 'Wednesday';
      case DateTime.thursday:
        return 'Thursday';
      case DateTime.friday:
        return 'Friday';
      case DateTime.saturday:
        return 'Saturday';
      case DateTime.sunday:
        return 'Sunday';
      default:
        return 'Monday';
    }
  }

  bool _isTimeBetween(String current, String from, String to) {
    return current.compareTo(from) >= 0 && current.compareTo(to) <= 0;
  }
}

class MartWorkingHours {
  String? day;
  List<MartTimeslot>? timeslot;

  MartWorkingHours({this.day, this.timeslot});

  MartWorkingHours.fromJson(Map<String, dynamic> json) {
    day = json['day'];
    if (json['timeslot'] != null) {
      timeslot = <MartTimeslot>[];
      json['timeslot'].forEach((v) {
        timeslot!.add(MartTimeslot.fromJson(v));
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

class MartTimeslot {
  String? from;
  String? to;

  MartTimeslot({this.from, this.to});

  MartTimeslot.fromJson(Map<String, dynamic> json) {
    from = json['from'];
    to = json['to'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['from'] = from;
    data['to'] = to;
    return data;
  }
}

class MartSpecialDiscount {
  String? day;
  List<MartTimeslot>? timeslot;

  MartSpecialDiscount({this.day, this.timeslot});

  MartSpecialDiscount.fromJson(Map<String, dynamic> json) {
    day = json['day'];
    if (json['timeslot'] != null) {
      timeslot = <MartTimeslot>[];
      json['timeslot'].forEach((v) {
        timeslot!.add(MartTimeslot.fromJson(v));
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
