# HideMyBanks

Aplicativo gratuito e de código aberto, desenvolvido em Flutter, que combina uma calculadora funcional com uma área privada acessada por um número configurável. O objetivo é ajudar usuários a preservar sua privacidade financeira e restringir o acesso aos aplicativos bancários no próprio iPhone, inclusive em situações de coação.

O nome exibido no iPhone é **Calculadora**. A distribuição planejada é **AltStore PAL**. O projeto está em desenvolvimento e depende das permissões e limitações do iOS.

A interface nasceu no [projeto do Stitch](https://stitch.withgoogle.com/projects/10902155357120582589). A demonstração web continua separada da integração nativa do iPhone.

## Situação atual

- Interface, cálculo e demonstração web implementados.
- Integração Swift de Family Controls/Managed Settings compilada no simulador, com seletor nativo, verificação de número no Keychain e extensão Device Activity Monitor.
- Pipeline Codemagic, verificação de assinatura e preparação do pacote PAL implementados.
- Workflow `validate` aprovado no Codemagic: análise Flutter sem ocorrências, 17 testes Flutter, sete testes dos scripts e cinco testes Swift aprovados, além da build web.
- **A IPA assinada para o iPhone, os testes físicos e a publicação ainda estão pendentes.** Nenhuma notificação real de banco foi bloqueada ou validada nesta entrega.

O caminho operacional completo está em [Implementação e publicação](docs/IMPLEMENTACAO_E_PUBLICACAO.md). As evidências pendentes estão em `release/readiness.json`; não devem ser marcadas como aprovadas sem execução real.

## Executar no Windows

Requer Flutter 3.41.6 e Python.

```powershell
flutter pub get --enforce-lockfile
flutter analyze --fatal-infos
flutter test
flutter build web --release --no-web-resources-cdn
.\scripts\Start-Prototype.ps1
```

Abra [a demonstração local](http://127.0.0.1:8765). O número **31415926 seguido de =** existe exclusivamente na demonstração. As configurações da web ficam em memória; não use senhas reais.

Se o OneDrive bloquear arquivos de build, execute em uma cópia local fora do sincronizador.

## Executar no iPhone

A versão nativa não usa o número da demonstração. O primeiro uso exige criar e confirmar um número de 8–12 dígitos; o verificador fica no Keychain. A sessão fecha ao sair da app.

Autorizar Tempo de Uso e selecionar de 1 a 50 aplicativos no seletor do iOS. Salvar aplica bloqueio; liberar agenda até 15 minutos de acesso. Se o agendamento falhar, o app mantém o bloqueio. O sistema pode atrasar callbacks.

Para compilar a partir do Windows, conectar o [repositório HideMyBanks](https://github.com/marcelofreitas95-lgtm/HideMyBanks) ao Codemagic, preencher `release/identity.json` e cadastrar os certificados/perfis descritos na documentação. Rodar primeiro `validate`, depois `ios-development`; validar no iPhone antes de `pal-notarization`.

**A Apple não oferece à Calculadora controle geral das notificações de terceiros.** O comportamento dos bancos, da pesquisa e do bloqueio precisa ser comprovado no aparelho. A autorização pode ser revogada e o app pode ser removido; não há garantia contra coação.

[Validação no Codemagic](docs/VALIDACAO_CODEMAGIC_20261101.md) registra o commit e a build aprovados. O [registro local](docs/VALIDACAO_20261101.md) preserva as verificações anteriores. O acesso ao serviço está documentado em [Codemagic](docs/CODEMAGIC.md).

## Organização

| Caminho | Responsabilidade |
|---|---|
| `lib/calculator_engine.dart` | Cálculo sequencial e entrada literal |
| `lib/prototype_model.dart` | Demonstração em memória |
| `lib/security/` | Canal nativo e estado confirmado pelo iOS |
| `lib/main.dart` | Interface Flutter, configuração inicial e controles privados |
| `ios/Runner/CodeVault.swift` | Keychain, PBKDF2 e tentativas |
| `ios/Runner/ProtectionPlugin.swift` | Autorização, seletor e comandos nativos |
| `ios/Shared/ProtectionPolicy.swift` | Política persistente compartilhada |
| `ios/DeviceActivityMonitor/` | Extensão de bloqueio automático |
| `codemagic.yaml` | Testes, IPA de desenvolvimento e notarização |
| `scripts/` | Identidade, assinatura, API PAL, fonte e integridade |
| `release/` | Identidade e resultados reais necessários à publicação |
| `design/stitch/` | Telas de referência exportadas do Stitch |
| `docs/` | Plano, implantação, privacidade e notas para revisão |

Certificados, chaves e respostas de acesso não pertencem ao repositório. `.secrets/`, `.p8`, `.p12`, `.mobileprovision` e arquivos `.env` são ignorados pelo Git.

## Contribuir

Sugestões e problemas podem ser registrados nas [issues](https://github.com/marcelofreitas95-lgtm/HideMyBanks/issues). Para contribuir com código, crie um fork, execute a análise e os testes Flutter descritos acima e rode `python -m unittest discover -s scripts -p test_release_tools.py` antes de abrir um pull request. Mudanças na integração iOS também precisam de validação com Xcode e, quando afetarem as restrições, no iPhone.

## Licença

O código do projeto está disponível sob a [licença MIT](LICENSE), que permite uso, modificação e redistribuição, inclusive comercial, preservando os avisos da licença. As fontes Manrope mantêm sua própria [SIL Open Font License](assets/fonts/OFL.txt).
