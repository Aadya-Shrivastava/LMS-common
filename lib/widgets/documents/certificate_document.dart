import 'package:flutter/material.dart';
import '../../core/constants/institute_info.dart';
import '../../core/utils/json_parsers.dart';
import '../../models/student/certificate_model.dart';

/// An issued certificate laid out like the institute's printed ones:
/// the letterhead, the certificate number and date, the title, and the
/// text with the student's details filled into dotted blanks.
///
/// The details come from the certificate request's `issued_data` (API
/// 33): name, father, roll, trade, dob, pob, gender, conduct, session.
/// The letterhead comes from `InstituteInfo` (no API sends it yet).
///
/// Bonafide and Character certificates follow the institute's
/// templates; Course Completion (and any other type) uses the same
/// layout with matching wording.
class CertificateDocument extends StatelessWidget {
  /// An A4 page.
  static const double pageWidth = 800;
  static const double pageHeight = 1131;

  final CertificateModel certificate;

  const CertificateDocument({super.key, required this.certificate});

  static const _ink = Color(0xFF4A5568);

  String _data(String key) => certificate.issuedData[key]?.trim() ?? '';

  /// "2002-09-09" -> "09-09-2002". Leaves other text as it is.
  static String _ddMmYyyy(String value) {
    final date = jsonDate(value);
    if (date == null) return value;
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(date.day)}-${two(date.month)}-${date.year}';
  }

  @override
  // Fixed-size page: ignore the phone's font-size setting (it's
  // scaled as a whole instead), so the layout never overflows.
  Widget build(BuildContext context) =>
      MediaQuery.withNoTextScaling(child: Builder(builder: _buildPage));

  Widget _buildPage(BuildContext context) {
    final type = certificate.certificateType.toLowerCase();
    final gender = _data('gender').toLowerCase();
    final female = gender.startsWith('f');

    final pronoun = female ? 'She' : 'He';
    final possessive = female ? 'Her' : 'His';
    final title = female ? 'Ms.' : 'Mr.';
    final relation = female ? 'D/o' : 'S/o';

    final issueDate = _data('issueDate').isNotEmpty
        ? _ddMmYyyy(_data('issueDate'))
        : certificate.issuedDate == null
        ? ''
        : _ddMmYyyy(certificate.issuedDate!.toIso8601String());

    // The opening is the same on every certificate.
    final opening = <InlineSpan>[
      TextSpan(text: '            This is to certify that $title '),
      _blank(_data('name'), 340),
      const TextSpan(text: '\n'),
      TextSpan(text: '$relation Mr. '),
      _blank(_data('father'), 230),
      const TextSpan(text: ' Roll No. '),
      _blank(_data('roll'), 130),
      const TextSpan(text: '\n'),
    ];

    final String heading;
    final List<InlineSpan> body;

    if (type.contains('bonafide')) {
      heading = 'BONAFIDE CERTIFICATE';
      body = [
        ...opening,
        const TextSpan(
          text:
              'Has been a bonafide student of ${InstituteInfo.nameInCertificates} in Trade ',
        ),
        _blank(_data('trade'), 230),
        TextSpan(
          text:
              '. $pronoun is reliable, sincere, hardworking and bears a good moral '
              'character. $possessive Date of Birth is ',
        ),
        _blank(_ddMmYyyy(_data('dob')), 130),
        const TextSpan(text: ' and Place of Birth is '),
        _blank(_data('pob'), 130),
        TextSpan(
          text: '.\nI wish all the best in ${possessive.toLowerCase()} future.',
        ),
      ];
    } else if (type.contains('character')) {
      heading = 'CHARACTER CERTIFICATE';
      body = [
        ...opening,
        const TextSpan(
          text:
              'was a student of ${InstituteInfo.nameInCertificates} in Trade ',
        ),
        _blank(_data('trade'), 230),
        const TextSpan(text: ' during the session '),
        _blank(_data('session'), 130),
        TextSpan(text: '. $possessive Date of Birth is '),
        _blank(_ddMmYyyy(_data('dob')), 130),
        TextSpan(
          text:
              '.\nTo the best of my knowledge, ${possessive.toLowerCase()} character and '
              'conduct during ${possessive.toLowerCase()} stay in this institute was ',
        ),
        _blank(_data('conduct'), 130),
        TextSpan(
          text: '.\nI wish all the best in ${possessive.toLowerCase()} future.',
        ),
      ];
    } else {
      heading = type.contains('completion')
          ? 'COURSE COMPLETION CERTIFICATE'
          : certificate.certificateType.toUpperCase();
      body = [
        ...opening,
        const TextSpan(text: 'has successfully completed the course in Trade '),
        _blank(_data('trade'), 230),
        const TextSpan(
          text: ' at ${InstituteInfo.nameInCertificates} during the session ',
        ),
        _blank(_data('session'), 130),
        TextSpan(text: '. $possessive Date of Birth is '),
        _blank(_ddMmYyyy(_data('dob')), 130),
        TextSpan(
          text: '.\nI wish all the best in ${possessive.toLowerCase()} future.',
        ),
      ];
    }

    return SizedBox(
      height: pageHeight,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(52, 56, 52, 52),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Letterhead(),
            const SizedBox(height: 18),
            Row(
              children: [
                const Text(
                  'पत्रांक ',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                _DottedBlank(
                  value: certificate.certificateNo,
                  width: 140,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                const Text(
                  'दिनांक ',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                _DottedBlank(
                  value: issueDate,
                  width: 140,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 52),
            Center(
              child: Text(
                heading,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'serif',
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const SizedBox(height: 40),
            Text.rich(
              TextSpan(children: body),
              textAlign: TextAlign.justify,
              style: const TextStyle(
                fontFamily: 'serif',
                fontSize: 20,
                height: 2.35,
                color: _ink,
              ),
            ),
            const SizedBox(height: 96),
            const Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Principal',
                style: TextStyle(fontFamily: 'serif', fontSize: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// A filled-in blank: the value in bold over a dotted line.
  static InlineSpan _blank(String value, double width) {
    return WidgetSpan(
      alignment: PlaceholderAlignment.baseline,
      baseline: TextBaseline.alphabetic,
      child: _DottedBlank(
        value: value,
        width: width,
        style: const TextStyle(
          fontFamily: 'serif',
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: _ink,
        ),
      ),
    );
  }
}

/// The institute letterhead at the top of every certificate.
class _Letterhead extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Row(
          children: [
            Text(
              'कालेज कोड - ${InstituteInfo.collegeCode}',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            Spacer(),
            Text(
              'Mob. ${InstituteInfo.phoneNumbers}',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Image.asset(InstituteInfo.logoAsset, width: 72, height: 72),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                children: [
                  const FittedBox(
                    child: Text(
                      InstituteInfo.hindiName,
                      style: TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    color: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 3,
                    ),
                    child: const Text(
                      InstituteInfo.hindiPlace,
                      style: TextStyle(color: Colors.white, fontSize: 15),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              children: [
                Text(
                  'ITI',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Industrial Training Institute',
                  style: TextStyle(fontSize: 10),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Center(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'भारत पत्रांक संख्या',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: ' - ${InstituteInfo.dgtLetterNo}'),
              ],
            ),
            style: TextStyle(fontSize: 13),
          ),
        ),
        const SizedBox(height: 10),
        Container(height: 3, color: Colors.black),
        const SizedBox(height: 2),
        Container(height: 1, color: Colors.black),
      ],
    );
  }
}

/// A value written over a dotted underline, at least `width` wide.
class _DottedBlank extends StatelessWidget {
  final String value;
  final double width;
  final TextStyle style;

  const _DottedBlank({
    required this.value,
    required this.width,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DottedUnderline(),
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: width),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text(value, textAlign: TextAlign.center, style: style),
        ),
      ),
    );
  }
}

class _DottedUnderline extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black87
      ..strokeWidth = 1;
    final y = size.height - 1;
    for (double x = 0; x < size.width; x += 4) {
      canvas.drawLine(
        Offset(x, y),
        Offset((x + 2).clamp(0, size.width), y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
