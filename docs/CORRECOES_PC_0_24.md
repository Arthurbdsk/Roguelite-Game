# Conclusão das correções PC 0.24.0

Base: commit 7d8f79e, PC 0.23.0, mais o trabalho local existente. Android não foi alterado, sincronizado, testado ou compilado. Os saves mantêm esquema 4 e os mesmos IDs. Os ensaios usaram perfis isolados.

## Bugs confirmados e correções

- Flecha com velocidade zero permanecia no host porque a idade era incrementada sem limitar sua vida. O teste de regressão falhou antes e passou depois. Agora há direção válida na criação, descarte de velocidades inválidas, prazo de voo e redesenho após remoção.
- Limpeza da partida removia somente alguns subsistemas de armas. `clear_attacks()` limpa flechas, sequências, efeitos e projéteis de todos os donos sem alterar a build.
- O ricochete reiniciava a distância sem renovar idade/prazo visual. Agora inicia um novo voo, preservando um acerto por alvo e a perfuração configurada.
- Flechas inimigas e magia inimiga nos clientes dependiam do snapshot seguinte para encerrar. Agora expiram pelo prazo e alcance; congelamento permanece respeitado. IDs adicionais e de impactos não são reutilizados no reset; snapshots antigos continuam rejeitados por partida e sequência.
- Machado: clientes e host usam a mesma trajetória e descarte pelo enquadramento lógico atual do dono. Contatos relativos varridos são ordenados pelo instante de colisão, sem repetir alvo. Nenhum timer curto foi introduzido. Runa mantém ricochete próprio; Bumerangue mantém ida e volta.
- Os quatro chefes sobrescreviam a vida já calculada, perdendo +30. A base foi centralizada; dificuldade é aplicada uma vez. Transformações não multiplicam nem concedem novamente o bônus absoluto, e preservam a vida temporal.
- Pivô horizontal do Orc era reposto sem a escala 1,1 durante a animação. Corrigido também para outras famílias. Barras acompanham altura e crescimento; nomes acompanham escala. Removida a função antiga de sombra do herói.

## Frequência e valores

Não foi reproduzida aceleração geral indevida: 64 combinações, todas as 16 armas nos níveis 1 e 8, sem bônus e com Luvas 8/Recarga permanente 5, com tolerância de um passo de 1/60 s. Inspeção confirmou retorno antecipado do caminho solo no cooperativo, um update por dono no host e previsão visual sem dano no cliente. Recursos de cooldown não são acumulados em reconstruções. Não foram elevados cooldowns gerais.

[Tabela completa dos intervalos](pc24/frequencias.md). [Valores de vida por espécie](pc24/vida.md).

- Varinha Mágica mantém a correção da 0.23: bases 2,0 s nos níveis 1/2 e 1,85 s nos níveis 3 a 8. Com bônus testados: 0,936 e 0,8658 s antes da quantização do passo. Sequência de 120 ms e seleção do alvo mais próximo preservadas.
- Machado mantém totais de acertos [3,3,4,4,5,5,6,7], visual 18,4 px, raio de contato 5,75 px e margem de descarte 14 px.
- Herói, variantes e chefes mantêm escala visual 1,1. Colisores físicos, alcance, velocidade e áreas de armas não são ampliados automaticamente.
- Slime pequeno inicial: (3,6 + 30) × 1,6 = 53,76 HP; pequeno azul de evento: 107,52 HP. Vida temporal +35 por estágio continua separada.
- Fogo aliado nos níveis 1 a 8: [67,2;76,8;86,4;96;105,6;115,2;127,2;141,6]. Cooldown 9,8 s e direção aleatória preservados. Fogo inimigo e esfera orbital preservados.
- Geração 90/minuto e chance de ouro 20% preservadas por confirmação expressa do usuário nesta continuação.

## Visuais para aprovação no jogo

Integrados os três atlases já existentes no trabalho local: Médico da Peste com máscara de bico e arremesso real de frasco; Devorador com alimentação, crescimento e combate preservados; `guard`, Soldado com comportamento `charge`, como entidade específica de dash. Nenhum outro inimigo com investida recebeu essa substituição.

