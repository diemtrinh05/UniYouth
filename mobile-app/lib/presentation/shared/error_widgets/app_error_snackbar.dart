import 'package:flutter/material.dart';

class AppErrorSnackBar {
  const AppErrorSnackBar._();

  static void show(BuildContext context, {required String message}) {
    final normalizedMessage = message.trim();
    if (normalizedMessage.isEmpty) {
      return;
    }

    // Avoid throwing when context is changing during async navigation flow.
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) {
      return;
    }

    final mediaQuery = MediaQuery.maybeOf(context);
    final bottomInset = mediaQuery?.padding.bottom ?? 0;
    final bottomMargin = bottomInset + 12;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.fromLTRB(16, 0, 16, bottomMargin),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: Text(normalizedMessage),
        ),
      );
  }
}
