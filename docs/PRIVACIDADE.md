# Privacidade da Calculadora

Texto para publicação depois de preencher o responsável e o canal de contato em `release/identity.json`. Última atualização: 01/11/2026.

A Calculadora é uma calculadora com controles privados sobre aplicativos selecionados no próprio iPhone. Não acessa credenciais, saldos ou transações dos aplicativos bancários.

## Dados no aparelho

O número de acesso é verificado localmente. Seu sal e uma derivação criptográfica ficam no Keychain deste aparelho; o número não é gravado em texto puro. Contadores de tentativas e período de espera também ficam no Keychain. O verificador pode permanecer após reinstalar o aplicativo. Não existe recuperação por e-mail.

A seleção de aplicativos usa identificadores privados do Tempo de Uso. Esses identificadores e o prazo de acesso temporário são armazenados no container protegido do App Group, compartilhado entre a Calculadora e sua extensão. Os nomes e ícones são apresentados pelo seletor do iOS.

## Transmissão e terceiros

A Calculadora não transmite o número nem a seleção para servidores. Não incorpora publicidade, análise de uso, rastreadores ou notificações próprias. A distribuição e instalação pelo AltStore PAL e pela Apple seguem as políticas desses serviços, que podem processar informações necessárias à conta, instalação, atualização e diagnóstico do sistema.

O aplicativo não gerencia os dados coletados pelos bancos. Consulte as políticas de cada banco e as configurações de notificações do iOS.

## Controle do usuário

Você pode mudar a seleção e o número pela área privada, liberar acesso temporário e reaplicar o bloqueio. A autorização de gerenciamento individual do Tempo de Uso pode ser revogada nas configurações do iOS e o aplicativo pode ser removido. A remoção pode apagar o container, mas não garante a remoção do verificador do Keychain.

A Calculadora não garante proteção contra coação nem invisibilidade em todas as telas do sistema. O comportamento de notificações e bloqueios depende da versão e das permissões do iOS.

## Responsável e contato

Antes da publicação, identificar o desenvolvedor responsável e disponibilizar um canal de contato público no site informado no marketplace. Não publicar este texto com campos de responsável ou suporte pendentes.
