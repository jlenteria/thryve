import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/date_utils.dart';

// Every persisted data model lives in this file: Milestone, Goal,
// DisciplineTask, UserProfile, WallItem, WeeklyReview and AppState, plus the
// plain value types passed between screens and view models (WeekSummary and
// the Goal/Milestone/Wall drafts).

enum MilestoneStatus {
  pending('Pending'),
  inProgress('In progress'),
  completed('Completed');

  const MilestoneStatus(this.label);

  final String label;
}

class Milestone {
  const Milestone({
    required this.id,
    required this.title,
    this.status = MilestoneStatus.pending,
    this.note,
    this.valueLabel,
    this.completedAt,
  });

  factory Milestone.fromJson(Map<String, dynamic> json) => Milestone(
    id: json['id'] as String,
    title: json['title'] as String,
    status: MilestoneStatus.values.firstWhere(
      (MilestoneStatus value) => value.name == json['status'],
      orElse: () => MilestoneStatus.pending,
    ),
    note: (json['note'] ?? json['subtitle']) as String?,
    valueLabel: (json['valueLabel'] ?? json['amountLabel']) as String?,
    completedAt: DateTime.tryParse(json['completedAt'] as String? ?? ''),
  );

  final String id;
  final String title;
  final MilestoneStatus status;

  /// Free-form details such as "Due Friday" or "14 / 20 sent".
  final String? note;

  /// Optional value shown on the trailing edge, e.g. "₱5,000".
  final String? valueLabel;
  final DateTime? completedAt;

  bool get isCompleted => status == MilestoneStatus.completed;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'title': title,
    'status': status.name,
    'note': note,
    'valueLabel': valueLabel,
    'completedAt': completedAt?.toIso8601String(),
  };
}

enum GoalTrackingType { money, progress }

class Goal {
  const Goal({
    required this.id,
    required this.title,
    required this.trackingType,
    required this.createdAt,
    this.currentAmount = 0,
    this.targetAmount = 0,
    this.currencySymbol = AppConstants.defaultCurrency,
    this.why,
    this.image,
    this.milestones = const <Milestone>[],
    this.achievedAt,
  });

  factory Goal.fromJson(Map<String, dynamic> json) {
    final DateTime createdAt =
        DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now();
    DateTime? achievedAt = DateTime.tryParse(
      json['achievedAt'] as String? ?? '',
    );
    // Earlier builds only stored a flag.
    if (achievedAt == null && json['isAchieved'] == true) {
      achievedAt = createdAt;
    }
    return Goal(
      id: json['id'] as String,
      title: json['title'] as String,
      trackingType: GoalTrackingType.values.firstWhere(
        (GoalTrackingType value) => value.name == json['trackingType'],
        orElse: () => GoalTrackingType.money,
      ),
      createdAt: createdAt,
      currentAmount: _amountFrom(json['currentAmount']),
      targetAmount: _amountFrom(json['targetAmount']),
      currencySymbol:
          json['currencySymbol'] as String? ?? AppConstants.defaultCurrency,
      why: json['why'] as String?,
      image: (json['image'] ?? json['whyImageUrl']) as String?,
      milestones: (json['milestones'] as List<dynamic>? ?? <dynamic>[])
          .map(
            (dynamic value) =>
                Milestone.fromJson(value as Map<String, dynamic>),
          )
          .toList(),
      achievedAt: achievedAt,
    );
  }

  /// Stored amounts must be finite and non-negative to be safe to format.
  static double _amountFrom(Object? value) {
    final double? amount = value is num ? value.toDouble() : null;
    return amount == null || !amount.isFinite || amount < 0 ? 0 : amount;
  }

  final String id;
  final String title;
  final GoalTrackingType trackingType;
  final DateTime createdAt;
  final double currentAmount;
  final double targetAmount;
  final String currencySymbol;
  final String? why;
  final String? image;
  final List<Milestone> milestones;
  final DateTime? achievedAt;

