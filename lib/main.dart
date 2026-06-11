import 'dart:async';
import 'dart:ui' as ui;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:gaseel_courier/core/di/dependency_injection.dart';
import 'package:gaseel_courier/core/firebase/fcm_token_service.dart';
import 'package:gaseel_courier/core/firebase/push_notification_service.dart';
import 'package:gaseel_courier/core/utils/simple_observer.dart';
import 'package:gaseel_courier/firebase_options.dart';
import 'app.dart';

void main() {
  // Optional: make zone errors fatal during development
  // BindingBase.debugZoneErrorsAreFatal = true;

  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      Bloc.observer = SimpleObserver();

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

      if (!kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.android ||
              defaultTargetPlatform == TargetPlatform.iOS)) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        await FcmTokenService.initialize();
        await PushNotificationService.initialize();
      }

      await setupGetIt();

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
