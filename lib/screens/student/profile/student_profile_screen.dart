import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/student/student_profile_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/utils/link_opener.dart';
import 'package:lms/models/student/student_profile_model.dart';
import 'package:lms/models/student/student_record_model.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../../widgets/custom_loader.dart';
import '../../../widgets/documents/document_viewer_screen.dart';
import '../../../widgets/documents/id_card_document.dart';
import '../../../widgets/error_state_widget.dart';
import '../../../widgets/section_card.dart';
import '../../../widgets/student/student_drawer.dart';

/// The "My Profile" screen: the student's details, read only.
///   - A header with the photo, name, course and roll no.
///   - Four summary tiles: attendance, grade, fees, placement (API 4).
///   - Personal details and academic details (API 5).
///   - My Documents (ID proof, marksheet) and the Digital ID Card,
///     which can be downloaded as a PDF.
///
/// Things the student can change (contact details, password, devices)
/// are on the separate "Account Settings" screen.
class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  /// Opens the ID card full screen, where it can be downloaded as a PDF.
  void _openIdCard(StudentProfileModel profile) {
    DocumentViewerScreen.open(
      context,
      title: 'Student ID Card',
      pageWidth: IdCardDocument.pageWidth,
      page: IdCardDocument(profile: profile),
      fileName: DocumentViewerScreen.safeFileName('ID_Card_${profile.fullName}'),
      pdfFormat: DocumentViewerScreen.cardFormat,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<StudentProfileController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'My Profile', fallbackRoute: Routes.studentDashboard),
      drawer: const StudentDrawer(currentRoute: Routes.studentProfile),
      body: Obx(() {
        final profile = controller.profile.value;
        final error = controller.errorMessage.value;
        if (error != null && profile == null) {
          return ErrorStateWidget(message: error, onRetry: controller.loadProfile);
        }
        if (profile == null) {
          return const CustomLoader(layout: SkeletonLayout.profile);
        }
        final record = controller.record.value;

        return RefreshIndicator(
          onRefresh: controller.loadProfile,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildHeader(profile),
              if (record != null) ...[const SizedBox(height: 14), _buildSummary(record)],
              const SizedBox(height: 14),
              _buildPersonalCard(profile),
              const SizedBox(height: 14),
              _buildAcademicCard(profile, record),
              const SizedBox(height: 14),
              _buildDocumentsCard(profile, record),
              const SizedBox(height: 14),
              _buildIdCard(profile),
              const SizedBox(height: 14),
              _buildSettingsLink(),
              const SizedBox(height: 8),
            ],
          ),
        );
      }),
    );
  }

  static String _orDash(String value) => value.trim().isEmpty ? '—' : value;

  /// Navy header: photo, name, course, roll no. and
  /// status.
  Widget _buildHeader(StudentProfileModel profile) {
    final initial = profile.fullName.isNotEmpty ? profile.fullName[0].toUpperCase() : 'S';
    final showPhoto = profile.photoUrl.isNotEmpty;
    final subtitle = [profile.course, profile.branch].where((part) => part.isNotEmpty && part != '—').join(' · ');

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryNavy, AppColors.secondaryNavy],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          // Photo changes are hidden until the backend has an upload API.
          CircleAvatar(
            radius: 36,
            backgroundColor: AppColors.white.withValues(alpha: 0.15),
            backgroundImage: showPhoto ? NetworkImage(profile.photoUrl) : null,
            // A broken photo link just leaves the circle blank.
            onBackgroundImageError: showPhoto ? (_, _) {} : null,
            child: showPhoto
                ? null
                : Text(
                    initial,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.white),
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.fullName,
                  style: const TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 12.5)),
                ],
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (profile.rollNo != '—') _HeaderChip('Roll No. ${profile.rollNo}'),
                    const _HeaderChip('Active', highlight: true),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Four headline numbers from the student record (API 4).
  Widget _buildSummary(StudentRecordModel record) {
    return _TwoColumns(
      spacing: 10,
      children: [
        _StatTile(
          icon: Icons.fact_check_outlined,
          color: AppColors.statCardBlue,
          value: _orDash(record.attendanceText),
          label: 'Attendance',
          onTap: () => Get.toNamed(Routes.studentAttendance),
        ),
        _StatTile(
          icon: Icons.emoji_events_outlined,
          color: AppColors.statCardGreen,
          value: _orDash(record.overallGrade),
          label: 'Overall Grade',
          onTap: () => Get.toNamed(Routes.studentExamsResults),
        ),
        _StatTile(
          icon: Icons.currency_rupee,
          color: AppColors.statCardOrange,
          value: _orDash(record.feeStatus),
          label: 'Fee Status',
          onTap: () => Get.toNamed(Routes.studentFees),
        ),
        _StatTile(
          icon: Icons.work_outline,
          color: AppColors.statusPurple,
          value: _orDash(record.placementStatus),
          label: 'Placement',
          onTap: () => Get.toNamed(Routes.studentPlacements),
        ),
      ],
    );
  }

  Widget _buildPersonalCard(StudentProfileModel profile) {
    final guardian = [
      profile.guardianName,
      profile.guardianMobile,
    ].where((part) => part != '—' && part.isNotEmpty).join(' · ');

    return SectionCard(
      title: 'Personal Details',
      child: Column(
        children: [
          _DetailRow(Icons.person_outline, "Father's Name", profile.fatherName),
          _DetailRow(Icons.family_restroom_outlined, 'Guardian', _orDash(guardian)),
          _DetailRow(Icons.cake_outlined, 'Date of Birth', profile.dateOfBirthText),
          _DetailRow(Icons.badge_outlined, 'Gender · Blood', '${profile.gender} · ${profile.bloodGroup}'),
          _DetailRow(Icons.phone_outlined, 'Mobile', profile.mobileNumber),
          _DetailRow(Icons.mail_outline, 'Email', profile.email),
          _DetailRow(Icons.home_outlined, 'Address', profile.address, isLast: true),
        ],
      ),
    );
  }

  Widget _buildAcademicCard(StudentProfileModel profile, StudentRecordModel? record) {
    return SectionCard(
      title: 'Academic Details',
      child: _TwoColumns(
        spacing: 14,
        children: [
          _GridField('Registration No.', profile.registrationNo),
          _GridField('Roll No.', profile.rollNo),
          _GridField('Course', profile.course),
          _GridField('Branch', profile.branch),
          _GridField('Batch', profile.batch),
          _GridField('Semester', profile.semester),
          _GridField('Session', profile.session),
          _GridField('Study Mode', profile.studyMode),
          _GridField('Admission Date', profile.admissionDateText),
          if (record != null) _GridField('Assignments Done', _orDash(record.assignmentsDoneText)),
        ],
      ),
    );
  }

  /// The ID proof and marksheet on file, side by side, plus anything
  /// the office is still waiting for.
  Widget _buildDocumentsCard(StudentProfileModel profile, StudentRecordModel? record) {
    final pending = record?.documentsPending ?? const <String>[];

    return SectionCard(
      title: 'My Documents',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _DocumentTile(label: 'ID Proof', url: profile.idProofUrl),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DocumentTile(label: 'Marksheet', url: profile.marksheetUrl),
              ),
            ],
          ),
          if (pending.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.statusAmberBg, borderRadius: BorderRadius.circular(10)),
              child: Text(
                'Pending: ${pending.join(', ')}',
                style: const TextStyle(fontSize: 12, color: AppColors.statusAmber),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// The "Digital ID Card", laid out like the printed card and filled
  /// in from the profile API. Tap it to see it full size and download.
  Widget _buildIdCard(StudentProfileModel profile) {
    return SectionCard(
      title: 'Digital ID Card',
      child: Column(
        children: [
          GestureDetector(
            onTap: () => _openIdCard(profile),
            child: FittedBox(child: IdCardDocument(profile: profile)),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: AppColors.primaryNavy),
              onPressed: () => _openIdCard(profile),
              icon: const Icon(Icons.download_outlined, size: 18),
              label: const Text('View & Download'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsLink() {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(14),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.cardBorder),
        ),
        leading: const Icon(Icons.manage_accounts_outlined, color: AppColors.primaryNavy),
        title: const Text('Account Settings', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: const Text('Contact details, password & devices', style: TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Get.toNamed(Routes.studentAccountSettings),
      ),
    );
  }
}

/// Lays children out two per row, each half the width.
class _TwoColumns extends StatelessWidget {
  final double spacing;
  final List<Widget> children;

  const _TwoColumns({required this.spacing, required this.children});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - spacing) / 2;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [for (final child in children) SizedBox(width: width, child: child)],
        );
      },
    );
  }
}

