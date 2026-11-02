import 'package:calculadora/main.dart';
import 'package:calculadora/security/native_model.dart';
import 'package:calculadora/security/protection_gateway.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'native_model_test.dart' show FakeGateway;

void main() {
  testWidgets('iOS setup requires confirmation and never exposes demo access', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final gateway = FakeGateway()
      ..value = const ProtectionStatus(
        hasCode: false,
        authorized: false,
        selectedCount: 0,
        appliedCount: 0,
        mode: 'unavailable',
      );
    final model = NativeModel(gateway: gateway);
    await tester.pumpWidget(CalculadoraApp(controller: model));
    await tester.pumpAndSettle();
    expect(find.text('Configure a Calculadora'), findsOneWidget);
    expect(find.textContaining('31415926'), findsNothing);
    expect(find.byType(TextField), findsNWidgets(2));
    await tester.enterText(find.byType(TextField).first, '00123456');
    await tester.enterText(find.byType(TextField).last, '00123456');
    await tester.scrollUntilVisible(
      find.byType(CheckboxListTile),
      200,
      scrollable: find
          .descendant(
            of: find.byType(SetupScreen),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Criar número'));
    await tester.tap(find.text('Criar número'));
    await tester.pumpAndSettle();
    expect(find.text('Configure a Calculadora'), findsNothing);
    for (final digit in '00123456'.split('')) {
      await tester.tap(find.widgetWithText(CalcKey, digit));
      await tester.pump();
    }
    await tester.tap(find.text('='));
    await tester.pumpAndSettle();
    expect(find.text('Área privada'), findsOneWidget);
    expect(find.text('Verificar'), findsOneWidget);
    expect(find.text('Silenciadas'), findsNothing);
    expect(find.text('Ver simulação no iPhone'), findsNothing);
    expect(find.text('Autorizar Tempo de Uso'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('unavailable native bridge shows retry, never the demo', (
    tester,
  ) async {
    final model = NativeModel(gateway: FakeGateway()..available = false);
    await tester.pumpWidget(CalculadoraApp(controller: model));
    await tester.pumpAndSettle();
    expect(find.text('Tentar novamente'), findsOneWidget);
    expect(find.textContaining('31415926'), findsNothing);
    expect(find.text('='), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