  bool get isAchieved => achievedAt != null;

  bool get isFinancial => trackingType == GoalTrackingType.money;

  int get completedMilestones => milestones
      .where((Milestone item) => item.status == MilestoneStatus.completed)
      .length;

  bool get allMilestonesComplete =>
      milestones.isNotEmpty && completedMilestones == milestones.length;

  /// Amounts are cents-clean by construction, but a cent is not exact in
  /// binary, so the target comparison allows half a cent of slack.
  static const double _amountTolerance = 0.005;

  bool get targetReached =>
      isFinancial &&
      targetAmount > 0 &&
      currentAmount >= targetAmount - _amountTolerance;

  double get progress {
    if (isAchieved) {
      return 1;
    }
    if (isFinancial) {
      return targetAmount > 0
          ? (currentAmount / targetAmount).clamp(0.0, 1.0)
          : 0;
    }
    return milestones.isEmpty ? 0 : completedMilestones / milestones.length;
  }

  int get progressPercent => (progress * 100).round();

  /// Calendar days from creation to completion (or to today while active),
  /// counting the first day.
  ///
  /// [now] comes from the app clock so tests and the UI agree.
  int daysActiveAt(DateTime now) =>
      DateKeys.daysBetween(createdAt, achievedAt ?? now) + 1;

  Goal copyWith({
    String? title,
    GoalTrackingType? trackingType,
    double? currentAmount,
    double? targetAmount,
    String? why,
    String? Function()? image,
    List<Milestone>? milestones,
    DateTime? Function()? achievedAt,
  }) => Goal(
    id: id,
    title: title ?? this.title,
    trackingType: trackingType ?? this.trackingType,
    createdAt: createdAt,
    currentAmount: currentAmount ?? this.currentAmount,
    targetAmount: targetAmount ?? this.targetAmount,
    currencySymbol: currencySymbol,
    why: why ?? this.why,
    image: image != null ? image() : this.image,
    milestones: milestones ?? this.milestones,
    achievedAt: achievedAt != null ? achievedAt() : this.achievedAt,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'title': title,
    'trackingType': trackingType.name,
    'createdAt': createdAt.toIso8601String(),
    'currentAmount': currentAmount,
    'targetAmount': targetAmount,
    'currencySymbol': currencySymbol,
    'why': why,
    'image': image,
    'milestones': milestones.map((Milestone m) => m.toJson()).toList(),
    'achievedAt': achievedAt?.toIso8601String(),
  };
}

/// A daily practice. [completed] reflects today only and is reset each day.
class DisciplineTask {
  const DisciplineTask({
    required this.id,
    required this.title,
    this.completed = false,
  });

  factory DisciplineTask.fromJson(Map<String, dynamic> json) => DisciplineTask(
    id: json['id'] as String,
    title: json['title'] as String,
    completed: json['completed'] as bool? ?? false,
  );

  final String id;
  final String title;
  final bool completed;

  DisciplineTask copyWith({String? title, bool? completed}) => DisciplineTask(
    id: id,
    title: title ?? this.title,
    completed: completed ?? this.completed,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'title': title,
    'completed': completed,
  };
}

