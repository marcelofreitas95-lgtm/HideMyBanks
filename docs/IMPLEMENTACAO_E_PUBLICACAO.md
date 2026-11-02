# Implementação e distribuição da Calculadora

Referência: 01/11/2026. Canal escolhido: AltStore PAL. Código Flutter 3.41.6/Dart 3.11.4; iOS mínimo do aplicativo: 16.0; pipeline fixado em Xcode 26.6. A disponibilidade do marketplace depende adicionalmente do país, conta e versão do sistema.

## Situação verificável

| Entrega | Situação |
|---|---|
| Calculadora, interface e demonstração web do Stitch | Implementadas e testadas |
| Ponte Flutter/Swift, PIN, seleção e políticas | Código implementado; compilação e validação iOS pendentes |
| Extensão Device Activity Monitor | Código e target integrados; testes no macOS e iPhone pendentes |
| Testes Flutter | 17 aprovados; análise sem ocorrências |
| Testes Swift/Keychain | Cinco testes escritos, ainda não executados |
| Codemagic e assinatura | Três workflows prontos; conta, integração e perfis pendentes |
| Aprovações Family Controls app/extensão | Pendentes da Apple |
| Notarização e ADP | Pendentes |
| Instalação via PAL e testes de notificações | Pendentes |

Não existe uma IPA assinada ou app publicado nesta etapa. O simulador web não é evidência da proteção real.

## Funcionamento no iPhone

1. No primeiro uso, criar e confirmar um número de 8–12 dígitos. Não existe código padrão na versão nativa.
2. Digitar o número literalmente na calculadora e tocar em `=`. Resultados de cálculos nunca autenticam.
3. Autorizar gerenciamento individual do Tempo de Uso usando a tela da Apple.
4. Selecionar somente aplicativos bancários no FamilyActivityPicker. Não selecionar a Calculadora, categorias ou sites. Limite de 50 aplicativos.
5. Salvar aplica `ManagedSettingsStore.application.blockedApplications` usando os tokens de aplicação.
6. Liberar acesso agenda um intervalo de 15 minutos, com margem de dois segundos, antes de retirar os bloqueios. Falha no agendamento mantém o bloqueio.
7. Ao sair da Calculadora, sua área privada fecha. Os bancos permanecem liberados até a extensão restabelecer o bloqueio, permitindo abrir o app bancário. Também é possível proteger imediatamente.

O monitor utiliza a mesma store nomeada e o App Group da aplicação. A política e o prazo são persistidos em arquivo protegido, com coordenação entre processos. A reconciliação ocorre no callback da extensão e no lançamento/retorno da aplicação. Uma callback antiga não encerra uma liberação mais recente.

O iOS pode atrasar callbacks. A revogação da autorização, remoção do aplicativo, reinício, alteração do relógio e outras superfícies do sistema devem ser testados e documentados. O PIN não é um bloqueio global do iPhone.

## Número e privacidade

`CodeVault` guarda apenas sal de 32 bytes e derivação PBKDF2-HMAC-SHA256 de 210.000 iterações no Keychain, acessível com o aparelho desbloqueado e restrito a este dispositivo. O número não é persistido em texto puro. A comparação acumula diferenças entre bytes. Cinco tentativas erradas iniciam espera progressiva, persistida no Keychain. A troca exige o número atual.

A sessão nativa expira após dois minutos sem comando privado e fecha ao ir ao segundo plano. Um verificador atrasado não reabre uma sessão que foi fechada. Um painel neutro cobre o conteúdo quando a aplicação perde foco. Isso não bloqueia screenshots nem gravação de tela realizados enquanto o conteúdo está visível.

O app não envia PIN, nomes de bancos ou tokens a servidores. Os tokens ficam no container protegido do App Group; o seletor de nomes é exibido pelo iOS. O Keychain pode sobreviver à reinstalação: reinstalar não é um procedimento de recuperação do número. Não existe recuperação por e-mail.

## Conta e identificadores

Usar Apple Developer Program ativo. Registrar três recursos sob a mesma equipe:

- Bundle ID exclusivo da app, por exemplo `com.seudominio.calculadora`.
- Bundle ID da extensão: `<bundle>.Monitor`.
- App Group: `group.<bundle>`.

