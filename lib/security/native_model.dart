import 'dart:async';

import 'package:flutter/services.dart';

import '../prototype_model.dart';
import 'protection_gateway.dart';

/// Native state is acknowledged by iOS; it is never updated optimistically.
class NativeModel extends PrototypeModel {
  NativeModel({required this.gateway}) {
    selected = {};
    isProtected = false;
  }
  final ProtectionGateway gateway;
  ProtectionStatus? _status;
  bool _busy = false, _initialized = false, _disposed = false;
  bool nativePresentation = false;
  String? _error;
  int _generation = 0;
  Timer? _refreshTimer;

  @override
  bool get isNative => true;
  @override
  bool get busy => _busy;
  @override
  bool get initialized => _initialized;
  @override
  bool get needsSetup => _status != null && !_status!.hasCode;
  @override
  bool get authorized => _status?.authorized ?? false;
  @override
  String? get error => _error;
  @override
  DateTime? get releaseUntil => _status?.releaseUntil;
  @override
  int get selectedCount => _status?.selectedCount ?? 0;
  @override
  int get appliedCount => _status?.appliedCount ?? 0;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void _apply(ProtectionStatus value) {
    _status = value;
    _initialized = true;
    isProtected =
        value.authorized &&
        value.mode == 'blocked' &&
        value.selectedCount > 0 &&
        value.appliedCount == value.selectedCount;
    _refreshTimer?.cancel();
    final deadline = value.releaseUntil;
    if (deadline != null) {
      final wait = deadline.difference(DateTime.now());
      _refreshTimer = Timer(
        wait.isNegative ? Duration.zero : wait,
        () => unawaited(refresh()),
      );
    }
  }

  String _message(Object error) => switch (error) {
    PlatformException(:final code) => switch (code) {
      'rate_limited' => 'Aguarde antes de tentar novamente.',
      'invalid_code' => 'Número atual incorreto.',
      'authorization_required' => 'Autorize o acesso ao Tempo de Uso.',
      'selection_invalid' =>
        'Escolha de 1 a 50 aplicativos, sem categorias ou sites.',
      'session_required' => 'Digite seu número novamente para continuar.',
      'monitor_failed' =>
        'Não foi possível agendar o bloqueio. O acesso não foi liberado.',
      _ => 'Não foi possível concluir a operação no iOS. Tente novamente.',
    },
    _ => 'A integração do iOS não está disponível. Tente novamente.',
  };

  Future<void> _run(
    Future<ProtectionStatus> Function() action, {
    bool presentation = false,
  }) async {
    if (_busy || _disposed) return;
    _busy = true;
    nativePresentation = presentation;
    _error = null;
    _notify();
    try {
      final value = await action();
      if (!_disposed) _apply(value);
    } catch (e) {
      _error = _message(e);
    } finally {
      _busy = false;
      nativePresentation = false;
      _notify();
    }
  }

  @override
  Future<void> initialize() => _run(gateway.status);
  @override
  Future<void> refresh() => _run(gateway.status);
  @override
  Future<void> authorize() async {
    if (!sessionOpen) return;
    await _run(gateway.authorize, presentation: true);
  }

  @override
  Future<String?> setupCode(String next, String confirmation) async {
    if (!needsSetup || _busy) return 'Configuração indisponível.';
    if (!RegExp(r'^[0-9]{8,12}$').hasMatch(next)) {
      return 'Use de 8 a 12 dígitos.';
    }
    if (next != confirmation) return 'Os números não coincidem.';
    await _run(() => gateway.setupCode(next));
    return _error;
  }

  @override
  void press(String key) {
    if (_busy || !_initialized || needsSetup) return;
    final candidate = calculator.accessCandidate;
    if (key == '=' &&
        candidate != null &&
        RegExp(r'^[0-9]{8,12}$').hasMatch(candidate)) {
      calculator.press('=');
      unawaited(_open(candidate));
    } else {
      calculator.press(key);
      _notify();
    }
  }

  Future<void> _open(String candidate) async {
    final generation = _generation;
    _busy = true;
    _error = null;
    _notify();
    try {
      final accepted = await gateway.openSession(candidate);
      if (generation != _generation || _disposed) {
        await gateway.closeSession();
        return;
      }
      if (accepted) {
        _apply(await gateway.status());
        if (generation != _generation || _disposed) return;
        sessionOpen = true;
        page = PrototypePage.privateArea;
        calculator.clear();
      }
    } catch (e) {
      _error = _message(e);
    } finally {
      _busy = false;
      _notify();
    }
  }

  @override
  void closePrivateArea() {
    _generation++;
    sessionOpen = false;
    page = PrototypePage.calculator;
    calculator.clear();
    unawaited(gateway.closeSession().catchError((Object _) {}));
    _error = null;
    _notify();
  }

  @override
  void navigate(PrototypePage target) {
    if (!sessionOpen || _busy) return;
    if (target == PrototypePage.selectApps) {
      unawaited(_run(gateway.selectApps, presentation: true));
    } else if (target != PrototypePage.appearance) {
      page = target;
      _notify();
    }
  }

  @override
  void toggleProtection() {
    if (!sessionOpen || _busy || !authorized || selectedCount == 0) return;
    unawaited(_run(isProtected ? gateway.release : gateway.protect));
  }

  @override
  Future<String?> changeCode(
    String current,
    String next,
    String confirmation,
  ) async {
    if (!sessionOpen || _busy) {
      return 'Digite seu número novamente para continuar.';
    }
    if (!RegExp(r'^[0-9]{8,12}$').hasMatch(next)) {
      return 'Use de 8 a 12 dígitos.';
    }
    if (next != confirmation) return 'Os novos números não coincidem.';
    _busy = true;
    _notify();
    try {
      await gateway.changeCode(current, next);
      return null;
    } catch (e) {
      return _message(e);
    } finally {
      _busy = false;
      _notify();
    }
  }

  @override
  void resetDemo() {}
  @override
  void dispose() {
    _disposed = true;
    _generation++;
    _refreshTimer?.cancel();
    super.dispose();
  }
}