class UserProfile {
  const UserProfile({
    required this.name,
    this.avatar,
    this.bigDream,
    this.anchor,
    this.anchorImage,
    this.reminderHour = 8,
    this.reminderMinute = 0,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final TimeOfDay reminder = json.containsKey('reminderHour')
        ? TimeOfDay(
            hour: json['reminderHour'] as int? ?? 8,
            minute: json['reminderMinute'] as int? ?? 0,
          )
        : _parseLegacyFocusWindow(json['focusWindow'] as String?);
    return UserProfile(
      name: json['name'] as String? ?? '',
      avatar: (json['avatar'] ?? json['avatarUrl']) as String?,
      bigDream: json['bigDream'] as String?,
      anchor: json['anchor'] as String?,
      anchorImage: (json['anchorImage'] ?? json['anchorImageUrl']) as String?,
      reminderHour: reminder.hour,
      reminderMinute: reminder.minute,
    );
  }

  static const UserProfile empty = UserProfile(name: '');

  final String name;

  /// Image reference understood by `AppImage` (local file, data URI or URL).
  final String? avatar;
  final String? bigDream;
  final String? anchor;
  final String? anchorImage;
  final int reminderHour;
  final int reminderMinute;

  TimeOfDay get reminderTime =>
      TimeOfDay(hour: reminderHour, minute: reminderMinute);

  String get anchorOrDefault =>
      anchor?.trim().isNotEmpty == true ? anchor!.trim() : 'your purpose';

  UserProfile copyWith({
    String? name,
    String? Function()? avatar,
    String? bigDream,
    String? anchor,
    String? Function()? anchorImage,
    TimeOfDay? reminderTime,
  }) => UserProfile(
    name: name ?? this.name,
    avatar: avatar != null ? avatar() : this.avatar,
    bigDream: bigDream ?? this.bigDream,
    anchor: anchor ?? this.anchor,
    anchorImage: anchorImage != null ? anchorImage() : this.anchorImage,
    reminderHour: reminderTime?.hour ?? reminderHour,
    reminderMinute: reminderTime?.minute ?? reminderMinute,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'name': name,
    'avatar': avatar,
    'bigDream': bigDream,
    'anchor': anchor,
    'anchorImage': anchorImage,
    'reminderHour': reminderHour,
    'reminderMinute': reminderMinute,
  };

  /// Earlier builds stored the reminder as a formatted string, e.g. "8:00 AM".
  static TimeOfDay _parseLegacyFocusWindow(String? value) {
    const TimeOfDay fallback = TimeOfDay(hour: 8, minute: 0);
    if (value == null) {
      return fallback;
    }
    final RegExpMatch? match = RegExp(
      r'(\d{1,2}):(\d{2})\s*(AM|PM)?',
      caseSensitive: false,
    ).firstMatch(value);
    if (match == null) {
      return fallback;
    }
    int hour = int.parse(match.group(1)!);
    final int minute = int.parse(match.group(2)!);
    final String? period = match.group(3)?.toUpperCase();
    if (period == 'PM' && hour < 12) {
      hour += 12;
    }
    if (period == 'AM' && hour == 12) {
      hour = 0;
    }
    return TimeOfDay(hour: hour.clamp(0, 23), minute: minute.clamp(0, 59));
  }
}

/// Wall ordering shared by the Wall tab and the Home feature card.
extension WallItems on List<WallItem> {
  /// Pinned items first, otherwise newest first (insertion order).
  ///
  /// Partitions rather than sorts: `List.sort` is not stable, and this
  /// comparator is equal for every pair that shares a pin state, so sorting
  /// silently reshuffles the rest of the Wall once the list grows past the
  /// insertion-sort cutoff.
  List<WallItem> get pinnedFirst {
    final List<WallItem> pinned = <WallItem>[];
    final List<WallItem> rest = <WallItem>[];
    for (final WallItem item in this) {
      (item.isPinned ? pinned : rest).add(item);
    }
    if (pinned.isEmpty) {
      return List<WallItem>.of(this);
    }
    return <WallItem>[...pinned, ...rest];
  }

  /// The item Home features: the pinned one, else the newest.
  WallItem? get featured {
    if (isEmpty) {
      return null;
    }
    for (final WallItem item in this) {
      if (item.isPinned) {
        return item;
      }
    }
    return first;
  }
}

class WallItem {
  const WallItem({
    required this.id,
    required this.title,
    required this.category,
    required this.image,
    this.note = '',
    this.nextStep = '',
    this.isPinned = false,
  });

  factory WallItem.fromJson(Map<String, dynamic> json) => WallItem(
    id: json['id'] as String,
    title: json['title'] as String,
    category: json['category'] as String? ?? 'Inspiration',
    image: (json['image'] ?? json['imageUrl']) as String? ?? '',
    note: json['note'] as String? ?? '',
    nextStep: json['nextStep'] as String? ?? '',
    isPinned: json['isPinned'] as bool? ?? false,
  );

