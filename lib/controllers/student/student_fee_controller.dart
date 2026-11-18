import 'package:get/get.dart';
import '../../core/network/saved_then_fresh.dart';
import 'package:lms/models/student/student_record_model.dart';
import 'package:lms/models/student/fee_receipt_model.dart';
import 'package:lms/models/student/fee_summary_model.dart';
import 'package:lms/models/student/student_fee_item_model.dart';
import 'package:lms/services/student/student_fee_service.dart';
import 'package:lms/services/student/student_record_service.dart';

/// Holds the student's fee summary, fee breakdown and payment history.
class StudentFeeController extends GetxController {
  final StudentFeeService _service = StudentFeeService();

  final RxBool isLoading = true.obs;
  final RxnString errorMessage = RxnString();

  final Rx<FeeSummaryModel?> summary = Rx<FeeSummaryModel?>(null);
  final RxList<StudentFeeItemModel> fees = <StudentFeeItemModel>[].obs;
  final RxList<FeeReceiptModel> paymentHistory = <FeeReceiptModel>[].obs;
  final RxList<FeeHeadPaidModel> paidByFeeHead = <FeeHeadPaidModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadFees();
  }

  Future<void> loadFees() async {
    isLoading.value = true;
    errorMessage.value = null;

    // Everything loads at the same time. The official totals (fee
    // summary API) and the institute name are extras: if they fail, the
    // totals added up from the fee list are still correct, and the
    // receipt just leaves the name out.
    errorMessage.value = await loadSavedThenFresh(
      () => Future.wait<Object?>([
        _service.getFees(),
        _service.getPaymentHistory(),
        _service.getPaidByFeeHead(),
        _optional(_service.getOfficialTotals()),
        _optional(_recordService.getRecord()),
      ]),
      (results) {
        final feeData =
            results[0]! as ({FeeSummaryModel summary, List<StudentFeeItemModel> fees});
        final totals = results[3] as ({double total, double paid, double due})?;
        final record = results[4] as StudentRecordModel?;

        summary.value = totals == null
            ? feeData.summary
            : _service.withOfficialTotals(feeData.summary, totals);
        fees.assignAll(feeData.fees);
        paymentHistory.assignAll(results[1]! as List<FeeReceiptModel>);
        paidByFeeHead.assignAll(results[2]! as List<FeeHeadPaidModel>);
        if (record != null) instituteName.value = record.instituteName;
        isLoading.value = false;
      },
    );
    isLoading.value = false;
  }

  /// Waits for `future`, giving back null instead of an error.
  Future<T?> _optional<T>(Future<T> future) async {
    try {
      return await future;
    } catch (_) {
      return null;
    }
  }

  /// e.g. "Mgbi", from the student record (API 4). Printed at the top
  /// of fee receipts.
  final RxString instituteName = ''.obs;
  final StudentRecordService _recordService = StudentRecordService();
}
