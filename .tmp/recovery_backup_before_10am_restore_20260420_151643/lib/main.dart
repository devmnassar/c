import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app.dart';

void main() {
  // Optional: make zone errors fatal during development
  // BindingBase.debugZoneErrorsAreFatal = true;

  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      FlutterError.onError = (FlutterErrorDetails details) {
        _logError(details.exceptionAsString(), details.stack);
        FlutterError.presentError(details);
      };

      ui.PlatformDispatcher.instance.onError =
          (Object error, StackTrace stack) {
        _logError(error.toString(), stack);
        return true;
      };

      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);

      runApp(App(key: App.appKey));
    },
    (Object error, StackTrace stack) {
      _logError(error.toString(), stack);
    },
  );
}

void _logError(String message, StackTrace? stack) {
  if (_isBenignPhoneTypingParseError(message)) {
    debugPrint('[GaseelError] $message');
    return;
  }

  debugPrint('[GaseelError] $message');
  if (stack != null) {
    debugPrint('[GaseelError] $stack');
  }
}

bool _isBenignPhoneTypingParseError(String message) {
  return message.contains('ErrorType.tooShortNsn') &&
      message.contains('phone number');
}
