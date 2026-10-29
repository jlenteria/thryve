import '../../data/models/models.dart';
import 'notification_service.dart';
import 'reminder_copy.dart';

/// Brings the scheduled daily reminder in line with the saved profile.
abstract final class ReminderSync {
  /// [ReminderResult.denied] is the only outcome worth telling the user
  /// about: [ReminderResult.unsupported] means the platform has no
  /// notification backend at all, which no setting on their side can fix.
  ///
  /// [askExactAlarms] is forwarded to [NotificationService.scheduleDaily].
  static Future<ReminderResult> apply(
    AppState state, {
    bool askExactAlarms = false,
  }) async {
    if (!state.notificationsEnabled) {
      await NotificationService.cancelDaily();
      return ReminderResult.scheduled;
    }
    return NotificationService.scheduleDaily(
      hour: state.user.reminderHour,
      minute: state.user.reminderMinute,
      askExactAlarms: askExactAlarms,
      copy: ReminderCopy(
        name: state.user.name,
        anchor: state.user.anchor ?? '',
      ),
    );
  }
}
