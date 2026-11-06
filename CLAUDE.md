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
- Tests : `bash tools/test.sh`, la seule commande de test. Elle importe le
  projet puis lance GUT, et sort en 1 sur toute erreur de script. GUT seul sort
  en 0 sans rien lancer si l'import manque ou si un test ne parse pas.
- Smoke réseau : `bash tools/smoke.sh`. Avec un binaire exporté :
  `STACKMATES_EXPORTED=1 GODOT=export/linux/stackmates.x86_64 bash tools/smoke.sh`.

## Workflow

- Commits directs sur `main`. Jamais de branche, jamais de PR.
- Message de commit : préfixe Conventional Commits en anglais (`feat:`, `fix:`,
  `test:`, `docs:`, `ci:`, `chore:`), sujet en français.
