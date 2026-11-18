/// Fixed institute details printed on certificates (the letterhead).
///
/// None of the APIs send these yet, so they're copied from the
/// institute's printed certificates. If the backend adds them (e.g. to
/// the profile API), read them from there instead.
class InstituteInfo {
  InstituteInfo._();

  static const String collegeCode = '2995';
  static const String phoneNumbers = '9792044188, 9450277027';
  static const String hindiName = 'माँ गुलजारी भरत निजी औद्योगिक प्रशिक्षण केन्द्र';
  static const String hindiPlace = 'कन्सो - मऊ (उ.प्र.)';
  static const String dgtLetterNo = 'DGT6/24/62/2016-TC';

  /// How the institute is named in the certificate text.
  static const String nameInCertificates = 'Maa Guljari Bharat PVT ITI Kanso - Mau';

  /// The crest on receipts, certificates and the ID card.
  static const String logoAsset = 'assets/images/logo.png';
}
