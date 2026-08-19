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
import '../../../widgets/custom_text_field.dart';
import '../../../widgets/section_card.dart';
import '../../../widgets/student/student_drawer.dart';

const List<String> _certificateTypes = [
  'Bonafide Certificate',
  'Character Certificate',
  'Transfer Certificate',
];

/// The "Certificates" screen: the student's issued certificates/
/// documents, plus a form to request a new one.
class StudentCertificatesScreen extends StatefulWidget {
  const StudentCertificatesScreen({super.key});

  @override
  State<StudentCertificatesScreen> createState() => _StudentCertificatesScreenState();
}

class _StudentCertificatesScreenState extends State<StudentCertificatesScreen> {
  final _reasonController = TextEditingController();
  String _certificateType = _certificateTypes.first;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _submitRequest() {
    if (_reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a reason for the request')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$_certificateType request submitted')),
    );

    setState(() {
      _reasonController.clear();
      _certificateType = _certificateTypes.first;
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<StudentCertificateController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(
        title: 'Certificates',
        subtitle: 'Download your certificates and placement letters',
        fallbackRoute: Routes.studentDashboard,
      ),
      drawer: const StudentDrawer(currentRoute: Routes.studentCertificates),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const CustomLoader();
        }

        return RefreshIndicator(
          onRefresh: controller.loadCertificates,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
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
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _reasonController,
                      label: 'Reason',
                      hint: 'Purpose of request',
                    ),
                    const SizedBox(height: 20),
                    CustomButton(text: 'Submit Request', onPressed: _submitRequest),
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
        return (icon: Icons.hourglass_empty_outlined, color: AppColors.statusAmber);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAvailable = certificate.status == CertificateStatus.available;
    final style = _iconStyle;

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
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              minimumSize: const Size(0, 32),
            ),
            onPressed: isAvailable
                ? () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Downloading "${certificate.title}"...')),
                    );
                  }
                : null,
            child: Text(
              isAvailable ? 'Download' : 'Not Available',
              style: const TextStyle(fontSize: 11.5),
            ),
          ),
        ],
      ),
    );
  }
}
