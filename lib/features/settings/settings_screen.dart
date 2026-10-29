import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/extensions/context_ext.dart';
import '../../core/services/image_store.dart';
import '../../core/theme/theme_manager.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_image.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/sheets.dart';
import '../../core/widgets/thryve_page.dart';
import '../support/support_screen.dart';
import 'about_screen.dart';
import 'privacy_policy_screen.dart';
import 'settings_form_view_model.dart';
import 'settings_view_model.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SettingsFormViewModel>(
      create: (BuildContext context) =>
          SettingsFormViewModel(context.read<SettingsViewModel>().user),
      child: const _SettingsView(),
    );
  }
}

class _SettingsView extends StatelessWidget {
  const _SettingsView();

  Future<void> _saveProfile(BuildContext context) async {
    final SettingsFormViewModel form = context.read<SettingsFormViewModel>();
    final SettingsViewModel app = context.read<SettingsViewModel>();
    if (!form.validate()) {
      return;
    }
    FocusScope.of(context).unfocus();
    await app.updateProfile(
      name: form.name.text,
      dream: form.dream.text,
      anchor: form.anchor.text,
    );
    if (context.mounted) {
      context.showSnack('Profile updated.');
    }
  }

  Future<void> _pickAvatar(BuildContext context) async {
    final SettingsViewModel app = context.read<SettingsViewModel>();
    try {
      final String? ref = await ImageStore.pickFromGallery(maxDimension: 600);
      if (ref != null) {
        app.setAvatar(ref);
      }
    } on Object {
      if (context.mounted) {
        context.showSnack('Could not open the photo library.');
      }
    }
  }

