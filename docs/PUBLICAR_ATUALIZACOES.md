# Publicar atualizações

O jogo consulta `https://raw.githubusercontent.com/Arthurbdsk/Roguelite-Game/codex/release-channel/stable.json`. Os arquivos ficam em Releases públicos do repositório `Arthurbdsk/Roguelite-Game`, sem exigir login dos jogadores. O túnel usado para transferir os arquivos ao Actions nesta entrega não faz parte do endereço usado pelo jogo.

## Preparação

1. Implementar e validar a plataforma autorizada. Android exige pedido explícito, branch `codex/android-mobile` e worktree separado.
2. Atualizar versão e manifesto de gameplay, validar e commitar o código antes da exportação. O sidecar registra o HEAD exportado. O exportador PC deriva versão e nome padrão do arquivo de `project.godot`, sem repetir o número em seu código. Compilar `python tools/updates/build_helper.py` ao alterar o helper Windows. Executar a exportação PC pelo procedimento de `tools/export_windows.py`; usar o exportador Android somente quando autorizado.
3. Guardar a chave RSA de publicação em `%USERPROFILE%/.hordas-updates/private.pem`, fora do Git. A chave Android existente também permanece fora do repositório. Fazer backup privado: perder essas chaves impede autenticar futuras atualizações com a confiança atual. O jogo contém apenas a chave pública.
4. Enviar os commits de origem ao GitHub. Não reutilizar uma versão com bytes diferentes.

Preparar os metadados PC a partir do executável e do sidecar produzido pelo exportador:

```powershell
python tools/updates/publish.py --artifact build/Hordas-VERSAO/Hordas-VERSAO.exe --metadata build/Hordas-VERSAO/build_manifest.json --platform pc --notes caminho/notas.txt
```

O comando verifica SHA e a versão real do PE, deriva URL, tamanho, conteúdo de gameplay e protocolo, autentica o canal anterior e preserva o registro Android. O resultado assinado fica em `build/updates/stable.json`. Informar `--previous caminho/stable.json` permite encadear duas plataformas preparadas na mesma entrega. Usar `--online-required` quando a nova versão for necessária para as salas atuais; esse sinal só bloqueia online quando a identidade do conteúdo também difere.

Android, somente sob demanda:

```powershell
python tools/updates/publish.py --artifact "../Hordas Android/build/ARQUIVO.apk" --metadata "../Hordas Android/build/ARQUIVO.json" --platform android --notes caminho/notas.txt --previous build/updates/stable.json
```

O publicador confere package ID, versionName, versionCode, manifesto de gameplay embutido e certificado original do APK. Publicar PC não recompila nem anuncia outra versão Android. Se os conteúdos diferirem, as notas de compatibilidade mostram apenas as versões com a mesma identidade.

## Envio público

Com GitHub CLI autenticado externamente, adicionar `--publish` ao comando da plataforma. O arquivo é enviado antes da promoção do manifesto. O tag usa o commit registrado na exportação. Não inserir token em código, argumentos, arquivos de notas ou no jogo.

Nesta entrega foi usado o conector GitHub autenticado e o workflow `.github/workflows/publish-channel.yml`, na branch `codex/release-channel`, porque o login do conector é independente do login do CLI. O workflow recebe um `release-request.json` com `source` HTTPS temporário, `platforms` explicitamente selecionadas e identificador da solicitação. A origem permitida é um subdomínio `trycloudflare.com`, servindo somente o manifesto assinado e os artefatos públicos selecionados. O Actions usa seu próprio token efêmero de publicação, verifica a assinatura RSA e cada hash/tamanho, envia os arquivos e só então promove `stable.json`. Nunca transferir a chave privada ao workflow. Fechar a origem temporária depois do sucesso.

O canal tem validade de 90 dias. Renovar sua assinatura e expiração antes de vencer, inclusive quando não houver nova versão, preservando os registros de cada plataforma. A expiração impede uma atualização sem manifesto vigente; não impede jogar solo. Não trocar o par de chaves sem um plano de migração dos clientes já instalados.

## Verificação de entrega

Conferir sucesso do Actions, URLs permanentes dos arquivos e canal assinado. Abrir a versão antiga, verificar, baixar e instalar. Preservar evidências de versão, hash, confirmação de inicialização e save antes/depois. Testar arquivo corrompido, cancelamento e recuperação Windows. No Android, confirmar o instalador do sistema e distinguir emulador de aparelho físico. Não considerar apenas a exportação do APK como teste de instalação.

O Windows instala em `%LOCALAPPDATA%/Hordas/Game/Hordas.exe`, com atalho no menu Iniciar e cópia `Hordas.previous.exe`. O download inicial portátil pode ser movido para esse local por **Atualizações > Instalar nesta conta > Reiniciar e atualizar**. O helper altera somente os arquivos conhecidos do jogo. Não extrai ZIP nem remove conteúdo arbitrário. Saves permanecem no diretório de dados do perfil Godot.

O Android distribuído diretamente usa o instalador oficial. A autorização para instalar desta origem e a confirmação de instalação pertencem ao sistema. Manter `com.socialy.hordas.android` e o certificado original. Uma futura distribuição Play deve ter fluxo próprio; o caminho direto está bloqueado quando `updates/distribution` não for `direct`.
