import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thryve/core/constants/app_constants.dart';
import 'package:thryve/data/models/models.dart';
import 'package:thryve/data/repositories/app_state_repository.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  group('AppStateRepository', () {
    test('a failed save does not block later saves (regression)', () async {
      final AppStateRepository repository = AppStateRepository();
      final AppState poisoned = AppState(
        goals: <Goal>[
          Goal(
            id: 'bad',
            title: 'Bad',
            trackingType: GoalTrackingType.money,
            createdAt: DateTime(2026),
            currentAmount: double.infinity,
          ),
        ],
      );

      await expectLater(repository.save(poisoned), throwsA(anything));
      await repository.flush();

      await repository.save(const AppState(onboardingComplete: true));
      final AppState loaded = await repository.load();
      expect(loaded.onboardingComplete, isTrue);
    });

    test('writes land in call order', () async {
      final AppStateRepository repository = AppStateRepository();
      await Future.wait(<Future<void>>[
        repository.save(const AppState(tasksDay: 'first')),
        repository.save(const AppState(tasksDay: 'second')),
        repository.save(const AppState(tasksDay: 'third')),
      ]);
      expect((await repository.load()).tasksDay, 'third');
    });

    test('clear also removes the corrupt-data backup (regression)', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        AppConstants.stateKey: '{not json',
      });
      final AppStateRepository repository = AppStateRepository();
      await repository.load();
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(AppConstants.corruptStateKey), isNotNull);

      await repository.clear();

      expect(prefs.getString(AppConstants.stateKey), isNull);
      expect(prefs.getString(AppConstants.corruptStateKey), isNull);
    });
  });

  group('AppState.fromJson robustness', () {
    test('drops one malformed record instead of the whole state', () {
      final AppState state = AppState.fromJson(<String, dynamic>{
        'onboardingComplete': true,
        'goals': <dynamic>[
          <String, dynamic>{'id': 'ok', 'title': 'Keep me'},
          <String, dynamic>{'title': 'Missing id'},
          'not a map',
          <String, dynamic>{'id': 'ok2', 'title': 'Also kept'},
        ],
      });
      expect(state.onboardingComplete, isTrue);
      expect(state.goals.map((Goal g) => g.id), <String>['ok', 'ok2']);
    });

    test('ignores non-numeric activity entries', () {
      final AppState state = AppState.fromJson(<String, dynamic>{
        'activity': <String, dynamic>{
          '2026-10-01': 3,
          '2026-10-02': 'oops',
          '2026-10-03': 2.0,
        },
      });
      expect(state.activity, <String, int>{'2026-10-01': 3, '2026-10-03': 2});
    });

    test('clamps review stars into range (regression)', () {
      WeeklyReview parse(Object? stars) => WeeklyReview.fromJson(
        <String, dynamic>{'weekKey': '2026-10-05', 'stars': stars},
      );
      expect(parse(99).stars, WeeklyReview.maxStars);
      expect(parse(-3).stars, 0);
      expect(parse('x').stars, 0);
      expect(parse(4).stars, 4);
    });

    test('sanitises stored amounts so they are safe to format', () {
      final Goal goal = Goal.fromJson(<String, dynamic>{
        'id': 'g',
        'title': 'T',
        'currentAmount': double.infinity,
        'targetAmount': -50,
      });
      expect(goal.currentAmount, 0);
      expect(goal.targetAmount, 0);
    });
  });
}