  Future<void> _editReminderTime(BuildContext context) async {
    final SettingsViewModel app = context.read<SettingsViewModel>();
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: app.user.reminderTime,
    );
    if (picked != null) {
      await app.setReminderTime(picked);
    }
  }

  Future<void> _setReminders(BuildContext context, bool enabled) async {
    final bool ok = await context
        .read<SettingsViewModel>()
        .setNotificationsEnabled(enabled);
    if (!ok && context.mounted) {
      context.showSnack(
        'Reminders are off in system settings. Allow notifications for '
        'Thryve to receive them.',
      );
    }
  }

  Future<void> _reset(BuildContext context) async {
    final SettingsViewModel app = context.read<SettingsViewModel>();
    final bool confirmed = await confirmDestructive(
      context,
      title: 'Reset Thryve?',
      message:
          'This removes your goals, practices, Wall, reviews and profile '
          'from this device. This cannot be undone.',
      confirmLabel: 'Reset',
    );
    if (confirmed) {
      // The app root switches back to onboarding once state is cleared.
      await app.resetApp();
    }
  }

  void _open(BuildContext context, Widget page) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (BuildContext context) => page));
  }

  @override
  Widget build(BuildContext context) =>
      Consumer2<SettingsViewModel, ThemeManager>(builder: _buildContent);

  Widget _buildContent(
    BuildContext context,
    SettingsViewModel app,
    ThemeManager theme,
    Widget? child,
  ) {
    final SettingsFormViewModel form = context.read<SettingsFormViewModel>();
    final ColorScheme colors = context.colors;

    return ThryveTabPage(
      children: <Widget>[
        const PageHeading(
          title: 'Settings',
          subtitle: 'Shape your Thryve experience.',
        ),
        const SizedBox(height: 24),
        SectionLabel('Profile', color: colors.primary),
        const SizedBox(height: 12),
        Center(
          child: Stack(
            children: <Widget>[
              Avatar(source: app.user.avatar, radius: 42),
              Positioned(
                right: -4,
                bottom: -4,
                child: IconButton.filled(
                  tooltip: 'Change photo',
                  onPressed: () => _pickAvatar(context),
                  icon: const Icon(Icons.camera_alt_outlined, size: 18),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Form(
          key: form.formKey,
          child: Column(
            children: <Widget>[
              TextFormField(
                controller: form.name,
                textCapitalization: TextCapitalization.words,
                inputFormatters: <TextInputFormatter>[
                  LengthLimitingTextInputFormatter(AppConstants.maxTitleLength),
                ],
                decoration: const InputDecoration(labelText: 'Your name'),
                validator: (String? value) =>
                    value == null || value.trim().isEmpty
                    ? 'Please enter your name'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: form.dream,
                textCapitalization: TextCapitalization.sentences,
                inputFormatters: <TextInputFormatter>[
                  LengthLimitingTextInputFormatter(AppConstants.maxTitleLength),
                ],
                decoration: const InputDecoration(labelText: 'Big dream'),
                validator: (String? value) =>
                    value == null || value.trim().isEmpty
                    ? 'Describe your big dream'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: form.anchor,
                textCapitalization: TextCapitalization.sentences,
                inputFormatters: <TextInputFormatter>[
                  LengthLimitingTextInputFormatter(AppConstants.maxNoteLength),
                ],
                decoration: const InputDecoration(
                  labelText: 'Your anchor',
                  helperText: 'Who or what you are doing this for',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: () => _saveProfile(context),
            icon: const Icon(Icons.save_outlined, size: 18),
            label: const Text('Save profile'),
          ),
        ),
        const SizedBox(height: 24),
        SectionLabel('Appearance', color: colors.primary),
        const SizedBox(height: 10),
        SegmentedButton<ThemeMode>(
          segments: const <ButtonSegment<ThemeMode>>[
            ButtonSegment<ThemeMode>(
              value: ThemeMode.light,
              label: Text('Light'),
              icon: Icon(Icons.light_mode_outlined),
            ),
            ButtonSegment<ThemeMode>(
              value: ThemeMode.dark,
              label: Text('Dark'),
              icon: Icon(Icons.dark_mode_outlined),
            ),
            ButtonSegment<ThemeMode>(
              value: ThemeMode.system,
              label: Text('System'),
              icon: Icon(Icons.settings_brightness_outlined),
            ),
          ],
          selected: <ThemeMode>{theme.themeMode},
          onSelectionChanged: (Set<ThemeMode> values) =>
              theme.setThemeMode(values.first),
          showSelectedIcon: false,
        ),
        const SizedBox(height: 24),
        SectionLabel('Reminders', color: colors.primary),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          secondary: const Icon(Icons.notifications_outlined),
          title: const Text('Daily reminder'),
          subtitle: const Text('A gentle nudge at your focus time.'),
          value: app.notificationsEnabled,
          onChanged: (bool value) => _setReminders(context, value),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          enabled: app.notificationsEnabled,
          leading: const Icon(Icons.schedule_outlined),
          title: const Text('Focus time'),
          subtitle: Text(Formatters.timeOfDay(app.user.reminderTime)),
          trailing: const Icon(Icons.edit_outlined, size: 20),
          onTap: () => _editReminderTime(context),
        ),
        const Divider(height: 32),
        SectionLabel('Data', color: colors.primary),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.restart_alt, color: colors.error),
          title: Text(
            'Reset all local data',
            style: TextStyle(color: colors.error),
          ),
          subtitle: const Text('Start onboarding again on this device.'),
          onTap: () => _reset(context),
        ),
        const Divider(height: 32),
        SectionLabel('About', color: colors.primary),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.info_outline),
          title: const Text('About Thryve'),
          subtitle: const Text('Version and what Thryve is for'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _open(context, const AboutScreen()),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.privacy_tip_outlined),
          title: const Text('Privacy policy'),
          subtitle: const Text('How your data and photos are handled'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _open(context, const PrivacyPolicyScreen()),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.favorite_border),
          title: const Text('Support Thryve'),
          subtitle: const Text('Optional tip for independent development'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _open(context, const SupportScreen()),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            'Thryve · Grow with intention',
            style: context.text.bodySmall,
          ),
        ),
      ],
    );
  }
}