/// A small pill in the header, e.g. "Roll 982837".
class _HeaderChip extends StatelessWidget {
  final String text;
  final bool highlight;

  const _HeaderChip(this.text, {this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: highlight ? AppColors.statCardGreen.withValues(alpha: 0.9) : AppColors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(color: AppColors.white, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// One summary tile: a coloured icon, the value, and its label.
class _StatTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;
  final VoidCallback? onTap;

  const _StatTile({required this.icon, required this.color, required this.value, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              if (onTap != null) const Icon(Icons.chevron_right, size: 18, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

/// One personal-details line: icon, label on the left, value on the right.
class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  const _DetailRow(this.icon, this.label, this.value, {this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: isLast
          ? null
          : const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
            ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: Text(label, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              value.trim().isEmpty ? '—' : value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// One academic-details cell: small label over a bold value.
class _GridField extends StatelessWidget {
  final String label;
  final String value;

  const _GridField(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
        const SizedBox(height: 2),
        Text(value.trim().isEmpty ? '—' : value, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

/// A document tile: tap to open it, greyed out if not uploaded.
class _DocumentTile extends StatelessWidget {
  final String label;
  final String url;

  const _DocumentTile({required this.label, required this.url});

  @override
  Widget build(BuildContext context) {
    final uploaded = url.isNotEmpty;

    return InkWell(
      onTap: uploaded ? () => openLink(url) : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: uploaded ? AppColors.sectionBlueBg : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            Icon(
              uploaded ? Icons.description_outlined : Icons.upload_file_outlined,
              size: 22,
              color: uploaded ? AppColors.statCardBlue : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  Text(
                    uploaded ? 'Tap to view' : 'Not uploaded',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
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