  final String id;
  final String title;
  final String category;

  /// Image reference understood by `AppImage` (local file, data URI or URL).
  final String image;
  final String note;
  final String nextStep;
  final bool isPinned;

  WallItem copyWith({
    String? title,
    String? category,
    String? image,
    String? note,
    String? nextStep,
    bool? isPinned,
  }) => WallItem(
    id: id,
    title: title ?? this.title,
    category: category ?? this.category,
    image: image ?? this.image,
    note: note ?? this.note,
    nextStep: nextStep ?? this.nextStep,
    isPinned: isPinned ?? this.isPinned,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'title': title,
    'category': category,
    'image': image,
    'note': note,
    'nextStep': nextStep,
    'isPinned': isPinned,
  };
}

/// One check-in per calendar week, keyed by the Monday it starts on.
class WeeklyReview {
  const WeeklyReview({
    required this.weekKey,
    required this.stars,
    required this.reflection,
    required this.savedAt,
  });

  factory WeeklyReview.fromJson(Map<String, dynamic> json) => WeeklyReview(
    weekKey: json['weekKey'] as String,
    stars: (json['stars'] is num ? (json['stars'] as num).toInt() : 0).clamp(
      0,
      maxStars,
    ),
    reflection: json['reflection'] as String? ?? '',
    savedAt:
        DateTime.tryParse(json['savedAt'] as String? ?? '') ?? DateTime.now(),
  );

  static const int maxStars = 5;

  static const List<String> vibeLabels = <String>[
    'Tap a star to check in',
    'Heavy week',
    'A little difficult',
    'Steady week',
    'Good momentum',
    'Great week',
  ];

  /// `yyyy-MM-dd` of the week's Monday.
  final String weekKey;
  final int stars;
  final String reflection;
  final DateTime savedAt;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'weekKey': weekKey,
    'stars': stars,
    'reflection': reflection,
    'savedAt': savedAt.toIso8601String(),
  };
}

/// Everything Thryve persists, serialized as one JSON document.
class AppState {
  const AppState({
    this.onboardingComplete = false,
    this.notificationsEnabled = true,
    this.user = UserProfile.empty,
    this.goals = const <Goal>[],
    this.tasks = const <DisciplineTask>[],
    this.tasksDay = '',
    this.wallItems = const <WallItem>[],
    this.reviews = const <WeeklyReview>[],
    this.activity = const <String, int>{},
  });

  /// Reads both the current schema and the v1 schema written by earlier
  /// builds (single review, string focus window, flag-based achievement).
  factory AppState.fromJson(Map<String, dynamic> json) {
    // A single malformed record is dropped rather than discarding the
    // whole document.
    List<T> list<T>(String key, T Function(Map<String, dynamic>) parse) {
      final Object? raw = json[key];
      final List<T> result = <T>[];
      if (raw is! List<dynamic>) {
        return result;
      }
      for (final dynamic value in raw) {
        if (value is! Map<String, dynamic>) {
          continue;
        }
        try {
          result.add(parse(value));
        } on Object {
          continue;
        }
      }
      return result;
    }

    final Object? rawActivity = json['activity'];
    final Map<String, int> activity = <String, int>{
      if (rawActivity is Map<String, dynamic>)
        for (final MapEntry<String, dynamic> entry in rawActivity.entries)
          if (entry.value is num) entry.key: (entry.value as num).toInt(),
    };

    final List<WeeklyReview> reviews = list('reviews', WeeklyReview.fromJson);
    final DateTime? legacyReviewAt = DateTime.tryParse(
      json['reviewSavedAt'] as String? ?? '',
    );
    if (reviews.isEmpty && legacyReviewAt != null) {
      reviews.add(
        WeeklyReview(
          weekKey: DateKeys.weekKey(legacyReviewAt),
          stars: json['vibeStars'] as int? ?? 0,
          reflection: json['reflection'] as String? ?? '',
          savedAt: legacyReviewAt,
        ),
      );
    }

    return AppState(
      onboardingComplete: json['onboardingComplete'] as bool? ?? false,
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      user: json['user'] is Map<String, dynamic>
          ? UserProfile.fromJson(json['user'] as Map<String, dynamic>)
          : UserProfile.empty,
      goals: list('goals', Goal.fromJson),
      tasks: list('tasks', DisciplineTask.fromJson),
      tasksDay: json['tasksDay'] as String? ?? '',
      wallItems: list('wallItems', WallItem.fromJson),
      reviews: reviews,
      activity: activity,
    );
  }

