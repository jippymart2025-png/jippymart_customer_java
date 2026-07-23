import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/eventmodels.dart';
import '../theme/app_theme.dart' show AppColors;

class EventsNotifier extends StateNotifier<List<CommunityEvent>> {
  EventsNotifier() : super(_seed);

  static final _seed = [
    CommunityEvent(
      title: 'Community Potluck',
      description: 'Bring a dish, share happiness!',
      date: '25 May, Sun',
      time: '7:00 PM',
      location: 'Club House',
      goingCount: 32,
      color: AppColors.accentOrange,
      images: "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=800",
      status: EventStatus.upcoming,
    ),
    CommunityEvent(
      title: 'Yoga Morning',
      description: "Let's stay healthy together",
      date: '1 Jun, Sun',
      time: '7:00 AM',
      location: 'Park Area',
      goingCount: 18,
      color: AppColors.success,
      images: "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=800",
      status: EventStatus.upcoming,
    ),
    CommunityEvent(
      title: "Children's Day Special",
      description: 'Fun games and snacks',
      date: '15 Jun, Sun',
      time: '5:00 PM',
      location: 'Club House',
      goingCount: 27,
      color: AppColors.warning,
      images: "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=800",
      status: EventStatus.upcoming,
    ),
  ];

  void toggleGoing(int index) {
    final event = state[index];
    final nowGoing = !event.isGoing;
    final updated = event.copyWith(
      isGoing: nowGoing,
      goingCount: event.goingCount + (nowGoing ? 1 : -1),
    );
    state = [...state]..[index] = updated;
  }
}

final eventsProvider =
    StateNotifierProvider<EventsNotifier, List<CommunityEvent>>(
      (ref) => EventsNotifier(),
    );

final selectedEventTabProvider = StateProvider<EventStatus>(
  (ref) => EventStatus.upcoming,
);

final filteredEventsProvider = Provider<List<CommunityEvent>>((ref) {
  final events = ref.watch(eventsProvider);
  final tab = ref.watch(selectedEventTabProvider);
  return events.where((e) => e.status == tab).toList();
});
