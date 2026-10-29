import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/sheets.dart';
import '../../../data/models/models.dart';
import 'goal_form_view_model.dart';

/// Create or edit a goal. Resolves to null if the user cancels.
Future<GoalDraft?> showGoalForm(BuildContext context, {Goal? initial}) =>
    showThryveSheet<GoalDraft>(
      context,
      (BuildContext context) => ChangeNotifierProvider<GoalFormViewModel>(
        create: (_) => GoalFormViewModel(initial: initial),
        child: const _GoalFormSheet(),
      ),
    );

class _GoalFormSheet extends StatelessWidget {
  const _GoalFormSheet();

  @override
  Widget build(BuildContext context) =>
      Consumer<GoalFormViewModel>(builder: _buildContent);

  Widget _buildContent(
    BuildContext context,
    GoalFormViewModel vm,
    Widget? child,
  ) {
    return ThryveBottomSheet(
      title: vm.isEditing ? 'Edit goal' : 'Add a goal',
      content: Form(
        key: vm.formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextFormField(
              controller: vm.title,
              autofocus: !vm.isEditing,
              textCapitalization: TextCapitalization.sentences,
              inputFormatters: <TextInputFormatter>[
                LengthLimitingTextInputFormatter(AppConstants.maxTitleLength),
              ],
              decoration: const InputDecoration(
                labelText: 'What do you want to achieve?',
              ),
              validator: (String? value) =>
                  value == null || value.trim().isEmpty
                  ? 'Give your goal a name'
                  : null,
            ),
            const SizedBox(height: 16),
            SegmentedButton<GoalTrackingType>(
              segments: const <ButtonSegment<GoalTrackingType>>[
                ButtonSegment<GoalTrackingType>(
                  value: GoalTrackingType.progress,
                  label: Text('Milestones'),
                  icon: Icon(Icons.flag_outlined),
                ),
                ButtonSegment<GoalTrackingType>(
                  value: GoalTrackingType.money,
                  label: Text('Money'),
                  icon: Icon(Icons.account_balance_wallet_outlined),
                ),
              ],
              selected: <GoalTrackingType>{vm.type},
              showSelectedIcon: false,
              onSelectionChanged: (Set<GoalTrackingType> value) =>
                  vm.setType(value.first),
            ),
            if (vm.isMoney) ...<Widget>[
              const SizedBox(height: 16),
              TextFormField(
                controller: vm.target,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Target amount',
                  prefixText:
                      vm.initial?.currencySymbol ??
                      AppConstants.defaultCurrency,
                ),
                validator: (String? value) =>
                    Formatters.parseAmount(value ?? '') == null
                    ? 'Enter an amount between 0 and '
                          '${Formatters.amount(Formatters.maxAmount)}'
                    : null,
              ),
            ],
            const SizedBox(height: 16),
            TextFormField(
              controller: vm.why,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 2,
              inputFormatters: <TextInputFormatter>[
                LengthLimitingTextInputFormatter(AppConstants.maxNoteLength),
              ],
              decoration: const InputDecoration(
                labelText: 'Why does this matter? (optional)',
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final GoalDraft? draft = vm.submit();
            if (draft != null) {
              Navigator.pop(context, draft);
            }
          },
          child: Text(vm.isEditing ? 'Save' : 'Create goal'),
        ),
      ],
    );
  }
}