  static const int schemaVersion = 2;

  final bool onboardingComplete;
  final bool notificationsEnabled;
  final UserProfile user;
  final List<Goal> goals;
  final List<DisciplineTask> tasks;

  /// The day (`yyyy-MM-dd`) that [tasks] completion flags belong to.
  final String tasksDay;
  final List<WallItem> wallItems;
  final List<WeeklyReview> reviews;

  /// Actions taken per day (`yyyy-MM-dd` → count). Drives streaks and the
  /// weekly review.
  final Map<String, int> activity;

  /// Replaces only the given slices; untouched slices keep the same
  /// instance, which lets view models detect what actually changed.
  AppState copyWith({
    bool? onboardingComplete,
    bool? notificationsEnabled,
    UserProfile? user,
    List<Goal>? goals,
    List<DisciplineTask>? tasks,
    String? tasksDay,
    List<WallItem>? wallItems,
    List<WeeklyReview>? reviews,
    Map<String, int>? activity,
  }) => AppState(
    onboardingComplete: onboardingComplete ?? this.onboardingComplete,
    notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    user: user ?? this.user,
    goals: goals ?? this.goals,
    tasks: tasks ?? this.tasks,
    tasksDay: tasksDay ?? this.tasksDay,
    wallItems: wallItems ?? this.wallItems,
    reviews: reviews ?? this.reviews,
    activity: activity ?? this.activity,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'version': schemaVersion,
    'onboardingComplete': onboardingComplete,
    'notificationsEnabled': notificationsEnabled,
    'user': user.toJson(),
    'goals': goals.map((Goal goal) => goal.toJson()).toList(),
    'tasks': tasks.map((DisciplineTask task) => task.toJson()).toList(),
    'tasksDay': tasksDay,
    'wallItems': wallItems.map((WallItem item) => item.toJson()).toList(),
    'reviews': reviews.map((WeeklyReview review) => review.toJson()).toList(),
    'activity': activity,
  };
}

/// What the current week looks like, for the Weekly Review.
class WeekSummary {
  const WeekSummary({
    required this.start,
    required this.actions,
    required this.activeDays,
    required this.milestonesCompleted,
    required this.goalsAchieved,
  });

  final DateTime start;
  final int actions;
  final int activeDays;
  final int milestonesCompleted;
  final int goalsAchieved;

  DateTime get end => DateKeys.addDays(start, 6);

  bool get isEmpty =>
      actions == 0 && milestonesCompleted == 0 && goalsAchieved == 0;
}

class GoalDraft {
  const GoalDraft({
    required this.title,
    required this.trackingType,
    required this.targetAmount,
    required this.why,
  });

  final String title;
  final GoalTrackingType trackingType;
  final double targetAmount;
  final String why;
}

class MilestoneDraft {
  const MilestoneDraft({
    required this.title,
    required this.status,
    this.note,
    this.valueLabel,
  });

  final String title;
  final MilestoneStatus status;
  final String? note;
  final String? valueLabel;
}

class WallDraft {
  const WallDraft({
    required this.title,
    required this.category,
    required this.image,
    required this.note,
    required this.nextStep,
  });

  final String title;
  final String category;
  final String image;
  final String note;
  final String nextStep;
}
