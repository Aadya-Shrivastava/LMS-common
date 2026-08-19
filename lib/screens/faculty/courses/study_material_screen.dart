import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/faculty/faculty_course_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import 'package:lms/models/faculty/study_material_model.dart';
import 'package:lms/widgets/faculty/app_drawer.dart';
import 'package:lms/widgets/custom_app_bar.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_dialog.dart';
import '../../../widgets/custom_dropdown_field.dart';
import '../../../widgets/custom_loader.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../widgets/empty_state_widget.dart';
import '../../../widgets/search_field.dart';
import '../../../widgets/section_card.dart';
import '../../../widgets/status_badge.dart';

const List<String> _subjects = ['Basic Electrical Wiring', 'Circuit Design'];
const List<String> _batches = ['Batch A', 'Batch B', 'All Batches'];

/// The "Study Material Upload" screen, split into two tabs:
///   - "New Material": the upload form.
///   - "Uploaded Material": search + browse + delete what's already up.
class StudyMaterialScreen extends StatefulWidget {
  const StudyMaterialScreen({super.key});

  @override
  State<StudyMaterialScreen> createState() => _StudyMaterialScreenState();
}

class _StudyMaterialScreenState extends State<StudyMaterialScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(length: 2, vsync: this);
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<FacultyCourseController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'Study Material Upload',
        subtitle: 'Share notes, PDFs and recorded lectures',
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: AppColors.white,
          tabs: const [
            Tab(text: 'New Material'),
            Tab(text: 'Uploaded Material'),
          ],
        ),
      ),
      drawer: const AppDrawer(currentRoute: Routes.facultyStudyMaterial),
      body: Obx(() {
        if (controller.isLoadingMaterials.value) {
          return const CustomLoader();
        }

        return TabBarView(
          controller: _tabController,
          children: [
            _buildNewMaterialTab(controller),
            _buildUploadedMaterialTab(controller),
          ],
        );
      }),
    );
  }

  Widget _buildNewMaterialTab(FacultyCourseController controller) {
    return RefreshIndicator(
      onRefresh: controller.loadMaterials,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _UploadMaterialForm(controller: controller, onUploaded: () => _tabController.animateTo(1)),
        ],
      ),
    );
  }

  Widget _buildUploadedMaterialTab(FacultyCourseController controller) {
    final query = _searchQuery.trim().toLowerCase();
    final materials = controller.materials
        .where((material) => material.title.toLowerCase().contains(query))
        .toList();

    return RefreshIndicator(
      onRefresh: controller.loadMaterials,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SearchField(
            controller: _searchController,
            hint: 'Search materials by title',
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'My Uploaded Materials',
            padding: EdgeInsets.zero,
            child: materials.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(24),
                    child: EmptyStateWidget(
                      icon: Icons.folder_off_outlined,
                      title: 'Nothing here',
                      message: 'No materials match, or none uploaded yet.',
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
  }
}

class _UploadMaterialForm extends StatefulWidget {
  final FacultyCourseController controller;

  /// Called right after a successful upload, so the screen can flip
  /// over to the "Uploaded Material" tab and show what was just added.
  final VoidCallback onUploaded;

  const _UploadMaterialForm({required this.controller, required this.onUploaded});

  @override
  State<_UploadMaterialForm> createState() => _UploadMaterialFormState();
}

class _UploadMaterialFormState extends State<_UploadMaterialForm> {
  final _titleController = TextEditingController();
  StudyMaterialType _type = StudyMaterialType.pdf;
  String _subject = _subjects.first;
  String _batch = _batches.first;

  /// The name of the file the user picked, shown after tapping the
  /// "Choose File" button. Picking a real file needs a file-picker
  /// package, which isn't wired up yet since there's no backend to
  /// upload it to - for now this just simulates a file being chosen.
  String? _pickedFileName;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  String _typeLabel(StudyMaterialType type) {
    switch (type) {
      case StudyMaterialType.pdf:
        return 'PDF / Notes';
      case StudyMaterialType.video:
        return 'Video Lecture';
      case StudyMaterialType.document:
        return 'Document';
    }
  }

  void _simulateFilePick() {
    setState(() => _pickedFileName = 'document_${DateTime.now().second}.pdf');
  }

  void _upload() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please give the material a title')),
      );
      return;
    }

    widget.controller.addMaterial(
      StudyMaterialModel(
        id: 'm-${DateTime.now().millisecondsSinceEpoch}',
        title: _titleController.text.trim(),
        subject: _subject,
        type: _type,
        batch: _batch,
        uploadedOnText: 'Just now',
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${_titleController.text.trim()} uploaded')),
    );

    setState(() {
      _titleController.clear();
      _pickedFileName = null;
    });

    widget.onUploaded();
  }

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Upload New Material',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomTextField(
            controller: _titleController,
            label: 'Title',
            hint: 'Material title',
          ),
          const SizedBox(height: 16),
          CustomDropdownField<StudyMaterialType>(
            label: 'Type',
            value: _type,
            options: StudyMaterialType.values,
            labelFor: _typeLabel,
            onChanged: (value) => setState(() => _type = value!),
          ),
          const SizedBox(height: 16),
          CustomDropdownField<String>(
            label: 'Subject',
            value: _subject,
            options: _subjects,
            labelFor: (option) => option,
            onChanged: (value) => setState(() => _subject = value!),
          ),
          const SizedBox(height: 16),
          CustomDropdownField<String>(
            label: 'Batch',
            value: _batch,
            options: _batches,
            labelFor: (option) => option,
            onChanged: (value) => setState(() => _batch = value!),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _simulateFilePick,
            icon: const Icon(Icons.attach_file),
            label: Text(_pickedFileName ?? 'Choose File'),
          ),
          const SizedBox(height: 20),
          CustomButton(text: 'Upload & Publish', onPressed: _upload),
        ],
      ),
    );
  }
}

