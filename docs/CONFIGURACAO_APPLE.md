# Configuração Apple para a Calculadora

O Team ID informado foi conferido no portal Apple em 02/11/2026 e está em `release/identity.json`. O Bundle ID ainda não foi registrado. A integração, os certificados, os perfis e a autorização de distribuição também estão pendentes. O projeto já passou pela compilação e pelos testes no simulador; ainda precisa da instalação e dos testes no iPhone.

## Permissões necessárias

Um administrador ou o titular deve liberar **Access to Certificates, Identifiers & Profiles** para o usuário que fará os cadastros. A função Desenvolvedor, isoladamente, não garante esse acesso. O portal pode apresentar **Access Unavailable** enquanto a liberação estiver pendente.

Um administrador deve criar uma **chave de equipe** do App Store Connect para a integração. Chaves individuais não permitem usar os endpoints de provisionamento. Se a API ainda não estiver habilitada, o titular deve solicitar seu acesso. [Permissões Apple](https://developer.apple.com/help/app-store-connect/reference/account-management/role-permissions/) e [chaves da API](https://developer.apple.com/documentation/appstoreconnectapi/creating-api-keys-for-app-store-connect-api).

Não é necessário promover o usuário a administrador apenas para liberar o recurso de certificados. A criação da chave e as tarefas restritas podem ser realizadas pelo administrador existente.

## Identificadores a registrar

Os identificadores abaixo são sugestões e precisam ser conferidos e registrados antes de preencher `bundleIdentifier` em `release/identity.json`.

| Recurso | Identificador sugerido | Configuração |
| --- | --- | --- |
| App Calculadora | `io.github.marcelofreitas95-lgtm.hidemybanks` | App ID explícito; Family Controls e App Groups |
| Extensão Monitor | `io.github.marcelofreitas95-lgtm.hidemybanks.Monitor` | App ID explícito; Family Controls e App Groups |
| Grupo compartilhado | `group.io.github.marcelofreitas95-lgtm.hidemybanks` | Associar aos dois App IDs |

Após o registro, `python3 scripts/configure_ios.py` aplica os identificadores e o Team ID ao app e à extensão, mantendo a versão e o número de build iguais. Os identificadores de exemplo do Xcode não servem para gerar a IPA de desenvolvimento.

## Integração e assinatura no Codemagic

O administrador cria a chave em **Users and Access > Integrations > App Store Connect API**. O Codemagic recomenda a função **App Manager** para a chave. Cadastrar o **Issuer ID**, o **Key ID** e o arquivo privado `.p8` em **Team settings > Team integrations > Developer Portal > Manage keys**, usando a referência `calculadora_apple`. [Configuração oficial de assinatura](https://docs.codemagic.io/yaml-code-signing/signing-ios/).

O arquivo `.p8` pode ser baixado uma única vez. Mantê-lo em armazenamento privado, fora do Git e de pastas compartilhadas; cadastrá-lo diretamente no Codemagic. Não incluir conteúdo de chaves, certificados privados, senhas ou UDIDs em issues, commits ou relatórios públicos.

As referências abaixo já constam em `codemagic.yaml` e devem ser usadas ao cadastrar os recursos:

| Recurso | Referência no Codemagic |
| --- | --- |
| Integração Apple | `calculadora_apple` |
| Certificado Apple Development | `calculadora_development_certificate` |
| Perfil de desenvolvimento do app | `calculadora_development` |
| Perfil de desenvolvimento da extensão | `calculadora_monitor_development` |
| Certificado Apple Distribution | `calculadora_distribution_certificate` |
| Perfil de distribuição do app | `calculadora_distribution` |
| Perfil de distribuição da extensão | `calculadora_monitor_distribution` |

Para a primeira instalação, registrar o UDID do iPhone na Apple e incluí-lo nos dois perfis de desenvolvimento. Os perfis devem conter o App Group compartilhado e o entitlement Family Controls. Cadastrar o certificado com sua chave privada e os dois perfis no Codemagic antes de iniciar `ios-development`.

## Distribuição na AltStore PAL

O titular deve solicitar a autorização de distribuição Family Controls separadamente para o app e a extensão. A aprovação precisa contemplar o provisionamento usado para marketplaces. O texto técnico está em [Notas de notarização](NOTAS_NOTARIZACAO.md); ele não declara como comprovadas a ocultação na busca nem a supressão de notificações. [Solicitação do entitlement](https://developer.apple.com/documentation/familycontrols/requesting-the-family-controls-entitlement).

Antes de `pal-notarization`, concluir os testes físicos, preencher os dados públicos de privacidade e confirmar as evidências em `release/readiness.json`. A liberação do acesso Apple e a geração de uma IPA não comprovam, por si sós, os requisitos de proteção.
