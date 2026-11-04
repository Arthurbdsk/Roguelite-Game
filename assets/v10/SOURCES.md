# Assets da campanha 0.10

Novos PNGs gerados com a ferramenta integrada `image_gen`, a partir das orientações do usuário. As referências orientaram desenho, cores e movimento. A explosão foi gerada como composição original; a prévia de banco de imagens com marcas não foi recortada nem usada como textura. Não foi usado fallback de API ou chave particular.

Os arquivos em `sources/` preservam os resultados brutos para edição. Os PNGs de execução passaram por recorte de células, alinhamento de pivô, nearest neighbor, alpha binário e redução de paleta. O PCK exclui os resultados brutos. Filtro nearest e ausência de mipmaps na importação.

## Especificações dos prompts

As descrições abaixo resumem as especificações utilizadas na geração, não são uma transcrição literal das chamadas.

### snowflake

Referência: 2. Floco azul e branco com simetria, surgimento, pequenos desvios e dissolução contínua em oito quadros; fundo transparente. Pixel art retrô, bordas nítidas, escala consistente, sem logotipo ou assinatura.

- Resultado bruto: `sources/snowflake.png`, origem `exec-f49cdf41-1fa1-4ba4-8124-89e07dd05785.png`.
- Atlas de execução: `snowflake.png`, 256 × 32.
- SHA-256 do bruto: `4c58554ff819422a39f889baa62f91b446485d34ebdcfe61e67fa7e26ff78c55`.

### explosion

Referência: 3. Explosão original em oito quadros: clarão amarelo, expansão laranja, fragmentos vermelhos e dissipação; sem texto, marca ou elementos da apresentação. Pixel art retrô, bordas nítidas, escala consistente, sem logotipo ou assinatura.

- Resultado bruto: `sources/explosion.png`, origem `exec-84f41bac-dc68-4972-a7e4-f4ae82eb3af4.png`.
- Atlas de execução: `explosion.png`, 768 × 96.
- SHA-256 do bruto: `e76c9806aeae9e9a171d1d6b5b65be71d93f34f0426fcbe6125ac8351bc52138`.

### guardian

Referência: 4 e 5. Figura medieval alta com seis asas, rosto oculto e vestes longas; perspectiva de arena, silhueta clara e trinta e dois quadros de espera, caminhada, conjuração, recuperação, dano e morte. Pixel art retrô, bordas nítidas, escala consistente, sem logotipo ou assinatura.

- Resultado bruto: `sources/guardian.png`, origem `exec-2a3e6597-ed78-4c5f-aec2-c5df4eedb6bc.png`.
- Atlas de execução: `guardian.png`, 5120 × 128.
- SHA-256 do bruto: `8c9f30cbf07de91fc6459e44a0245de9a5478ad105d4e46d259981ae9296e1ef`.

### horror

Referência: 6. Criatura baixa e alongada com vários membros parecidos com braços humanos, corpo escuro segmentado, acentos alaranjados e olhos claros; trinta e dois quadros, movimento coordenado e fundo transparente. Pixel art retrô, bordas nítidas, escala consistente, sem logotipo ou assinatura.

- Resultado bruto: `sources/horror.png`, origem `exec-dea9db6e-15cf-4c32-9700-afb2d1b3864a.png`.
- Atlas de execução: `horror.png`, 6144 × 112.
- SHA-256 do bruto: `f3077c1bcf1ae770489cd50b419f3f41484b26b036dda5831b196797ceae2686`.

### true_form

Referência: 7. Caveira clara com órbitas escuras, boca comprida e aberta, manto negro e trinta e dois quadros para arena; fundo transparente, sem o fundo vermelho da referência. Pixel art retrô, bordas nítidas, escala consistente, sem logotipo ou assinatura.

- Resultado bruto: `sources/true_form.png`, origem `exec-1b2bfc3c-726e-4d4b-9944-1f281cc3a1ce.png`.
- Atlas de execução: `true_form.png`, 4096 × 112.
- SHA-256 do bruto: `9a398a5bc44818e4af9c6ac64ea7d17e48b5451b85779ca4e99b6c9d6b2f819c`.

### bar_ornament

Referência: 8. Ornamento de caveira/criatura em metal escuro e detalhe vermelho, pixel art frontal para extremidade esquerda da barra; sem barra preenchida, texto ou fundo. Pixel art retrô, bordas nítidas, escala consistente, sem logotipo ou assinatura.

- Resultado bruto: `sources/bar_ornament.png`, origem `exec-87fd7688-81fc-4f9b-bd8a-c0b138fe0b31.png`.
- Atlas de execução: `bar_ornament.png`, 48 × 48.
- SHA-256 do bruto: `fec60cc55674456b5ada5fb402d80b677794671d8b1a40fc7f0cccfcad86538e`.

## Empacotamento reproduzível

```powershell
python tools/pack_fx_atlas.py assets/v10/sources/snowflake.png assets/v10/snowflake.png --cols 8 --size 32 --align-centers
python tools/pack_fx_atlas.py assets/v10/sources/explosion.png assets/v10/explosion.png --cols 4 --rows 2 --size 96 --align-centers
python tools/pack_character_atlas.py assets/v10/sources/guardian.png assets/v10/guardian.png --height 84 --width 160 --cellheight 128
python tools/pack_character_atlas.py assets/v10/sources/horror.png assets/v10/horror.png --height 76 --width 192 --cellheight 112
python tools/pack_character_atlas.py assets/v10/sources/true_form.png assets/v10/true_form.png --height 84 --width 128 --cellheight 112
python tools/pack_fx_atlas.py assets/v10/sources/bar_ornament.png assets/v10/bar_ornament.png --cols 1 --size 48
```

Os personagens têm 32 quadros em uma linha no atlas final: 0–3 espera, 4–11 movimento, 12–15 preparação, 16–23 ação/recuperação, 24–25 dano e 26–31 morte/transição. A Abominação usa pivô central ajustado no código; suas extremidades decorativas não ampliam a colisão.

A fonte Kingdom não integra esta pasta. Falta o arquivo TTF/OTF utilizável e autorizado. A imagem de apresentação não foi transformada em fonte nem usada para desenhar textos.
