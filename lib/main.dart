import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'prototype_model.dart';
import 'security/native_model.dart';
import 'security/protection_gateway.dart';

const bg = Color(0xFF171817);
const surface = Color(0xFF272A28);
const ivory = Color(0xFFEEEAE1);
const muted = Color(0xFF9DA49C);
const amber = Color(0xFFD9AB62);
const green = Color(0xFF89D7A0);

void main() => runApp(const CalculadoraApp());

class NativeLoadingScreen extends StatelessWidget {
  const NativeLoadingScreen({super.key, required this.model});
  final PrototypeModel model;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.calculate_outlined, color: amber, size: 40),
          const SizedBox(height: 16),
          const Text('Calculadora'),
          const SizedBox(height: 20),
          if (model.busy)
            const CircularProgressIndicator()
          else ...[
            Text(
              model.error ?? 'Não foi possível iniciar.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ActionButton(
              label: 'Tentar novamente',
              onPressed: model.initialize,
            ),
          ],
        ],
      ),
    ),
  );
}

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key, required this.model});
  final PrototypeModel model;
  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final code = TextEditingController(), confirmation = TextEditingController();
  bool accepted = false;
  String? error;
  @override
  void dispose() {
    code.dispose();
    confirmation.dispose();
    super.dispose();
  }

  Future<void> save() async {
    final message = await widget.model.setupCode(code.text, confirmation.text);
    code.clear();
    confirmation.clear();
    if (mounted) setState(() => error = message);
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      const Icon(Icons.calculate_outlined, color: amber, size: 40),
      const SizedBox(height: 20),
      const Text('Configure a Calculadora', style: TextStyle(fontSize: 24)),
      const SizedBox(height: 12),
      const Text(
        'Crie um número de 8 a 12 dígitos. Para abrir a área privada, digite esse número na calculadora e toque em =. Ao sair, a tela volta à calculadora.',
        style: TextStyle(color: muted, height: 1.6),
      ),
      const SizedBox(height: 24),
      for (final item in [
        (code, 'Número de acesso'),
        (confirmation, 'Confirmar número'),
      ]) ...[
        TextField(
          controller: item.$1,
          obscureText: true,
          maxLength: 12,
          autocorrect: false,
          enableSuggestions: false,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(labelText: item.$2, counterText: ''),
        ),
        const SizedBox(height: 16),
      ],
      const NativeLimitations(),
      CheckboxListTile(
        value: accepted,
        contentPadding: EdgeInsets.zero,
        onChanged: widget.model.busy
            ? null
            : (value) => setState(() => accepted = value ?? false),
        title: const Text(
          'Memorizarei o número e compreendo os limites do iOS.',
          style: TextStyle(fontSize: 12),
        ),
      ),
      if (error != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(error!, style: const TextStyle(color: Color(0xFFFFB4AB))),
        ),
      ActionButton(
        label: widget.model.busy ? 'Salvando…' : 'Criar número',
        onPressed: accepted && !widget.model.busy ? save : null,
      ),
    ],
  );
}

class NativeStatusPanel extends StatelessWidget {
  const NativeStatusPanel({super.key, required this.model});
  final PrototypeModel model;
  @override
  Widget build(BuildContext context) => Panel(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            model.authorized
                ? 'Tempo de Uso autorizado'
                : 'Autorize o Tempo de Uso',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Text(
            model.selectedCount == 0
                ? 'Escolha os aplicativos no seletor do iOS. Nenhum app está selecionado.'
                : '${model.selectedCount} aplicativos escolhidos no seletor privado do iOS.',
            style: const TextStyle(fontSize: 12, color: muted, height: 1.6),
          ),
          if (!model.authorized) ...[
            const SizedBox(height: 12),
            ActionButton(
              label: 'Autorizar Tempo de Uso',
              onPressed: model.busy ? null : model.authorize,
            ),
          ],
          if (model.releaseUntil != null) ...[
            const SizedBox(height: 12),
            Text(
              'Bloqueio agendado para ${TimeOfDay.fromDateTime(model.releaseUntil!).format(context)}. Você pode proteger agora.',
              style: const TextStyle(color: amber, fontSize: 12),
            ),
          ],
          if (model.busy)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: LinearProgressIndicator(),
            ),
          if (model.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                model.error!,
                style: const TextStyle(color: Color(0xFFFFB4AB), fontSize: 12),
              ),
            ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Privacidade'),
                content: const Text(
                  'A Calculadora não envia seu número nem a seleção de aplicativos a servidores. O número é verificado no Keychain deste iPhone. A seleção usa identificadores privados do Tempo de Uso. Não há publicidade, rastreadores ou notificações próprias. A Apple e o AltStore processam os dados necessários à distribuição e instalação.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Fechar'),
                  ),
                ],
              ),
            ),
            icon: const Icon(Icons.privacy_tip_outlined, size: 18),
            label: const Text('Privacidade'),
          ),
        ],
      ),
    ),
  );
}

