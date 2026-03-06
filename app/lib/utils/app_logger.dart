import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Centralized app logger with pretty-printed output in debug mode
/// and minimal output in release mode.
class AppLogger {
  AppLogger._();

  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 80,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
    output: _StdoutOutput(), // stdout.writeln bypasses Flutter's print stripping in release
    level: Level.trace, // TODO: revert to kReleaseMode ? Level.warning : Level.trace
  );

  /// Verbose / trace-level logging for detailed flow tracking.
  static void trace(String message, {String? tag}) {
    _logger.t(_format(tag, message));
  }

  /// Debug-level: useful during development.
  static void debug(String message, {String? tag}) {
    _logger.d(_format(tag, message));
  }

  /// Info-level: key lifecycle or business events.
  static void info(String message, {String? tag}) {
    _logger.i(_format(tag, message));
  }

  /// Warning-level: recoverable issues or unexpected states.
  static void warning(String message, {String? tag}) {
    _logger.w(_format(tag, message));
  }

  /// Error-level: failures that need attention.
  static void error(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _logger.e(_format(tag, message), error: error, stackTrace: stackTrace);
  }

  /// Fatal-level: app-breaking errors.
  static void fatal(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _logger.f(_format(tag, message), error: error, stackTrace: stackTrace);
  }

  static String _format(String? tag, String message) {
    return tag != null ? '[$tag] $message' : message;
  }
}

/// Custom output that writes directly to stdout, bypassing Flutter's
/// release-mode stripping of print() calls.
class _StdoutOutput extends LogOutput {
  @override
  void output(OutputEvent event) {
    for (final line in event.lines) {
      stdout.writeln(line);
    }
  }
}
