import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// A small, single-line dropdown pill - much shorter than
/// `CustomDropdownField` (which has a floating label and full-height
/// border, more like a form field). Used wherever a dropdown needs to
/// sit inline in a row instead of taking up its own block of space,
/// e.g. the Attendance screen's subject/batch filters.
class CompactDropdown<T> extends StatelessWidget {
  final T value;
  final List<T> options;
  final String Function(T option) labelFor;
  final ValueChanged<T?> onChanged;
  final IconData? icon;

  const CompactDropdown({
    super.key,
    required this.value,
    required this.options,
    required this.labelFor,
    required this.onChanged,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isDense: true,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, size: 18),
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          items: [
            for (final option in options)
              DropdownMenuItem<T>(
                value: option,
                // The dropdown's popup gives each item a fixed width
                // (matching the button), not however wide it wants to
                // be - so without `mainAxisSize.min` here, and with the
                // text in an `Expanded`, a long option like "Basic
                // Electrical Wiring" shrinks/ellipsizes to fit instead
                // of overflowing past the edge of the menu.
                child: Row(
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                    ],
                    Expanded(
                      child: Text(
                        labelFor(option),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}