class NativeLimitations extends StatelessWidget {
  const NativeLimitations({super.key});
  @override
  Widget build(BuildContext context) => const Text(
    'O bloqueio usa o Tempo de Uso deste iPhone. A autorização pode ser revogada e o app pode ser desinstalado. Notificações, busca e bloqueio automático precisam ser conferidos no aparelho; o iOS pode atrasar a execução agendada. A Calculadora não garante proteção contra coação. Não há recuperação do número por e-mail.',
    style: TextStyle(fontSize: 11, color: muted, height: 1.7),
  );
}

class CalculadoraApp extends StatelessWidget {
  const CalculadoraApp({super.key, this.controller});
  final PrototypeModel? controller;
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Calculadora',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      fontFamily: 'Manrope',
      scaffoldBackgroundColor: bg,
      colorScheme: const ColorScheme.dark(
        primary: amber,
        onPrimary: bg,
        surface: bg,
        onSurface: ivory,
        secondary: green,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        labelStyle: const TextStyle(color: muted, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFF41473E)),
        ),
      ),
    ),
    home: PrototypeHost(controller: controller),
  );
}

class PrototypeHost extends StatefulWidget {
  const PrototypeHost({super.key, this.controller});
  final PrototypeModel? controller;
  @override
  State<PrototypeHost> createState() => _PrototypeHostState();
}

