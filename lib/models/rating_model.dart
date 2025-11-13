import 'dart:convert';

class RatingModel {
  String? id;
  double? rating;
  List<dynamic>? photos;
  String? comment;
  String? orderId;
  String? customerId;
  String? vendorId;
  String? productId;
  String? driverId;
  String? uname;
  String? profile;
  Map<String, dynamic>? reviewAttributes;
  String? createdAt;

  RatingModel({
    this.id,
    this.comment,
    this.photos,
    this.rating,
    this.orderId,
    this.vendorId,
    this.productId,
    this.driverId,
    this.customerId,
    this.uname,
    this.createdAt,
    this.reviewAttributes,
    this.profile,
  });

  factory RatingModel.fromJson(Map<String, dynamic> parsedJson) {
    // Helper function to parse string to double safely
    double? parseRating(dynamic ratingValue) {
      if (ratingValue == null) return null;
      if (ratingValue is double) return ratingValue;
      if (ratingValue is int) return ratingValue.toDouble();
      if (ratingValue is String) {
        return double.tryParse(ratingValue);
      }
      return null;
    }

    // Parse reviewAttributes
    Map<String, dynamic> reviewAttrs = {};
    if (parsedJson['reviewAttributes'] != null) {
      if (parsedJson['reviewAttributes'] is String) {
        try {
          final decoded = json.decode(parsedJson['reviewAttributes']);
          if (decoded is Map) {
            reviewAttrs = Map<String, dynamic>.from(decoded);
          }
        } catch (e) {
          reviewAttrs = {};
        }
      } else if (parsedJson['reviewAttributes'] is Map) {
        reviewAttrs = Map<String, dynamic>.from(parsedJson['reviewAttributes']);
      }
    }

    // Parse photos
    List<dynamic> photosList = [];
    if (parsedJson['photos'] != null) {
      if (parsedJson['photos'] is String) {
        try {
          final decoded = json.decode(parsedJson['photos']);
          if (decoded is List) {
            photosList = decoded;
          }
        } catch (e) {
          photosList = [];
        }
      } else if (parsedJson['photos'] is List) {
        photosList = List<dynamic>.from(parsedJson['photos']);
      }
    }

    // Parse createdAt - remove extra quotes if present
    String? createdAt = parsedJson['createdAt']?.toString();
    if (createdAt != null &&
        createdAt.startsWith('"') &&
        createdAt.endsWith('"')) {
      createdAt = createdAt.substring(1, createdAt.length - 1);
    }

    return RatingModel(
      comment: parsedJson['comment'] ?? '',
      photos: photosList,
      rating: parseRating(parsedJson['rating']),
      id: parsedJson['id'] ?? parsedJson['Id'] ?? '',
      orderId: parsedJson['orderid'] ?? parsedJson['orderId'] ?? '',
      vendorId: parsedJson['VendorId'] ?? parsedJson['vendorId'] ?? '',
      productId: parsedJson['productId'] ?? '',
      driverId: parsedJson['driverId'] ?? '',
      customerId: parsedJson['CustomerId'] ?? parsedJson['customerId'] ?? '',
      uname: parsedJson['uname'] ?? '',
      reviewAttributes: reviewAttrs,
      createdAt: createdAt ?? '',
      profile: parsedJson['profile'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'comment': comment,
      'photos': photos ?? [],
      'rating': rating,
      'id': id,
      'orderid': orderId,
      'VendorId': vendorId,
      'productId': productId,
      'driverId': driverId,
      'CustomerId': customerId,
      'uname': uname,
      'profile': profile,
      'reviewAttributes': json.encode(reviewAttributes ?? {}),
      'createdAt': createdAt,
    };
  }

  @override
  String toString() {
    return 'RatingModel(id: $id, rating: $rating, productId: $productId, orderId: $orderId)';
  }
}
