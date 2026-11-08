# Origem e prompts da arte 0.22

Ferramenta utilizada: geração de imagens integrada (`image_gen`), com fundo transparente. Não foi utilizada a API/CLI. Arte criada para este projeto em 7 de novembro de 2026 a partir das referências fornecidas pelo usuário. Não é pacote Tiny RPG oficial. Soldado e Orc comum continuam os assets gratuitos anteriores, com sua atribuição própria.

## Especificação comum enviada

Original tiny medieval RPG character animation spritesheet. Crisp square pixel clusters, dark outlines, limited natural palette, small readable proportions matching the existing tiny soldier. Exact uniform grid four columns by six rows, 24 frames, portrait 2:3. Same character and equipment in every cell, right-facing three-quarter top-down RPG perspective, fixed body center and foot baseline, generous transparent margins. Row 1 four idle poses; row 2 four movement poses; row 3 anticipation, attack release and recovery; row 4 alternate attack or special cast; row 5 four hurt poses; row 6 four death poses ending at the original ground pivot. Transparent RGBA background, no text, labels, watermark, grid, scenery or baked ground shadow. No blur or smooth gradients. Readable after nearest downsampling to game scale.

## Instruções por fonte

| Fonte em assets/v22/sources | Direção enviada |
| --- | --- |
| bat.png | Tiny charcoal-purple bat, pale gray face, pointed ears and purple leathery wings. Calm hovering, cyclic wingbeats, bite anticipation/lunge/recovery, hurt and folding-wing death. Not a dog or cat. |
| necromancer.png | Charcoal navy layered robe, pale hidden face, wide ragged teal-gray pointed hat and wooden staff with small cyan accents. Walk, magic casting, raised staff summoning and crumpled robe death. |
| skeleton_sword.png | Ivory skull, bony body, brown waist wrap, round wooden shield and silver short sword. Distinct windup, slash, hurt and collapse into bones. |
| skeleton_archer.png | Ivory skeleton, steel blue helmet with nose guard, brown belt/quiver and tall curved wooden bow. No sword or shield. Draw string and release, then recover. Final correction: remove detached flying arrows from row 3 column 3 and row 4 column 3 because the real game projectile is rendered separately; preserve the held arrow in column 2. |
| skeleton_armored.png | Ivory skull, dark steel horned helmet, cuirass and shoulders, rectangular steel shield and silver sword. Armor readable at 19 px. |
| orc_armored.png | Compact green tusked Orc, wide gray horned helmet, blue gray steel armor, leather belt and axe with red-brown handle. Not a giant. |
| orc_elite.png | Compact green Orc, two long upward ivory horns, red-brown round shield, curved sword and iron shoulder guards. Same small body scale, distinct shield and helmet. |
| orc_mounted.png | Green Orc rider with leather/iron armor and axe on a stocky charcoal-gray wolf with pale muzzle. Four-legged trot, crouch/anticipation, bite and mounted swing, rider and mount fall together. |
| slime.png | Wide lime green jelly mound with dark eyes, mint highlight and dark green rim. Breathing squash/stretch, hopping, contact attack, two-lobe preparation and splash division. |
| slime_blue.png | Edit only the palette of the referenced original slime sheet to medium blue, navy shadows and pale cyan highlights. Preserve frame layout, poses and alpha. Generated with slime.png as edit target. |
| slime_king.png | Large emerald green jelly with rippling lower skirt, side lobes, central dome and gold crown with red gem. Own silhouette, heavy wobble, split and fallen crown. No blue children baked into sheet. |
| water_vial.png | Single small glass round-bottom vial with narrow neck, brown cork, silver lip, blue liquid, cyan highlights and ivory cross label. Dark navy outline, transparent, readable at 16x24. Based on the supplied blue holy water bottle. |
| water_pool.png | Top-down blue/cyan organic water puddle and splash, four-by-four grid. Four impact/glass splash frames, eight caustic/bubble loop frames with stable footprint, four dissolution frames. Transparent, no floor or lettering. |

As imagens foram inspecionadas e reempacotadas com alpha binário, paleta limitada e nearest. As margens/células são normalizadas tecnicamente; o centro dos personagens não é recalculado por arma ou asa. A superfície do efeito foi normalizada ao círculo de dano existente sem alterar seu raio. Não foram inseridos fundos, textos de prévia ou assinaturas das referências.
