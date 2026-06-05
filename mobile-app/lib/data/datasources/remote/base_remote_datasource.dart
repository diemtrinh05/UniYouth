import 'package:dio/dio.dart';

import '../../../core/error/app_error.dart';
import '../../../core/error/app_error_parser.dart';
import '../../../core/network/retry_policy/network_retry_policy.dart';

abstract class BaseRemoteDataSource {
  BaseRemoteDataSource(this.dio);

  final Dio dio;
  static const NetworkRetryPolicy _retryPolicy = NetworkRetryPolicy();

  Future<T> runRequest<T>(Future<T> Function() request) async {
    var retryCount = 0;

    while (true) {
      try {
        return await request();
      } on DioException catch (error) {
        if (_retryPolicy.shouldRetry(error: error, retryCount: retryCount)) {
          final delay = _retryPolicy.delayForRetry(retryCount: retryCount);
          retryCount += 1;
          await Future<void>.delayed(delay);
          continue;
        }

        if (error.error is AppError) {
          throw error.error! as AppError;
        }

        throw AppErrorParser.fromDioException(error);
      }
    }
  }
}
