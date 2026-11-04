# Fontes e edição

As referências foram fornecidas por Arthur. Os novos desenhos foram produzidos com a ferramenta integrada imagegen, com fundo transparente. As referências orientam identidade e proporções; não são exibidas inteiras no jogo.

Os PNGs de origem permanecem em `sources/`. Os atlas horizontais ao lado deste arquivo são editáveis por quadro em Aseprite, LibreSprite ou outro editor com transparência.

`tools/pack_character_atlas.py` faz somente a preparação técnica: recorte em células iguais, escala nearest uniforme, paleta reduzida, alpha binário e alinhamento dos pés. Não altera atributos ou colisões.

| Atlas | Grade de origem | Quadros de uso |
|---|---|---|
| hero | 8 × 4 | espera 0–3; antecipação 8–9; golpe 10–15; caminhada 16–23; dano 24–25; caído 26–28; retorno 29–31 |
| necromancer | 8 × 2 | espera 0–3; caminhada 4–7; preparação 8–11; recuperação 12–15; conjuração 8–15 |
| plague | 8 × 2 | espera 0–3; caminhada 4–7; preparação do arremesso 8–11; lançamento e recuperação 12–15 |

Prompts usados: atlas de poses distintas, mesma escala e linha dos pés, pixels nítidos, fundo alpha, sem cenário ou texto. Herói: aço cinza, elmo fechado e tecido azul, espada apenas no ataque. Necromante: capuz e tecido vinho rasgado, caveira sombreada, cajado com chama. Médico: máscara clara com bico, chapéu verde, capa verde, roupa azul, cinto e frasco retirado da bolsa e arremessado com o braço.

Originais preservados em `C:/Users/Arthur/.codex/generated_images/01a19e99-c569-7be0-9eac-4be2109dad44/`:

- hero: `exec-489d311f-cd50-41e1-ae33-31a438fd5e6b.png`
- necromancer: `exec-5ef9ed3b-44ec-480f-87a2-dbc428ad461b.png`
- plague: `exec-e00926cf-3adc-4f0f-a971-108d3a25e5c1.png`