Habilitar Family Controls e App Groups em ambos os identificadores. Solicitar **Family Controls para distribuição da app e da extensão**, explicando a finalidade real de gerenciamento individual e privacidade. Confirmar que Provisioning Support inclui o método de distribuição necessário ao marketplace.

Preencher `release/identity.json` com os identificadores registrados, Team ID, Apple ID numérico do aplicativo no App Store Connect, nome público do desenvolvedor, URLs públicas HTTPS, screenshots reais, versão e número do build. Team ID e Bundle ID não são senhas. Chaves `.p8`, certificados `.p12`, senhas e perfis não devem ir ao Git ou ao chat.

O script `python scripts/configure_ios.py` aplica os identificadores e mantém app/extensão na mesma versão. A configuração de exemplo é rejeitada para assinatura. O registro prévio na Apple não é feito por esse script.

## Compilar no Codemagic a partir do Windows

Conectar o [repositório público HideMyBanks](https://github.com/marcelofreitas95-lgtm/HideMyBanks). Cadastrar os certificados/perfis em **Team settings → Code signing identities**, usando exatamente estas referências:

| Recurso | Referência no YAML |
|---|---|
| Certificado Apple Development | `calculadora_development_certificate` |
| Perfil development da app, com o UDID do iPhone | `calculadora_development` |
| Perfil development da extensão, com o mesmo UDID | `calculadora_monitor_development` |
| Certificado Apple Distribution | `calculadora_distribution_certificate` |
| Perfil distribution da app, com as capacidades aprovadas | `calculadora_distribution` |
| Perfil distribution da extensão, com as capacidades aprovadas | `calculadora_monitor_distribution` |

Cadastrar a integração App Store Connect com referência `calculadora_apple`, usando a interface segura do Codemagic. Não colar a chave no YAML. Obter/regenerar certificados e perfis pelo serviço ou portal, conforme a conta permitir; não é necessário manter um Mac local.

Executar, em ordem:

1. `validate`: análise, testes Flutter, compilação da app/extensão e cinco testes XCTest no simulador. Não requer certificado de distribuição. O simulador não prova ocultação ou notificações.
2. `ios-development`: compila a IPA de desenvolvimento, verifica assinatura, entitlements, App Group, versões e perfis da app/extensão e entrega `signing.json`.
3. Instalar essa IPA no iPhone registrado, conectado ao Windows, com ferramenta compatível com pacotes de desenvolvimento, como iMazing. Ativar Developer Mode e confiar no computador quando o iOS solicitar. Não usar AltStore Classic para reassinar e perder as capacidades especiais.
4. Executar os testes físicos abaixo e registrar evidências da versão em `release/readiness.json`.
5. `pal-notarization`: verifica as evidências, repete os testes, assina e envia ao App Store Connect. Não solicita publicação na App Store nem TestFlight. No App Store Connect, configurar a distribuição alternativa e submeter a versão escolhida para **Notarization**.

O `codemagic.yaml` foi escrito e validado estruturalmente; ainda não foi executado em uma conta do Codemagic. A disponibilidade do Xcode fixado deve ser confirmada ao conectar o serviço. Minutos de compilação e a assinatura Apple têm custos definidos pelos provedores.

## Testes físicos obrigatórios

Registrar modelo do iPhone, versão completa do iOS, região, versão/build da app, resultado e referência à evidência. Não incluir dados bancários ou notificações financeiras sensíveis.

| Registro em readiness.json | Procedimento |
|---|---|
| `nativeBuild`, `nativeTests` | Build macOS e XCTest aprovados |
| `familyControlsAppApproved`, `familyControlsMonitorApproved` | Capacidade de distribuição Assigned para ambos |
| `marketplaceProvisioningSupported` | Método de distribuição compatível nos dois perfis |
| `physicalDevice` | IPA assinada instalada no aparelho de teste |
| `hiddenHomeAndLibrary` | Bancos somem da Tela de Início e da Biblioteca, incluindo pastas |
| `hiddenSearch` | Spotlight, pesquisa da Biblioteca, sugestões e links relevantes |
| `launchBlocked` | Abertura por ícone antigo, link universal e atalhos é impedida |
| `notificationsSuppressed` | Alertas novos, já existentes, tela bloqueada, central, banners e badges |
| `automaticRelock` | Bloqueio ao fim do intervalo, com a Calculadora suspensa e encerrada |
| `rebootAndTermination` | Reinício antes/depois do prazo, app encerrada, offline e alterações de fuso |
| `authorizationRevocation` | Revogar permissão e remover app; registrar os caminhos de recuperação |
| `privacyAndMetadata` | Conteúdo, nomes, screenshots e política correspondem ao comportamento real |

`UNUserNotificationCenter` não controla as notificações de terceiros. Se o bloqueio do iOS não eliminar as notificações dos bancos, **o requisito completo permanece não atendido e esta versão não deve ser publicada com essa promessa**. Não registrar um teste como aprovado com base no simulador ou apenas em leitura de código.

## AltStore PAL e hospedagem

1. No App Store Connect, selecionar os países compatíveis e aceitar os termos de distribuição alternativa que se aplicarem à conta. A documentação atual do PAL inclui UE, Japão e Brasil; o requisito específico do Brasil inclui iOS 26.5 ou posterior. Confirmar os requisitos atuais antes da instalação.
2. Registrar Developer ID e e-mail no PAL usando a API oficial. `python scripts/altstore.py register --developer-id SEU_ID --email SEU_EMAIL` salva o resultado em `%LOCALAPPDATA%/CalculadoraRelease/altstore-registration.json`. O token não é exibido. Adicionar esse token à integração de marketplace no App Store Connect.
3. Selecionar a Calculadora na integração do PAL e habilitar notificações de processamento da Apple para o marketplace.
4. Após notarização aprovada, obter o ADP ID. `altstore.py process --adp-id ID` solicita processamento; `altstore.py status --adp-id ID` salva o status e eventual URL de download em `%LOCALAPPDATA%/CalculadoraRelease/altstore-adp.json`. Os resultados ficam fora da pasta sincronizada do projeto. Nunca colocar links de acesso temporários no repositório.
5. Baixar o ADP pela URL retornada e extrair em um diretório reservado. Preservar exatamente arquivos, estrutura, manifest e assinatura. O gerador copia o ADP sem alterar seus bytes; ele não substitui a assinatura/notarização da Apple.
6. Preparar o diretório de publicação em um destino novo:

```powershell
python scripts/prepare_pal_source.py --adp CAMINHO_ADP --output dist/pal-1.0.0-1 --base-url https://SEU_HOST/calculadora --signing-report CAMINHO_SIGNING_JSON
```

7. Hospedar o pacote em HTTPS público com a estrutura intacta e sem autenticação para downloads. Hospedar ícone, screenshots reais, página do aplicativo e política de privacidade nas URLs configuradas. O `downloadURL` da fonte PAL aponta para o `manifest.json` do ADP, não para a IPA.
8. Conferir os arquivos publicados:

```powershell
python scripts/verify_pal_host.py --package dist/pal-1.0.0-1 --base-url https://SEU_HOST/calculadora
```

9. Adicionar a URL de `source.json` no AltStore PAL e confirmar instalação e atualização em um iPhone elegível. Só considerar a publicação concluída após a instalação pelo marketplace. A descoberta pública/federação é opcional e não está configurada.

Para atualizações: incrementar buildNumber, manter app e extensão alinhadas, repetir validações na nova versão, notarizar, preparar novo ADP e colocar a nova versão primeiro na fonte, preservando os registros anteriores.

## Fontes oficiais

- [blockedApplications](https://developer.apple.com/documentation/managedsettings/applicationsettings/blockedapplications-swift.property)
- [Autorização individual](https://developer.apple.com/documentation/familycontrols/authorizationcenter/requestauthorization(for:))
- [Family Controls para distribuição](https://developer.apple.com/documentation/familycontrols/requesting-the-family-controls-entitlement)
- [DeviceActivitySchedule](https://developer.apple.com/documentation/deviceactivity/deviceactivityschedule)
- [Codemagic: assinatura iOS](https://docs.codemagic.io/yaml-code-signing/signing-ios/)
- [Distribuir no AltStore PAL](https://faq.altstore.io/developers/distribute-with-altstore-pal)
- [Fonte JSON do AltStore](https://faq.altstore.io/developers/make-a-source)
- [API REST do PAL](https://faq.altstore.io/developers/rest-api)
- [Distribuição por região](https://developer.apple.com/documentation/marketplacekit/participating-in-alternative-distribution-for-specific-regions)
