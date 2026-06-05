import '../../../core/error/app_error.dart';
import '../../../domain/usecases/auth/check_api_health_usecase.dart';
import '../../datasources/remote/auth_remote_datasource.dart';

class AuthHealthRepository implements CheckApiHealthRepository {
  AuthHealthRepository({
    required AuthRemoteDataSource authRemoteDataSource,
  }) : _authRemoteDataSource = authRemoteDataSource;

  final AuthRemoteDataSource _authRemoteDataSource;

  @override
  Future<bool> checkApiHealth() async {
    try {
      return await _authRemoteDataSource.checkHealth();
    } on AppError {
      return false;
    } on FormatException {
      return false;
    }
  }
}
