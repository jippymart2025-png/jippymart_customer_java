// models/story_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class StoryModel {
  String? id;
  String? vendorID;
  String? videoThumbnail;
  List<String> videoUrls;
  DateTime? createdAt;

  StoryModel({
    this.id,
    this.vendorID,
    this.videoThumbnail,
    List<String>? videoUrls,
    this.createdAt,
  }) : videoUrls = videoUrls ?? [];

  factory StoryModel.fromJson(Map<String, dynamic> json) {
    final StoryModel model = StoryModel(
      id: json['id'],
      vendorID: json['vendorID'],
      videoThumbnail: json['videoThumbnail'] ?? json['video_thumbnail'],
    );

    final dynamic videoPayload = json['videoUrl'] ?? json['video_url'];
    model.videoUrls = _parseVideoPayload(videoPayload);

    // If thumbnail wasn't provided separately, try to derive it from payload map/list entries
    if (model.videoThumbnail == null) {
      if (videoPayload is Map<String, dynamic>) {
        model.videoThumbnail = videoPayload['videoThumbnail']?.toString() ?? videoPayload['video_thumbnail']?.toString();
      } else if (videoPayload is List) {
        for (final item in videoPayload) {
          if (item is Map<String, dynamic>) {
            model.videoThumbnail = item['videoThumbnail']?.toString() ?? item['video_thumbnail']?.toString();
            if (model.videoThumbnail != null) break;
          }
        }
      }
    }

    // Parse createdAt from string or timestamp
    if (json['createdAt'] != null) {
      if (json['createdAt'] is String) {
        model.createdAt = DateTime.tryParse(json['createdAt']);
      } else if (json['createdAt'] is Timestamp) {
        model.createdAt = (json['createdAt'] as Timestamp).toDate();
      }
    }
    return model;
  }

  static List<String> _parseVideoPayload(dynamic payload) {
    if (payload == null) return [];

    if (payload is List) {
      return payload
          .map((entry) {
            if (entry is String) return entry;
            if (entry is Map<String, dynamic>) {
              return entry['url']?.toString();
            }
            return entry?.toString();
          })
          .whereType<String>()
          .where((url) => url.isNotEmpty)
          .toList();
    }

    if (payload is Map<String, dynamic>) {
      final String? url = payload['url']?.toString();
      return url != null && url.isNotEmpty ? [url] : [];
    }

    final String url = payload.toString();
    return url.isNotEmpty ? [url] : [];
  }

  String? get primaryVideoUrl => videoUrls.isNotEmpty ? videoUrls.first : null;

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['vendorID'] = vendorID;
    data['videoThumbnail'] = videoThumbnail;
    data['videoUrl'] = videoUrls;
    data['createdAt'] = createdAt?.toIso8601String();
    return data;
  }
}
