# Validação da implementação — 01/11/2026

## Verificações executadas

- `flutter analyze --fatal-infos`: nenhuma ocorrência.
- `flutter test --coverage`: **17 testes aprovados**, incluindo os dez testes do estado nativo com ponte simulada, dois fluxos da interface nativa e cinco regressões da demonstração/cálculo.
- `python -m unittest discover -s scripts -p test_release_tools.py`: **sete testes aprovados** para evidências, versão, fonte PAL, cópia intacta do ADP e rejeição de identificadores de exemplo.
- Sintaxe dos sete arquivos Swift analisada com Tree-sitter Swift 0.7.4: sem nós de erro. Essa verificação não resolve tipos ou frameworks da Apple e não substitui Xcode.
- Projeto Xcode interpretado com OpenStep Parser: targets Runner, RunnerTests e Monitor; sem referências indefinidas nas listas verificadas.
- Arquivos plist, entitlements, manifesto de privacidade e YAML interpretados com sucesso.
- `release_gate.py` rejeitou a publicação com identidade, aprovações e evidências físicas pendentes, conforme esperado.
- Build web release compilada. A demonstração web continua sem efeitos no iOS.

Os testes e a build ocorreram em uma cópia de trabalho local fora do OneDrive, devido ao bloqueio de arquivos pelo sincronizador. As fontes entregues permanecem na pasta original.

## Verificações ainda necessárias

- Compilação Swift com os SDKs Apple e execução dos cinco XCTest.
- Criação e validação de certificados/perfis para os identificadores registrados.
- Assinatura da IPA e instalação no iPhone.
- Comportamento de bloqueio e ocultação com autorização individual.
- Busca, notificações existentes e novas, callbacks de fim do prazo, encerramento e reinício.
- Aprovação Family Controls para distribuição da app e da extensão.
- Notarização, pacote ADP, hospedagem pública e instalação pelo AltStore PAL.

Este registro descreve a etapa local anterior ao primeiro envio ao GitHub. A posterior compilação e execução dos testes no Codemagic estão registradas em [Validação no Codemagic](VALIDACAO_CODEMAGIC_20261101.md). A submissão à Apple e a publicação no AltStore PAL continuam pendentes.
