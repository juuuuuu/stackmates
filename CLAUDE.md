# Stackmates

Clone des mécaniques de Pico Park. Godot 4.7.2, GDScript typé, online 2 à 8
joueurs, `host-authoritative`.

- `docs/design.md` : toutes les décisions (règles, réseau, jalons). À lire avant
  tout travail de conception ou d'implémentation.
- `docs/adr/` : les choix structurants et leurs raisons. Un choix listé là ne se
  rediscute pas sans nouvel ADR.
- `GLOSSARY.md` : les termes du jeu. Nommer le code avec ces termes exacts.

## Règles de code

- Toute règle de jeu vit dans `sim/`, en GDScript pur, sans node ni
  `scene tree`. Les nodes affichent, ils ne décident pas.
- Typage statique sur chaque déclaration. Les `GDScript warnings` sont des
  erreurs dans `project.godot`.
- Une mécanique se construit en TDD avec GUT : test rouge dans `tests/`, puis le
  code dans `sim/` ou `net/`.
- Tests : `godot --headless --path . --import` une fois après un ajout de
  fichier, puis `godot --headless --path . -s addons/gut/gut_cmdln.gd -gexit`
  (exit 0 si vert, 1 sinon). Sans `--import` préalable, GUT ne trouve pas ses
  classes et sort en 0 sans rien lancer.

## Workflow

- Commits directs sur `main`. Jamais de branche, jamais de PR.
- Message de commit : préfixe Conventional Commits en anglais (`feat:`, `fix:`,
  `test:`, `docs:`, `ci:`, `chore:`), sujet en français.
