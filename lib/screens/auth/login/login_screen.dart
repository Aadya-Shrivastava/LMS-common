import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/auth_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../models/user_model.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_text_field.dart';

/// The login screen: email, password, a Student/Faculty switch, and a
/// login button.
///
/// There's no real backend yet, so any email and password will work -
/// picking "Faculty" or "Student" simply decides which mock account and
/// which dashboard you're sent to. See AuthService for the mock data.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // A GlobalKey lets us tell the Form widget "please validate yourself".
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Which role is currently selected on screen. Defaults to Faculty,
  // since that's the portal this app is based on.
  UserRole _selectedRole = UserRole.faculty;

  // We look up the AuthController that was already created when the
  // app started (see bindings/auth_binding.dart + app.dart).
  final AuthController _authController = Get.find<AuthController>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLoginPressed() {
    // Ask the form to check every field's validator. If any of them
    // return an error message, `validate()` returns false and we stop.
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    _authController.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      role: _selectedRole,
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
                  const Icon(
                    Icons.school_outlined,
                    size: 56,
                    color: AppColors.primaryNavy,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Campus LMS',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Sign in to continue',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 32),

                  // The Student/Faculty role switch.
                  _buildRoleSelector(),
                  const SizedBox(height: 20),

                  CustomTextField(
                    controller: _emailController,
                    label: 'Email',
                    hint: 'you@example.com',
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.email,
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

  /// Builds the two-button switch that lets the user pick their role
  /// before logging in.
  Widget _buildRoleSelector() {
    return Row(
      children: [
        Expanded(child: _buildRoleButton(UserRole.student, 'Student')),
        const SizedBox(width: 12),
        Expanded(child: _buildRoleButton(UserRole.faculty, 'Faculty')),
      ],
    );
  }

  Widget _buildRoleButton(UserRole role, String label) {
    final isSelected = _selectedRole == role;

    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryNavy : AppColors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primaryNavy : AppColors.cardBorder,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? AppColors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
