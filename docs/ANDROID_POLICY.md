# Android sob demanda

O PC continua sendo a versão principal. Código-base inicial: Hordas 0.20.0, commit `4b6e2e5dd1a86c2feb8ed169c8da305c0fd5d0a8`.

O primeiro Android é desenvolvido separadamente em `codex/android-mobile`. Seu código e documentação de entrega vivem nessa branch. O worktree fica fora da pasta principal, sem duplicar um projeto dentro dela.

Após a primeira entrega, mobile fica congelado. Nenhum pedido genérico sobre o jogo autoriza sincronização, teste, compilação, publicação ou manutenção Android. É necessário mencionar explicitamente celular, Android ou versão mobile.

Android não integra o fluxo padrão de testes ou releases do PC. Atualizações autorizadas devem incorporar somente os commits necessários, registrar a nova base, testar novamente a compatibilidade e preservar identificador do aplicativo, armazenamento e assinatura. Não publicar em loja sem pedido específico.

Cada build mobile declara sua própria versão e a versão/protocolo de PC com que foi verificada. Versões futuras do PC não são automaticamente compatíveis.
