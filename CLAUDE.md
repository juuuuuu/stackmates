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
- Les WAV sont importés compressés (QOA) : une longueur en échantillons se lit
  par `get_length() * mix_rate`, jamais par `data.size()`.
- `make help` liste les commandes courantes ; chaque cible appelle un script de
  `tools/` ou Godot (`make test`, `make lint`, `make check`, `make build`).
- Tests : `bash tools/test.sh`, la seule commande de test. Elle importe le
  projet puis lance GUT, et sort en 1 sur toute erreur de script. GUT seul sort
  en 0 sans rien lancer si l'import manque ou si un test ne parse pas.
- Smoke réseau : `bash tools/smoke.sh`. Avec un binaire exporté :
  `STACKMATES_EXPORTED=1 GODOT=export/linux/stackmates.x86_64 bash tools/smoke.sh`.
- Publication itch.io : `tools/publish_itch.sh`, variable `ITCH_TARGET` et
  secret `BUTLER_API_KEY` sur le dépôt ; la release GitHub ne dépend pas
  d'itch.io. Si le job `publish` échoue après un premier zip, relancer le job :
  butler renvoie un build déjà poussé sans le dupliquer.

## Workflow

- Commits directs sur `main`. Jamais de branche, jamais de PR.
- Message de commit : préfixe Conventional Commits en anglais (`feat:`, `fix:`,
  `test:`, `docs:`, `ci:`, `chore:`), sujet en français.
- Avant un tag : `config/version` dans `project.godot`, `application/version`
  et `short_version` dans `export_presets.cfg`, et `PROTOCOL_VERSION` dans
  `net/session.gd` si un RPC ou le format du `snapshot` a changé.
