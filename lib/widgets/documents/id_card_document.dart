import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/constants/institute_info.dart';
import '../../models/student/student_profile_model.dart';

/// The student ID card, laid out like the web portal's: the campus
/// header, the student's photo and details, and a QR code. Everything
/// comes from the profile API (API 5).
///
/// Designed at `pageWidth` x `pageHeight` (a card's proportions);
/// scale it with a `FittedBox` or `DocumentViewerScreen`.
class IdCardDocument extends StatelessWidget {
  static const double pageWidth = 1294;
  static const double pageHeight = 816;

  final StudentProfileModel profile;

  const IdCardDocument({super.key, required this.profile});

  static String _clean(String value) => value == '—' ? '' : value;

  /// "09-09-2002".
  String get _dob {
    final date = profile.dateOfBirth;
    if (date == null) return _clean(profile.dateOfBirthText);
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(date.day)}-${two(date.month)}-${date.year}';
  }

  /// What the QR code holds: the student's key details, so anyone
  /// scanning the card can read them.
  String get _qrData => [
    'Name: ${profile.fullName}',
    'Registration No.: ${_clean(profile.registrationNo)}',
    'Course: ${_clean(profile.course)} / ${_clean(profile.branch)}',
    'Batch: ${_clean(profile.batch)} / ${_clean(profile.semester)}',
    if (profile.campusName.isNotEmpty) profile.campusName,
  ].join('\n');

  @override
  // Fixed-size page: ignore the phone's font-size setting (it's
  // scaled as a whole instead), so the layout never overflows.
  Widget build(BuildContext context) =>
      MediaQuery.withNoTextScaling(child: Builder(builder: _buildPage));

  Widget _buildPage(BuildContext context) {
    final details = <(String, String)>[
      ('Registration No.', _clean(profile.registrationNo)),
      (
        'Batch',
        [
          profile.batch,
          profile.semester,
        ].map(_clean).where((s) => s.isNotEmpty).join(' / '),
      ),
      ('Session', _clean(profile.session)),
      ('Father', _clean(profile.fatherName)),
      ('DOB', _dob),
      ('Mobile', _clean(profile.mobileNumber)),
      ('Blood', _clean(profile.bloodGroup)),
    ];
    final courseLine = [
      profile.course,
      profile.branch,
    ].map(_clean).where((s) => s.isNotEmpty).join(' · ');

    return SizedBox(
      width: pageWidth,
      height: pageHeight,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0D5BC6), Color(0xFF0A86C9), Color(0xFF00B1C9)],
            ),
          ),
          child: Column(
            children: [
              // Header band: crest and campus name.
              Container(
                height: 166,
                color: const Color(0x55002A6B),
                padding: const EdgeInsets.symmetric(horizontal: 46),
                child: Row(
                  children: [
                    Container(
                      width: 106,
                      height: 106,
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Image.asset(InstituteInfo.logoAsset),
                    ),
                    const SizedBox(width: 30),
                    Expanded(
                      child: Text(
                        profile.campusName.isEmpty
                            ? 'Student ID Card'
                            : profile.campusName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(46, 38, 46, 46),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Photo(url: profile.photoUrl, name: profile.fullName),
                      const SizedBox(width: 48),
                      Expanded(
                        // Shrinks (never overflows) if a font measures taller than expected.
                        child: LayoutBuilder(
                          builder: (context, box) => FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.topLeft,
                            child: SizedBox(
                              width: box.maxWidth,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    profile.fullName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 46,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (courseLine.isNotEmpty)
                                    Text(
                                      courseLine,
                                      style: const TextStyle(
                                        color: Color(0xFFD6ECFF),
                                        fontSize: 30,
                                      ),
                                    ),
                                  const SizedBox(height: 22),
                                  for (final (label, value) in details)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Row(
                                        children: [
                                          SizedBox(
                                            width: 166,
                                            child: Text(
                                              label,
                                              style: const TextStyle(
                                                color: Color(0xFFD6ECFF),
                                                fontSize: 30,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              value.isEmpty ? '—' : value,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 30,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      // QR code, bottom right.
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: QrImageView(
                            data: _qrData,
                            size: 168,
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The student's photo, or their initial if there's none.
class _Photo extends StatelessWidget {
  final String url;
  final String name;

  const _Photo({required this.url, required this.name});

  @override
  Widget build(BuildContext context) {
    final initial = Center(
      child: Text(
        name.isEmpty ? 'S' : name[0].toUpperCase(),
        style: const TextStyle(
          fontSize: 120,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    return Container(
      width: 286,
      height: 360,
      decoration: BoxDecoration(
        color: const Color(0x33FFFFFF),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white, width: 4),
      ),
      clipBehavior: Clip.antiAlias,
      child: url.isEmpty
          ? initial
          : Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => initial,
            ),
    );
  }
}
