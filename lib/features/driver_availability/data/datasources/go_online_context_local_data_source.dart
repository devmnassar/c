import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:gaseel_courier/core/firebase/fcm_token_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:gaseel_courier/core/networking/api_exception.dart';

import '../models/go_online_native_snapshot_model.dart';

class GoOnlineContextLocalDataSource {
  const GoOnlineContextLocalDataSource();

  static const MethodChannel _channel = MethodChannel(
    'app.driver_availability',
  );

  Future<Position> getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const ApiException(
        message: 'Location services are disabled. Please enable them first.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw const ApiException(
        message: 'Location permission is required to go online.',
      );
    }

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } on TimeoutException {
      throw const ApiException(
        message: 'Unable to get your current location right now.',
      );
    } catch (_) {
      throw const ApiException(
        message: 'Unable to get your current location right now.',
      );
    }
  }

  Future<Position?> getOptionalCurrentOrLastKnownPosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      final permission = await Geolocator.checkPermission();
      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        return null;
      }

      try {
        return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 5),
        );
      } on TimeoutException {
        return Geolocator.getLastKnownPosition();
      } catch (_) {
        return Geolocator.getLastKnownPosition();
      }
    } catch (_) {
      return null;
    }
  }

  Future<GoOnlineNativeSnapshotModel> getNativeSnapshot() async {
    if (!Platform.isAndroid) {
      throw const ApiException(
        message: 'Go online device snapshot is supported on Android only.',
      );
    }

    try {
      final result = await _channel.invokeMethod<Map<Object?, Object?>>(
        'getGoOnlineDeviceContext',
      );
      if (result == null) {
        throw const ApiException(
          message: 'Unable to collect device information.',
        );
      }

      final snapshot = GoOnlineNativeSnapshotModel.fromMap(result);
      if (snapshot.deviceId.isEmpty ||
          snapshot.deviceModel.isEmpty ||
          snapshot.networkType.isEmpty ||
          snapshot.batteryLevel < 0) {
        throw const ApiException(
          message: 'Unable to collect complete device information.',
        );
      }
      return snapshot;
    } on PlatformException catch (error) {
      throw ApiException(
        message: error.message ?? 'Unable to collect device information.',
      );
    }
  }

  Future<GoOnlineNativeSnapshotModel?> getOptionalNativeSnapshot() async {
    try {
      return await getNativeSnapshot();
    } catch (_) {
      return null;
    }
  }

  Future<String> getFirebaseFcmToken() async {
    try {
      final normalizedToken =
          (await FcmTokenService.getCachedOrRefreshToken())?.trim() ?? '';
      if (normalizedToken.isNotEmpty) {
        return normalizedToken;
      }
      throw const ApiException(
        message: 'Unable to get Firebase Cloud Messaging token.',
      );
    } on ApiException {
      rethrow;
    } on FirebaseException catch (error) {
      throw ApiException(
        message:
            error.message ?? 'Unable to get Firebase Cloud Messaging token.',
      );
    } catch (_) {
      throw const ApiException(
        message: 'Unable to get Firebase Cloud Messaging token.',
      );
    }
  }

  Future<String> getAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    final version = info.version.trim();
    if (version.isNotEmpty) {
      return version;
    }
    throw const ApiException(message: 'Unable to read app version.');
  }

  Future<String?> getOptionalAppVersion() async {
    try {
      return await getAppVersion();
    } catch (_) {
      return null;
    }
  }

  String getPlatformName() {
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return Platform.operatingSystem;
  }

  Future<String?> getOptionalDeviceId() async {
    if (!Platform.isAndroid) {
      return null;
    }

    try {
      final result = await _channel.invokeMethod<Map<Object?, Object?>>(
        'getGoOnlineDeviceContext',
      );
      final deviceId = (result?['deviceId'] as String?)?.trim() ?? '';
      return deviceId.isEmpty ? null : deviceId;
    } catch (_) {
      return null;
    }
  }

  Future<String?> getOptionalFirebaseFcmToken() async {
    try {
      final token = await getFirebaseFcmToken();
      return token.trim().isEmpty ? null : token.trim();
    } catch (_) {
      return null;
    }
  }

  Future<bool> isLocationServiceEnabled() {
    return Geolocator.isLocationServiceEnabled();
  }

  Future<bool> hasLocationPermission() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }
}
