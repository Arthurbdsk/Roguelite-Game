# Android 0.25.0-android.2

Atualização autorizada em 8 de novembro de 2026. Branch `codex/android-mobile`, worktree separado. Base PC 0.25.0, commit `4276c18125e5a61f57022437569729a0afe577e0`. A lista de commits incorporados fica em `data/mobile_build.json`. Mobile volta a ficar congelado depois da entrega.

Pacote preservado: `com.socialy.hordas.android`. Código de versão 2, assinatura original, mesmo armazenamento privado. No emulador, a instalação sobre a versão de código 1 preservou o arquivo do save byte por byte. Certificado SHA-256: `a2d917b419ab3da9572b72f1e0c825b56b800ef6ef011ed4108591b396449c05`.

Incluídos os novos personagens, as correções PC 0.21 a 0.25, o bestiário e os contadores individuais. Mantidos os controles de toque, teclado, área segura e limites cosméticos próprios do Android. Não houve redução de inimigos ou colisões específica do mobile. A redução de geração de 20% e vida/velocidade do solo aplicam-se igualmente ao cooperativo PC e Android.

O bestiário usa fonte de interface, botões de pelo menos 44 unidades lógicas e rolagem, com acesso pelo menu e pela base. O cronômetro conserva a fonte gótica. As estatísticas usam o perfil local de cada dispositivo, sem sincronização de saves entre plataformas.

Testes de prévia aprovados: toque/joystick, teclado, ciclo de aplicativo, 30 combinações de telas e áreas seguras, bestiário/persistência, multiplayer e aprimoramentos. Identificação de gameplay calculada com os mesmos 116 arquivos/trechos do PC, protocolo 2.

Ensaios mistos com o APK QA de mesma simulação e o PCK do executável público PC: três processos PC mais um Android emulado. Realizados com host no PC e host no Android, atravessando `wss://hordas-relay.onrender.com`. Três mapas, seis armas por dono, personagens novos, descobertas, crédito do golpe final, escolhas individuais, gesto ADB mantido para reanimar PC pelo Android, transformação/morte de Demônio e recompensa salva uma única vez. O Android cliente foi para Home e os três PCs continuaram; o retorno manteve a liquidação única.

Ambiente: AVD Hordas_API35, Android 15/API 35, x86_64, janela horizontal 2340×1080, viewport 640×360, Compatibility/OpenGL ES, host Windows com Ryzen 5 5600 e RX 6600. Uma máquina e uma conexão de internet. Não são aparelhos físicos nem redes distintas. O usuário fará esses testes.

APK público exclui DEV e executores QA. APK QA usa pacote separado, serve apenas para ensaios e não é a entrega de instalação normal. Não houve publicação em lojas.

Limites preservados: não há migração de host nem reconexão automática. Se o Android anfitrião for suspenso ou desconectado, a sala termina. Se for cliente, os demais continuam. A volta não restaura uma partida encerrada pelo sistema operacional.

Entrega final: `build/Hordas-Android-0.25.0-2.apk`. Identificação compartilhada `0.25.0+24d20eff97f22428`, protocolo 2. Os dois ensaios mistos finais passaram com esse conteúdo. APK SHA-256: `882e9524fd991a910884c9d90cdc62aa96d87d8e516563c468d7d455f4d08ab0`.

Carga nativa curta no emulador: 200 inimigos, quatro donos simulados, seis armas e quatro passivas no nível 8; 2 s de aquecimento, amostras de 5/5/10 s nos três mapas. Resultados: 5,42 / 5,85 / 6,00 FPS; p95 224 / 206 / 197 ms. Nenhuma falha de contagem ou execução, mas desempenho insuficiente nesse cenário. Esse ensaio desativa descobertas do bestiário e não comprova estabilidade longa nem desempenho em aparelho físico. Não considerar performance mobile aprovada. Evidências em `docs/validation25`.

Bestiário do APK público aberto por toque e inspecionado. Atualização final preservou certificado e bytes do perfil; o ensaio anterior confirmou instalação do código 2 sobre o código 1. Android congelado após esta entrega.
