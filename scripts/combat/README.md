# Armas e escolhas

`weapons.gd` é um nó Godot editável, com uma cena reutilizável em `scenes/combat/weapons.tscn`. Os dados de cada arma e passiva são Resources em `data/weapons` e `data/upgrades`.

Integração: `setup(main)`, `reset(apoio)` após restaurar os atributos base do jogador, e `update_combat(delta)` somente durante a ação. O nó deve ficar em origem global zero. A interface consulta `get_loadout()`, `get_passives()` e `get_offers()`. O método `apply_upgrade(id)` retorna falso quando o limite ou requisito bloqueia uma escolha.

Três armas, até três passivas, armas até nível 5 e passivas até nível 2. O quinto nível exige uma afinidade: lâmina com Selo da muralha, besta com Passo do exílio, brasas com Ímã funerário. As três ofertas nunca repetem o mesmo ID. Uma arma é garantida enquanto existir progressão válida; o sorteio reduz a chance de repetir ofertas anteriores. Quando a build chega ao limite, entram cura, selos e uma repulsão imediata. Não existe escolha sem efeito: cura com vida cheia concede selos.

A lâmina atinge somente o arco desenhado; o nível 3 abre um segundo arco traseiro. Os virotes usam segmento varrido entre posições para reduzir atravessamento em frames longos; nível 2 atravessa dois alvos, nível 3 abre leque e nível 5 ricocheteia uma vez. A órbita tem intervalo de dano por inimigo, independente da taxa de quadros.

Os apoios são trocas: Arsenal começa com a besta e torna a rotação orbital 15% mais lenta. Biblioteca começa com brasas e torna os disparos de besta 15% mais lentos. A seleção favorece a arma vinculada com peso 1,8. Nenhum apoio altera permanentemente atributos.

Limites: 100 projéteis de jogador; efeitos de arco duram até 0,22 s; IDs de contato orbital expirados são limpos. As verificações percorrem a lista de inimigos mantida pelo jogo, sem buscas globais. Não foi adicionado pool sem medição de benefício.

Sons solicitados: `sword`, `bolt`, `upgrade`. Os efeitos respeitam `game.effects` entre 0 e 1 e mantêm projéteis legíveis mesmo no mínimo.
