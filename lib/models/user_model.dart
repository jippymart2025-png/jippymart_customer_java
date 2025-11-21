import 'dart:convert';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jippymart_customer/models/subscription_plan_model.dart';

class UserModel {
  String? id;
  String? firstName;
  String? lastName;
  String? email;
  String? profilePictureURL;
  String? fcmToken;
  String? countryCode;
  String? firebaseId;
  String? phoneNumber;
  int? walletAmount;
  bool? active;
  bool? isActive;
  bool? isDocumentVerify;
  Timestamp? createdAt;
  String? role;
  UserLocation? location;
  UserBankDetails? userBankDetails;
  List<ShippingAddress>? shippingAddress;
  String? carName;
  String? carNumber;
  String? carPictureURL;
  List<dynamic>? inProgressOrderID;
  List<dynamic>? orderRequestData;
  String? vendorID;
  String? zoneId;
  num? rotation;
  String? appIdentifier;
  String? provider;
  String? subscriptionPlanId;
  Timestamp? subscriptionExpiryDate;
  SubscriptionPlanModel? subscriptionPlan;

  UserModel({
    this.firebaseId,
    this.id,
    this.firstName,
    this.lastName,
    this.active,
    this.isActive,
    this.isDocumentVerify,
    this.email,
    this.profilePictureURL,
    this.fcmToken,
    this.countryCode,
    this.phoneNumber,
    this.walletAmount,
    this.createdAt,
    this.role,
    this.location,
    this.shippingAddress,
    this.carName,
    this.carNumber,
    this.carPictureURL,
    this.inProgressOrderID,
    this.orderRequestData,
    this.vendorID,
    this.zoneId,
    this.rotation,
    this.appIdentifier,
    this.provider,
    this.subscriptionPlanId,
    this.subscriptionExpiryDate,
    this.subscriptionPlan,
  });

  String fullName() {
    return "${firstName ?? ''} ${lastName ?? ''}";
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    try {
      List<ShippingAddress>? addresses;
      if (json['shippingAddress'] != null) {
        if (json['shippingAddress'] is List) {
          addresses = (json['shippingAddress'] as List).map((e) {
            if (e is Map<String, dynamic>) {
              return ShippingAddress.fromJson(e);
            } else if (e is String) {
              try {
                return ShippingAddress.fromJson(jsonDecode(e));
              } catch (e) {
                log('Error parsing shipping address string: $e');
                return ShippingAddress();
              }
            }
            return ShippingAddress();
          }).toList();
        } else if (json['shippingAddress'] is Map) {
          addresses = [
            ShippingAddress.fromJson(
              json['shippingAddress'] as Map<String, dynamic>,
            ),
          ];
        } else if (json['shippingAddress'] is String) {
          try {
            addresses = [
              ShippingAddress.fromJson(jsonDecode(json['shippingAddress'])),
            ];
          } catch (e) {
            log('Error parsing shipping address string: $e');
            addresses = [];
          }
        } else {
          addresses = [];
        }
      }

      return UserModel(
        id: json['id']?.toString(),
        firebaseId: json['firebase_id']?.toString(),
        // Added null safety
        email: json['email']?.toString(),
        firstName: json['firstName']?.toString(),
        lastName: json['lastName']?.toString(),
        profilePictureURL: json['profilePictureURL']?.toString(),
        fcmToken: json['fcmToken']?.toString(),
        countryCode: json['countryCode']?.toString(),
        phoneNumber: json['phoneNumber']?.toString(),
        walletAmount: (json['wallet_amount'] is num)
            ? (json['wallet_amount'] as num).toInt()
            : 0,
        createdAt: _parseTimestamp(json['createdAt']),
        active: json['active'] as bool?,
        isActive: json['isActive'] as bool?,
        role: json['role']?.toString(),
        isDocumentVerify: json['isDocumentVerify'] as bool?,
        zoneId: json['zoneId']?.toString(),
        appIdentifier: json['appIdentifier']?.toString(),
        provider: json['provider']?.toString(),
        shippingAddress: addresses,
      );
    } catch (e) {
      log('Error converting user data: $e');
      rethrow;
    }
  }

  static Timestamp? _parseTimestamp(dynamic value) {
    if (value == null) return null;

    if (value is Timestamp) return value;

    if (value is String) {
      try {
        DateTime date = DateTime.tryParse(value) ?? DateTime.now();
        return Timestamp.fromDate(date);
      } catch (_) {
        return null;
      }
    }

    if (value is int) {
      // Treat as seconds if length == 10, milliseconds otherwise
      if (value.toString().length == 10) {
        return Timestamp(value, 0); // seconds, nanoseconds
      } else {
        return Timestamp.fromMillisecondsSinceEpoch(value);
      }
    }

    if (value is Map && value['_seconds'] != null) {
      return Timestamp(value['_seconds'], value['_nanoseconds'] ?? 0);
    }

    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'firebase_id': firebaseId,
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'profilePictureURL': profilePictureURL,
      'fcmToken': fcmToken,
      'countryCode': countryCode,
      'phoneNumber': phoneNumber,
      'wallet_amount': walletAmount,
      'createdAt': createdAt,
      'active': active,
      'isActive': isActive,
      'role': role,
      'isDocumentVerify': isDocumentVerify,
      'zoneId': zoneId,
      'appIdentifier': appIdentifier,
      'provider': provider,
      'shippingAddress': shippingAddress?.map((e) => e.toJson()).toList(),
    };
  }
}

class UserLocation {
  double? latitude;
  double? longitude;

  UserLocation({this.latitude, this.longitude});

