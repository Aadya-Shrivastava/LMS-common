import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/student/student_profile_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import 'package:lms/models/student/student_profile_model.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_loader.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../widgets/section_card.dart';
import '../../../widgets/status_badge.dart';
import '../../../widgets/student/student_drawer.dart';

/// The "Account Settings" screen: built the same way the faculty one
/// is (a changeable photo, editable contact details, change password),
/// with the student-specific Personal Information, Academic
/// Information and Digital ID Card sections from the prototype added
/// on top.
///
/// Everything here is local UI state - there's no backend yet to
/// actually upload a photo or save these details against, so the
/// buttons just confirm the action with a snackbar.
class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
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

  void _downloadIdCard() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Downloading ID card...')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<StudentProfileController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(
        title: 'Account Settings',
        fallbackRoute: Routes.studentDashboard,
      ),
      drawer: const StudentDrawer(currentRoute: Routes.studentProfile),
      body: Obx(() {
        final profile = controller.profile.value;
        if (controller.isLoading.value || profile == null) {
          return const CustomLoader();
        }

        return RefreshIndicator(
          onRefresh: controller.loadProfile,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildPhotoCard(profile),
              const SizedBox(height: 16),
              _buildPersonalInfoCard(profile),
              const SizedBox(height: 16),
              _buildAcademicInfoCard(profile),
              const SizedBox(height: 16),
              _buildIdCard(profile),
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
      }),
    );
  }

  /// The profile photo card: a big circular avatar with a small camera
  /// button overlaid on its corner, plus the student's name, course ·
  /// batch, and an "Active Student" badge.
  Widget _buildPhotoCard(StudentProfileModel profile) {
    final initial = profile.fullName.isNotEmpty ? profile.fullName[0].toUpperCase() : 'S';

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
            Text(profile.fullName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 2),
            Text(
              '${profile.course} · ${profile.batch}',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            const StatusBadge(label: 'Active Student', type: BadgeType.success),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInfoCard(StudentProfileModel profile) {
    return SectionCard(
      title: 'Personal Information',
      child: Column(
        children: [
          _InfoRow(label: 'Full Name', value: profile.fullName),
          _InfoRow(label: 'Enrollment No.', value: profile.enrollmentNo),
          _InfoRow(label: "Father's Name", value: profile.fatherName),
          _InfoRow(label: 'Date of Birth', value: profile.dateOfBirthText),
          _InfoRow(label: 'Mobile Number', value: profile.mobileNumber),
          _InfoRow(label: 'Email Address', value: profile.email),
          _InfoRow(label: 'Address', value: profile.address, isLast: true),
        ],
      ),
    );
  }

  Widget _buildAcademicInfoCard(StudentProfileModel profile) {
    return SectionCard(
      title: 'Academic Information',
      child: Column(
        children: [
          _InfoRow(label: 'Course', value: profile.course),
          _InfoRow(label: 'Batch', value: profile.batch),
          _InfoRow(label: 'Semester', value: profile.semester),
          _InfoRow(label: 'Admission Date', value: profile.admissionDateText, isLast: true),
        ],
      ),
    );
  }

  /// The gradient "Digital ID Card" - a compact reproduction of the
  /// student's physical ID, with a button to download it.
  Widget _buildIdCard(StudentProfileModel profile) {
    final initial = profile.fullName.isNotEmpty ? profile.fullName[0].toUpperCase() : 'S';

    return SectionCard(
      title: 'Digital ID Card',
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primaryNavy, AppColors.secondaryNavy],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'MAA GULJARI BHARAT ITI',
                  style: TextStyle(color: Colors.white70, fontSize: 11, letterSpacing: 0.4),
                ),
                const SizedBox(height: 14),
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.white.withValues(alpha: 0.2),
                  child: Text(
                    initial,
                    style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  profile.fullName,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  '${profile.enrollmentNo} · ${profile.course}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _downloadIdCard,
              icon: const Icon(Icons.download_outlined, size: 18),
              label: const Text('Download ID Card'),
            ),
          ),
        ],
      ),
    );
  }
}

/// One read-only "label / value" line used across the Personal and
/// Academic Information cards.
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isLast;

  const _InfoRow({required this.label, required this.value, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      margin: EdgeInsets.only(bottom: isLast ? 0 : 12),
      decoration: isLast
          ? null
          : const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
