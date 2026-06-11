import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';

class SimpleObserver extends BlocObserver {
  static const String _line =
      '============================================================';

  @override
  void onCreate(BlocBase bloc) {
    super.onCreate(bloc);
    log('$_line\n[BLOC CREATED] ${bloc.runtimeType}\n$_line');
  }

  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);

    final previousStatus = _extractStatus(change.currentState);
    final nextStatus = _extractStatus(change.nextState);

    if (previousStatus != null || nextStatus != null) {
      log(
        '$_line\n'
        '[STATE FLOW] ${bloc.runtimeType}\n'
        'STATUS: ${previousStatus ?? '-'} -> ${nextStatus ?? '-'}\n'
        '$_line',
      );
    } else {
      log(
        '$_line\n'
        '[STATE CHANGE] ${bloc.runtimeType}\n'
        '$change\n'
        '$_line',
      );
    }
  }

  @override
  void onEvent(Bloc bloc, Object? event) {
    super.onEvent(bloc, event);
    log('$_line\n[EVENT] ${bloc.runtimeType}\n$event\n$_line');
  }

  @override
  void onTransition(Bloc bloc, Transition transition) {
    super.onTransition(bloc, transition);
    log('$_line\n[TRANSITION] ${bloc.runtimeType}\n$transition\n$_line');
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    log(
      '$_line\n'
      '[BLOC ERROR] ${bloc.runtimeType}\n'
      '$error\n'
      '$_line',
      stackTrace: stackTrace,
    );
  }

  @override
  void onClose(BlocBase bloc) {
    super.onClose(bloc);
    log('$_line\n[BLOC CLOSED] ${bloc.runtimeType}\n$_line');
  }

  String? _extractStatus(dynamic state) {
    try {
      final dynamic status = state.status;
      return status?.toString();
    } catch (_) {
      return null;
    }
  }
}
