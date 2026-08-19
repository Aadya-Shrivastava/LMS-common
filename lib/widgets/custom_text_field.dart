import 'package:flutter/material.dart';

/// A reusable text input field with a label and an optional validator.
///
/// We use this on the login screen for the "Email" and "Password" fields
/// instead of writing a full TextFormField by hand each time.
///
/// When `obscureText` is true, an eye icon shows up on the right so the
/// user can toggle whether their password is hidden or visible - that's
/// why this needs to be a `StatefulWidget` (it has to remember whether
/// the eye is currently "open" or "closed").
class CustomTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;

  /// Set this to true for password fields, so the text starts hidden
  /// as dots, with an eye icon to reveal it.
  final bool obscureText;

  final TextInputType keyboardType;

  /// How many lines tall the field is. Set this higher than 1 for
  /// something like "Instructions", where people write a few sentences.
  final int maxLines;

  /// A function that checks if the typed text is valid.
  /// Returning null means "this is fine", returning a String shows it
  /// as an error message under the field.
  final String? Function(String?)? validator;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.validator,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  // Starts hidden (matching `obscureText`), but the user can flip this
  // with the eye icon. Only relevant for password fields.
  late bool _hidden = widget.obscureText;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _hidden,
      keyboardType: widget.keyboardType,
      maxLines: widget.obscureText ? 1 : widget.maxLines,
      validator: widget.validator,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        suffixIcon: widget.obscureText
            ? IconButton(
                icon: Icon(_hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                tooltip: _hidden ? 'Show password' : 'Hide password',
                onPressed: () => setState(() => _hidden = !_hidden),
              )
            : null,
      ),
    );
  }
}
