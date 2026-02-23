class DailyCheckinModel {
  String? userId;
  DateTime? date; // date only (calendar day)
  int? streakDayNumber; // 1–30
  int? coinsAwarded;
  DateTime? createdAt;

  DailyCheckinModel({
    this.userId,
    this.date,
    this.streakDayNumber,
    this.coinsAwarded,
    this.createdAt,
  });

  bool get checkedInToday {
    if (date == null) return false;
    final now = DateTime.now();
    return date!.year == now.year &&
        date!.month == now.month &&
        date!.day == now.day;
  }

  DailyCheckinModel.fromJson(Map<String, dynamic> json) {
    userId = json['userId']?.toString();
    if (json['date'] != null) {
      if (json['date'] is String) {
        date = DateTime.tryParse((json['date'] as String).split('T').first);
      } else if (json['date'] is DateTime) {
        date = (json['date'] as DateTime).toUtc();
      }
    }
    streakDayNumber = json['streakDayNumber'] is int
        ? json['streakDayNumber'] as int
        : int.tryParse(json['streakDayNumber']?.toString() ?? '0');
    coinsAwarded = json['coinsAwarded'] is int
        ? json['coinsAwarded'] as int
        : int.tryParse(json['coinsAwarded']?.toString() ?? '0');
    if (json['createdAt'] != null) {
      if (json['createdAt'] is String) {
        createdAt = DateTime.tryParse(json['createdAt'] as String);
      } else if (json['createdAt'] is DateTime) {
        createdAt = json['createdAt'] as DateTime;
      }
    }
    // Support alternative API keys
    if (streakDayNumber == 0 && json['streak_day'] != null) {
      streakDayNumber = json['streak_day'] is int
          ? json['streak_day'] as int
          : int.tryParse(json['streak_day']?.toString() ?? '0');
    }
    if (coinsAwarded == 0 && json['coins_awarded'] != null) {
      coinsAwarded = json['coins_awarded'] is int
          ? json['coins_awarded'] as int
          : int.tryParse(json['coins_awarded']?.toString() ?? '0');
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['userId'] = userId;
    data['date'] = date != null
        ? '${date!.year}-${date!.month.toString().padLeft(2, '0')}-${date!.day.toString().padLeft(2, '0')}'
        : null;
    data['streakDayNumber'] = streakDayNumber;
    data['coinsAwarded'] = coinsAwarded;
    data['createdAt'] = createdAt?.toIso8601String();
    return data;
  }
}
