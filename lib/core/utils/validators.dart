/// Simple helper functions for checking that form input is valid.
///
/// Each function takes the text the user typed and returns:
///   - null if the text is OK
///   - an error message (String) if the text is NOT OK
///
/// This matches what Flutter's TextFormField `validator` expects.
class Validators {
  Validators._();

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email';
    }

    // A simple check: does it contain an "@" and a "." after it?
    final emailPattern = RegExp(r'^[\w\.\-]+@[\w\-]+\.[\w\-\.]+$');
    if (!emailPattern.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }

    if (value.length < 4) {
      return 'Password must be at least 4 characters';
    }

    return null;
  }

  /// A generic check used for fields that simply must not be empty,
  /// like "Name" or "Department".
  static String? notEmpty(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName cannot be empty';
    }
    return null;
  }
}
