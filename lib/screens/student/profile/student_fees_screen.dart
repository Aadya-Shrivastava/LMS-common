import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/student/student_fee_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import 'package:lms/models/student/fee_receipt_model.dart';
import 'package:lms/models/student/fee_summary_model.dart';
import 'package:lms/models/student/student_fee_item_model.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../../widgets/custom_loader.dart';
import '../../../widgets/documents/document_viewer_screen.dart';
import '../../../widgets/documents/fee_receipt_document.dart';
import '../../../widgets/empty_state_widget.dart';
import '../../../widgets/error_state_widget.dart';
import '../../../widgets/section_card.dart';
import '../../../widgets/status_badge.dart';
import '../../../widgets/student/student_drawer.dart';

String _formatRupees(double amount) => '₹${amount.round()}';

/// The "Fees" screen, split into two tabs:
///   - "Payment": total fee / amount due, and the next installment
///     with a "Pay Now" button.
///   - "History": every past payment receipt.
class StudentFeesScreen extends StatefulWidget {
  const StudentFeesScreen({super.key});

  @override
  State<StudentFeesScreen> createState() => _StudentFeesScreenState();
}

class _StudentFeesScreenState extends State<StudentFeesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<StudentFeeController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'Fees',
        subtitle: 'Fee status, payment history and receipts',
        fallbackRoute: Routes.studentDashboard,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: AppColors.white,
          tabs: const [
            Tab(text: 'Payment'),
            Tab(text: 'History'),
          ],
        ),
      ),
      drawer: const StudentDrawer(currentRoute: Routes.studentFees),
      body: Obx(() {
        final summary = controller.summary.value;
        final error = controller.errorMessage.value;
        if (error != null && summary == null) {
          return ErrorStateWidget(message: error, onRetry: controller.loadFees);
        }
        if (summary == null) {
          return const CustomLoader();
        }

        return TabBarView(
          controller: _tabController,
          children: [
            _buildPaymentTab(context, controller, summary),
            _buildHistoryTab(controller),
          ],
        );
      }),
    );
  }

  Widget _buildPaymentTab(
    BuildContext context,
    StudentFeeController controller,
    FeeSummaryModel summary,
  ) {
    return RefreshIndicator(
      onRefresh: controller.loadFees,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _AmountCard(
                    label: 'Total Fee',
                    amountText: _formatRupees(summary.totalFee),
                    icon: Icons.account_balance_wallet_outlined,
                    color: AppColors.statCardBlue,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _AmountCard(
                    label: 'Amount Due',
                    amountText: _formatRupees(summary.amountDue),
                    icon: Icons.error_outline,
                    color: AppColors.statusRed,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Next Installment',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (summary.amountDue > 0) ...[
                  Text.rich(
                    TextSpan(
                      style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                      children: [
                        const TextSpan(text: 'Next installment of '),
                        TextSpan(
                          text: _formatRupees(summary.nextInstallmentAmount),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const TextSpan(text: ' is due on '),
                        TextSpan(
                          text: summary.nextInstallmentDueDateText,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const TextSpan(text: '.'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ] else
                  const Text(
                    'All installments are paid up. Nothing due right now.',
                    style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
                  ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: summary.paidFraction,
                    minHeight: 8,
                    backgroundColor: AppColors.statCardBlue.withValues(alpha: 0.15),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.statCardBlue),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${_formatRupees(summary.amountPaid)} of ${_formatRupees(summary.totalFee)} paid',
                  style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: AppColors.primaryNavy),
                    // There's no online payment API yet, so fees are
                    // paid at the campus fee counter for now.
                    onPressed: summary.amountDue <= 0
                        ? null
                        : () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Online payment is coming soon. Please pay at the fee counter.',
                                ),
                              ),
                            );
                          },
                    child: Text(summary.amountDue <= 0 ? 'Fully Paid' : 'Pay Now'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Fee Breakdown',
            padding: EdgeInsets.zero,
            child: controller.fees.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(24),
                    child: EmptyStateWidget(
                      icon: Icons.receipt_outlined,
                      title: 'No fees yet',
                      message: 'Fees charged to you will show up here.',
                    ),
                  )
                : Column(
                    children: [for (final fee in controller.fees) _FeeTile(fee: fee)],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab(StudentFeeController controller) {
    return RefreshIndicator(
      onRefresh: controller.loadFees,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (controller.paidByFeeHead.isNotEmpty) ...[
            SectionCard(
              title: 'Paid by Fee Head',
              child: Column(
                children: [
                  for (final item in controller.paidByFeeHead) _FeeHeadPaidRow(item: item),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          SectionCard(
            title: 'Payment History',
            padding: EdgeInsets.zero,
            child: controller.paymentHistory.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(24),
                    child: EmptyStateWidget(
                      icon: Icons.receipt_long_outlined,
                      title: 'No payments yet',
                      message: 'Your payment receipts will show up here.',
                    ),
                  )
                : Column(
                    children: [
                      for (final receipt in controller.paymentHistory)
                        _ReceiptTile(receipt: receipt),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _AmountCard extends StatelessWidget {
  final String label;
  final String amountText;
  final IconData icon;
  final Color color;

  const _AmountCard({
    required this.label,
    required this.amountText,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text(
                  amountText,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
                ),
              ],
            ),
          ),
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 18),
          ),
        ],
      ),
    );
  }
}

/// One row in "Fee Breakdown": the fee head, what was charged/paid, and
/// its status.
class _FeeTile extends StatelessWidget {
  final StudentFeeItemModel fee;

  const _FeeTile({required this.fee});

  @override
  Widget build(BuildContext context) {
    final isPaid = fee.dueAmount <= 0;
    final dueText = fee.dueDateText.isEmpty ? '' : ' · Due ${fee.dueDateText}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fee.feeHead,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_formatRupees(fee.paidAmount)} of ${_formatRupees(fee.netAmount)} paid$dueText',
                  style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          StatusBadge(
            label: isPaid
                ? (fee.status.isEmpty ? 'Paid' : fee.status)
                : '${_formatRupees(fee.dueAmount)} due',
            type: isPaid ? BadgeType.success : BadgeType.danger,
          ),
        ],
      ),
    );
  }
}

/// One row in "Paid by Fee Head", e.g. "Tution Fees ..... ₹120000".
class _FeeHeadPaidRow extends StatelessWidget {
  final FeeHeadPaidModel item;

  const _FeeHeadPaidRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.feeHead,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                ),
                if (item.fineAmount > 0)
                  Text(
                    'Includes ${_formatRupees(item.fineAmount)} late fee',
                    style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                  ),
              ],
            ),
          ),
          Text(
            _formatRupees(item.amount + item.fineAmount),
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _ReceiptTile extends StatelessWidget {
  final FeeReceiptModel receipt;

  const _ReceiptTile({required this.receipt});

  void _openReceipt(BuildContext context) {
    DocumentViewerScreen.open(
      context,
      title: 'Receipt ${receipt.receiptNo}',
      fileName: DocumentViewerScreen.safeFileName('Receipt_${receipt.receiptNo}'),
      pageWidth: FeeReceiptDocument.pageWidth,
      page: FeeReceiptDocument(
        receipt: receipt,
        instituteName: Get.find<StudentFeeController>().instituteName.value,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _openReceipt(context),
      child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  receipt.description,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                ),
                const SizedBox(height: 2),
                Text(
                  '${receipt.receiptNo} · ${receipt.dateText} · ${receipt.paymentMode}',
                  style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Text(
            _formatRupees(receipt.amount),
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
          const SizedBox(width: 8),
          // An icon (not a "Download" text button) so the row still fits a
          // small phone next to a 6-digit amount.
          IconButton(
            tooltip: 'View receipt',
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.receipt_long_outlined, size: 20),
            onPressed: () => _openReceipt(context),
          ),
        ],
      ),
      ),
    );
  }
}
