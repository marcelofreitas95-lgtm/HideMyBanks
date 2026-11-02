import 'dart:async';
import 'package:calculadora/prototype_model.dart';
import 'package:calculadora/security/native_model.dart';
import 'package:calculadora/security/protection_gateway.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeGateway implements ProtectionGateway {
  ProtectionStatus value = const ProtectionStatus(
    hasCode: true,
    authorized: true,
    selectedCount: 2,
    appliedCount: 2,
    mode: 'blocked',
  );
  bool available = true;
  int opens = 0, closes = 0, releases = 0, picks = 0, changes = 0;
  Completer<bool>? authentication;
  Completer<ProtectionStatus>? pendingRelease;
  Object? releaseError;
  @override
  Future<ProtectionStatus> status() async {
    if (!available) throw MissingPluginException();
    return value;
  }

  @override
  Future<bool> openSession(String code) {
    opens++;
    return authentication?.future ?? Future.value(true);
  }

  @override
  Future<void> closeSession() async {
    closes++;
  }

  @override
  Future<ProtectionStatus> setupCode(String code) async {
    value = const ProtectionStatus(
      hasCode: true,
      authorized: false,
      selectedCount: 0,
      appliedCount: 0,
      mode: 'unavailable',
    );
    return value;
  }

  @override
  Future<void> changeCode(String current, String next) async {
    changes++;
  }

  @override
  Future<ProtectionStatus> authorize() async => value;
  @override
  Future<ProtectionStatus> selectApps() async {
    picks++;
    return value;
  }

  @override
  Future<ProtectionStatus> protect() async => value;
  @override
  Future<ProtectionStatus> release() async {
    releases++;
    if (releaseError != null) throw releaseError!;
    return pendingRelease?.future ?? value;
  }
}

void type(NativeModel model, String input) {
  for (final key in input.split('')) {
    model.press(key);
  }
}

Future<void> settle() => Future<void>.delayed(Duration.zero);

void main() {
  test('missing native integration never falls back to demo', () async {
    final gateway = FakeGateway()..available = false;
    final model = NativeModel(gateway: gateway);
    await model.initialize();
    type(model, '31415926=');
    expect(model.initialized, false);
    expect(model.isProtected, false);
    expect(model.selectedCount, 0);
    expect(model.sessionOpen, false);
    expect(gateway.opens, 0);
    expect(model.error, isNotNull);
    model.dispose();
  });
  test('native first launch requires a user-created code', () async {
    final gateway = FakeGateway()
      ..value = const ProtectionStatus(
        hasCode: false,
        authorized: false,
        selectedCount: 0,
        appliedCount: 0,
        mode: 'unavailable',
      );
    final model = NativeModel(gateway: gateway);
    await model.initialize();
    expect(model.needsSetup, true);
    type(model, '31415926=');
    expect(gateway.opens, 0);
    expect(await model.setupCode('123', '123'), isNotNull);
    expect(await model.setupCode('00123456', '00123457'), isNotNull);
    expect(await model.setupCode('00123456', '00123456'), isNull);
    expect(model.needsSetup, false);
    expect(model.sessionOpen, false);
    model.dispose();
  });
  test('arithmetic results never call native authentication', () async {
    final gateway = FakeGateway();
    final model = NativeModel(gateway: gateway);
    await model.initialize();
    type(model, '31415925+1==');
    await settle();
    expect(model.calculator.display, '31415926');
    expect(gateway.opens, 0);
    model.press('AC');
    type(model, '00123456=');
    await settle();
    expect(gateway.opens, 1);
    expect(model.sessionOpen, true);
    model.dispose();
  });
  test('backgrounding during verification rejects late success', () async {
    final gateway = FakeGateway()..authentication = Completer<bool>();
    final model = NativeModel(gateway: gateway);
    await model.initialize();
    type(model, '00123456=');
    model.closePrivateArea();
    gateway.authentication!.complete(true);
    await settle();
    expect(model.sessionOpen, false);
    expect(model.page, PrototypePage.calculator);
    expect(gateway.closes, greaterThanOrEqualTo(2));
    model.dispose();
  });
  test('release changes state only after native acknowledgement', () async {
    final gateway = FakeGateway()
      ..pendingRelease = Completer<ProtectionStatus>();
    final model = NativeModel(gateway: gateway);
    await model.initialize();
    type(model, '00123456=');
    await settle();
    model.toggleProtection();
    expect(model.isProtected, true);
    expect(model.busy, true);
    model.toggleProtection();
    expect(gateway.releases, 1);
    gateway.pendingRelease!.complete(
      const ProtectionStatus(
        hasCode: true,
        authorized: true,
        selectedCount: 2,
        appliedCount: 0,
        mode: 'released',
      ),
    );
    await settle();
    expect(model.isProtected, false);
    model.dispose();
  });
  test('scheduling failure preserves protection', () async {
    final gateway = FakeGateway()
      ..releaseError = PlatformException(code: 'monitor_failed');
    final model = NativeModel(gateway: gateway);
    await model.initialize();
    type(model, '00123456=');
    await settle();
    model.toggleProtection();
    await settle();
    expect(model.isProtected, true);
    expect(model.error, contains('não foi liberado'));
    model.dispose();
  });
  test(
    'real selection uses iOS picker; simulation remains unavailable',
    () async {
      final gateway = FakeGateway();
      final model = NativeModel(gateway: gateway);
      await model.initialize();
      type(model, '00123456=');
      await settle();
      model.navigate(PrototypePage.selectApps);
      await settle();
      expect(gateway.picks, 1);
      expect(model.page, PrototypePage.privateArea);
      model.navigate(PrototypePage.appearance);
      expect(model.page, PrototypePage.privateArea);
      expect(model.selectedBanks, isEmpty);
      model.dispose();
    },
  );
  test('revoked authorization cannot report applied protection', () async {
    final gateway = FakeGateway();
    final model = NativeModel(gateway: gateway);
    await model.initialize();
    type(model, '00123456=');
    await settle();
    gateway.value = const ProtectionStatus(
      hasCode: true,
      authorized: false,
      selectedCount: 2,
      appliedCount: 0,
      mode: 'unavailable',
    );
    await model.refresh();
    model.toggleProtection();
    expect(model.isProtected, false);
    expect(gateway.releases, 0);
    model.dispose();
  });
  test('native private commands require an authenticated session', () async {
    final gateway = FakeGateway();
    final model = NativeModel(gateway: gateway);
    await model.initialize();
    model.toggleProtection();
    model.navigate(PrototypePage.selectApps);
    expect(
      await model.changeCode('00123456', '12345678', '12345678'),
      isNotNull,
    );
    expect(gateway.releases, 0);
    expect(gateway.picks, 0);
    expect(gateway.changes, 0);
    model.dispose();
  });
  test('status decoder rejects malformed counts and modes', () {
    final map = <Object?, Object?>{
      'hasCode': true,
      'authorized': true,
      'selectedCount': 1,
      'appliedCount': 1,
      'mode': 'blocked',
    };
    expect(ProtectionStatus.fromMap(map).mode, 'blocked');
    expect(
      () => ProtectionStatus.fromMap({...map, 'appliedCount': 2}),
      throwsFormatException,
    );
    expect(
      () => ProtectionStatus.fromMap({...map, 'selectedCount': 51}),
      throwsFormatException,
    );
    expect(
      () => ProtectionStatus.fromMap({...map, 'mode': 'protected'}),
      throwsFormatException,
    );
  });
}
