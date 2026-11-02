import 'package:flutter/services.dart';

class ProtectionStatus {
  const ProtectionStatus({
    required this.hasCode,
    required this.authorized,
    required this.selectedCount,
    required this.appliedCount,
    required this.mode,
    this.releaseUntil,
  });

  factory ProtectionStatus.fromMap(Map<Object?, Object?> value) {
    final hasCode = value['hasCode'];
    final authorized = value['authorized'];
    final selected = value['selectedCount'];
    final applied = value['appliedCount'];
    final mode = value['mode'];
    final deadline = value['releaseUntil'];
    if (hasCode is! bool ||
        authorized is! bool ||
        selected is! int ||
        applied is! int ||
        selected < 0 ||
        selected > 50 ||
        applied < 0 ||
        applied > selected ||
        !const [
          'blocked',
          'released',
          'unconfigured',
          'unavailable',
        ].contains(mode) ||
        (deadline != null && deadline is! num)) {
      throw const FormatException('Resposta de proteção inválida.');
    }
    return ProtectionStatus(
      hasCode: hasCode,
      authorized: authorized,
      selectedCount: selected,
      appliedCount: applied,
      mode: mode as String,
      releaseUntil: deadline is num
          ? DateTime.fromMillisecondsSinceEpoch((deadline * 1000).round())
          : null,
    );
  }

  final bool hasCode, authorized;
  final int selectedCount, appliedCount;
  final String mode;
  final DateTime? releaseUntil;
}

abstract interface class ProtectionGateway {
  Future<ProtectionStatus> status();
  Future<ProtectionStatus> setupCode(String code);
  Future<bool> openSession(String code);
  Future<void> closeSession();
  Future<void> changeCode(String current, String next);
  Future<ProtectionStatus> authorize();
  Future<ProtectionStatus> selectApps();
  Future<ProtectionStatus> protect();
  Future<ProtectionStatus> release();
}

class IOSProtectionGateway implements ProtectionGateway {
  const IOSProtectionGateway();
  static const channel = MethodChannel('app.calculadora/protection');

  Future<ProtectionStatus> _statusCall(
    String method, [
    Map<String, Object?>? arguments,
  ]) async {
    final value = await channel.invokeMapMethod<Object?, Object?>(
      method,
      arguments,
    );
    if (value == null) throw const FormatException('Resposta vazia do iOS.');
    return ProtectionStatus.fromMap(value);
  }

  @override
  Future<ProtectionStatus> status() => _statusCall('status');
  @override
  Future<ProtectionStatus> setupCode(String code) =>
      _statusCall('setupCode', {'code': code});
  @override
  Future<bool> openSession(String code) async =>
      await channel.invokeMethod<bool>('openSession', {'code': code}) ?? false;
  @override
  Future<void> closeSession() => channel.invokeMethod<void>('closeSession');
  @override
  Future<void> changeCode(String current, String next) => channel
      .invokeMethod<void>('changeCode', {'current': current, 'next': next});
  @override
  Future<ProtectionStatus> authorize() => _statusCall('authorize');
  @override
  Future<ProtectionStatus> selectApps() => _statusCall('selectApps');
  @override
  Future<ProtectionStatus> protect() => _statusCall('protect');
  @override
  Future<ProtectionStatus> release() => _statusCall('release');
}
