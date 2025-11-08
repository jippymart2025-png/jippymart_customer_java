// models/story_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class StoryModel {
  String? id;
  String? vendorID;
  String? videoThumbnail;
  String? videoUrl;
  DateTime? createdAt;

  StoryModel({
    this.id,
    this.vendorID,
    this.videoThumbnail,
    this.videoUrl,
    this.createdAt,
  });

  StoryModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    vendorID = json['vendorID'];
    videoThumbnail = json['videoThumbnail'];
    videoUrl = json['videoUrl'];

    // Parse createdAt from string
    if (json['createdAt'] != null) {
      if (json['createdAt'] is String) {
        createdAt = DateTime.parse(json['createdAt']);
      } else if (json['createdAt'] is Timestamp) {
        createdAt = (json['createdAt'] as Timestamp).toDate();
      }
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['vendorID'] = vendorID;
    data['videoThumbnail'] = videoThumbnail;
    data['videoUrl'] = videoUrl;
    data['createdAt'] = createdAt?.toIso8601String();
    return data;
  }
}
