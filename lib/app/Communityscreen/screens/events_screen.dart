import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/eventmodels.dart';
import '../providers/eventproviders.dart';
import '../theme/app_theme.dart';
import '../theme/responsive.dart';

class EventsScreen extends ConsumerWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(filteredEventsProvider);
    final selectedTab = ref.watch(selectedEventTabProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Events', style: AppText.title),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(Icons.add_rounded, color: AppColors.textPrimary),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.symmetric(
            horizontal: context.pagePadding,
            vertical: AppSpacing.md,
          ),
          children: [
            _EventTabs(
              selected: selectedTab,
              onChanged: (s) =>
                  ref.read(selectedEventTabProvider.notifier).state = s,
            ),
            const SizedBox(height: AppSpacing.lg),
            if (events.isEmpty)
              const _EmptyEvents()
            else
              ...events.map((event) {
                final index = ref.read(eventsProvider).indexOf(event);
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: _EventCard(
                    event: event,
                    onToggleGoing: () =>
                        ref.read(eventsProvider.notifier).toggleGoing(index),
                  ),
                );
              }),
            const SizedBox(height: AppSpacing.sm),
            const _SubmitIdeaCard(),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

class _EventTabs extends StatelessWidget {
  final EventStatus selected;
  final ValueChanged<EventStatus> onChanged;

  const _EventTabs({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: EventStatus.values.map((status) {
          final isActive = status == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(status),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.success : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                alignment: Alignment.center,
                child: Text(
                  status == EventStatus.upcoming ? 'Upcoming' : 'Past',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: isActive ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final CommunityEvent event;
  final VoidCallback onToggleGoing;

  const _EventCard({required this.event, required this.onToggleGoing});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: AppDecorations.card(radius: AppRadius.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: event.images != null && event.images!.isNotEmpty
                  ? Image.network(
                      event.images!,
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.medium,
                      frameBuilder:
                          (context, child, frame, wasSynchronouslyLoaded) {
                            if (wasSynchronouslyLoaded || frame != null) {
                              return AnimatedSwitcher(
                                duration: const Duration(milliseconds: 250),
                                child: child,
                              );
                            }

                            return _eventPlaceholder();
                          },
                      errorBuilder: (_, __, ___) => _eventPlaceholder(),
                    )
                  : _eventPlaceholder(),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.title, style: AppText.subtitle),
                const SizedBox(height: 2),
                Text(event.description, style: AppText.body),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      size: 13,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      event.date,
                      style: AppText.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(
                      Icons.access_time_rounded,
                      size: 13,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      event.time,
                      style: AppText.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      size: 13,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      event.location,
                      style: AppText.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      Icons.people_alt_rounded,
                      size: 14,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${event.goingCount} Going',
                      style: AppText.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    if (event.status == EventStatus.upcoming)
                      _GoingButton(
                        isGoing: event.isGoing,
                        onTap: onToggleGoing,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget _eventPlaceholder() {
  return Container(
    decoration: BoxDecoration(
      color: const Color(0xFFF3F4F6),
      borderRadius: BorderRadius.circular(14),
    ),
    child: const Center(
      child: Icon(Icons.event_rounded, size: 24, color: Color(0xFF9CA3AF)),
    ),
  );
}

class _GoingButton extends StatelessWidget {
  final bool isGoing;
  final VoidCallback onTap;

  const _GoingButton({required this.isGoing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isGoing ? AppColors.successSoft : AppColors.success,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: isGoing ? Border.all(color: AppColors.success) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isGoing)
              const Padding(
                padding: EdgeInsets.only(right: 4),
                child: Icon(
                  Icons.check_rounded,
                  size: 14,
                  color: AppColors.success,
                ),
              ),
            Text(
              "I'm Going",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isGoing ? AppColors.success : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubmitIdeaCard extends StatelessWidget {
  const _SubmitIdeaCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.successSoft,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Have an event idea?', style: AppText.subtitle),
                const SizedBox(height: 2),
                Text('Suggest events for our community', style: AppText.body),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Submit Idea',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          const Icon(
            Icons.emoji_people_rounded,
            color: AppColors.success,
            size: 42,
          ),
        ],
      ),
    );
  }
}

class _EmptyEvents extends StatelessWidget {
  const _EmptyEvents();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      alignment: Alignment.center,
      decoration: AppDecorations.outlinedCard(),
      child: Column(
        children: [
          const Icon(
            Icons.event_busy_rounded,
            color: AppColors.textMuted,
            size: 28,
          ),
          const SizedBox(height: 8),
          Text('No events here yet', style: AppText.body),
        ],
      ),
    );
  }
}
