import 'package:lms/models/student/fee_receipt_model.dart';
import 'package:lms/models/student/fee_summary_model.dart';

/// Provides the student's fee summary and payment history.
class StudentFeeService {
  Future<FeeSummaryModel> getFeeSummary() async {
    await Future.delayed(const Duration(milliseconds: 300));

    return const FeeSummaryModel(
      totalFee: 45000,
      amountDue: 3000,
      amountPaid: 42000,
      nextInstallmentAmount: 3000,
      nextInstallmentDueDateText: '10 Aug 2026',
    );
  }

  Future<List<FeeReceiptModel>> getPaymentHistory() async {
    await Future.delayed(const Duration(milliseconds: 300));

    return const [
      FeeReceiptModel(
        receiptNo: 'RCPT-8801',
        description: 'Semester 2 - Installment 3',
        amount: 12000,
        dateText: '29 Jul 2026',
        paymentMode: 'UPI',
      ),
      FeeReceiptModel(
        receiptNo: 'RCPT-8560',
        description: 'Semester 2 - Installment 2',
        amount: 15000,
        dateText: '10 May 2026',
        paymentMode: 'Net Banking',
      ),
      FeeReceiptModel(
        receiptNo: 'RCPT-8210',
        description: 'Semester 2 - Installment 1',
        amount: 15000,
        dateText: '15 Feb 2026',
        paymentMode: 'Cash',
      ),
    ];
  }
}
