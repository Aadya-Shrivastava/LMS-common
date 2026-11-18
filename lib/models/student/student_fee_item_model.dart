/// One fee charged to the student, e.g. "Tution Fees: ₹120000, paid
/// ₹120000, nothing due". Shown in "Fee Breakdown" on the Fees screen.
class StudentFeeItemModel {
  final String feeHead;
  final String dueDateText;
  final double netAmount;
  final double paidAmount;

  /// What's still owed, including any unpaid late fee.
  final double dueAmount;

  /// e.g. "Paid", "Partially Paid", "Unpaid".
  final String status;

  const StudentFeeItemModel({
    required this.feeHead,
    required this.dueDateText,
    required this.netAmount,
    required this.paidAmount,
    required this.dueAmount,
    required this.status,
  });
}

/// How much has been paid towards one fee head across all payments,
/// worked out from the fee-payment-items API. Shown in "Paid by Fee
/// Head" on the Fees screen.
class FeeHeadPaidModel {
  final String feeHead;
  final double amount;
  final double fineAmount;

  const FeeHeadPaidModel({
    required this.feeHead,
    required this.amount,
    required this.fineAmount,
  });
}
