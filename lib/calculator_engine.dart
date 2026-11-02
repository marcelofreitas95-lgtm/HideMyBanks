/// Small, sequential calculator. Access codes use raw input, never results.
class CalculatorEngine {
  String entry = '0';
  String expression = '';
  bool isLiteral = false;
  double? _left;
  String? _operator;
  bool _newEntry = true;
  bool _hasError = false;

  String get display => entry.replaceAll('.', ',');
  String? get accessCandidate => isLiteral ? entry : null;

  void clear() {
    entry = '0';
    expression = '';
    isLiteral = false;
    _left = null;
    _operator = null;
    _newEntry = true;
    _hasError = false;
  }

  void press(String key) {
    if (key == 'AC') {
      clear();
      return;
    }
    if (RegExp(r'^\d$').hasMatch(key)) {
      if (_hasError) clear();
      if (_newEntry) {
        entry = key;
        isLiteral = _operator == null;
        if (_operator == null) expression = '';
        _newEntry = false;
      } else if (entry.replaceAll('-', '').length < 16) {
        entry += key;
      }
      return;
    }
    if (_hasError) return;
    if (key == 'backspace') {
      if (_newEntry) return;
      entry = entry.length > 1 ? entry.substring(0, entry.length - 1) : '0';
      if (entry == '-') entry = '0';
      return;
    }
    isLiteral = false;
    if (key == ',') {
      if (_newEntry) {
        entry = '0';
        _newEntry = false;
      }
      if (!entry.contains('.')) entry += '.';
      return;
    }
    if (key == '+/−') {
      entry = _format(-_value);
      return;
    }
    if (key == '%') {
      final fraction = _value / 100;
      entry = _format(
        (_operator == '+' || _operator == '−') && _left != null
            ? _left! * fraction
            : fraction,
      );
      return;
    }
    if (key == '=') {
      if (_operator != null && _left != null && !_newEntry) {
        expression =
            '${_format(_left!).replaceAll('.', ',')} $_operator $display =';
        final result = _calculate(_left!, _value, _operator!);
        if (result == null) return;
        entry = _format(result);
      }
      _operator = null;
      _left = null;
      _newEntry = true;
      return;
    }
    if (const ['+', '−', '×', '÷'].contains(key)) {
      if (_operator != null && _left != null && !_newEntry) {
        final result = _calculate(_left!, _value, _operator!);
        if (result == null) return;
        entry = _format(result);
      }
      _left = _value;
      _operator = key;
      expression = '$display $key';
      _newEntry = true;
    }
  }

  double get _value => double.tryParse(entry) ?? 0;

  double? _calculate(double left, double right, String op) {
    if (op == '÷' && right == 0) {
      entry = 'Erro';
      expression = 'Não é possível dividir por zero';
      _hasError = true;
      _operator = null;
      _left = null;
      _newEntry = true;
      return null;
    }
    return switch (op) {
      '+' => left + right,
      '−' => left - right,
      '×' => left * right,
      '÷' => left / right,
      _ => right,
    };
  }

  String _format(double value) {
    if (!value.isFinite) return 'Erro';
    if (value == 0) return '0';
    return double.parse(
      value.toStringAsPrecision(12),
    ).toString().replaceFirst(RegExp(r'\.0$'), '');
  }
}
