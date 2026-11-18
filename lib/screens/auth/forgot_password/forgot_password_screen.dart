import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/validators.dart';
import '../../../services/auth_service.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_text_field.dart';

/// The "Forgot Password" screen: the user types their email and the
/// server emails them a reset link (API 2).
///
/// The server gives the same reply whether or not the email is
/// registered, so the screen never reveals which emails have accounts.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _authService = AuthService();

  bool _isSending = false;

  /// The server's reply once the request has gone through.
  String? _sentMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendLink() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSending = true);
    try {
      final message = await _authService.requestPasswordReset(_emailController.text.trim());
      if (mounted) setState(() => _sentMessage = message);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ApiClient.messageFor(e))));
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Icon(Icons.lock_reset_outlined, size: 56),
            const SizedBox(height: 16),
            const Text(
              'Enter the email linked to your account and we will send you '
              'a link to reset your password.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (_sentMessage != null) ...[
              Text(_sentMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              CustomButton(
                text: 'Back to Login',
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ] else
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CustomTextField(
                      controller: _emailController,
                      label: 'Email',
                      hint: 'you@example.com',
                      keyboardType: TextInputType.emailAddress,
                      validator: Validators.email,
                    ),
                    const SizedBox(height: 20),
                    CustomButton(
                      text: 'Send Reset Link',
                      isLoading: _isSending,
                      onPressed: _isSending ? null : _sendLink,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
