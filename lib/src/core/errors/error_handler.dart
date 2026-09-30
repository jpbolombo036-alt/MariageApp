import 'package:flutter/material.dart';

import '../errors/app_failure.dart';

/// Affiche les erreurs utilisateur via SnackBar / dialog, selon le contexte.
class ErrorHandler {
  const ErrorHandler();

  void show(BuildContext context, AppFailure failure) {
    final messenger = ScaffoldMessenger.of(context);
    if (messenger.mounted) {
      messenger.clearSnackBars();
      messenger.showSnackBar(
        SnackBar(
          content: Text(failure.userMessage),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'OK',
            onPressed: () {},
          ),
        ),
      );
    }
  }

  void showUnknown(BuildContext context, Object error) {
    final failure = error is AppFailure
        ? error
        : UnknownFailure(cause: error);
    show(context, failure);
  }
}
