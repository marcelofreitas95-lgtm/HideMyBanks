import 'package:flutter_test/flutter_test.dart';
import 'package:calculadora/prototype_model.dart';

void enter(PrototypeModel model, String input) {
  for (final key in input.split('')) {
    model.press(key);
  }
}

void main() {
  test('calculation results never authenticate as access codes', () {
    final model = PrototypeModel();
    enter(model, '31415925+1=');
    expect(model.calculator.display, '31415926');
    model.press('=');
    expect(model.sessionOpen, false);
    model.press('AC');
    enter(model, '31415926=');
    expect(model.page, PrototypePage.privateArea);
    expect(model.isProtected, true);
  });

  test('decimal arithmetic, contextual percentage and error recovery', () {
    final model = PrototypeModel();
    enter(model, '0,1+0,2=');
    expect(model.calculator.display, '0,3');
    model.press('AC');
    enter(model, '200+10%=');
    expect(model.calculator.display, '220');
    model.press('AC');
    enter(model, '8÷0=');
    expect(model.calculator.display, 'Erro');
    enter(model, '7');
    expect(model.calculator.display, '7');
  });

  test(
    'private commands require a session and selection controls appearance',
    () {
      final model = PrototypeModel();
      model.navigate(PrototypePage.settings);
      model.toggleProtection();
      expect(model.page, PrototypePage.calculator);
      expect(model.isProtected, true);
      enter(model, '31415926=');
      model.navigate(PrototypePage.selectApps);
      model.toggleBank('basa');
      model.saveSelection();
      expect(model.selected.length, 5);
      expect(model.visibleBanks.map((b) => b.id), ['bradesco']);
      model.toggleProtection();
      expect(model.visibleBanks.length, 6);
      model.closePrivateArea();
      model.toggleProtection();
      expect(model.isProtected, false);
    },
  );

  test(
    'changing code validates current, length, confirmation and leading zeros',
    () async {
      final model = PrototypeModel();
      enter(model, '31415926=');
      expect(
        await model.changeCode('wrong', '00123456', '00123456'),
        isNotNull,
      );
      expect(await model.changeCode('31415926', '123', '123'), isNotNull);
      expect(
        await model.changeCode('31415926', '00123456', '00123457'),
        isNotNull,
      );
      expect(
        await model.changeCode('31415926', '00123456', '00123456'),
        isNull,
      );
      model.closePrivateArea();
      enter(model, '31415926=');
      expect(model.sessionOpen, false);
      model.press('AC');
      enter(model, '00123456=');
      expect(model.sessionOpen, true);
      model.resetDemo();
      enter(model, '31415926=');
      expect(model.sessionOpen, true);
    },
  );
}
