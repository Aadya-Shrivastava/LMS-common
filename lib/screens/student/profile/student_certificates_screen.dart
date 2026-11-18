import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/student/student_certificate_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import 'package:lms/models/student/certificate_model.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_dropdown_field.dart';
import '../../../widgets/custom_loader.dart';
import '../../../widgets/documents/certificate_document.dart';
import '../../../widgets/documents/document_viewer_screen.dart';
import '../../../widgets/empty_state_widget.dart';
import '../../../widgets/error_state_widget.dart';
import '../../../widgets/section_card.dart';
import '../../../widgets/status_badge.dart';
import '../../../widgets/student/student_drawer.dart';

const List<String> _certificateTypes = [
  'Bonafide Certificate',
  'Character Certificate',
  'Course Completion',
  'Transfer Certificate',
];

/// The "Certificates" screen: the student's certificate requests and
/// issued certificates, plus a form to request a new one.
class StudentCertificatesScreen extends StatefulWidget {
  const StudentCertificatesScreen({super.key});

  @override
  State<StudentCertificatesScreen> createState() => _StudentCertificatesScreenState();
}

class _StudentCertificatesScreenState extends State<StudentCertificatesScreen> {
  String _certificateType = _certificateTypes.first;

  Future<void> _submitRequest(StudentCertificateController controller) async {
    final error = await controller.requestCertificate(_certificateType);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? '$_certificateType requested')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<StudentCertificateController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(
        title: 'Certificates',
        subtitle: 'Your certificate requests and issued certificates',
        fallbackRoute: Routes.studentDashboard,
      ),
      drawer: const StudentDrawer(currentRoute: Routes.studentCertificates),
      body: Obx(() {
        final error = controller.errorMessage.value;
        if (error != null && !controller.hasLoaded) {
          return ErrorStateWidget(message: error, onRetry: controller.loadCertificates);
        }
        if (controller.isLoading.value && !controller.hasLoaded) {
          return const CustomLoader();
        }

        return RefreshIndicator(
          onRefresh: controller.loadCertificates,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (controller.certificates.isEmpty)
                const SectionCard(
                  title: 'My Certificates',
                  child: EmptyStateWidget(
                    icon: Icons.workspace_premium_outlined,
                    title: 'No certificates yet',
                    message: 'Request one below and it will show up here.',
                  ),
                ),
              for (final certificate in controller.certificates) ...[
                _CertificateCard(certificate: certificate),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 4),
              SectionCard(
                title: 'Request a New Certificate',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomDropdownField<String>(
                      label: 'Certificate Type',
                      value: _certificateType,
                      options: _certificateTypes,
                      labelFor: (option) => option,
                      onChanged: (value) => setState(() => _certificateType = value!),
                    ),
                    const SizedBox(height: 20),
                    Obx(() => CustomButton(
                          text: 'Submit Request',
                          isLoading: controller.isSubmitting.value,
                          onPressed: controller.isSubmitting.value
                              ? null
                              : () => _submitRequest(controller),
                        )),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _CertificateCard extends StatelessWidget {
  final CertificateModel certificate;

  const _CertificateCard({required this.certificate});

  ({IconData icon, Color color}) get _iconStyle {
    switch (certificate.icon) {
      case IconIdentifier.marksheet:
        return (icon: Icons.description_outlined, color: AppColors.statCardBlue);
      case IconIdentifier.bonafide:
        return (icon: Icons.check_circle_outline, color: AppColors.statusGreen);
      case IconIdentifier.completion:
        return (icon: Icons.school_outlined, color: AppColors.statusAmber);
    }
  }

  /// Opens the issued certificate as a document, filled in with the
  /// details from the API. Falls back to a plain list of the details
  /// if the server hasn't sent any (so there's nothing to fill in).
  Future<void> _viewDetails(BuildContext context) async {
    if (certificate.issuedData.isNotEmpty) {
      return DocumentViewerScreen.open(
        context,
        title: certificate.title,
        pageWidth: CertificateDocument.pageWidth,
        page: CertificateDocument(certificate: certificate),
        fileName: DocumentViewerScreen.safeFileName(
          [
            certificate.title,
            certificate.issuedData['name'] ?? '',
            certificate.certificateNo,
          ].where((part) => part.isNotEmpty).join('_'),
        ),
      );
    }

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(certificate.title),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(certificate.subtitle,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 10),
                for (final entry in certificate.issuedDetails.entries)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 100,
                          child: Text(entry.key,
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ),
                        Expanded(
                          child: Text(entry.value,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                if (certificate.remarks.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('Remarks: ${certificate.remarks}', style: const TextStyle(fontSize: 12)),
                ],
                const SizedBox(height: 10),
                const Text(
                  'Collect the printed copy from the office.',
                  style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = _iconStyle;

    final (label, type) = switch (certificate.status) {
      CertificateStatus.available => ('Issued', BadgeType.success),
      CertificateStatus.notYetAvailable => ('Pending', BadgeType.warning),
      CertificateStatus.rejected => ('Rejected', BadgeType.danger),
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: style.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(style.icon, color: style.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  certificate.title,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  certificate.subtitle,
                  style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (certificate.status == CertificateStatus.available)
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                minimumSize: const Size(0, 32),
              ),
              onPressed: () => _viewDetails(context),
              child: const Text('View', style: TextStyle(fontSize: 11.5)),
            )
          else
            StatusBadge(label: label, type: type),
        ],
      ),
    );
  }
}
