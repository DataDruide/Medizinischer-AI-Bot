import 'dart:async';

import 'package:flutter/foundation.dart';

enum OperationPhase { working, success, error, info }

class OperationNotice {
  const OperationNotice({
    required this.phase,
    required this.title,
    this.detail,
  });

  final OperationPhase phase;
  final String title;
  final String? detail;
}

class OperationStatusProvider extends ChangeNotifier {
  OperationNotice? _notice;
  Timer? _dismissTimer;

  OperationNotice? get notice => _notice;

  void working(String title, {String? detail}) {
    _publish(OperationPhase.working, title, detail);
  }

  void success(String title, {String? detail}) {
    _publish(
      OperationPhase.success,
      title,
      detail,
      dismissAfter: const Duration(seconds: 4),
    );
  }

  void error(String title, {String? detail}) {
    _publish(
      OperationPhase.error,
      title,
      detail,
      dismissAfter: const Duration(seconds: 8),
    );
  }

  void info(String title, {String? detail}) {
    _publish(
      OperationPhase.info,
      title,
      detail,
      dismissAfter: const Duration(seconds: 6),
    );
  }

  void dismiss() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    _notice = null;
    notifyListeners();
  }

  void _publish(
    OperationPhase phase,
    String title,
    String? detail, {
    Duration? dismissAfter,
  }) {
    _dismissTimer?.cancel();
    _notice = OperationNotice(phase: phase, title: title, detail: detail);
    notifyListeners();
    if (dismissAfter != null) {
      _dismissTimer = Timer(dismissAfter, dismiss);
    }
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    super.dispose();
  }
}
