/// Text for the daily reminder. Shared by the onboarding preview and the
/// scheduled notification so what users see is what they get.
class ReminderCopy {
  const ReminderCopy({required this.name, required this.anchor});

  final String name;
  final String anchor;

  static const String _lead = 'Take a few minutes of action today.';

  String get title => name.trim().isNotEmpty
      ? 'Hey ${name.trim()}, time to thryve 🌱'
      : 'Time to thryve 🌱';

  /// The part of [body] that the preview highlights.
  String get highlight {
    if (anchor.trim().isNotEmpty) {
      return anchor.trim();
    }
    if (name.trim().isNotEmpty) {
      return '${name.trim()}. Keep going.';
    }
    return 'Your future self will thank you.';
  }

  /// Everything in [body] before [highlight]. Exposed so the preview can
  /// split without searching the assembled text: an anchor such as "today"
  /// also occurs inside [_lead], and the search would land on that instead.
  String get prefix {
    if (anchor.trim().isEmpty && name.trim().isNotEmpty) {
      return 'Take a few minutes of action today, ';
    }
    return '$_lead ';
  }

  String get body => '$prefix$highlight';
}
