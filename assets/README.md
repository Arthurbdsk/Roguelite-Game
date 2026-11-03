# Assets de Brasafria

Arte original gerada em tools/generate_assets.py com Pillow. Sem antialiasing.
Filtro de importação: Nearest. Spritesheets originais têm 4 quadros horizontais. Os esqueletos da versão 0.2 têm 6 quadros de 32x36 (quatro passos, preparação e ataque), gerados separadamente por `tools/generate_skeletons.py`. A moeda `gold.png` tem 4 quadros de 8x8.

| Arquivo | Quadro | Uso |
| --- | --- | --- |
| player.png | 24x32 | Sentinela, caminhada frontal |
| ghoul.png | 24x32 | Perseguidor comum |
| hound.png | 24x24 | Fera rápida |
| guard.png | 32x40 | Guarda resistente |
| boss.png | 64x64 | Cavaleiro espectral |
| tiles.png | 32x32, atlas 4x4 | Piso, 16 variantes |
| pillar.png | 32x48 | Pilar sólido, base nos 12 pixels inferiores |
| grave.png | 24x24 | Lápide sólida |
| brazier.png | 24x32 | Braseiro decorativo |
| fortress.png | 256x160 | Ilustração de cenário para título/base |
| icons/*.png | 16x16 | Oito ícones de armas e passivas |
| xp.png | 10x12 | Fragmento de experiência |
| seal.png | 12x12 | Selo |
| icon.png | 64x64 | Ícone do aplicativo |

Frames 0/2 correspondem ao repouso; frames 1/3 alternam apoio dos pés e deslocamento de 1 pixel.
Pontos de origem recomendados: meio da base de cada quadro, com 2 pixels de margem.
Pixelify Sans: copyright The Pixelify Sans Project Authors. Licença em OFL.txt.
Fonte: https://github.com/google/fonts/tree/main/ofl/pixelifysans

Arte provisória funcional. Animações direcionais, ataques próprios e animação de morte são acabamento futuro.
