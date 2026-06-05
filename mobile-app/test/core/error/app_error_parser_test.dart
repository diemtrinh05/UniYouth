import 'package:flutter_test/flutter_test.dart';
import 'package:uniyouth_app/core/error/app_error_parser.dart';
import 'package:uniyouth_app/core/error/app_error_type.dart';

void main() {
  group('AppErrorParser.fromResponse (ResponseType.plain JSON string)', () {
    test('parses ApiResponseDto failure from JSON string', () {
      const body = '''
{"success":false,"message":"Invalid operation","data":null,"errors":{"fieldA":["errorA"]}}
''';

      final error = AppErrorParser.fromResponse(
        statusCode: 400,
        data: body,
        fallbackMessage: 'fallback',
      );

      expect(error.type, AppErrorType.badRequest);
      expect(error.statusCode, 400);
      expect(error.message, 'Invalid operation');
      expect(error.fieldErrors, isNotNull);
      expect(error.fieldErrors!['fieldA'], isNotNull);
      expect(error.fieldErrors!['fieldA']!.first, 'errorA');
    });

    test('parses ProblemDetails from JSON string', () {
      const body = '''
{"type":"https://example.com","title":"Bad Request","status":400,"detail":"Wrong input","instance":"/api/x"}
''';

      final error = AppErrorParser.fromResponse(
        statusCode: 400,
        data: body,
        fallbackMessage: 'fallback',
      );

      expect(error.type, AppErrorType.badRequest);
      expect(error.statusCode, 400);
      expect(error.message, 'Wrong input');
      expect(error.title, 'Bad Request');
      expect(error.detail, 'Wrong input');
    });

    test('falls back when body is not JSON', () {
      const body = 'not-json';

      final error = AppErrorParser.fromResponse(
        statusCode: 400,
        data: body,
        fallbackMessage: 'fallback',
      );

      expect(error.type, AppErrorType.badRequest);
      expect(error.statusCode, 400);
      expect(error.message, 'fallback');
    });
  });

  group('AppErrorParser.fromResponse (rate limit 429 body)', () {
    test('parses 429 from Map body {message,statusCode}', () {
      final error = AppErrorParser.fromResponse(
        statusCode: 429,
        data: <String, Object>{
          'message': 'Quá nhiều yêu cầu. Vui lòng thử lại sau.',
          'statusCode': 429,
        },
        fallbackMessage: 'fallback',
      );

      expect(error.type, AppErrorType.tooManyRequests);
      expect(error.statusCode, 429);
      expect(error.message, 'Quá nhiều yêu cầu. Vui lòng thử lại sau.');
    });

    test('parses 429 from JSON string body {message,statusCode}', () {
      const body = '''
{"message":"Rate limited","statusCode":429}
''';

      final error = AppErrorParser.fromResponse(
        statusCode: 429,
        data: body,
        fallbackMessage: 'fallback',
      );

      expect(error.type, AppErrorType.tooManyRequests);
      expect(error.statusCode, 429);
      expect(error.message, 'Rate limited');
    });
  });
}
