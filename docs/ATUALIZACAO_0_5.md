# Atualização 0.5.0

Implementação concluída em etapas, com verificações após cada sistema.

## Implementado

- Título Hordas, menus e nomes simples, descrições numéricas e identificadores antigos preservados.
- Layout inicial com containers e rodapé separado. Melhorias em lista vertical, ícones, níveis, vagas e atributos finais visíveis.
- Necromante com magia de trajetória fixa, preparação, sete pontos de invocação e limite de sete esqueletos vivos próprios. Eliminar o conjurador preserva os esqueletos já criados.
- Besta com 120 de vida e velocidade 47,5, equivalentes a cinco vezes a vida e 1,9 vez a velocidade do Zumbi. Ataque preparado, cone legível e recuperação.
- Médico da peste com aviso do frasco, poça de seis segundos, veneno de dez segundos e dois de dano por segundo antes de defesa. Renovação sem instâncias acumuladas; ícone e duração no HUD.
- Shadow com marca fixa, desaparecimento de 1,5 segundo, reaparecimento, dano e imobilização de 0,75 segundo. Escolha de jogador vivo por ataque no cooperativo.
- Raio com alvos aleatórios distintos, alcance validado, dano e progressão configuráveis.
- Lança Relógio em doze direções horárias a partir de cima, perfuração, dano baixo, paralisação de três segundos e resistência posterior. Chefes recebem desaceleração de 30% por um segundo.
- Coroa de nível único, bônus individual de 7% de experiência, frações preservadas e sem crédito retroativo.
- Novos inimigos introduzidos gradualmente nas hordas, com experiência e ouro existentes.
- Demônio com transição sem recompensa; segunda fase com cinco vezes a vida máxima da primeira, depois da escala multiplayer. Carrasco preservado.
- Raios em sequência, gelo em faixas com corredor, anel com abertura e rajadas repetidas de fogo. Grupos de 12 e 20 invocações, limite de 32 entre vivos e avisos, sem multiplicar quantidade duas vezes.
- Replicação dos novos inimigos, armas, estados e efeitos, escolhas individuais sem pausa online, encerramento e salvamento preservados.

## Configuração

`data/enemies/*.tres`: atributos e ataques. `data/waves/*.tres`: composições e intervalos. `data/encounters/special.tres` e `scripts/data/special_balance.gd`: invocações, veneno, emboscada e limites. `data/weapons/*.tres`: dano, intervalo, alcance, alvos e largura. `data/bosses/balance.tres` e `scripts/data/boss_balance.gd`: fases e padrões.

## Executado e verificado

- Importação Godot sem erros e smoke do executável nativo por 120 frames.
- Layout renderizado em 1280×720, 1024×768 e 1920×800; 18 verificações. Build completa e descrições dentro dos painéis.
- Suítes de combate, integração solo completa, habilidades, ouro, novos inimigos, Raio, Lança Relógio, Coroa, duas fases, padrões do chefe, regras de rede e backpressure.
- Onze suítes executadas contra os recursos do executável final, usando o runtime Godot correspondente e perfis isolados.
- Partida de quatro processos pelo WSS público com movimentação, efeitos novos, transformação, melhorias privadas, resgates, carga, derrota, saída e ouro persistido. Todos passaram, sem erros de script.
- Carga de 180 inimigos, 2.000 moedas, 240 cristais e 320 flechas; teste separado com inimigos especiais, poças, magia e armas novas simultâneos.
- Teste público prolongado interrompido a pedido do usuário antes dos 310 segundos planejados. Não constitui um teste completo de cinco minutos.

Logs e capturas estão em `test_output/`. As suítes headless medem comportamento e tempo de CPU; não comprovam FPS renderizado nem equilíbrio para jogadores humanos. Os quatro processos rodaram neste computador através do túnel público, sem evidência de quatro redes físicas diferentes.

## Ainda depende de avaliação

Dificuldade real, legibilidade com jogadores humanos, acabamento das animações de seis quadros, controles físicos e estabilidade entre redes diferentes. O relay ainda depende deste computador e do túnel temporário. Não há hospedagem permanente, reconexão ou migração de anfitrião.
