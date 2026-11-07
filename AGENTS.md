# Orientações do projeto

Comunicação breve e direta em português. Sem emojis, travessões ou elogios automáticos. Preservar salvamentos, balanceamento e regras de gameplay. Implementar, executar, testar e corrigir uma etapa antes de avançar. Não declarar testes ou desempenho sem evidência.

## Android somente sob demanda

- A versão principal é PC. Pedidos genéricos de atualizar, corrigir, testar, compilar ou publicar o jogo aplicam-se somente ao PC.
- Após a primeira entrega Android, não atualizar, sincronizar, testar, compilar, publicar ou fazer manutenção mobile automaticamente.
- Só trabalhar novamente no mobile quando o usuário mencionar explicitamente celular, Android ou versão mobile.
- Não incluir Android em testes, scripts de release, CI ou sincronização padrão do PC.
- Android vive na branch `codex/android-mobile`, em worktree separado fora desta pasta. Não duplicar o projeto dentro da pasta principal.
- A base inicial do código mobile é PC 0.20.0, commit `4b6e2e5dd1a86c2feb8ed169c8da305c0fd5d0a8`. Registrar cada atualização mobile autorizada, os commits incorporados e a compatibilidade de rede.
- Não mesclar mudanças futuras do PC automaticamente. Não presumir compatibilidade com versões futuras.
- Chaves e senhas de assinatura ficam fora do repositório. Preservar a assinatura nas atualizações Android.

Ver `docs/ANDROID_POLICY.md`. Esta regra também vale para agentes trabalhando na branch Android.
