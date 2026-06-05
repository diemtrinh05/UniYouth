import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/support_chat/support_chat_repository.dart';
import 'app_foundation_providers.dart';

final supportChatRepositoryProvider = Provider<SupportChatRepository>(
  (ref) => SupportChatRepository(
    remoteDataSource: ref.watch(supportChatRemoteDataSourceProvider),
  ),
);
