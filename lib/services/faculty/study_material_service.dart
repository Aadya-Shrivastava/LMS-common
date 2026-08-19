import 'package:lms/models/faculty/study_material_model.dart';

/// Provides the study materials a faculty member has uploaded.
class StudyMaterialService {
  Future<List<StudyMaterialModel>> getMyMaterials() async {
    await Future.delayed(const Duration(milliseconds: 400));

    return const [
      StudyMaterialModel(
        id: 'm1',
        title: 'Chapter 4 - Wiring Diagrams Notes',
        subject: 'Basic Electrical Wiring',
        type: StudyMaterialType.pdf,
        batch: 'Batch A',
        uploadedOnText: '29 Jul 2026',
      ),
      StudyMaterialModel(
        id: 'm2',
        title: 'Practical Demo - Wiring',
        subject: 'Basic Electrical Wiring',
        type: StudyMaterialType.video,
        batch: 'Batch A',
        uploadedOnText: '10 Jul 2026',
      ),
      StudyMaterialModel(
        id: 'm3',
        title: 'Circuit Design Reference',
        subject: 'Circuit Design',
        type: StudyMaterialType.pdf,
        batch: 'Batch B',
        uploadedOnText: '25 Jul 2026',
      ),
    ];
  }
}
