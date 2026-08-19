import 'package:get/get.dart';
import 'package:lms/models/student/fee_receipt_model.dart';
import 'package:lms/models/student/fee_summary_model.dart';
import 'package:lms/services/student/student_fee_service.dart';
import '../../core/utils/date_formatters.dart';

/// Holds the student's fee summary and payment history, and lets them
/// pay the next installment.
class StudentFeeController extends GetxController {
  final StudentFeeService _service = StudentFeeService();

  final RxBool isLoading = true.obs;
  final Rx<FeeSummaryModel?> summary = Rx<FeeSummaryModel?>(null);
  final RxList<FeeReceiptModel> paymentHistory = <FeeReceiptModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadFees();
  }

  Future<void> loadFees() async {
    isLoading.value = true;

    final results = await Future.wait([
      _service.getFeeSummary(),
      _service.getPaymentHistory(),
    ]);

    summary.value = results[0] as FeeSummaryModel;
    paymentHistory.assignAll(results[1] as List<FeeReceiptModel>);

    isLoading.value = false;
  }

  /// Pays off the next installment: adds a receipt to the top of the
  /// history and updates the summary to reflect the new balance.
  /// There's no real payment gateway yet, so this is a local-only mock
  /// payment.
  void payNextInstallment() {
    final current = summary.value;
    if (current == null || current.amountDue <= 0) return;

    final paidAmount = current.nextInstallmentAmount;

    paymentHistory.insert(
      0,
      FeeReceiptModel(
        receiptNo: 'RCPT-${DateTime.now().millisecondsSinceEpoch % 10000}',
        description: 'Semester 2 - Installment',
        amount: paidAmount,
        dateText: formatDate(DateTime.now()),
        paymentMode: 'UPI',
      ),
    );

    summary.value = FeeSummaryModel(
      totalFee: current.totalFee,
      amountDue: (current.amountDue - paidAmount).clamp(0, current.totalFee).toDouble(),
      amountPaid: current.amountPaid + paidAmount,
      nextInstallmentAmount: 0,
      nextInstallmentDueDateText: current.nextInstallmentDueDateText,
    );
  }
}
