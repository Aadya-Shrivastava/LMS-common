// Tests for the small helper functions: reading API JSON safely,
// formatting dates, and checking form input.

import 'package:flutter_test/flutter_test.dart';
import 'package:lms/core/utils/date_formatters.dart';
import 'package:lms/core/utils/json_parsers.dart';
import 'package:lms/core/utils/validators.dart';

void main() {
  group('json parsers', () {
    test('jsonDouble reads numbers, numeric text, and falls back to 0', () {
      expect(jsonDouble(9000.0), 9000.0);
      expect(jsonDouble(75), 75.0);
      expect(jsonDouble('120000.00'), 120000.0);
      expect(jsonDouble(null), 0);
      expect(jsonDouble('abc'), 0);
    });

    test('jsonInt reads whole numbers from numbers and text', () {
      expect(jsonInt(15), 15);
      expect(jsonInt('30'), 30);
      expect(jsonInt('17.0'), 17);
      expect(jsonInt(null), 0);
    });

    test('jsonString trims and turns null into empty text', () {
      expect(jsonString('  BATCH A '), 'BATCH A');
      expect(jsonString(null), '');
      expect(jsonString(12), '12');
    });

    test('jsonDate reads dates and converts server time to phone time', () {
      expect(jsonDate('2026-10-08'), DateTime(2026, 10, 8));
      expect(jsonDate(null), isNull);
      expect(jsonDate('not a date'), isNull);

      final withZone = jsonDate('2026-10-25T14:00:00+05:30')!;
      expect(withZone.isUtc, isFalse);
      expect(withZone.toUtc(), DateTime.utc(2026, 10, 25, 8, 30));
    });

    test('jsonList accepts plain lists and paginated {results: [...]}', () {
      expect(jsonList([{'a': 1}, 'skip me', {'b': 2}]), [{'a': 1}, {'b': 2}]);
      expect(jsonList({'results': [{'a': 1}]}), [{'a': 1}]);
      expect(jsonList(null), isEmpty);
      expect(jsonList({'detail': 'x'}), isEmpty);
    });

    test('jsonMap gives an empty map for anything that is not an object', () {
      expect(jsonMap({'a': 1}), {'a': 1});
      expect(jsonMap(null), isEmpty);
      expect(jsonMap([1, 2]), isEmpty);
    });
  });

  group('date formatters', () {
    test('formatDate', () {
      expect(formatDate(DateTime(2026, 8, 2)), '02 Aug 2026');
    });

    test('formatTime', () {
      expect(formatTime(DateTime(2026, 1, 1, 14, 5)), '02:05 PM');
      expect(formatTime(DateTime(2026, 1, 1, 0, 30)), '12:30 AM');
    });

    test('formatTimeText turns API times into 12-hour times', () {
      expect(formatTimeText('14:00:00'), '02:00 PM');
      expect(formatTimeText('09:30'), '09:30 AM');
      expect(formatTimeText('soon'), 'soon');
    });
  });

  group('login validator', () {
    test('accepts an email or a username', () {
      expect(Validators.emailOrUsername('student@example.com'), isNull);
      expect(Validators.emailOrUsername('teststudent'), isNull);
      expect(Validators.emailOrUsername('test.student_01'), isNull);
    });

    test('rejects empty, too short, broken emails and odd characters', () {
      expect(Validators.emailOrUsername(''), isNotNull);
      expect(Validators.emailOrUsername('   '), isNotNull);
      expect(Validators.emailOrUsername('ab'), isNotNull);
      expect(Validators.emailOrUsername('student@'), isNotNull);
      expect(Validators.emailOrUsername('test student'), isNotNull);
    });
  });
}