class _MaterialTile extends StatelessWidget {
  final StudyMaterialModel material;

  const _MaterialTile({required this.material});

  String _typeLabel(StudyMaterialType type) {
    switch (type) {
      case StudyMaterialType.pdf:
        return 'PDF / Notes';
      case StudyMaterialType.video:
        return 'Video Lecture';
      case StudyMaterialType.document:
        return 'Document';
    }
  }

  /// Shows the material's full details - there's no real file content
  /// to open (this is mock data, not an actual PDF/video), so this is
  /// just an info view of what was uploaded.
  Future<void> _viewDetails(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(material.title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DetailRow(label: 'Type', value: _typeLabel(material.type)),
              _DetailRow(label: 'Subject', value: material.subject),
              _DetailRow(label: 'Batch', value: material.batch),
              _DetailRow(label: 'Uploaded', value: material.uploadedOnText),
            ],
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

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete material?',
      message: '"${material.title}" will be removed for students too. This cannot be undone.',
    );

    if (confirmed) {
      Get.find<FacultyCourseController>().removeMaterial(material);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${material.title} deleted')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _viewDetails(context),
      child: Container(
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
                    '${material.subject} · ${material.batch} · ${material.uploadedOnText}',
                    style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            _typeBadge(material.type),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              color: AppColors.statusRed,
              tooltip: 'Delete',
              onPressed: () => _confirmDelete(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeBadge(StudyMaterialType type) {
    switch (type) {
      case StudyMaterialType.pdf:
        return const StatusBadge(label: 'PDF', type: BadgeType.info);
      case StudyMaterialType.video:
        return const StatusBadge(label: 'Video', type: BadgeType.warning);
      case StudyMaterialType.document:
        return const StatusBadge(label: 'Document', type: BadgeType.neutral);
    }
  }
}

/// One "label: value" line in the material details dialog.
class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