Cada atlas tem 24 quadros distintos, seis clips de quatro quadros, alpha binário e filtro nearest. A animação não cria dano adicional. Preparação e recuperação do Soldado acompanham seus tempos reais de 0,85/1,25 s. Poça de veneno do trabalho existente também integrada. Estes atlases são arte original local, não assets oficiais do pacote pago Tiny RPG. A origem registrada é a do trabalho recuperado; não houve compra nem uso de prévias com marca. Aprovação estética pendente do usuário dentro do jogo.

Capturas: [Pátio](pc24/courtyard.png), [Biblioteca](pc24/library.png), [Campos](pc24/fields.png).

## Validação

36 suítes sequenciais aprovadas, incluindo 64 combinações de frequência, 14 verificações de ciclo de projéteis, 181 verificações renderizadas de flechas, Varinha nos oito níveis, Machado, escala, vida/fogo, arte, saves/aprimoramentos, colisão corporal, Runa, Bumerangue, eventos e campanha completa de chefes. O ensaio visual compara pixels antes/depois de 60 impactos e da remoção de uma flecha parada.

Host e três clientes em quatro processos separados passaram nos três mapas pelo relay local, incluindo uma janela renderizada, seis armas por dono, quatro passivas, novos visuais, mortes, limites e limpeza. Repetido com o PCK do executável exportado em pasta isolada. Isso não equivale a quatro computadores ou redes diferentes.

Pacote público verificado sem pasta do projeto: recursos novos e créditos embutidos, fontes de arte e ferramentas DEV excluídas, valores autorizados e descarte da flecha parada. Executáveis público e DEV passaram no smoke nativo headless de 120 frames. Um primeiro encerramento do harness de pacote avisou sobre dois objetos retidos; nova execução detalhada terminou sem aviso. Não foi identificado vazamento reproduzível em partida.

[Resultados das suítes](pc24/validation.json), [rede do pacote](pc24/network-packed.log), [pacote detalhado](pc24/pack-verbose.log).

## Desempenho observado

Mesmo harness externo e seed 21007, 150 inimigos iniciais, incluindo os três personagens revistos, quatro donos simulados com seis armas no nível 8 e poças. Dois segundos de aquecimento e dez de medição por mapa. Ryzen 5 5600 / RX 6600, Compatibility, 1280×720 com viewport lógico 640×360, teto de 60 FPS. Runtime do editor executando os PCKs exportados, não medição nativa de FPS release. A máquina não foi isolada de outros aplicativos; os números são observações curtas, sem garantia de desempenho prolongado.

| Mapa | FPS 0.23 / 0.24 | p99 frame 0.23 / 0.24, ms | Mediana simulação 0.23 / 0.24, ms |
| --- | --- | --- | --- |
| courtyard | 59.74 / 59.86 | 23.98 / 25.10 | 12.55 / 12.52 |
| library | 59.98 / 59.76 | 22.51 / 24.85 | 12.22 / 12.65 |
| fields | 59.46 / 59.58 | 25.56 / 24.61 | 12.38 / 12.65 |

O p99 piorou no Pátio e na Biblioteca e melhorou nos Campos; as medianas de simulação ficaram próximas, com pequeno aumento na Biblioteca e nos Campos. O ensaio não demonstra ausência de regressões em cargas prolongadas.

[Dados anteriores](pc24/bench-before.json), [dados finais](pc24/bench-after.json). Quantidades e limites não foram reduzidos para o ensaio. Os executáveis público e DEV também iniciaram e encerraram nativamente com renderização OpenGL e código de saída zero.

## Entrega e limites

`build/Hordas-0.24.0/Hordas-0.24.0.exe` e `build/Hordas-DEV-0.24.0/Hordas-DEV-0.24.0.exe`. Todos os jogadores devem usar a mesma versão PC 0.24.0 e a mesma modalidade pública/DEV. Android permanece na sua branch e base anterior.

Pendente: avaliação humana dos novos visuais e confirmação do sintoma original durante o jogo do usuário na 0.24.0. Os cenários reproduzidos foram corrigidos; os testes não cobrem todas as situações possíveis de uma sessão longa.