class _PrototypeHostState extends State<PrototypeHost>
    with WidgetsBindingObserver {
  late final model =
      widget.controller ??
      (kIsWeb
          ? PrototypeModel()
          : NativeModel(gateway: const IOSProtectionGateway()));
  final focus = FocusNode();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    model.initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    focus.dispose();
    model.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive &&
        model is NativeModel &&
        !(model as NativeModel).nativePresentation) {
      model.closePrivateArea();
    }
    if (state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused) {
      model.closePrivateArea();
    }
    if (state == AppLifecycleState.resumed) model.refresh();
  }

  KeyEventResult onKey(FocusNode node, KeyEvent event) {
    if (model.page != PrototypePage.calculator || event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }
    final key = switch (event.logicalKey) {
      LogicalKeyboardKey.enter ||
      LogicalKeyboardKey.numpadEnter ||
      LogicalKeyboardKey.equal => '=',
      LogicalKeyboardKey.backspace => 'backspace',
      LogicalKeyboardKey.escape || LogicalKeyboardKey.delete => 'AC',
      _ => switch (event.character) {
        '-' => '−',
        '*' => '×',
        '/' => '÷',
        '.' => ',',
        _ => event.character,
      },
    };
    if (key != null &&
        (RegExp(r'^\d$').hasMatch(key) ||
            const [
              '=',
              'backspace',
              'AC',
              '−',
              '×',
              '÷',
              '+',
              '%',
              ',',
            ].contains(key))) {
      model.press(key);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: model,
    builder: (context, _) => Focus(
      focusNode: focus,
      autofocus: true,
      onKeyEvent: onKey,
      child: Scaffold(
        body: LayoutBuilder(
          builder: (context, size) {
            if (!kIsWeb) return SafeArea(child: phone(false));
            if (size.maxWidth < 850) {
              return Column(
                children: [
                  const SizedBox(
                    height: 30,
                    child: Center(
                      child: Text(
                        'PROTÓTIPO FLUTTER · SIMULAÇÃO LOCAL',
                        style: TextStyle(
                          fontSize: 9,
                          color: muted,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 430),
                        child: phone(true),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 34,
                    child: TextButton(
                      onPressed: model.resetDemo,
                      child: const Text(
                        'Demo: 31415926 + =  ·  Reiniciar',
                        style: TextStyle(fontSize: 11, color: muted),
                      ),
                    ),
                  ),
                ],
              );
            }
            final height = (size.maxHeight - 64).clamp(600.0, 844.0);
            return ColoredBox(
              color: const Color(0xFF101210),
              child: Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 35,
                      vertical: 32,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(width: 335, child: guide()),
                        const SizedBox(width: 75),
                        Container(
                          width: 390,
                          height: height,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D0F0D),
                            border: Border.all(color: const Color(0xFF40463D)),
                            borderRadius: BorderRadius.circular(44),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black54,
                                blurRadius: 50,
                                offset: Offset(0, 22),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(36),
                            child: phone(true),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ),
  );

  Widget guide() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Row(
        children: [
          Icon(Icons.calculate_outlined, color: amber, size: 27),
          SizedBox(width: 10),
          Text(
            'Calculadora',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
          ),
        ],
      ),
      const SizedBox(height: 50),
      const Text(
        'Uma calculadora.\nUma área privada.',
        style: TextStyle(fontSize: 39, height: 1.2, letterSpacing: -1.8),
      ),
      const SizedBox(height: 20),
      const Text(
        'Explore o protótipo interativo criado a partir das telas do Stitch e desenvolvido em Flutter.',
        style: TextStyle(color: muted, height: 1.7, fontSize: 15),
      ),
      const SizedBox(height: 30),
      const GuideStep(
        '01',
        'Faça uma conta',
        'Use as teclas ou o teclado do computador.',
      ),
      const GuideStep(
        '02',
        'Abra a área privada',
        'Digite 31415926 e toque em =.',
      ),
      const GuideStep(
        '03',
        'Teste a proteção',
        'Selecione apps e compare os estados no simulador.',
      ),
      const SizedBox(height: 24),
      const Text(
        'DEMONSTRAÇÃO LOCAL',
        style: TextStyle(
          color: amber,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 2,
        ),
      ),
      const SizedBox(height: 8),
      const Text(
        'A ocultação e as notificações são simuladas. Nenhum aplicativo do aparelho é alterado. Mudanças duram até recarregar a página.',
        style: TextStyle(color: muted, fontSize: 12, height: 1.7),
      ),
      const SizedBox(height: 18),
      TextButton.icon(
        onPressed: model.resetDemo,
        icon: const Icon(Icons.restart_alt, size: 17),
        label: const Text('Reiniciar demonstração'),
        style: TextButton.styleFrom(
          foregroundColor: muted,
          padding: EdgeInsets.zero,
        ),
      ),
      const SizedBox(height: 20),
      const Text(
        'DESIGN NO STITCH  /  CÓDIGO EM FLUTTER',
        style: TextStyle(
          color: Color(0xFF667064),
          fontSize: 9,
          letterSpacing: 1.6,
        ),
      ),
    ],
  );

  Widget phone(bool chrome) => Material(
    color: bg,
    child: Column(
      children: [
        if (chrome) const StatusBar(),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: !model.initialized
                ? NativeLoadingScreen(model: model)
                : model.needsSetup
                ? SetupScreen(model: model)
                : switch (model.page) {
                    PrototypePage.calculator => CalculatorScreen(
                      key: const ValueKey('calc'),
                      model: model,
                    ),
                    PrototypePage.privateArea => PrivateScreen(
                      key: const ValueKey('private'),
                      model: model,
                    ),
                    PrototypePage.selectApps => SelectionScreen(
                      key: const ValueKey('selection'),
                      model: model,
                    ),
                    PrototypePage.settings => SettingsScreen(
                      key: const ValueKey('settings'),
                      model: model,
                    ),
                    PrototypePage.appearance => AppearanceScreen(
                      key: const ValueKey('appearance'),
                      model: model,
                    ),
                  },
          ),
        ),
        if (chrome)
          Container(
            width: 126,
            height: 4,
            margin: const EdgeInsets.only(top: 5, bottom: 14),
            decoration: BoxDecoration(
              color: ivory.withValues(alpha: .38),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
      ],
    ),
  );
}

class GuideStep extends StatelessWidget {
  const GuideStep(this.number, this.title, this.description, {super.key});
  final String number, title, description;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            number,
            style: const TextStyle(color: amber, fontSize: 10),
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(fontSize: 12, color: muted, height: 1.5),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class StatusBar extends StatelessWidget {
  const StatusBar({super.key});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(23, 16, 23, 10),
    child: Row(
      children: [
        const Text(
          '9:41',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        const Spacer(),
        const Icon(Icons.signal_cellular_alt, size: 16),
        const SizedBox(width: 5),
        const Icon(Icons.wifi, size: 16),
        const SizedBox(width: 5),
        Container(
          width: 23,
          height: 11,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            border: Border.all(color: ivory),
            borderRadius: BorderRadius.circular(3),
          ),
          child: const ColoredBox(color: ivory),
        ),
      ],
    ),
  );
}

class CalculatorScreen extends StatelessWidget {
  const CalculatorScreen({super.key, required this.model});
  final PrototypeModel model;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 2, 20, 4),
    child: LayoutBuilder(
      builder: (context, size) {
        final rowHeight = ((size.maxHeight - 142) / 5 - 10).clamp(42.0, 74.0);
        return Column(
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                'Calculadora',
                style: TextStyle(color: muted, fontSize: 13),
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: Text(
                    model.calculator.expression,
                    maxLines: 2,
                    style: const TextStyle(color: muted, fontSize: 14),
                  ),
                ),
                IconButton(
                  onPressed: () => model.press('backspace'),
                  tooltip: 'Apagar dígito',
                  icon: const Icon(
                    Icons.backspace_outlined,
                    size: 19,
                    color: muted,
                  ),
                ),
              ],
            ),
            Semantics(
              liveRegion: true,
              label: 'Resultado ${model.calculator.display}',
              child: SizedBox(
                height: 70,
                width: double.infinity,
                child: FittedBox(
                  alignment: Alignment.centerRight,
                  fit: BoxFit.scaleDown,
                  child: Text(
                    model.calculator.display,
                    style: const TextStyle(
                      fontSize: 58,
                      height: 1.2,
                      fontWeight: FontWeight.w300,
                      letterSpacing: -2,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            for (final keys in const [
              ['AC', '+/−', '%', '÷'],
              ['7', '8', '9', '×'],
              ['4', '5', '6', '−'],
              ['1', '2', '3', '+'],
              ['0', ',', '='],
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SizedBox(
                  height: rowHeight,
                  child: Row(
                    children: [
                      for (var i = 0; i < keys.length; i++) ...[
                        if (i > 0) const SizedBox(width: 10),
                        Expanded(
                          flex: keys[i] == '0' ? 2 : 1,
                          child: CalcKey(
                            label: keys[i],
                            onTap: () => model.press(keys[i]),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    ),
  );
}

class CalcKey extends StatelessWidget {
  const CalcKey({super.key, required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final operator = const ['÷', '×', '−', '+', '='].contains(label);
    final secondary = const ['AC', '+/−', '%'].contains(label);
    return Semantics(
      button: true,
      label: label == '='
          ? 'Igual'
          : label == 'AC'
          ? 'Limpar'
          : label,
      child: Material(
        color: operator
            ? amber
            : secondary
            ? const Color(0xFF393E39)
            : surface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Center(
            child: ExcludeSemantics(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: label == 'AC'
                      ? 23
                      : label == '+/−'
                      ? 24
                      : 29,
                  color: operator ? bg : ivory,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PrivateScreen extends StatelessWidget {
  const PrivateScreen({super.key, required this.model});
  final PrototypeModel model;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      PageHeader(title: 'Área privada', onClose: model.closePrivateArea),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 5, 20, 22),
          children: [
            Row(
              children: [
                StatusPill(
                  protected: model.isProtected,
                  label: model.isNative
                      ? (model.isProtected
                            ? 'Bloqueio aplicado'
                            : model.releaseUntil != null
                            ? 'Acesso temporário'
                            : 'Sem bloqueio')
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${model.selectedCount} aplicativos',
                    textAlign: TextAlign.right,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: muted, fontSize: 11),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 21),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    icon: Icons.visibility_off_outlined,
                    value: '${model.appliedCount}',
                    label: model.isNative
                        ? 'Bloqueios aplicados'
                        : 'Apps ocultos',
                    color: amber,
                    caption: model.isNative
                        ? 'Configuração do iOS'
                        : 'Na simulação',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: StatCard(
                    icon: model.isNative
                        ? Icons.help_outline
                        : model.isProtected
                        ? Icons.notifications_off_outlined
                        : Icons.notifications_outlined,
                    value: model.isNative
                        ? 'Verificar'
                        : model.isProtected
                        ? 'Silenciadas'
                        : 'Visíveis',
                    label: 'Notificações',
                    color: model.isNative
                        ? amber
                        : model.isProtected
                        ? green
                        : amber,
                    caption: model.isNative
                        ? 'Teste no aparelho'
                        : 'Na simulação',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'APLICATIVOS SELECIONADOS',
              style: TextStyle(color: muted, fontSize: 10, letterSpacing: 1.5),
            ),
            const SizedBox(height: 11),
            if (model.isNative)
              NativeStatusPanel(model: model)
            else
              Panel(
                child: Column(
                  children: [
                    for (var i = 0; i < model.selectedBanks.length; i++) ...[
                      if (i > 0)
                        const Divider(height: 1, color: Color(0xFF343A33)),
                      BankRow(
                        bank: model.selectedBanks[i],
                        subtitle: model.isProtected
                            ? 'Oculto na simulação'
                            : 'Acesso liberado na simulação',
                        trailing: Icon(
                          model.isProtected
                              ? Icons.shield_outlined
                              : Icons.lock_open_outlined,
                          color: muted,
                          size: 18,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            const SizedBox(height: 16),
            Panel(
              child: InkWell(
                onTap: () => model.navigate(PrototypePage.settings),
                borderRadius: BorderRadius.circular(18),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 17),
                  child: Row(
                    children: [
                      Icon(Icons.password_outlined, size: 19, color: muted),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Número de acesso',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                      Text(
                        '••••',
                        style: TextStyle(color: muted, letterSpacing: 2),
                      ),
                      SizedBox(width: 10),
                      Icon(Icons.chevron_right, size: 19, color: muted),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ActionButton(
              label: model.isProtected
                  ? (model.isNative
                        ? 'Liberar por 15 minutos'
                        : 'Liberar acesso')
                  : 'Proteger agora',
              icon: model.isProtected
                  ? Icons.lock_open_outlined
                  : Icons.shield_outlined,
              onPressed:
                  model.busy || !model.authorized || model.selectedCount == 0
                  ? null
                  : model.toggleProtection,
            ),
            const SizedBox(height: 10),
            ActionButton(
              label: 'Selecionar aplicativos',
              icon: Icons.apps_outlined,
              outlined: true,
              onPressed: model.busy || !model.authorized
                  ? null
                  : () => model.navigate(PrototypePage.selectApps),
            ),
            const SizedBox(height: 8),
            if (!model.isNative)
              TextButton.icon(
                onPressed: () => model.navigate(PrototypePage.appearance),
                icon: const Icon(Icons.phone_iphone_outlined, size: 17),
                label: const Text(
                  'Ver simulação no iPhone',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            const SizedBox(height: 7),
            if (model.isNative)
              const NativeLimitations()
            else
              const SimulationNote(),
          ],
        ),
      ),
    ],
  );
}

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.protected, this.label});
  final bool protected;
  final String? label;
  @override
  Widget build(BuildContext context) {
    final color = protected ? green : amber;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        border: Border.all(color: color.withValues(alpha: .3)),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 7),
          Text(
            label ?? (protected ? 'Modo protegido' : 'Acesso liberado'),
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    this.caption = 'Na simulação',
  });
  final IconData icon;
  final String value, label;
  final Color color;
  final String caption;
  @override
  Widget build(BuildContext context) => Panel(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 21),
          const SizedBox(height: 12),
          SizedBox(
            height: 31,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(label, style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 3),
          Text(caption, style: const TextStyle(color: muted, fontSize: 10)),
        ],
      ),
    ),
  );
}

class SelectionScreen extends StatelessWidget {
  const SelectionScreen({super.key, required this.model});
  final PrototypeModel model;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      PageHeader(
        title: 'Selecionar aplicativos',
        onBack: () => model.navigate(PrototypePage.privateArea),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${model.draftSelection.length} selecionados',
              style: const TextStyle(color: amber, fontSize: 12),
            ),
            const SizedBox(height: 18),
            TextField(
              onChanged: model.setSearch,
              decoration: const InputDecoration(
                hintText: 'Buscar aplicativo',
                prefixIcon: Icon(Icons.search, color: muted),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Escolha os apps que deseja ocultar na simulação.',
              style: TextStyle(color: muted, fontSize: 12, height: 1.6),
            ),
            const SizedBox(height: 14),
          ],
        ),
      ),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            if (model.filteredBanks.isEmpty)
              const Padding(
                padding: EdgeInsets.all(30),
                child: Text(
                  'Nenhum aplicativo encontrado.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: muted),
                ),
              ),
            for (final bank in model.filteredBanks)
              Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: Panel(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => model.toggleBank(bank.id),
                    child: BankRow(
                      bank: bank,
                      subtitle: bank.subtitle,
                      trailing: Checkbox(
                        value: model.draftSelection.contains(bank.id),
                        onChanged: (_) => model.toggleBank(bank.id),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
        child: Column(
          children: [
            ActionButton(
              label: 'Salvar seleção',
              onPressed: model.draftSelection.isEmpty
                  ? null
                  : model.saveSelection,
            ),
            const SizedBox(height: 9),
            const Text(
              'Ao salvar, a proteção simulada será aplicada.',
              style: TextStyle(color: muted, fontSize: 10),
            ),
          ],
        ),
      ),
    ],
  );
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.model});
  final PrototypeModel model;
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final current = TextEditingController(),
      next = TextEditingController(),
      confirmation = TextEditingController();
  bool reveal = false, success = false;
  String? message;
  @override
  void dispose() {
    current.dispose();
    next.dispose();
    confirmation.dispose();
    super.dispose();
  }

  void save() async {
    if (widget.model.busy) return;
    final error = await widget.model.changeCode(
      current.text,
      next.text,
      confirmation.text,
    );
    if (!mounted) return;
    setState(() {
      success = error == null;
      message =
          error ?? 'Número alterado. Use o novo número ao entrar novamente.';
      if (success) {
        current.clear();
        next.clear();
        confirmation.clear();
      }
    });
  }

  Widget field(String label, TextEditingController controller) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextField(
      controller: controller,
      obscureText: !reveal,
      keyboardType: TextInputType.number,
      enableSuggestions: false,
      autocorrect: false,
      maxLength: 12,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        labelText: label,
        counterText: '',
        suffixIcon: IconButton(
          tooltip: reveal ? 'Ocultar números' : 'Mostrar números',
          onPressed: () => setState(() => reveal = !reveal),
          icon: Icon(
            reveal ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: muted,
            size: 18,
          ),
        ),
      ),
    ),
  );
  @override
  Widget build(BuildContext context) => Column(
    children: [
      PageHeader(
        title: 'Número de acesso',
        onBack: () => widget.model.navigate(PrototypePage.privateArea),
      ),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
          children: [
            Panel(
              child: const Padding(
                padding: EdgeInsets.all(17),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.calculate_outlined, color: amber, size: 22),
                    SizedBox(height: 12),
                    Text(
                      'Seu acesso, do seu jeito.',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Digite o número na calculadora e toque em = para abrir a área privada.',
                      style: TextStyle(
                        fontSize: 12,
                        color: muted,
                        height: 1.65,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 26),
            field('Número atual', current),
            field('Novo número', next),
            field('Confirmar novo número', confirmation),
            const Text(
              'Use de 8 a 12 dígitos. Zeros no início são aceitos.',
              style: TextStyle(color: muted, fontSize: 11, height: 1.6),
            ),
            const SizedBox(height: 22),
            if (message != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 17),
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    message!,
                    style: TextStyle(
                      color: success ? green : const Color(0xFFFFB4AB),
                      height: 1.5,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ActionButton(
              label: 'Salvar número',
              icon: Icons.check,
              onPressed: widget.model.busy ? null : save,
            ),
            const SizedBox(height: 25),
            Text(
              widget.model.isNative
                  ? 'O iOS guarda um verificador do número no Keychain deste aparelho. Memorize o número: não há recuperação por e-mail.'
                  : 'Nesta demonstração, o número fica apenas na memória e volta a 31415926 ao reiniciar. Não use uma senha real.',
              style: const TextStyle(color: muted, fontSize: 11, height: 1.7),
            ),
            const SizedBox(height: 16),
            if (!widget.model.isNative) const SimulationNote(),
          ],
        ),
      ),
    ],
  );
}

class AppearanceScreen extends StatelessWidget {
  const AppearanceScreen({super.key, required this.model});
  final PrototypeModel model;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      PageHeader(
        title: 'Simulação do iPhone',
        onBack: () => model.navigate(PrototypePage.privateArea),
      ),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 3, 20, 20),
          children: [
            Row(
              children: [
                StatusPill(protected: model.isProtected),
                const Spacer(),
                const Text(
                  'SIMULAÇÃO',
                  style: TextStyle(
                    fontSize: 9,
                    color: muted,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  for (final tab in [false, true])
                    Expanded(
                      child: Semantics(
                        button: true,
                        selected: model.appearanceNotifications == tab,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => model.showNotifications(tab),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: model.appearanceNotifications == tab
                                  ? const Color(0xFF42483F)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              tab ? 'Notificações' : 'Aplicativos',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (model.appearanceNotifications) notifications() else apps(),
            const SizedBox(height: 18),
            Text(
              model.isProtected
                  ? 'Os apps selecionados ficam fora da lista e suas notificações não aparecem neste simulador.'
                  : 'Os apps e suas notificações voltaram a aparecer neste simulador.',
              style: const TextStyle(fontSize: 12, color: muted, height: 1.7),
            ),
            const SizedBox(height: 20),
            ActionButton(
              label: model.isProtected
                  ? 'Simular acesso liberado'
                  : 'Simular modo protegido',
              icon: Icons.swap_horiz,
              outlined: true,
              onPressed: model.toggleProtection,
            ),
            const SizedBox(height: 20),
            const SimulationNote(),
          ],
        ),
      ),
    ],
  );
  Widget apps() {
    final tiles = <({String name, String initials, Color color})>[
      (name: 'Calculadora', initials: '＋', color: const Color(0xFFAA8651)),
      (name: 'Mensagens', initials: '•••', color: const Color(0xFF619572)),
      (name: 'Fotos', initials: '✦', color: const Color(0xFF897FA5)),
      (name: 'Ajustes', initials: '⚙', color: const Color(0xFF777E7D)),
      (name: 'Calendário', initials: '01', color: const Color(0xFF9D7073)),
      (name: 'Notas', initials: '≡', color: const Color(0xFFAD9D61)),
      for (final bank in model.visibleBanks)
        (name: bank.name, initials: bank.initials, color: Color(bank.color)),
    ];
    return Panel(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                children: [
                  Icon(Icons.search, size: 16, color: muted),
                  SizedBox(width: 9),
                  Text(
                    'Biblioteca de Apps',
                    style: TextStyle(fontSize: 11, color: muted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            GridView.count(
              crossAxisCount: 3,
              childAspectRatio: .96,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (final tile in tiles)
                  Column(
                    children: [
                      Container(
                        width: 51,
                        height: 51,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: tile.color.withValues(alpha: .17),
                          border: Border.all(
                            color: tile.color.withValues(alpha: .32),
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          tile.initials,
                          style: TextStyle(
                            color: tile.color,
                            fontSize: 23,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        tile.name,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 9, height: 1.25),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget notifications() => Panel(
    child: Padding(
      padding: const EdgeInsets.all(17),
      child: Column(
        children: [
          const Text(
            'Central de Notificações',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 25),
          if (model.isProtected) ...[
            Container(
              width: 66,
              height: 66,
              decoration: BoxDecoration(
                color: green.withValues(alpha: .08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_off_outlined,
                color: green,
                size: 28,
              ),
            ),
            const SizedBox(height: 17),
            const Text(
              'Nenhuma notificação\nde banco protegido',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 17, height: 1.5),
            ),
            const SizedBox(height: 12),
            const Text(
              'Somente apps selecionados são silenciados na simulação.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: muted, height: 1.6),
            ),
            const SizedBox(height: 20),
          ] else
            for (final bank in model.selectedBanks)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    BankBadge(bank: bank, size: 34),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bank.name,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 3),
                          const Text(
                            'Notificação de exemplo',
                            style: TextStyle(fontSize: 10, color: muted),
                          ),
                        ],
                      ),
                    ),
                    const Text(
                      'agora',
                      style: TextStyle(color: muted, fontSize: 9),
                    ),
                  ],
                ),
              ),
        ],
      ),
    ),
  );
}

class PageHeader extends StatelessWidget {
  const PageHeader({super.key, required this.title, this.onBack, this.onClose});
  final String title;
  final VoidCallback? onBack, onClose;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 7, 12, 15),
    child: Row(
      children: [
        if (onBack != null)
          IconButton(
            onPressed: onBack,
            tooltip: 'Voltar',
            icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          )
        else
          const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: onBack == null ? 25 : 19,
              fontWeight: FontWeight.w600,
              letterSpacing: -.7,
            ),
          ),
        ),
        if (onClose != null)
          IconButton(
            onPressed: onClose,
            tooltip: 'Fechar área privada',
            icon: const Icon(Icons.close, size: 22),
          ),
      ],
    ),
  );
}

class Panel extends StatelessWidget {
  const Panel({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: const Color(0xFF1E211E),
      border: Border.all(color: const Color(0xFF30362F)),
      borderRadius: BorderRadius.circular(18),
    ),
    child: child,
  );
}

class BankBadge extends StatelessWidget {
  const BankBadge({super.key, required this.bank, this.size = 42});
  final BankApp bank;
  final double size;
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: Color(bank.color).withValues(alpha: .13),
      border: Border.all(color: Color(bank.color).withValues(alpha: .26)),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      bank.initials,
      style: TextStyle(
        color: Color(bank.color),
        fontSize: size * .37,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class BankRow extends StatelessWidget {
  const BankRow({
    super.key,
    required this.bank,
    required this.subtitle,
    required this.trailing,
  });
  final BankApp bank;
  final String subtitle;
  final Widget trailing;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
    child: Row(
      children: [
        BankBadge(bank: bank),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(bank.name, style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(color: muted, fontSize: 10),
              ),
            ],
          ),
        ),
        trailing,
      ],
    ),
  );
}

class ActionButton extends StatelessWidget {
  const ActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.outlined = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool outlined;
  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[Icon(icon, size: 19), const SizedBox(width: 10)],
        Flexible(
          child: Text(
            label,
            maxLines: 2,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: outlined
          ? OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: ivory,
                side: const BorderSide(color: Color(0xFF3B4339)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: child,
            )
          : FilledButton(
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                backgroundColor: amber,
                foregroundColor: bg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: child,
            ),
    );
  }
}

class SimulationNote extends StatelessWidget {
  const SimulationNote({super.key});
  @override
  Widget build(BuildContext context) => const Text(
    'Protótipo: a proteção do iOS está sendo simulada.',
    textAlign: TextAlign.center,
    style: TextStyle(color: muted, fontSize: 10, height: 1.6),
  );
}
