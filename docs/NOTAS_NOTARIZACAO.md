# Notas para notarização e Family Controls

Preencher os identificadores reais e enviar apenas após validação nativa. Estas notas descrevem as funções sem ocultá-las da revisão.

## Finalidade

Calculadora funcional com uma área privada acessível por um número configurável. O usuário gerencia restrições sobre aplicativos escolhidos no seu próprio dispositivo usando autorização individual do Tempo de Uso. A interface discreta busca privacidade no uso cotidiano. O produto não oferece garantia de proteção contra coação.

## APIs e extensão

Family Controls: autorização individual e FamilyActivityPicker. Managed Settings: `application.blockedApplications` para os aplicativos escolhidos. Device Activity: monitor de liberação temporária que restabelece os bloqueios. App Group: política compartilhada entre a app e o monitor. Keychain e CommonCrypto: verificação local do número e controle de tentativas.

Solicitar Family Controls para distribuição tanto para a app quanto para `<bundle>.Monitor`. Confirmar Provisioning Support para o canal alternativo usado. Não se trata de controle remoto de outras pessoas ou de gerenciamento de dispositivos de terceiros.

## Passos de revisão

1. Criar um número no primeiro uso; não há senha padrão de produção.
2. Limpar a calculadora, digitar o número escolhido e tocar em `=`.
3. Autorizar Tempo de Uso na tela da Apple.
4. Escolher aplicativos no seletor do iOS, sem escolher a própria Calculadora, categorias ou sites.
5. Salvar a seleção e conferir os bloqueios.
6. Liberar por 15 minutos; ao sair da Calculadora, a sessão privada fecha e o app bancário pode ser aberto. A extensão reaplica os bloqueios ao final do intervalo.
7. Reabrir a área privada e usar Proteger agora para reaplicar antes do prazo.

Fornecer um número de demonstração criado para a avaliação e instruções específicas conforme a revisão solicitar, em canal privado. Não usar códigos pessoais ou dados de contas bancárias.

Não afirmar que as notificações são bloqueadas até comprovar o resultado no aparelho e registrar a versão do iOS. Não afirmar que o número é o único caminho global de acesso aos apps: a autorização pode ser revogada e a Calculadora pode ser removida.
