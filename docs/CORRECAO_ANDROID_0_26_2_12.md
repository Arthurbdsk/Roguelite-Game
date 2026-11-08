# Android 0.26.2-android.12

Correção explícita do toque do joystick selecionando uma melhoria ao subir de nível. PC não foi alterado. Branch `codex/android-mobile`, em worktree separado. Base PC 0.26.2/01f01f0; protocolo 2 e gameplay `0.26.2+6c3b0b65ed77fe5a` preservados.

## Causa e comportamento

Ao abrir a tela de melhorias, `MobileControls.reset()` apagava o estado dos controles e também perdia a associação com os dedos ainda pressionados. Eventos restantes desse gesto, incluindo o mouse emulado pelo toque, podiam atingir os cartões recém-criados.

Agora os contatos físicos são registrados separadamente do estado do joystick. A abertura da escolha captura essa situação e bloqueia a interface até todos os contatos anteriores serem soltos. Toques adicionais durante esse bloqueio também precisam terminar. A interface indica **Solte os dedos para escolher**. Depois disso, um novo toque é necessário para confirmar uma melhoria.

Cada cartão exige uma pressão nova, válida na geração atual da interface. Soltar o joystick, receber um evento de mouse herdado ou terminar a escolha do nível anterior não autoriza outra seleção. Rolagem e cancelamento invalidam a pressão; perda de foco limpa contatos e não deixa a interface presa. Não foi adicionado um atraso fixo. Mouse e teclado continuam permitindo uma confirmação nova.

No solo, a escolha continua pausando o combate. No cooperativo, o bloqueio é local. O host mantém a aplicação das melhorias e o cliente envia a escolha para confirmação do host. Vida, dano, frequência, inimigos, salvamentos e regras de rede não foram modificados. As correções de rolagem e proporções da revisão 11 permanecem.

## Testes

O teste anterior à correção reproduziu uma escolha indevida depois de um gesto de joystick herdado: a tela já estava em `running`. Com a correção, permaneceu em `upgrading` até um novo toque.

- Eventos reais na GUI: joystick pressionado, mouse emulado herdado, dois dedos, novo dedo durante o bloqueio, níveis acumulados, cancelamento, saída/retorno ao aplicativo, mouse físico e teclado.
- Host cooperativo: uma aplicação da melhoria. Cliente: uma solicitação com a geração correta, sem aplicar localmente antes da confirmação do host.
- APK nativo: comandos Android DOWN, MOVE e UP mantiveram o dedo do joystick pressionado enquanto a tela abriu; o dedo foi movido sobre o cartão, mantido ali e solto. A tela aguardou um novo toque nos contextos solo, host e cliente. Os contextos de rede desse teste usam conexão de teste e quatro atores; não representam, isoladamente, tráfego de internet.
- Regressões: oito suites de preview e rolagem dos cartões pela GUI.

Ambiente Android: emulador Android 15/API 35. Nenhum teste em telefone físico foi realizado. Os scripts e fixtures de QA ficam fora do APK público. Evidências em `android012/`.

Package `com.socialy.hordas.android` e assinatura original preservados. Atualização opcional para online, compatível com PC 0.26.2. Android volta a ficar congelado após a entrega. Nenhuma publicação em loja.

Regressão de rede: quatro participantes conectados pelo relay WSS público, com host PC e depois host Android. Ambos passaram, incluindo escolhas, chefes, abates e recompensas. São processos deste computador e emulador; não comprovam duas redes independentes.


## Pacote público

Fonte de execução: `68813852b7ad85920c9b9170a3d515ad083f81c1`. APK com 83851459 bytes e SHA-256 `4ede55b01f5931fd458898481218fc1ea0dfd425e6eda503e818330d39d6130d`.

[APK Android 12](https://github.com/Arthurbdsk/Roguelite-Game/releases/download/update-android-0.26.2-android.12/Hordas-Android-0.26.2-12.apk). [Publicação concluída](https://github.com/Arthurbdsk/Roguelite-Game/actions/runs/42523457984). O manifesto assinado mantém o mesmo arquivo PC.

Atualização pública validada da revisão 11 para 12 pelo próprio jogo, baixando o APK do GitHub Release e confirmando no instalador oficial. Pacote instalado com hash idêntico ao publicado, mesmo identificador e assinatura. O save permaneceu idêntico durante a instalação e semanticamente igual após reabrir; duas partidas registradas preservadas. Evidência: `android012/public-update.json`. Não houve instalação do APK público por ADB.
