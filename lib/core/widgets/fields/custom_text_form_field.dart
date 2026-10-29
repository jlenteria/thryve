import 'package:flutter/material.dart';

/// Filled text field used by onboarding. Colors come from the active theme.
class CustomTextFormField extends StatelessWidget {
  const CustomTextFormField({
    super.key,
    required this.controller,
    this.hint,
    this.onChanged,
    this.errorText,
    this.prefix,
    this.minLines = 1,
    this.maxLines = 1,
    this.textStyle,
    this.textInputAction = TextInputAction.next,
    this.capitalization = TextCapitalization.sentences,
    this.maxLength,
  });

  final TextEditingController controller;
  final String? hint;
  final ValueChanged<String>? onChanged;

  /// Shown below the field when non-null. Driven by the view model so errors
  /// can appear on submit, not only after the user types.
  final String? errorText;
  final Widget? prefix;
  final int minLines;
  final int maxLines;
  final TextStyle? textStyle;
  final TextInputAction textInputAction;
  final TextCapitalization capitalization;
  final int? maxLength;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          borderSide: BorderSide(color: color, width: width),
        );
    return TextFormField(
      controller: controller,
      onChanged: onChanged,
      forceErrorText: errorText,
      onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
      textInputAction: maxLines > 1 ? TextInputAction.newline : textInputAction,
      textCapitalization: capitalization,
      minLines: minLines,
      maxLines: maxLines,
      maxLength: maxLength,
      cursorColor: colors.primary,
      style:
          textStyle ??
          const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: hint,
        counterText: '',
        filled: true,
        fillColor: colors.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 16,
        ),
        prefixIcon: prefix,
        prefixIconConstraints: const BoxConstraints(
          minWidth: 24,
          minHeight: 12,
        ),
        errorMaxLines: 3,
        hintStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: colors.onSurfaceVariant,
        ),
        enabledBorder: border(colors.outlineVariant),
        focusedBorder: border(colors.primary, 1.5),
        errorBorder: border(colors.error),
        focusedErrorBorder: border(colors.error, 1.5),
        border: border(colors.outlineVariant),
      ),
    );
  }
}
