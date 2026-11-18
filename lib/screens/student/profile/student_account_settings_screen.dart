import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/student/student_profile_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/utils/date_formatters.dart';
import 'package:lms/models/student/student_profile_model.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_loader.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../widgets/error_state_widget.dart';
import '../../../widgets/section_card.dart';
import '../../../widgets/student/student_drawer.dart';

/// The "Account Settings" screen: the things the student can change.
///   - Contact details: mobile, guardian mobile, address (API 6).
///   - Change password (API 42).
///   - Logged-in devices (API 43), with "log out other devices" (API 44).
///
/// The read-only details (personal and academic info, documents, ID
/// card) are on the separate "My Profile" screen.
class StudentAccountSettingsScreen extends StatefulWidget {
  const StudentAccountSettingsScreen({super.key});

  @override
  State<StudentAccountSettingsScreen> createState() =>
      _StudentAccountSettingsScreenState();
}

class _StudentAccountSettingsScreenState
    extends State<StudentAccountSettingsScreen> {
  final _mobileController = TextEditingController();
  final _guardianMobileController = TextEditingController();
  final _addressController = TextEditingController();

  /// The contact fields are filled from the profile once, the first
  /// time it loads, so a refresh doesn't wipe what the user is typing.
  bool _contactFieldsFilled = false;

  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _mobileController.dispose();
    _guardianMobileController.dispose();
    _addressController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  /// Puts the saved contact details into the fields. The profile shows
  /// "—" for empty values, which shouldn't end up in a text field.
  void _fillContactFields(StudentProfileModel profile) {
    if (_contactFieldsFilled) return;
    _contactFieldsFilled = true;

    String clean(String value) => value == '—' ? '' : value;
    _mobileController.text = clean(profile.mobileNumber);
    _guardianMobileController.text = clean(profile.guardianMobile);
    _addressController.text = clean(profile.address);
  }

  Future<void> _saveDetails() async {
    final message = await Get.find<StudentProfileController>()
        .saveContactDetails(
          mobile: _mobileController.text.trim(),
          guardianMobile: _guardianMobileController.text.trim(),
          address: _addressController.text.trim(),
        );
    _showMessage(message);
  }

  Future<void> _updatePassword() async {
    if (_currentPasswordController.text.isEmpty ||
        _newPasswordController.text.isEmpty) {
      _showMessage('Please fill in your current and new password');
      return;
    }
    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showMessage('New password and confirmation do not match');
      return;
    }

    final controller = Get.find<StudentProfileController>();
    final message = await controller.changePassword(
      currentPassword: _currentPasswordController.text,
      newPassword: _newPasswordController.text,
      confirmNewPassword: _confirmPasswordController.text,
    );
    _showMessage(message);

    // Only clear the fields when it worked, so a typo can be fixed.
    if (mounted && message.toLowerCase().contains('success')) {
      setState(() {
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      });
    }
  }

  Future<void> _logoutOtherDevices() async {
    final message = await Get.find<StudentProfileController>()
        .logoutOtherDevices();
    _showMessage(message);
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<StudentProfileController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(
        title: 'Account Settings',
        subtitle: 'Contact details, password and devices',
        fallbackRoute: Routes.studentDashboard,
      ),
      drawer: const StudentDrawer(currentRoute: Routes.studentAccountSettings),
      body: Obx(() {
        final profile = controller.profile.value;
        final error = controller.errorMessage.value;
        if (error != null && profile == null) {
          return ErrorStateWidget(
            message: error,
            onRetry: controller.loadProfile,
          );
        }
        if (profile == null) {
          return const CustomLoader(layout: SkeletonLayout.form);
        }
        _fillContactFields(profile);
        final isSaving = controller.isSaving.value;

        return RefreshIndicator(
          onRefresh: controller.loadProfile,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SectionCard(
                title: 'Contact Details',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomTextField(
                      controller: _mobileController,
                      label: 'Mobile Number',
                      hint: 'Enter your mobile number',
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _guardianMobileController,
                      label: 'Guardian Mobile Number',
                      hint: "Enter your guardian's mobile number",
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _addressController,
                      label: 'Address',
                      hint: 'Enter your address',
                      keyboardType: TextInputType.streetAddress,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 20),
                    CustomButton(
                      text: 'Save Details',
                      isLoading: isSaving,
                      onPressed: isSaving ? null : _saveDetails,
                    ),
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
                    CustomButton(
                      text: 'Update Password',
                      isLoading: isSaving,
                      onPressed: isSaving ? null : _updatePassword,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildSessionsCard(controller),
            ],
          ),
        );
      }),
    );
  }

  /// Every device the student is logged in on (API 43), with a button
  /// to log out all the others (API 44).
  Widget _buildSessionsCard(StudentProfileController controller) {
    final sessions = controller.activeSessions;

    return SectionCard(
      title: 'Logged-in Devices',
      child: sessions.isEmpty
          ? const Text(
              'No other active sessions.',
              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
            )
          : Column(
              children: [
                if (sessions.length > 1)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: controller.isSaving.value
                          ? null
                          : _logoutOtherDevices,
                      icon: const Icon(Icons.logout, size: 16),
                      label: const Text('Log out other devices'),
                    ),
                  ),
                for (final session in sessions)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: const Icon(
                      Icons.devices_outlined,
                      color: AppColors.primaryNavy,
                    ),
                    title: Text(
                      session.deviceName.isEmpty
                          ? 'Unknown device'
                          : session.deviceName,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      [
                        if (session.createdAt != null)
                          'Logged in ${formatDateTime(session.createdAt!)}',
                        if (session.expiresAt != null)
                          'expires ${formatDate(session.expiresAt!)}',
                      ].join(' · '),
                      style: const TextStyle(fontSize: 11.5),
                    ),
                  ),
              ],
            ),
    );
  }
}
