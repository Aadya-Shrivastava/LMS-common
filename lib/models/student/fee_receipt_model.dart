/// One row in "Payment History" - a receipt for a past fee payment.
class FeeReceiptModel {
  final String receiptNo;
  final String description;
  final double amount;
  final String dateText;
  final String paymentMode;

  const FeeReceiptModel({
    required this.receiptNo,
    required this.description,
    required this.amount,
    required this.dateText,
    required this.paymentMode,
  });
}
