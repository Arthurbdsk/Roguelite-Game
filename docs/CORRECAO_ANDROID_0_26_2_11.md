# Android 0.26.2-android.11

Pedido explícito de correção mobile. Branch `codex/android-mobile`, worktree separado. PC permanece em 0.26.2, sem alteração de código, arte, balanceamento ou executável. Android volta a ficar congelado após esta entrega.

## Rolagem

A lista de escolhas recebia o toque nos cartões, mas seus controles bloqueavam a propagação até o ScrollContainer. O foco também podia reposicionar a lista. Atualizações tinha ainda um tratamento global de ScreenDrag que alterava diretamente a posição da barra e disputava o gesto nativo.

`MobileScrolling` prepara os controles internos para propagar o gesto ao ScrollContainer. A rolagem, a inércia e o cancelamento da pressão no botão ficam a cargo do Godot. O foco não reposiciona a lista durante o arraste. Barras, campos de texto e sliders mantêm seus controles próprios. Removido o tratamento global de arraste de Atualizações. O mesmo preparo atende escolha de item, build, aprimoramentos, coleção, bestiário, opções, base, textos legais e teclado. O helper só é chamado ao construir a interface; não acrescenta varredura por quadro durante o combate.

Teste antes da correção: arrastar sobre um cartão produziu deslocamento zero. Depois: o mesmo caminho real de eventos GUI moveu a lista sem escolher o item. No APK nativo, gestos ADB produziram várias posições intermediárias, sinais nativos de início/fim e nenhum clique acidental. Um toque simples escolheu exatamente uma melhoria e retornou ao combate. Quinze painéis examinados: os que tinham conteúdo excedente rolaram; os demais couberam sem precisar de rolagem. Evidências em `android011/native-scroll.json` e logs de antes/depois.

## Proporções

O erro estava nos arquivos locais de arte, não na escala dos nós. Apenas Soldado e Orc tinham atlas com o dobro da resolução no Android; os demais PNGs coincidiam com o PC. A validação anterior de `scale=1` não detectava isso.

| Atlas | Android anterior | Corrigido, igual ao PC |
| --- | --- | --- |
| Soldado | 4816 x 80 | 2408 x 40 |
| Orc | 3808 x 80 | 1904 x 40 |

Os dois arquivos locais foram substituídos pelos correspondentes já licenciados e usados no PC. Os outros sprites permanecem iguais. Isso restaura o tamanho relativo de herói, Orc, esqueletos, morcegos e demais criaturas sem aumentar cada espécie arbitrariamente. Diferenças naturais entre criaturas e tamanho dos chefes seguem a referência PC. Alcance, velocidade, vida, dano e colisão não foram escalados.

A referência foi extraída dos recursos carregados pelo executável PC publicado, SHA-256 `820ab40246435ec1a30e85237a7cbd4c78ade1423ed78f0085b659d1b8ce8ac3`, origem `01f01f009d398cd4c06208ba75533a14e52f2ca7`. O APK foi comparado contra ela para o herói e as 23 espécies: pixels visíveis, dimensões, quadros, retângulos visíveis de cada quadro, posição, escala, filtro e raio do colisor. Todos corresponderam. RGB de pixels completamente transparentes é ignorado no hash, pois o importador pode preencher essas bordas sem alterar a imagem visível.

`data/mobile/pc_visual_reference.json` registra essa referência. O exportador Android agora verifica os pixels e dimensões reais antes de produzir o APK; atlas em 2x bloqueiam a exportação. Os PNGs Tiny RPG continuam fora do Git por licença. Essa verificação não sincroniza novos assets ou futuras versões PC automaticamente.

## Compatibilidade e validação

Protocolo 2, gameplay `0.26.2+6c3b0b65ed77fe5a`, compatível com PC 0.26.2. Nenhuma regra de combate foi alterada. Os oito testes de preview passaram, incluindo joystick, teclado, ciclo de vida, interface, bestiário e rede. Os testes nativos de rolagem e proporções usam o APK QA e perfis separados do aplicativo público. Scripts de QA e painéis DEV são excluídos do APK público.

Ambiente nativo: emulador Android 15/API 35. Os gestos foram enviados pelo sistema Android via ADB, sem chamar diretamente o código de arraste do jogo. Não houve teste em telefone físico nesta entrega. O teste do relay público usa clientes na mesma conexão de internet e não comprova redes independentes ou desempenho de aparelho real.

Package `com.socialy.hordas.android`, versionCode 11. Assinatura original preservada, sem desinstalação e sem migração nova do perfil. Publicação somente como APK direto, sem loja. A atualização é opcional para o online, pois mantém protocolo e conteúdo de gameplay.
