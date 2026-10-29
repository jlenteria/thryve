import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/sheets.dart';
import '../../../data/models/models.dart';
import 'wall_editor_view_model.dart';

Future<WallDraft?> showWallEditor(BuildContext context, {WallItem? initial}) =>
    showThryveSheet<WallDraft>(
      context,
      (BuildContext context) => ChangeNotifierProvider<WallEditorViewModel>(
        create: (_) => WallEditorViewModel(initial: initial),
        child: const _WallEditorSheet(),
      ),
    );

class _WallEditorSheet extends StatelessWidget {
  const _WallEditorSheet();

  @override
  Widget build(BuildContext context) =>
      Consumer<WallEditorViewModel>(builder: _buildContent);

  Widget _buildContent(
    BuildContext context,
    WallEditorViewModel vm,
    Widget? child,
  ) {
    return ThryveBottomSheet(
      title: vm.isEditing ? 'Edit inspiration' : 'Add to your Wall',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (vm.hasImage) ...<Widget>[
            AppImage(
              source: vm.image,
              width: double.infinity,
              height: 150,
              borderRadius: BorderRadius.circular(12),
            ),
            const SizedBox(height: 12),
          ],
          OutlinedButton.icon(
            onPressed: vm.isPicking ? null : vm.pickPhoto,
            icon: vm.isPicking
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.photo_library_outlined),
            label: Text(vm.hasImage ? 'Change photo' : 'Choose a photo'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: vm.url,
            keyboardType: TextInputType.url,
            onSubmitted: (_) => vm.usePastedUrl(),
            decoration: InputDecoration(
              labelText: 'Or paste an image link',
              suffixIcon: IconButton(
                tooltip: 'Preview link',
                onPressed: vm.usePastedUrl,
                icon: const Icon(Icons.arrow_forward),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: vm.title,
            autofocus: !vm.isEditing,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Title'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: vm.category,
            isExpanded: true,
            menuMaxHeight: 360,
            items: <DropdownMenuItem<String>>[
              for (final String category in vm.options)
                DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                ),
            ],
            onChanged: (String? value) {
              if (value != null) {
                vm.setCategory(value);
              }
            },
            decoration: const InputDecoration(labelText: 'Category'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: vm.note,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Why it matters (optional)',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: vm.nextStep,
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Next action (optional)',
              hintText: 'One small thing you can do next',
            ),
          ),
          if (vm.error != null) ...<Widget>[
            const SizedBox(height: 10),
            Text(
              vm.error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: vm.isPicking
              ? null
              : () {
                  final WallDraft? draft = vm.submit();
                  if (draft != null) {
                    Navigator.pop(context, draft);
                  }
                },
          child: Text(vm.isEditing ? 'Save changes' : 'Add'),
        ),
      ],
    );
  }
}
