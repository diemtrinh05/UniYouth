import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/notifications/background_handler.dart';
import 'presentation/app/uniyouth_app.dart';
import 'services/config/api_config_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  final preferences = await SharedPreferences.getInstance();
  final apiConfigService = ApiConfigService.fromEnvironment(
    preferences: preferences,
  );
  runApp(UniYouthApp(apiConfigService: apiConfigService));
}
