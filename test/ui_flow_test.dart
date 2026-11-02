import 'package:calculadora/main.dart';
import 'package:calculadora/prototype_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'calculator opens private controls and edits app selection on a small screen',
    (tester) async {
      tester.view.physicalSize = const Size(390, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(CalculadoraApp(controller: PrototypeModel()));
      expect(find.text('Área privada'), findsNothing);
      for (final digit in '31415926'.split('')) {
        await tester.tap(find.text(digit));
        await tester.pump();
      }
      await tester.tap(find.text('='));
      await tester.pumpAndSettle();
      expect(find.text('Área privada'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Liberar acesso'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Liberar acesso'));
      await tester.pumpAndSettle();
      expect(find.text('Proteger agora'), findsOneWidget);
      await tester.ensureVisible(find.text('Selecionar aplicativos'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Selecionar aplicativos'));
      await tester.pumpAndSettle();
      expect(find.text('Nubank'), findsOneWidget);
      await tester.tap(find.byType(Checkbox).first);
      await tester.pump();
      expect(find.text('3 selecionados'), findsOneWidget);
      await tester.tap(find.text('Salvar seleção'));
      await tester.pumpAndSettle();
      expect(find.text('3 aplicativos'), findsOneWidget);
      await tester.ensureVisible(find.text('Número de acesso'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Número de acesso'));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNWidgets(3));
      expect(tester.takeException(), isNull);
      await tester.enterText(find.byType(TextField).at(0), '31415926');
      await tester.enterText(find.byType(TextField).at(1), '87654321');
      await tester.enterText(find.byType(TextField).at(2), '87654321');
      await tester.ensureVisible(find.text('Salvar número'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Salvar número'));
      await tester.pumpAndSettle();
      expect(
        find.text('Número alterado. Use o novo número ao entrar novamente.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
