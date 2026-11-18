import 'package:get/get.dart';
import '../../core/network/api_client.dart';
import '../../core/network/saved_then_fresh.dart';
import 'package:lms/models/student/placement_models.dart';
import 'package:lms/services/student/student_placement_service.dart';

/// Holds placement drives, the student's applications and placed
/// students for the Placements screen, and applies to drives.
class StudentPlacementController extends GetxController {
  final StudentPlacementService _service = StudentPlacementService();

  final RxBool isLoading = true.obs;
  final RxnString errorMessage = RxnString();
  bool hasLoaded = false;

  final RxList<PlacementDriveModel> drives = <PlacementDriveModel>[].obs;
  final RxList<PlacementApplicationModel> applications = <PlacementApplicationModel>[].obs;
  final RxList<PlacedStudentModel> placedStudents = <PlacedStudentModel>[].obs;

  /// The drive currently being applied to, so only its button spins.
  final RxnString applyingDriveId = RxnString();

  @override
  void onInit() {
    super.onInit();
    loadPlacements();
  }

  Future<void> loadPlacements() async {
    isLoading.value = true;
    errorMessage.value = null;

    errorMessage.value = await loadSavedThenFresh(
      () => Future.wait([
        _service.getDrives(),
        _service.getApplications(),
        _service.getPlacedStudents(),
      ]),
      (results) {
        drives.assignAll(results[0] as List<PlacementDriveModel>);
        applications.assignAll(results[1] as List<PlacementApplicationModel>);
        placedStudents.assignAll(results[2] as List<PlacedStudentModel>);
        hasLoaded = true;
        isLoading.value = false;
      },
    );
    isLoading.value = false;
  }

  /// The student's application to `drive`, or null if they haven't
  /// applied.
  PlacementApplicationModel? applicationFor(PlacementDriveModel drive) {
    for (final application in applications) {
      if (application.driveId == drive.id) return application;
    }
    return null;
  }

  /// Applies to `drive`, then reloads the applications. Returns the
  /// message to show - the server's own wording when it sent one (for
  /// both success and failure) - and whether it worked.
  Future<({bool ok, String message})> apply(PlacementDriveModel drive) async {
    applyingDriveId.value = drive.id;

    try {
      final serverMessage = await _service.apply(drive.id);
      final message = serverMessage ?? 'Applied to ${drive.companyName}';
      try {
        applications.assignAll(await _service.getApplications());
      } catch (_) {
        // The application went through; a failed refresh of the list
        // shouldn't turn that into an error.
      }
      return (ok: true, message: message);
    } catch (e) {
      return (ok: false, message: ApiClient.messageFor(e));
    } finally {
      applyingDriveId.value = null;
    }
  }
}
