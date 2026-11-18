import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/student/student_course_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/utils/link_opener.dart';
import 'package:lms/models/student/student_study_material_model.dart';
import '../../../widgets/compact_dropdown.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../../widgets/custom_loader.dart';
import '../../../widgets/empty_state_widget.dart';
import '../../../widgets/error_state_widget.dart';
import '../../../widgets/search_field.dart';
import '../../../widgets/section_card.dart';
import '../../../widgets/status_badge.dart';
import '../../../widgets/student/student_drawer.dart';

/// The "Study Materials" screen: search + subject filter, then every
/// note/PDF/video a faculty member has shared.
class StudentCoursesScreen extends StatefulWidget {
  const StudentCoursesScreen({super.key});

  @override
  State<StudentCoursesScreen> createState() => _StudentCoursesScreenState();
}

class _StudentCoursesScreenState extends State<StudentCoursesScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _subjectFilter = 'All Subjects';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<StudentCourseController>();
    controller.ensureMaterialsLoaded();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(
        title: 'Study Materials',
        subtitle: 'Chapter-wise notes, PDFs and reference documents',
        fallbackRoute: Routes.studentDashboard,
      ),
      drawer: const StudentDrawer(currentRoute: Routes.studentCourses),
      body: Obx(() {
        final error = controller.materialsError.value;
        if (error != null && !controller.hasLoadedMaterials) {
          return ErrorStateWidget(message: error, onRetry: controller.loadMaterials);
        }
        if (controller.isLoadingMaterials.value && !controller.hasLoadedMaterials) {
          return const CustomLoader();
        }

        final subjects = controller.materialSubjects;
        // A refresh may have removed the picked subject.
        if (!subjects.contains(_subjectFilter)) _subjectFilter = subjects.first;

        final query = _searchQuery.trim().toLowerCase();
        final materials = controller.materials.where((material) {
          final matchesSearch = material.title.toLowerCase().contains(query) ||
              material.chapter.toLowerCase().contains(query);
          final matchesSubject =
              _subjectFilter == 'All Subjects' || material.subject == _subjectFilter;
          return matchesSearch && matchesSubject;
        }).toList();

        return RefreshIndicator(
          onRefresh: controller.loadMaterials,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: SearchField(
                      controller: _searchController,
                      hint: 'Search materials...',
                      onChanged: (value) => setState(() => _searchQuery = value),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: CompactDropdown<String>(
                      value: _subjectFilter,
                      options: subjects,
                      labelFor: (option) => option,
                      onChanged: (value) => setState(() => _subjectFilter = value!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SectionCard(
                title: 'Materials',
                padding: EdgeInsets.zero,
                child: materials.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(24),
                        child: EmptyStateWidget(
                          icon: Icons.folder_off_outlined,
                          title: 'Nothing here',
                          message: 'No materials match this search/filter.',
                        ),
                      )
                    : Column(
                        children: [
                          for (final material in materials) _MaterialTile(material: material),
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

class _MaterialTile extends StatelessWidget {
  final StudentStudyMaterialModel material;

  const _MaterialTile({required this.material});

  /// Text lessons (and lessons with only notes) open in a dialog.
  bool get _readsInApp => material.url.isEmpty && material.textContent.isNotEmpty;

  (String, IconData) get _action {
    if (_readsInApp) return ('Read', Icons.article_outlined);
    return switch (material.type) {
      StudentMaterialType.video => ('Watch', Icons.play_circle_outline),
      StudentMaterialType.link => ('Open', Icons.open_in_new),
      StudentMaterialType.image => ('View', Icons.image_outlined),
      _ => ('Download', Icons.download_outlined),
    };
  }

  void _showText(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(material.title),
        content: SingleChildScrollView(child: Text(material.textContent)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  material.title,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    material.subject,
                    if (material.chapter.isNotEmpty) material.chapter,
                    material.uploadedByFacultyName,
                    material.dateText,
                  ].where((part) => part.isNotEmpty).join(' · '),
                  style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          _typeBadge(material.type),
          const SizedBox(width: 8),
          // An icon (not a "Download" text button) so the row still fits
          // a small phone next to the type badge.
          IconButton(
            tooltip: _action.$1,
            visualDensity: VisualDensity.compact,
            icon: Icon(_action.$2, size: 22),
            onPressed: _readsInApp
                ? () => _showText(context)
                : material.url.isEmpty
                    ? null
                    : () => openLink(material.url),
          ),
        ],
      ),
    );
  }

  Widget _typeBadge(StudentMaterialType type) {
    switch (type) {
      case StudentMaterialType.pdf:
        return const StatusBadge(label: 'PDF', type: BadgeType.info);
      case StudentMaterialType.video:
        return const StatusBadge(label: 'Video', type: BadgeType.warning);
      case StudentMaterialType.document:
        return const StatusBadge(label: 'Document', type: BadgeType.neutral);
      case StudentMaterialType.image:
        return const StatusBadge(label: 'Image', type: BadgeType.success);
      case StudentMaterialType.presentation:
        return const StatusBadge(label: 'Slides', type: BadgeType.info);
      case StudentMaterialType.text:
        return const StatusBadge(label: 'Notes', type: BadgeType.neutral);
      case StudentMaterialType.link:
        return const StatusBadge(label: 'Media', type: BadgeType.warning);
    }
  }
}
