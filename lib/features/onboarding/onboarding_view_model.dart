import 'package:flutter/material.dart';

import '../../core/services/image_store.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/reminder_copy.dart';
import '../../core/services/reminder_sync.dart';
import '../../core/state/app_store.dart';
import '../../core/state/view_model.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/ids.dart';
import '../../data/models/models.dart';
import 'widgets/drum_picker.dart';

class OnboardingViewModel extends ViewModel {
  OnboardingViewModel(this._store);

  /// The three numbered steps plus the closing "allow notifications" page.
  static const int stepCount = 4;

  final AppStore _store;
  final PageController pageController = PageController();
  int _currentStep = 0;

  int get currentStep => _currentStep;

  // ── Step 1: Name + Dream ───────────────────────────────────────
  final TextEditingController nameController = TextEditingController();
  final TextEditingController dreamController = TextEditingController();
  bool _nameTouched = false;
  bool _dreamTouched = false;

  String get name => nameController.text.trim();
  String get dream => dreamController.text.trim();
  bool get isStep1Valid => name.isNotEmpty && dream.isNotEmpty;
  bool get showNameError => _nameTouched && name.isEmpty;
  bool get showDreamError => _dreamTouched && dream.isEmpty;

  void onNameChanged(String _) {
    _nameTouched = true;
    notifyListeners();
  }

  void onDreamChanged(String _) {
    _dreamTouched = true;
    notifyListeners();
  }

  void continueFromStep1() {
    if (!isStep1Valid) {
      _nameTouched = true;
      _dreamTouched = true;
      notifyListeners();
      return;
    }
    nextStep();
  }

  // ── Step 2: Anchor ─────────────────────────────────────────────
  final TextEditingController anchorController = TextEditingController();
  String? _anchorImage;
  bool _anchorTouched = false;

  String? get anchorImage => _anchorImage;
  String get anchorText => anchorController.text.trim();
  bool get isStep2Valid => anchorText.isNotEmpty;
  bool get showAnchorError => _anchorTouched && anchorText.isEmpty;

  void onAnchorChanged(String _) {
    _anchorTouched = true;
    notifyListeners();
  }

  void continueFromStep2() {
    if (!isStep2Valid) {
      _anchorTouched = true;
      notifyListeners();
      return;
    }
    nextStep();
  }

  /// Returns false if the photo library couldn't be opened.
  Future<bool> pickAnchorImage() async {
    try {
      final String? ref = await ImageStore.pickFromGallery();
      if (ref != null) {
        _discard(_anchorImage);
        _anchorImage = ref;
        notifyListeners();
      }
      return true;
    } on Object {
      return false;
    }
  }

  void removeAnchorImage() {
    _discard(_anchorImage);
    _anchorImage = null;
    notifyListeners();
  }

  // ── Step 3: Reminder time ──────────────────────────────────────
  int _reminderHour = 8;
  int _reminderMinute = 0;
  final FixedExtentScrollController hourWheel = DrumPicker.createController(
    value: 8,
    min: 1,
  );
  final FixedExtentScrollController minuteWheel = DrumPicker.createController(
    value: 0,
    min: 0,
  );
  bool _isAm = true;

  int get reminderHour => _reminderHour;
  int get reminderMinute => _reminderMinute;
  bool get isAm => _isAm;

  TimeOfDay get reminderTime {
    final int hour24 = _isAm
        ? (_reminderHour == 12 ? 0 : _reminderHour)
        : (_reminderHour == 12 ? 12 : _reminderHour + 12);
    return TimeOfDay(hour: hour24, minute: _reminderMinute);
  }

  String get formattedTime => Formatters.timeOfDay(reminderTime);

  ReminderCopy get reminderCopy => ReminderCopy(name: name, anchor: anchorText);

  void setReminderHour(int hour) {
    _reminderHour = hour.clamp(1, 12);
    DrumPicker.syncTo(hourWheel, value: _reminderHour, min: 1, max: 12);
    notifyListeners();
  }

  void setReminderMinute(int minute) {
    _reminderMinute = minute.clamp(0, 59);
    DrumPicker.syncTo(minuteWheel, value: _reminderMinute, min: 0, max: 59);
    notifyListeners();
  }

  void setAmPm({required bool isAm}) {
    _isAm = isAm;
    notifyListeners();
  }

