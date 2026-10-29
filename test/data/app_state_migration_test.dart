import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thryve/core/constants/app_constants.dart';
import 'package:thryve/data/models/models.dart';
import 'package:thryve/data/repositories/app_state_repository.dart';

/// Shape written by the previous build (schema v1).
const Map<String, dynamic> _v1 = <String, dynamic>{
  'onboardingComplete': true,
  'notificationsEnabled': false,
  'user': <String, dynamic>{
    'name': 'Alex',
    'avatarUrl': 'https://example.com/a.jpg',
    'streakDays': 14,
    'bigDream': 'Build a studio',
    'anchor': 'My family',
    'focusWindow': '7:30 PM',
  },
  'goals': <Map<String, dynamic>>[
    <String, dynamic>{
      'id': 'g1',
      'title': 'Build a studio',
      'category': 'Active Goal',
      'currentAmount': 0,
      'targetAmount': 0,
      'whyImageUrl': 'https://example.com/why.jpg',
      'isActive': false,
      'isAchieved': true,
      'trackingType': 'progress',
      'milestones': <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'm1',
          'title': 'Find a space',
          'status': 'completed',
          'subtitle': 'Completed on Oct 12',
          'amountLabel': '₱0',
        },
      ],
    },
  ],
  'tasks': <Map<String, dynamic>>[
    <String, dynamic>{'id': 't1', 'title': 'Sketch', 'completed': true},
  ],
  'tasksDay': '2026-10-01',
  'wallItems': <Map<String, dynamic>>[
    <String, dynamic>{
      'id': 'w1',
      'title': 'Lakehouse',
      'category': 'Home',
      'imageUrl': 'data:image/png;base64,AAAA',
      'isPinned': true,
    },
  ],
  'vibeStars': 4,
  'reflection': 'Protect mornings.',
  'reviewSavedAt': '2026-09-30T10:00:00.000',
};

void main() {
  test('reads v1 data without losing anything', () {
    final AppState state = AppState.fromJson(_v1);

    expect(state.onboardingComplete, isTrue);
    expect(state.notificationsEnabled, isFalse);
    expect(state.user.avatar, 'https://example.com/a.jpg');
    expect(state.user.reminderHour, 19);
    expect(state.user.reminderMinute, 30);

    final Goal goal = state.goals.single;
    expect(goal.isAchieved, isTrue);
    expect(goal.trackingType, GoalTrackingType.progress);
    expect(goal.image, 'https://example.com/why.jpg');
    final Milestone milestone = goal.milestones.single;
    expect(milestone.status, MilestoneStatus.completed);
    expect(milestone.note, 'Completed on Oct 12');
    expect(milestone.valueLabel, '₱0');

    expect(state.wallItems.single.image, startsWith('data:image/png'));
    expect(state.reviews.single.stars, 4);
    expect(state.reviews.single.weekKey, '2026-09-28');
    expect(state.reviews.single.reflection, 'Protect mornings.');
  });

  test('round-trips through the current schema', () {
    final AppState state = AppState.fromJson(_v1);
    final AppState again = AppState.fromJson(
      jsonDecode(jsonEncode(state.toJson())) as Map<String, dynamic>,
    );
    expect(again.toJson(), state.toJson());
    expect(again.toJson()['version'], AppState.schemaVersion);
  });

  test('corrupt saved data starts fresh instead of crashing', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      AppConstants.stateKey: '{not json',
    });
    final AppState state = await AppStateRepository().load();
    expect(state.onboardingComplete, isFalse);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('${AppConstants.stateKey}.corrupt'), '{not json');
  });
}
