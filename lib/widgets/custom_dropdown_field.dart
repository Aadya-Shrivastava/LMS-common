import 'package:flutter/material.dart';

/// A labeled dropdown field, styled to match `CustomTextField` - used
/// for form fields like "Subject" or "Batch" that pick from a fixed
/// list of options instead of free text.
class CustomDropdownField<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<T> options;

  /// How to turn one option into the text shown in the dropdown.
  final String Function(T option) labelFor;

  final ValueChanged<T?> onChanged;

  const CustomDropdownField({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.labelFor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: [
        for (final option in options)
          DropdownMenuItem<T>(value: option, child: Text(labelFor(option))),
      ],
      onChanged: onChanged,
    );
  }
}
