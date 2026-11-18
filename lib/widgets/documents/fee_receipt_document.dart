import 'package:flutter/material.dart';
import '../../core/constants/institute_info.dart';
import '../../models/student/fee_receipt_model.dart';

/// A fee receipt laid out like the web portal's printed receipt: the
/// institute header, receipt and student details, one line per fee
/// head, and the total. All values come from API 29 (Fee Payments).
///
/// Designed at `pageWidth` wide (an A4 page); `DocumentViewerScreen`
/// scales it to the phone.
class FeeReceiptDocument extends StatelessWidget {
  static const double pageWidth = 800;

  final FeeReceiptModel receipt;

  /// e.g. "Mgbi", from the student record (API 4). Can be empty.
  final String instituteName;

  const FeeReceiptDocument({
    super.key,
    required this.receipt,
    this.instituteName = '',
  });

  static const _blue = Color(0xFF2B4FCF);
  static const _green = Color(0xFF1E8E3E);
  static const _grey = Color(0xFF555555);

  /// "₹120000.00", or "—" for nothing.
  static String _money(double value) =>
      value == 0 ? '—' : '₹${value.toStringAsFixed(2)}';

  @override
  // Fixed-size page: ignore the phone's font-size setting (it's
  // scaled as a whole instead), so the layout never overflows.
  Widget build(BuildContext context) =>
      MediaQuery.withNoTextScaling(child: Builder(builder: _buildPage));

  Widget _buildPage(BuildContext context) {
    final status = receipt.status.isEmpty ? 'Paid' : receipt.status;
    final isPaid = status.toLowerCase() == 'paid';

    String orDash(String value) => value.isEmpty ? '—' : value;
    final courseSem = [
      receipt.courseName,
      receipt.semesterName,
    ].where((s) => s.isNotEmpty).join(' / ');

    final details = <(String, String)>[
      ('Receipt No.', receipt.receiptNo),
      ('Date', receipt.dateText),
      ('Student Name', receipt.studentName),
      ('Registration No.', receipt.registrationNo),
      ('Course / Sem', courseSem),
      ('Branch', receipt.branchName),
      ('Academic Session', receipt.sessionName),
      ('Payment Mode', receipt.paymentMode),
      if (receipt.transactionId.isNotEmpty)
        ('Transaction ID', receipt.transactionId),
      if (receipt.chequeNo.isNotEmpty) ('Cheque No.', receipt.chequeNo),
    ];

    return DefaultTextStyle(
      style: const TextStyle(
        fontSize: 15,
        color: Colors.black,
        fontFamily: 'Roboto',
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(56, 48, 56, 64),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Image.asset(InstituteInfo.logoAsset, width: 60, height: 60),
                const SizedBox(width: 18),
                Expanded(
                  child: Text(
                    instituteName.isEmpty ? 'Fee Receipt' : instituteName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(height: 3, color: _blue),
            const SizedBox(height: 22),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Fee Receipt',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  status,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isPaid ? _green : Colors.orange.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Two columns of label / value, like the printed receipt.
            for (var i = 0; i < details.length; i += 2)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _Field(
                        label: details[i].$1,
                        value: orDash(details[i].$2),
                      ),
                    ),
                    Expanded(
                      child: i + 1 < details.length
                          ? _Field(
                              label: details[i + 1].$1,
                              value: orDash(details[i + 1].$2),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            _row(const [
              'S.NO',
              'FEE HEAD',
              'DESCRIPTION',
              'DISCOUNT',
              'LATE FINE',
              'AMOUNT',
            ], header: true),
            for (final (index, item) in receipt.items.indexed)
              _row([
                '${index + 1}',
                item.feeHead,
                item.description,
                _money(item.discount),
                _money(item.lateFine),
                '₹${item.amount.toStringAsFixed(2)}',
              ]),
            const SizedBox(height: 20),
            const Align(
              alignment: Alignment.centerRight,
              child: Text('Total Amount Paid', style: TextStyle(fontSize: 15)),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '₹${receipt.amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: _blue,
                ),
              ),
            ),
            if (receipt.remarks.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Remarks: ${receipt.remarks}',
                style: const TextStyle(color: _grey),
              ),
            ],
            const SizedBox(height: 36),
            const Text(
              'This is a system-generated receipt and does not require a physical signature.',
              style: TextStyle(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  /// One table row. Column widths match the printed receipt.
  Widget _row(List<String> cells, {bool header = false}) {
    const flex = [2, 4, 4, 3, 3, 3];
    final style = header
        ? const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.6,
          )
        : const TextStyle(fontSize: 16);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: header ? 12 : 16),
      decoration: header
          ? null
          : const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE5E5E5))),
            ),
      child: Row(
        children: [
          for (var i = 0; i < cells.length; i++)
            Expanded(
              flex: flex[i],
              child: Text(cells[i], style: style),
            ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final String value;

  const _Field({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13)),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
