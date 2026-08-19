import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/auth_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import 'package:lms/widgets/faculty/app_drawer.dart';
import 'package:lms/widgets/custom_app_bar.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../widgets/section_card.dart';

/// The "Account Settings" screen: a changeable profile photo, contact
/// details (email/phone), and password change.
///
/// Everything here is local UI state - there's no backend yet to
/// actually upload a photo or save these details against, so the
/// buttons just confirm the action with a snackbar.
class FacultyProfileScreen extends StatefulWidget {
  const FacultyProfileScreen({super.key});

  @override
  State<FacultyProfileScreen> createState() => _FacultyProfileScreenState();
}

class _FacultyProfileScreenState extends State<FacultyProfileScreen> {
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  /// True once the user has "changed" their photo. There's no real
  /// image picker wired up (that needs a package + a backend to
  /// actually upload to), so this just swaps the placeholder icon to
  /// show something changed.
  bool _hasCustomPhoto = false;

  @override
  void initState() {
    super.initState();
    // Prefill the email field with whatever the logged-in user's
    // account already has, so it's not empty by default.
    _emailController.text = Get.find<AuthController>().currentUser.value?.email ?? '';
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _changePhoto() {
    setState(() => _hasCustomPhoto = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile photo updated')),
    );
  }

  void _saveDetails() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Contact details saved')),
    );
  }

  void _updatePassword() {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New password and confirmation do not match')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password updated')),
    );

    setState(() {
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'Account Settings'),
      drawer: const AppDrawer(currentRoute: Routes.facultyAccountSettings),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildPhotoCard(),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Contact Details',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomTextField(
                  controller: _emailController,
                  label: 'Email',
                  hint: 'you@example.com',
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _phoneController,
                  label: 'Phone Number',
                  hint: 'Enter your phone number',
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 20),
                CustomButton(text: 'Save Details', onPressed: _saveDetails),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Change Password',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomTextField(
                  controller: _currentPasswordController,
                  label: 'Current Password',
                  hint: 'Enter current password',
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _newPasswordController,
                  label: 'New Password',
                  hint: 'Enter new password',
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _confirmPasswordController,
                  label: 'Confirm New Password',
                  hint: 'Re-enter new password',
                  obscureText: true,
                ),
                const SizedBox(height: 20),
                CustomButton(text: 'Update Password', onPressed: _updatePassword),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// The profile photo card: a big circular avatar with a small camera
  /// button overlaid on its corner, tap either to "change" the photo.
  Widget _buildPhotoCard() {
    return Obx(() {
      final user = Get.find<AuthController>().currentUser.value;
      final name = user?.name ?? 'Faculty Member';
      final initial = name.isNotEmpty ? name[0].toUpperCase() : 'F';

      return SectionCard(
        title: 'Profile Photo',
        child: Center(
          child: Column(
            children: [
              GestureDetector(
                onTap: _changePhoto,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      radius: 44,
                      backgroundColor: AppColors.primaryNavy.withValues(alpha: 0.1),
                      child: _hasCustomPhoto
                          ? const Icon(Icons.person, size: 44, color: AppColors.primaryNavy)
                          : Text(
                              initial,
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryNavy,
                              ),
                            ),
                    ),
                    Positioned(
                      bottom: -2,
                      right: -2,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: AppColors.primaryNavy,
                          shape: BoxShape.circle,
                          border: Border.fromBorderSide(
                            BorderSide(color: AppColors.white, width: 2),
                          ),
                        ),
                        child: const Icon(Icons.camera_alt, size: 14, color: AppColors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              if (user?.designation.isNotEmpty ?? false)
                Text(
                  user!.designation,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              const SizedBox(height: 4),
              const Text(
                'Tap the photo to change it',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    });
  }
}
