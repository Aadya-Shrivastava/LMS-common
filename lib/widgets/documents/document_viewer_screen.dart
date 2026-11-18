import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../core/constants/app_colors.dart';

/// Shows a document (fee receipt, certificate, ID card) full screen,
/// with buttons to download/share it as a PDF and to print it.
///
/// Each document is laid out at a fixed "paper" size (`pageWidth`
/// wide), the same way it looks when printed from the web portal, and
/// then scaled down to fit the phone. Pinch to zoom in on the details.
///
/// The PDF is made in the app (there's no PDF API): the document is
/// captured as a sharp image and placed on a PDF page. That keeps it
/// identical to what's on screen, including the Hindi letterhead,
/// which the PDF library can't lay out as text.
class DocumentViewerScreen extends StatefulWidget {
  final String title;
  final double pageWidth;
  final Widget page;

  /// e.g. "Receipt_RCPT-1-2026-000003.pdf".
  final String fileName;

  /// The PDF page size. Defaults to A4; the ID card passes a card size.
  final PdfPageFormat pdfFormat;

  const DocumentViewerScreen({
    super.key,
    required this.title,
    required this.pageWidth,
    required this.page,
    required this.fileName,
    this.pdfFormat = PdfPageFormat.a4,
  });

  /// Opens `page` in the viewer.
  static Future<void> open(
    BuildContext context, {
    required String title,
    required double pageWidth,
    required Widget page,
    required String fileName,
    PdfPageFormat pdfFormat = PdfPageFormat.a4,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DocumentViewerScreen(
          title: title,
          pageWidth: pageWidth,
          page: page,
          fileName: fileName,
          pdfFormat: pdfFormat,
        ),
      ),
    );
  }

  /// A credit-card-sized page (85.6 x 54 mm) for ID cards.
  static const PdfPageFormat cardFormat = PdfPageFormat(
    85.6 * PdfPageFormat.mm,
    54 * PdfPageFormat.mm,
  );

  /// Turns any text into a safe file name, e.g. "CHR/2026/0001" ->
  /// "CHR-2026-0001".
  static String safeFileName(String name) =>
      '${name.replaceAll(RegExp(r'[^\w\-]+'), '-').replaceAll(RegExp(r'-+'), '-')}.pdf';

  @override
  State<DocumentViewerScreen> createState() => _DocumentViewerScreenState();
}

class _DocumentViewerScreenState extends State<DocumentViewerScreen> {
  final GlobalKey _pageKey = GlobalKey();
  bool _isBusy = false;

  /// Captures the document and builds the PDF.
  Future<Uint8List> _buildPdf() async {
    final boundary = _pageKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;

    // About 2000 px wide for an A4 page: sharp when printed.
    final image = await boundary.toImage(pixelRatio: 2000 / widget.pageWidth);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();

    final document = pw.Document(title: widget.title);
    final format = widget.pdfFormat.copyWith(
      marginLeft: 0,
      marginRight: 0,
      marginTop: 0,
      marginBottom: 0,
    );
    document.addPage(
      pw.Page(
        pageFormat: format,
        build: (_) => pw.Image(
          pw.MemoryImage(bytes!.buffer.asUint8List()),
          fit: pw.BoxFit.contain,
          alignment: pw.Alignment.topCenter,
        ),
      ),
    );
    return document.save();
  }

  Future<void> _run(Future<void> Function(Uint8List pdf) action) async {
    if (_isBusy) return;
    setState(() => _isBusy = true);
    try {
      await action(await _buildPdf());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Couldn't create the PDF. Please try again. ($e)")),
        );
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  /// The phone's share sheet: Save to Files / Drive, WhatsApp, email...
  Future<void> _download() => _run(
        (pdf) => Printing.sharePdf(bytes: pdf, filename: widget.fileName),
      );

  /// The print dialog, which also offers "Save as PDF".
  Future<void> _print() => _run(
        (pdf) => Printing.layoutPdf(
          name: widget.fileName,
          format: widget.pdfFormat,
          onLayout: (_) async => pdf,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          if (_isBusy)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
            )
          else ...[
            IconButton(
              tooltip: 'Download PDF',
              icon: const Icon(Icons.download_outlined),
              onPressed: _download,
            ),
            IconButton(
              tooltip: 'Print',
              icon: const Icon(Icons.print_outlined),
              onPressed: _print,
            ),
          ],
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: InteractiveViewer(
                maxScale: 5,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: FittedBox(
                      child: Material(
                        elevation: 2,
                        color: Colors.white,
                        child: RepaintBoundary(
                          key: _pageKey,
                          child: ColoredBox(
                            color: Colors.white,
                            child: SizedBox(width: widget.pageWidth, child: widget.page),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Text(
                'Pinch to zoom · Download to save or share the PDF',
                style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
