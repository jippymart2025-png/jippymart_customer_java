import 'package:flutter/cupertino.dart';

enum EventStatus { upcoming, past }

@immutable
class CommunityEvent {
  final String title;
  final String description;
  final String date;
  final String time;
  final String location;
  final int goingCount;
  final Color color;
  final String? images;
  final EventStatus status;
  final bool isGoing;

  const CommunityEvent({
    required this.title,
    required this.description,
    required this.date,
    required this.time,
    required this.location,
    required this.goingCount,
    required this.color,
    this.images,
    required this.status,
    this.isGoing = false,
  });

  CommunityEvent copyWith({bool? isGoing, int? goingCount}) {
    return CommunityEvent(
      title: title,
      description: description,
      date: date,
      time: time,
      location: location,
      goingCount: goingCount ?? this.goingCount,
      color: color,
      images: images,
      status: status,
      isGoing: isGoing ?? this.isGoing,
    );
  }
}
