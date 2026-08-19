/// The fee overview at the top of the Fees screen: total fee, how
/// much is still due, and the next installment.
class FeeSummaryModel {
  final double totalFee;
  final double amountDue;
  final double amountPaid;
  final double nextInstallmentAmount;
  final String nextInstallmentDueDateText;

  const FeeSummaryModel({
    required this.totalFee,
    required this.amountDue,
    required this.amountPaid,
    required this.nextInstallmentAmount,
    required this.nextInstallmentDueDateText,
  });

  /// How much of the total fee has been paid so far, from 0.0 to 1.0.
  double get paidFraction => totalFee == 0 ? 0 : (amountPaid / totalFee).clamp(0.0, 1.0);
}
