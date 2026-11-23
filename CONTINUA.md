# Come continuare lo sviluppo (note per i prossimi modelli / sviluppatori)

Progetto: **DEBITO D'ORO** – incrementale/idle a tema azzardo, Godot **4.3** (GDScript), niente asset esterni
a parte i font in [`assets/fonts/`](assets/fonts/) (tutta la grafica è disegnata via codice con `_draw()`).

- Repository: `https://github.com/MirkoVanzetto/debito-doro`
- Release v1.0.0 con `DebitoDOro.exe` e `DebitoDOro-Windows.zip`: `https://github.com/MirkoVanzetto/debito-doro/releases/tag/v1.0.0`

## Ambiente & Comandi rapidi
- Godot 4.3 headless:
  ```bash
  curl -sSL -o godot.zip https://github.com/godotengine/godot/releases/download/4.3-stable/Godot_v4.3-stable_linux.x86_64.zip
  unzip -q godot.zip && chmod +x Godot_v4.3-stable_linux.x86_64
  ```
- Export templates Windows in `~/.local/share/godot/export_templates/4.3.stable/` (`windows_*` + `version.txt`).
- Screenshot di verifica headless (con `xvfb-run`):
  ```bash
  xvfb-run -a -s "-screen 0 1280x720x24" ./Godot_v4.3-stable_linux.x86_64 --audio-driver Dummy -- --demo --tab=0 --screenshot=/tmp/out.png
  ```
  Flag supportati da [`scripts/main.gd`](scripts/main.gd): `--demo`, `--tab=0..5`, `--sub=0..2`, `--screenshot=<path>`, `--fresh`.
- Build `.exe` singolo (`embed_pck=true` in [`export_presets.cfg`](export_presets.cfg)):
  ```bash
  ./Godot_v4.3-stable_linux.x86_64 --headless --export-release "Windows Desktop" build/DebitoDOro.exe
  ```
- CI GitHub Actions: [`.github/workflows/build.yml`](.github/workflows/build.yml) compila l'exe automaticamente a ogni tag `v*` o manualmente via `workflow_dispatch`.

## Architettura dei file
- [`scripts/style.gd`](scripts/style.gd) (autoload `S`): palette (`INK`, `PAPER`, `RED`, `GOLD`, `TEAL`, `FELT`...), font (`LuckiestGuy`, `LilitaOne`, `Rubik`), tema UI e funzioni di disegno procedurale (`draw_card`, `draw_chip`, `draw_symbol`, `draw_icon`, `draw_face`, `draw_shark`, `draw_cat`).
- [`scripts/game.gd`](scripts/game.gd) (autoload `G`): dati delle 10 attività, 10 manager, 110+ migliorie, 9 talismani, 7 città/Squali, 74 trofei; logica di tick, RNG dei minigiochi, prestigio, salvataggio JSON (`user://save.json`), guadagni offline e formattazione numeri (`K`, `M`, `B`, `T`, `Qa`... `aa`, `ab`).
- [`scripts/sfx.gd`](scripts/sfx.gd) (autoload `Sfx`): sintetizzatore WAV in codice per tutti gli effetti sonori + loop musicale jazz-lounge.
- [`scripts/main.gd`](scripts/main.gd): assembla l'interfaccia, gestisce le 6 schede, i badge di notifica sulle fiches, i toast, lo screen-shake e la lettera iniziale dello Squalo.
- [`scripts/ui/`](scripts/ui/):
  - `felt_bg.gd` / `table_rail.gd`: panno verde con cono di luce, trama a rombi e bordo in legno con borchie.
  - `top_bar.gd`: portafoglio, quadrifogli, barra del debito dello Squalo e pulsante *Paga Debito*.
  - `chip_button.gd`: fiches da poker animate (navigazione tra le 6 schede).
  - `business_card.gd` / `businesses_panel.gd`: *La Sala* (griglia 2×5 delle attività + selettore `x1/x10/x100/MAX` + Sinergia d'Impero).
  - `gamble_panel.gd`: *Il Banco* (selettore puntata, tabella premi dinamica, *Raddoppia o Lascia*).
  - `scratch_card.gd`: *Gratta e Vinci* con maschera `Image` grattabile pixel-per-pixel col mouse.
  - `slot_machine.gd`: *Slot Fortuna 777* a 3 rulli cilindrici con leva e lampadine.
  - `dice_table.gd`: *Tavolo dei Dadi* (*Sotto 7 / Sette! / Sopra 7* + bonus dadi doppi).
  - `managers_panel.gd`, `upgrades_panel.gd`, `prestige_panel.gd`, `trophies_panel.gd`, `lucky_cat.gd`, `fx_layer.gd`, `story_modal.gd`.

## Idee per espansioni future
- Quarto minigioco al Banco: **Mini-Roulette** o **Blackjack veloce**.
- Eventi casuali dello Squalo (es. *"Ispezione a sorpresa"*: minigioco lampo per non pagare la tangente).
- Classifica / export della stringa di salvataggio negli appunti.
- Esportazione Web (HTML5/WebAssembly) su GitHub Pages oltre all'eseguibile Windows.
