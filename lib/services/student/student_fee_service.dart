import '../../core/constants/app_urls.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/date_formatters.dart';
import '../../core/utils/json_parsers.dart';
import 'package:lms/models/student/fee_receipt_model.dart';
import 'package:lms/models/student/fee_summary_model.dart';
import 'package:lms/models/student/student_fee_item_model.dart';
import 'package:lms/services/student/student_record_service.dart';

/// Loads the student's fees, payment receipts and paid items.
class StudentFeeService {
  final ApiClient _apiClient = ApiClient();
  final StudentRecordService _recordService = StudentRecordService();

  /// Every fee charged to the student, plus a summary of them all.
  /// From `AppUrls.studentFees`.
  Future<({FeeSummaryModel summary, List<StudentFeeItemModel> fees})> getFees() async {
    final items = jsonList(await _apiClient.get(AppUrls.studentFees));

    var total = 0.0;
    var paid = 0.0;
    var due = 0.0;
    final fees = <StudentFeeItemModel>[];
    final unpaid = <(DateTime, double)>[];

    for (final item in items) {
      final netAmount = jsonDouble(item['net_amount']);
      final paidAmount = jsonDouble(item['paid_amount']);
      final dueAmount = jsonDouble(item['due_amount']) + jsonDouble(item['late_fee_due']);
      final dueDate = jsonDate(item['due_date']);

      total += netAmount;
      paid += paidAmount;
      due += dueAmount;

      if (dueAmount > 0 && dueDate != null) unpaid.add((dueDate, dueAmount));

      final installment = jsonString(item['installment_name']);
      final feeHead = jsonString(item['fee_head_name']);

      fees.add(StudentFeeItemModel(
        feeHead: installment.isEmpty ? feeHead : '$feeHead - $installment',
        dueDateText: dueDate == null ? '' : formatDate(dueDate),
        netAmount: netAmount,
        paidAmount: paidAmount,
        dueAmount: dueAmount,
        status: jsonString(item['status']),
      ));
    }

    // The "next installment" is whichever unpaid fee is due soonest.
    unpaid.sort((a, b) => a.$1.compareTo(b.$1));
    final next = unpaid.isEmpty ? null : unpaid.first;

    return (
      summary: FeeSummaryModel(
        totalFee: total,
        amountDue: due,
        amountPaid: paid,
        nextInstallmentAmount: next?.$2 ?? 0,
        nextInstallmentDueDateText: next == null ? '' : formatDate(next.$1),
      ),
      fees: fees,
    );
  }

  /// The official total / paid / due from `AppUrls.feeSummary` (API
  /// 20), applied on top of `current` (which keeps the next-installment
  /// details worked out by `getFees`).
  Future<FeeSummaryModel> applyFeeSummary(FeeSummaryModel current) async {
    final totals = await getOfficialTotals();
    return withOfficialTotals(current, totals);
  }

  /// Just the official total / paid / due from `AppUrls.feeSummary`
  /// (API 31), so it can load at the same time as the fee list.
  Future<({double total, double paid, double due})> getOfficialTotals() async {
    final studentId = await _recordService.getStudentId();
    final json = jsonMap(await _apiClient.get(AppUrls.feeSummary(studentId)));
    return (
      total: jsonDouble(json['total_fee']),
      paid: jsonDouble(json['amount_paid']),
      due: jsonDouble(json['amount_due']),
    );
  }

  /// `current` (worked out from the fee list) with the official totals.
  FeeSummaryModel withOfficialTotals(
    FeeSummaryModel current,
    ({double total, double paid, double due}) totals,
  ) {
    return FeeSummaryModel(
      totalFee: totals.total,
      amountPaid: totals.paid,
      amountDue: totals.due,
      nextInstallmentAmount: current.nextInstallmentAmount,
      nextInstallmentDueDateText: current.nextInstallmentDueDateText,
    );
  }

  /// Payment receipts, most recent first. From `AppUrls.feePayments`.
  Future<List<FeeReceiptModel>> getPaymentHistory() async {
    final items = jsonList(await _apiClient.get(AppUrls.feePayments));

    final receipts = <(DateTime?, FeeReceiptModel)>[];
    for (final item in items) {
      final paidAt = jsonDate(item['paid_at']);
      final feeHeads = jsonList(item['items'])
          .map((paidItem) => jsonString(paidItem['fee_head_name']))
          .where((name) => name.isNotEmpty)
          .toSet();

      receipts.add((
        paidAt,
        FeeReceiptModel(
          receiptNo: jsonString(item['receipt_no']),
          description: feeHeads.isEmpty ? 'Fee Payment' : feeHeads.join(', '),
          amount: jsonDouble(item['amount_paid']),
          dateText: paidAt == null ? '' : formatDate(paidAt),
          paymentMode: jsonString(item['payment_mode_name']),
          studentName: jsonString(item['student_name']),
          registrationNo: jsonString(item['registration_no']),
          courseName: jsonString(item['course_name']),
          semesterName: jsonString(item['semester_name']),
          branchName: jsonString(item['branch_name']),
          sessionName: jsonString(item['academic_year_name']),
          status: jsonString(item['status']),
          transactionId: jsonString(item['transaction_id']),
          chequeNo: jsonString(item['cheque_no']),
          remarks: jsonString(item['remarks']),
          items: [
            for (final paidItem in jsonList(item['items']))
              FeeReceiptItemModel(
                feeHead: jsonString(paidItem['fee_head_name']),
                description: jsonString(paidItem['installment_name']),
                discount: jsonDouble(paidItem['discount_amount']),
                lateFine: jsonDouble(paidItem['fine_amount']),
                amount: jsonDouble(paidItem['amount']),
              ),
          ],
        ),
      ));
    }

    receipts.sort((a, b) => (b.$1 ?? DateTime(0)).compareTo(a.$1 ?? DateTime(0)));
    return [for (final receipt in receipts) receipt.$2];
  }

  /// Total paid per fee head, adding up every paid item. From
  /// `AppUrls.feePaymentItems`.
  Future<List<FeeHeadPaidModel>> getPaidByFeeHead() async {
    final items = jsonList(await _apiClient.get(AppUrls.feePaymentItems));

    final totals = <String, (double amount, double fine)>{};
    for (final item in items) {
      final feeHead = jsonString(item['fee_head_name']);
      final current = totals[feeHead] ?? (0, 0);
      totals[feeHead] = (
        current.$1 + jsonDouble(item['amount']),
        current.$2 + jsonDouble(item['fine_amount']),
      );
    }

    return [
      for (final MapEntry(key: feeHead, value: sums) in totals.entries)
        FeeHeadPaidModel(feeHead: feeHead, amount: sums.$1, fineAmount: sums.$2),
    ];
  }
}