  UserLocation.fromJson(Map<String, dynamic> json) {
    // Handle both int and double types for latitude and longitude
    latitude = _convertToDouble(json['latitude']);
    longitude = _convertToDouble(json['longitude']);
  }

  // Helper method to convert dynamic values to double
  static double? _convertToDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['latitude'] = latitude;
    data['longitude'] = longitude;
    return data;
  }
}

class ShippingAddress {
  String? id;
  String? address;
  String? addressAs;
  String? landmark;
  String? locality;
  UserLocation? location;
  bool? isDefault;
  String? zoneId;
  double? latitude;
  double? longitude;

  ShippingAddress({
    this.id,
    this.address,
    this.addressAs,
    this.landmark,
    this.locality,
    this.location,
    this.isDefault,
    this.zoneId,
    this.latitude,
    this.longitude,
  });

  // IMPROVED PARSING WITH BETTER NULL SAFETY
  factory ShippingAddress.fromJson(Map<String, dynamic> json) {
    double? lat;
    double? lng;

    if (json['location'] != null && json['location'] is Map) {
      final locationData = json['location'] as Map<String, dynamic>;
      lat = _parseDouble(locationData['latitude']);
      lng = _parseDouble(locationData['longitude']);
    }
    if (lat == null) lat = _parseDouble(json['latitude']);
    if (lng == null) lng = _parseDouble(json['longitude']);
    UserLocation? location;
    if (lat != null && lng != null) {
      location = UserLocation(latitude: lat, longitude: lng);
    }
    // FIX: Handle int/string to bool conversion for isDefault
    bool? isDefaultValue;
    if (json['isDefault'] != null) {
      if (json['isDefault'] is bool) {
        isDefaultValue = json['isDefault'] as bool;
      } else if (json['isDefault'] is int) {
        isDefaultValue = (json['isDefault'] as int) == 1;
      } else if (json['isDefault'] is String) {
        isDefaultValue =
            json['isDefault'] == '1' ||
            json['isDefault'].toLowerCase() == 'true';
      }
    }

    return ShippingAddress(
      id: json['id']?.toString(),
      address: json['address']?.toString(),
      addressAs: json['addressAs']?.toString(),
      landmark: json['landmark']?.toString(),
      locality: json['locality']?.toString(),
      isDefault: isDefaultValue ?? false,
      // Default to false if null
      zoneId: json['zoneId']?.toString(),
      latitude: lat,
      longitude: lng,
      location: location,
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};

    data['id'] = id;
    data['address'] = address;
    data['addressAs'] = addressAs;
    data['landmark'] = landmark;
    data['locality'] = locality;
    data['isDefault'] = isDefault;
    data['zoneId'] = zoneId;
    data['latitude'] = latitude;
    data['longitude'] = longitude;

    // Always include location object for consistency
    if (location != null) {
      data['location'] = location!.toJson();
    } else if (latitude != null && longitude != null) {
      data['location'] = {'latitude': latitude, 'longitude': longitude};
    }

    return data;
  }

  // GETTERS WITH FALLBACK LOGIC
  double? get effectiveLatitude => location?.latitude ?? latitude;

  double? get effectiveLongitude => location?.longitude ?? longitude;

  bool get hasCoordinates =>
      effectiveLatitude != null && effectiveLongitude != null;

  /// Build formatted full address
  String getFullAddress() {
    List<String> addressParts = [];

    if (address != null && address!.trim().isNotEmpty) {
      addressParts.add(address!.trim());
    }
    if (locality != null &&
        locality!.trim().isNotEmpty &&
        locality != address) {
      addressParts.add(locality!.trim());
    }
    if (landmark != null &&
        landmark!.trim().isNotEmpty &&
        landmark != address &&
        landmark != locality) {
      addressParts.add(landmark!.trim());
    }

    // Remove duplicates
    List<String> uniqueParts = [];
    for (String part in addressParts) {
      if (!uniqueParts.contains(part)) {
        uniqueParts.add(part);
      }
    }

    final full = uniqueParts.join(", ");
    return full.isEmpty ? "Current Location" : full;
  }

  ShippingAddress copyWith({
    String? id,
    String? address,
    String? addressAs,
    String? landmark,
    String? locality,
    UserLocation? location,
    bool? isDefault,
    String? zoneId,
    double? latitude,
    double? longitude,
  }) {
    return ShippingAddress(
      id: id ?? this.id,
      address: address ?? this.address,
      addressAs: addressAs ?? this.addressAs,
      landmark: landmark ?? this.landmark,
      locality: locality ?? this.locality,
      location: location ?? this.location,
      isDefault: isDefault ?? this.isDefault,
      zoneId: zoneId ?? this.zoneId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}

class UserBankDetails {
  String bankName;
  String branchName;
  String holderName;
  String accountNumber;
  String otherDetails;

  UserBankDetails({
    this.bankName = '',
    this.otherDetails = '',
    this.branchName = '',
    this.accountNumber = '',
    this.holderName = '',
  });

  factory UserBankDetails.fromJson(Map<String, dynamic> parsedJson) {
    return UserBankDetails(
      bankName: parsedJson['bankName'] ?? '',
      branchName: parsedJson['branchName'] ?? '',
      holderName: parsedJson['holderName'] ?? '',
      accountNumber: parsedJson['accountNumber'] ?? '',
      otherDetails: parsedJson['otherDetails'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bankName': bankName,
      'branchName': branchName,
      'holderName': holderName,
      'accountNumber': accountNumber,
      'otherDetails': otherDetails,
    };
  }
}
