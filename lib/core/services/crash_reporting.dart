import 'dart:async';

import 'package:flutter/foundation.dart';

/// Crash reporting hook.
///
/// Native `sentry_flutter` was removed from release builds because its Android
/// Gradle plugin could not resolve Google Maven artifacts on this machine
/// (SSL/network). Wire Sentry back when CI/network can fetch AGP deps, or via
/// `--dart-define` + a future optional package.
///
/// Current behavior: no-op run wrapper + debugPrint on capture.
class CrashReporting {
  static const dsn = String.fromEnvironment('SENTRY_DSN', defaultValue: '');

  static bool get enabled => dsn.isNotEmpty;

  static Future<void> run(FutureOr<void> Function() appRunner) async {
    await appRunner();
  }

  static Future<void> captureException(
    Object error, {
    StackTrace? stackTrace,
  }) async {
    debugPrint('CrashReporting: $error');
    if (stackTrace != null) debugPrint('$stackTrace');
  }
}