  // ── Navigation ─────────────────────────────────────────────────
  void nextStep() {
    if (_currentStep >= stepCount - 1) {
      return;
    }
    _currentStep++;
    _animateToStep();
  }

  void prevStep() {
    if (_currentStep <= 0) {
      return;
    }
    _currentStep--;
    _animateToStep();
  }

  void _animateToStep() {
    FocusManager.instance.primaryFocus?.unfocus();
    pageController.animateToPage(
      _currentStep,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
    notifyListeners();
  }

  // ── Completion ─────────────────────────────────────────────────
  /// Set once the store's state references [_anchorImage]. From that moment
  /// the file belongs to the saved data — even if the write itself failed and
  /// the user retries — so [dispose] must not delete it.
  bool _imageOwned = false;
  String? _firstGoalId;

  /// Saves the profile and first goal, then lines up the daily reminder.
  ///
  /// Returns a message for the user when something didn't land, or null when
  /// everything did. The store keeps its `saveFailed` flag and retry banner,
  /// so a failed write is recoverable rather than fatal.
  Future<String?> complete({required bool enableReminders}) async {
    if (isLoading) {
      return null;
    }
    startLoading();
    try {
      return await _saveProfileAndFirstGoal(remindersEnabled: enableReminders);
    } finally {
      stopLoading();
    }
  }

  Future<String?> _saveProfileAndFirstGoal({
    required bool remindersEnabled,
  }) async {
    final DateTime now = _store.clock();
    // A stable id so a retry after a failed save replaces the goal instead of
    // adding a second copy of it.
    final String goalId = _firstGoalId ??= Ids.next();
    final Goal firstGoal = Goal(
      id: goalId,
      title: dream,
      trackingType: looksFinancial(dream)
          ? GoalTrackingType.money
          : GoalTrackingType.progress,
      createdAt: now,
      why: anchorText.isEmpty ? null : anchorText,
      image: _anchorImage,
    );
    final UserProfile profile = UserProfile(
      name: name,
      bigDream: dream,
      anchor: anchorText,
      anchorImage: _anchorImage,
      reminderHour: reminderTime.hour,
      reminderMinute: reminderTime.minute,
    );
    AppState withReminders(bool on) => _store.state.copyWith(
      onboardingComplete: true,
      notificationsEnabled: on,
      user: profile,
      goals: <Goal>[
        firstGoal,
        for (final Goal goal in _store.state.goals)
          if (goal.id != goalId) goal,
      ],
      tasksDay: DateKeys.today(now),
    );

    // Scheduled before the commit on purpose: committing flips the app to the
    // main shell, so a warning raised afterwards is shown on a screen that is
    // already gone and the user never sees why reminders are silent.
    String? reminderWarning;
    bool remindersOn = remindersEnabled;
    if (remindersEnabled) {
      final ReminderResult result = await ReminderSync.apply(
        withReminders(true),
        askExactAlarms: true,
      );
      if (result == ReminderResult.denied) {
        remindersOn = false;
        reminderWarning =
            'Notifications are blocked. Allow them in Settings to get your daily nudge.';
      }
    }

    await _store.commit(withReminders(remindersOn));
    _imageOwned = true;
    if (_store.saveFailed) {
      return "We couldn't save your details. Tap Retry on the banner.";
    }
    return reminderWarning;
  }

  /// Whole-word match so "Save the whales" isn't treated as a money goal.
  static final RegExp _financialWords = RegExp(
    r'\b(income|money|savings|earn|earning|earnings|salary|debt|budget|'
    r'freelance|business|revenue|peso|pesos|php)\b',
    caseSensitive: false,
  );

  /// Whether a dream sounds like a financial target.
  static bool looksFinancial(String dream) =>
      dream.contains('₱') ||
      dream.contains(r'$') ||
      _financialWords.hasMatch(dream);

  @override
  void dispose() {
    if (!_imageOwned) {
      _discard(_anchorImage);
    }
    pageController.dispose();
    hourWheel.dispose();
    minuteWheel.dispose();
    nameController.dispose();
    dreamController.dispose();
    anchorController.dispose();
    super.dispose();
  }

  /// Deletes a picked file that was never saved, best effort: a leftover
  /// image is harmless, a thrown error in dispose is not.
  void _discard(String? ref) {
    if (ref == null) {
      return;
    }
    ImageStore.delete(ref).catchError((Object error) {
      debugPrint('Thryve: could not remove onboarding image ($error).');
    });
  }
}
