/// One fee payment receipt (API 29): a row in "Payment History", and
/// everything printed on the receipt document.
class FeeReceiptModel {
  final String receiptNo;

  /// The fee heads paid, e.g. "Tution Fees" - the row's title.
  final String description;

  /// Total paid, including any late fine.
  final double amount;

  /// e.g. "01 Oct 2026".
  final String dateText;
  final String paymentMode;

  // ---- Printed on the receipt ----

  final String studentName;
  final String registrationNo;
  final String courseName;
  final String semesterName;
  final String branchName;
  final String sessionName;

  /// e.g. "Paid".
  final String status;
  final String transactionId;
  final String chequeNo;
  final String remarks;

  /// One line per fee head paid.
  final List<FeeReceiptItemModel> items;

  const FeeReceiptModel({
    required this.receiptNo,
    required this.description,
    required this.amount,
    required this.dateText,
    required this.paymentMode,
    this.studentName = '',
    this.registrationNo = '',
    this.courseName = '',
    this.semesterName = '',
    this.branchName = '',
    this.sessionName = '',
    this.status = '',
    this.transactionId = '',
    this.chequeNo = '',
    this.remarks = '',
    this.items = const [],
  });
}

/// One line on a receipt, e.g. "Tution Fees, fine ₹1000, ₹120000".
class FeeReceiptItemModel {
  final String feeHead;

  /// The installment name, e.g. "Installment 1". Can be empty.
  final String description;
  final double discount;
  final double lateFine;

  /// The fee amount paid for this head, not counting the fine.
  final double amount;

  const FeeReceiptItemModel({
    required this.feeHead,
    required this.description,
    required this.discount,
    required this.lateFine,
    required this.amount,
  });
}
