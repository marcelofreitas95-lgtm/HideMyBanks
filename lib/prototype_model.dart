import 'package:flutter/foundation.dart';

import 'calculator_engine.dart';

enum PrototypePage { calculator, privateArea, selectApps, settings, appearance }

class BankApp {
  const BankApp(this.id, this.name, this.initials, this.color, this.subtitle);
  final String id;
  final String name;
  final String initials;
  final int color;
  final String subtitle;
}

const demoBanks = [
  BankApp('nubank', 'Nubank', 'nu', 0xFF9C6CE8, 'Conta digital'),
  BankApp('itau', 'Itaú', 'it', 0xFFE7A050, 'Banco'),
  BankApp('bb', 'Banco do Brasil', 'BB', 0xFFE2CF74, 'Banco'),
  BankApp('caixa', 'Caixa', 'CX', 0xFF69A6D2, 'Banco'),
  BankApp('basa', 'Banco da Amazônia', 'BA', 0xFF7BAA8A, 'Banco'),
  BankApp('bradesco', 'Bradesco', 'br', 0xFFD07A83, 'Banco'),
];

/// An in-memory UI demonstration. It never modifies the operating system.
class PrototypeModel extends ChangeNotifier {
  static const demoCode = '31415926';
  final calculator = CalculatorEngine();
  String _code = demoCode;
  PrototypePage page = PrototypePage.calculator;
  bool isProtected = true;
  bool sessionOpen = false;
  bool appearanceNotifications = false;
  Set<String> selected = {'nubank', 'itau', 'bb', 'caixa'};
  Set<String> draftSelection = {};
  String search = '';
  bool get isNative => false;
  bool get busy => false;
  bool get initialized => true;
  bool get needsSetup => false;
  bool get authorized => true;
  String? get error => null;
  DateTime? get releaseUntil => null;
  int get selectedCount => selected.length;
  int get appliedCount => isProtected ? selected.length : 0;

  Future<void> initialize() async {}
  Future<void> refresh() async {}
  Future<void> authorize() async {}
  Future<String?> setupCode(String next, String confirmation) async => null;

  List<BankApp> get selectedBanks =>
      demoBanks.where((b) => selected.contains(b.id)).toList();
  List<BankApp> get visibleBanks => isProtected
      ? demoBanks.where((b) => !selected.contains(b.id)).toList()
      : demoBanks;
  List<BankApp> get filteredBanks => demoBanks
      .where((b) => b.name.toLowerCase().contains(search.toLowerCase()))
      .toList();

  void press(String key) {
    if (key == '=' && calculator.accessCandidate == _code) {
      sessionOpen = true;
      page = PrototypePage.privateArea;
      calculator.clear();
    } else {
      calculator.press(key);
    }
    notifyListeners();
  }

  void navigate(PrototypePage target) {
    if (!sessionOpen && target != PrototypePage.calculator) return;
    if (target == PrototypePage.selectApps) {
      draftSelection = Set.of(selected);
      search = '';
    }
    page = target;
    notifyListeners();
  }

  void closePrivateArea() {
    sessionOpen = false;
    page = PrototypePage.calculator;
    calculator.clear();
    notifyListeners();
  }

  void toggleProtection() {
    if (!sessionOpen || selected.isEmpty) return;
    isProtected = !isProtected;
    notifyListeners();
  }

  void toggleBank(String id) {
    if (!sessionOpen || page != PrototypePage.selectApps) return;
    if (!draftSelection.remove(id)) draftSelection.add(id);
    notifyListeners();
  }

  void setSearch(String value) {
    search = value;
    notifyListeners();
  }

  void saveSelection() {
    if (!sessionOpen || draftSelection.isEmpty) return;
    selected = Set.of(draftSelection);
    isProtected = true;
    page = PrototypePage.privateArea;
    notifyListeners();
  }

  Future<String?> changeCode(
    String current,
    String next,
    String confirmation,
  ) async {
    if (!sessionOpen) return 'Abra a área privada para alterar o número.';
    if (current != _code) return 'O número atual está incorreto.';
    if (!RegExp(r'^\d{8,12}$').hasMatch(next)) return 'Use de 8 a 12 dígitos.';
    if (next != confirmation) return 'Os novos números não coincidem.';
    _code = next;
    notifyListeners();
    return null;
  }

  void showNotifications(bool value) {
    appearanceNotifications = value;
    notifyListeners();
  }

  void resetDemo() {
    _code = demoCode;
    isProtected = true;
    selected = {'nubank', 'itau', 'bb', 'caixa'};
    closePrivateArea();
  }
}
