import 'package:flutter/material.dart';
import '../../../widgets/empty_state_widget.dart';

/// The "Forgot Password" screen.
///
/// This is a placeholder for now - it will eventually let the user
/// type their email and receive a reset link, once there's a real
/// backend to send that email.
class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password')),
      body: const EmptyStateWidget(
        icon: Icons.lock_reset_outlined,
        title: 'Coming Soon',
        message: 'Password reset will be available once the app '
            'is connected to a real backend.',
      ),
    );
  }
}
