# Codemagic do HideMyBanks

Aplicativo cadastrado em 01/11/2026 e conectado ao repositório público do projeto.

- [Aplicativo no Codemagic](https://codemagic.io/app/6ae7f03e3fff223c356f76af).
- [Repositório no GitHub](https://github.com/marcelofreitas95-lgtm/HideMyBanks).
- Branch: `main`.
- App ID do Codemagic: `6ae7f03e3fff223c356f76af`.
- Configuração: `codemagic.yaml`, lida diretamente do repositório.

## Validar uma alteração

Executar o workflow `validate`. Ele usa Mac M2, Flutter 3.41.6 e Xcode 26.6, com limite de 60 minutos por execução. As builds são iniciadas manualmente; o projeto não configura disparos automáticos a cada push.

O workflow executa análise e testes Flutter, testes Python dos scripts de distribuição, compilação e XCTest no simulador iOS e compilação da demonstração web. O relatório nativo, o resumo JSON, os entitlements simulados gerados pelo Xcode e a cobertura são disponibilizados como artefatos.

Os testes do simulador usam assinatura local ad hoc e o Keychain real do simulador. Essa assinatura não requer certificado Apple e não produz uma IPA instalável no iPhone.

O plano individual oferece 500 minutos gratuitos mensais de Mac M2. Em 01/11/2026, a API não retornou assinaturas pagas para a conta usada nesta configuração. Consultar o saldo na página de billing antes de novas execuções; o saldo disponível não é registrado no Git. [Preços e franquia do Codemagic](https://codemagic.io/pricing/).

## Acesso pela API

O token pessoal é enviado no cabeçalho `x-auth-token`. Mantê-lo fora do código, do YAML e dos arquivos de evidência. Para automações próprias, obter o token de uma variável de ambiente ou de um gerenciador de segredos.

A API atual permite iniciar `validate` com `POST /api/v3/apps/6ae7f03e3fff223c356f76af/builds`, enviando `workflow_id: validate`, `branch: main` e `instance_type: mac_mini_m2`. A resposta 202 informa aceitação do pedido; o resultado deve ser consultado em `GET /api/v3/builds/<build_id>`. [Documentação da API](https://codemagic.io/api/v3/schema).

## Validação confirmada

O workflow completo passou na [build 4](https://codemagic.io/app/6ae7f03e3fff223c356f76af/build/6ae7f590efa74786046ff2a2), com 17 testes Flutter, sete testes Python e cinco testes Swift aprovados. Consulte [o registro da validação](VALIDACAO_CODEMAGIC_20261101.md) para identificar o commit e os limites do teste.

## Gerar a IPA e distribuir

Os workflows `ios-development` e `pal-notarization` dependem dos identificadores e das credenciais Apple descritos em [Implementação e publicação](IMPLEMENTACAO_E_PUBLICACAO.md). A validação no simulador precisa ser complementada pela instalação no iPhone e pelos testes de ocultação, busca, notificações e bloqueio antes da distribuição.
