import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/sheets.dart';
import '../../../data/models/models.dart';
import 'milestone_view_model.dart';

Future<MilestoneDraft?> showMilestoneSheet(
  BuildContext context, {
  Milestone? initial,
}) => showThryveSheet<MilestoneDraft>(
  context,
  (BuildContext context) => ChangeNotifierProvider<MilestoneViewModel>(
    create: (_) => MilestoneViewModel(initial: initial),
    child: const _MilestoneSheet(),
  ),
);

class _MilestoneSheet extends StatelessWidget {
  const _MilestoneSheet();

  @override
  Widget build(BuildContext context) =>
      Consumer<MilestoneViewModel>(builder: _buildContent);

  Widget _buildContent(
    BuildContext context,
    MilestoneViewModel vm,
    Widget? child,
  ) {
    return ThryveBottomSheet(
      title: vm.isEditing ? 'Edit milestone' : 'Add milestone',
      content: Form(
        key: vm.formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextFormField(
              controller: vm.title,
              autofocus: !vm.isEditing,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Milestone',
                hintText: 'e.g. Send the proposal',
              ),
              validator: (String? value) =>
                  value == null || value.trim().isEmpty
                  ? 'Name this milestone'
                  : null,
            ),
            const SizedBox(height: 16),
            SegmentedButton<MilestoneStatus>(
              segments: <ButtonSegment<MilestoneStatus>>[
                for (final MilestoneStatus status in MilestoneStatus.values)
                  ButtonSegment<MilestoneStatus>(
                    value: status,
                    label: Text(status.label),
                  ),
              ],
              selected: <MilestoneStatus>{vm.status},
              showSelectedIcon: false,
              onSelectionChanged: (Set<MilestoneStatus> value) =>
                  vm.setStatus(value.first),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: vm.note,
              decoration: const InputDecoration(
                labelText: 'Details (optional)',
                hintText: 'Due Friday, 14 / 20 sent, or a short note',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: vm.value,
              decoration: const InputDecoration(
                labelText: 'Value label (optional)',
                hintText: 'e.g. ₱5,000 or 20 minutes',
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
            final MilestoneDraft? draft = vm.submit();
            if (draft != null) {
              Navigator.pop(context, draft);
            }
          },
          child: const Text('Save milestone'),
        ),
      ],
    );
  }
}
