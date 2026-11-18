import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/auth_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../models/user_model.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_text_field.dart';

/// The student login screen: email or username, password, and a login
/// button.
///
/// Logs in against the real backend (see AuthService). This app is
/// student-only, so login always signs in as a student.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // A GlobalKey lets us tell the Form widget "please validate yourself".
  final _formKey = GlobalKey<FormState>();

  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();

  // We look up the AuthController that was already created when the
  // app started (see bindings/auth_binding.dart + app.dart).
  final AuthController _authController = Get.find<AuthController>();

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLoginPressed() {
    // Ask the form to check every field's validator. If any of them
    // return an error message, `validate()` returns false and we stop.
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    _authController.login(
      identifier: _identifierController.text.trim(),
      password: _passwordController.text,
      role: UserRole.student,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  Image.asset('assets/images/logo.png', height: 136),
                  const SizedBox(height: 4),
                  const Text(
                    'Sign in to continue',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 32),

                  CustomTextField(
                    controller: _identifierController,
                    label: 'Email or Username',
                    hint: 'you@example.com or username',
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.emailOrUsername,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _passwordController,
                    label: 'Password',
                    hint: 'Enter your password',
                    obscureText: true,
                    validator: Validators.password,
                  ),
                  const SizedBox(height: 24),

                  // `Obx` automatically rebuilds this button whenever
                  // `isLoading` changes, so we don't need setState here.
                  Obx(
                    () => CustomButton(
                      text: 'Login',
                      isLoading: _authController.isLoading.value,
                      onPressed: _onLoginPressed,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Get.toNamed('/forgot-password'),
                    child: const Text('Forgot password?'),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
