# Validação no Codemagic — 01/11/2026

O workflow `validate` foi aprovado na [build 4 do HideMyBanks](https://codemagic.io/app/6ae7f03e3fff223c356f76af/build/6ae7f590efa74786046ff2a2).

- Commit testado: [`96a88f3`](https://github.com/marcelofreitas95-lgtm/HideMyBanks/commit/96a88f39e5c82174afd4e9db61d10a2450f3a7e8).
- Máquina: Mac M2, macOS 26.5.1, Xcode 26.6 e Flutter 3.41.6.
- Simulador: iPhone 17 Pro, iOS 26.5, arquitetura arm64.
- Duração da build aprovada: 4 minutos e 55 segundos.
- Evidência estruturada: [codemagic-20261101.json](evidence/codemagic-20261101.json).

## Resultados

| Verificação | Resultado |
|---|---|
| Análise Flutter | Nenhuma ocorrência |
| Testes Flutter | 17 aprovados |
| Testes Python dos scripts de distribuição | 7 aprovados |
| Compilação da app e da extensão Monitor | Aprovada para o simulador |
| XCTest de código, Keychain e prazo de bloqueio | 5 aprovados, nenhuma falha ou teste ignorado |
| Demonstração web release | Compilada |

Os cinco XCTest existentes foram preservados. O Keychain usado pelos testes é o serviço real do simulador, com assinatura local ad hoc. A incorporação da extensão foi posicionada antes do Run Script do Flutter; os testes do Xcode passaram a usar assinatura local e a exportar seu resumo JSON. Os entitlements simulados gerados pelo Xcode são guardados como diagnóstico, separado da validação de assinatura para uma IPA de distribuição.

Os artefatos da build incluem o relatório `native.xcresult`, o resumo `native-summary.json`, os entitlements simulados, a cobertura Flutter e a demonstração web. O resultado final também foi confirmado por consulta independente à API v3 do Codemagic.

Foram necessárias quatro builds, que somaram 16 minutos e 33 segundos de duração registrada pela API. Esse tempo não é uma medição de cobrança; o valor faturado e o saldo da franquia não foram consultados. Não foi criada assinatura paga nesta configuração.

## Pendências para o iPhone e AltStore PAL

- Conta Apple Developer, identificadores definitivos, certificados e perfis de desenvolvimento e distribuição.
- Aprovações Family Controls da app e da extensão e compatibilidade dos perfis com o marketplace.
- IPA assinada e instalação no iPhone registrado.
- Validação física de ocultação, busca, notificações, callbacks, reinício, encerramento e revogação de autorização.
- Notarização, pacote ADP, hospedagem e publicação no AltStore PAL.

O simulador confirma compilação e os cenários dos testes. A proteção dos bancos e o silenciamento de notificações não foram demonstrados em aparelho físico. Em `release/readiness.json`, apenas `nativeBuild` e `nativeTests` recebem esta evidência; os demais requisitos continuam pendentes.
