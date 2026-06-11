import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app.dart';

void main() {
  // Optional: make zone errors fatal during development
  // BindingBase.debugZoneErrorsAreFatal = true;

  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

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
  debugPrint('[GaseelError] $message');
  if (stack != null) {
    debugPrint('[GaseelError] $stack');
  }
  // Optional: write to file (e.g. via path_provider getTemporaryDirectory() + File)
}
