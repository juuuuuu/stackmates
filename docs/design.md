# Stackmates : conception

Décisions prises lors de l'interview de conception du 2026-11-05. Ce document est la
référence du périmètre et des choix. Les choix structurants ont aussi un ADR dans
`docs/adr/`. Les termes du jeu sont définis dans `GLOSSARY.md`.

## Produit

- Clone des mécaniques de Pico Park : plateforme coopérative en 2D, les joueurs
  doivent coopérer pour amener la clé à la porte et tous entrer.
- Nom original « Stackmates ». Aucun asset, logo ou texte repris de Pico Park.
- Public : les amis du développeur d'abord, en sessions privées. Sortie publique
  sur itch.io ensuite.
- Plateformes : Windows, Linux, macOS. Config minimale : portable avec GPU intégré
  (référence : Intel i7-1165G7, 16 Go, Intel Iris Xe, Ubuntu 24.04).
- Budget : zéro. Tous les outils sont gratuits ou open source.
- Joueurs : de 2 à 8 par session. Les niveaux et tests de v1 visent 2 à 4.
- Online seulement en v1. La co-op locale (plusieurs joueurs sur une machine)
  n'est pas en v1, mais l'input est structuré par `player slot` pour l'ajouter
  sans refonte.
- Interface en anglais, système de traduction Godot branché dès le premier écran
  pour ajouter le français.

## Règles du jeu (v1)

Mécaniques retenues : marche, saut, `stack`, `push chain`, clé, porte, mort.
Hors v1 : interrupteurs, plateformes mobiles, cordes, tapis roulants, mode joueur
géant, chrono, score, vies.

### Mouvement

- Joueur de 1 tuile sur 1 (16x16 px). Une `stack` de 8 tient dans l'écran.
- Vitesse de course : 6 tuiles par seconde.
- Saut à hauteur fixe de 2,5 tuiles : un rebord de 2 tuiles passe seul, un rebord
  de 3 tuiles demande une `stack`.
- Gravité réglée pour 0,5 s de vol.
- `Coyote time` de 4 `ticks`, `jump buffer` de 4 `ticks`.
- Pas de saut à hauteur variable, pas de double saut.
- Ces valeurs sont des constantes dans `sim/` et se règlent au playtest.

### `Push chain` et `stack`

- Un joueur qui marche contre un autre au sol le pousse à sa vitesse.
- La poussée se propage à une chaîne de joueurs contigus. Un mur bloque toute la
  chaîne.
- Deux joueurs qui poussent en sens inverse : personne ne bouge.
- Un joueur posé sur un autre suit ses déplacements horizontaux et peut sauter
  depuis sa tête.
- On ne peut pas pousser un joueur en l'air.

### Mort

- Causes : sortir du niveau par le bas, toucher la zone létale d'une tuile
  `spike` (6 px sur 6 au centre de la base de la tuile : un marcheur meurt, un
  sauteur passe dès 6 px de hauteur).
- La zone létale laisse une fenêtre de départ de saut d'au moins 12 `ticks`
  (200 ms) devant un `spike` isolé, pour un `client` en retard.
- Un joueur meurt : bandeau « X died » pendant 1 s, puis le niveau recommence
  pour tout le monde. Pas de vies, pas de compteur.

### Clé et porte

- La clé se ramasse au contact et flotte au-dessus du `key carrier`.
- Le `key carrier` ne peut pas lâcher la clé.
- Le `key carrier` touche la porte : la porte s'ouvre, la clé disparaît.
- Chaque joueur qui touche la porte ouverte entre et disparaît.
- `Level clear` quand tous les joueurs sont entrés : bandeau « Level clear »
  1,5 s, puis le `host` charge le niveau suivant.
- Après le niveau 5 : écran de victoire, puis retour au lobby où le `host` peut
  relancer.

## Rendu et contrôles

- Pixel art, tuiles de 16 px.
- Viewport de base 640x360 (40 tuiles sur 22,5). Stretch mode `canvas_items`,
  aspect `keep`, échelle fractionnaire, filtre `nearest` : la fenêtre est
  remplie même quand elle n'est pas un multiple exact (fenêtre maximisée sur
  un écran 1080p), au prix de pixels légèrement inégaux dans ce cas.
- Fenêtre 1280x720 par défaut, redimensionnable. Plein écran activable (F11 et
  options). 1080p couvert à l'échelle x3 exacte, 1440p à x4.
- Niveaux sur un seul écran, caméra fixe, pas de scrolling.
- Renderer `Compatibility` (OpenGL 3).
- Touches fixes en v1. Clavier : flèches ou touches physiques WASD (donc ZQSD en
  AZERTY) pour bouger, Espace ou flèche haut pour sauter. Manette : stick gauche
  ou croix, bouton A. Pas de rebinding en v1.
- Échap ouvre un menu en surimpression (reprendre, quitter la partie) sans mettre
  la simulation en pause.
- Interface en nodes `Control`, thème minimal (police par défaut de Godot,
  quelques couleurs), navigable au clavier et à la manette. Pas de souris
  obligatoire.

## Simulation

Voir `docs/adr/0001-sim-core-pur.md`.

- Le `sim core` est du GDScript pur : le niveau est une grille de tuiles, les
  joueurs sont des AABB, collisions et règles écrites à la main.
- Aucune dépendance au `scene tree` ni à la physique Godot. Les nodes ne font que
  l'affichage.
- Le `host` fait tourner le `sim core` à 60 Hz. Le `snapshot` est son état.
- Testable avec GUT sans `scene tree`.

## Réseau

Voir `docs/adr/0002-host-authoritative-sans-prediction.md` et
`docs/adr/0003-enet-direct-sans-relay.md`.

### Topologie

- Le `host` joue et sert en même temps (`listen server`). Pas de serveur dédié.
- Transport `ENet` en direct : le `host` ouvre un port, les `clients` entrent
  `IP:port`. IPv4 seulement en v1.
- Port par défaut 28015, modifiable.
- À l'ouverture, le jeu tente `UPnP` et affiche le résultat : « port ouvert » ou
  « ouvre le port 28015 à la main ».
- Le lobby montre au `host` son IP locale et son IP publique (requête HTTPS vers
  api.ipify.org, avec bouton copier).
- Secours documentés pour les joueurs : port forwarding manuel, puis VPN gratuit
  entre amis (ZeroTier ou Tailscale).
- Le mapping `UPnP` est retiré quand le `host` quitte le lobby ou la partie ;
  un plantage le laisse en place, sans danger (même port réutilisé). Le lobby
  affiche « IP publique : recherche... » jusqu'à la réponse d'ipify, puis
  l'adresse ou « inconnue ».
- Pas de `relay server`, pas de `host migration`, pas d'anti-triche.

### Autorité et cadence

- `Host-authoritative` : le `host` fait seul la simulation. Pas de `prediction`,
  pas de `rollback`. Un `client` voit son propre personnage réagir avec la latence
  aller-retour.
- Le `sim core` tourne à 60 Hz sur le `host`.
- Chaque `client` envoie son `input` à chaque `tick`, en `unreliable` : numéro de
  `tick` (uint32) + bitfield (uint8 : gauche, droite, saut). Le `host` applique le
  dernier `input` reçu, sans file d'attente.
- Le `host` envoie un `snapshot` 30 fois par seconde, en `unreliable`, dans un
  seul `PackedByteArray` : numéro de `tick`, puis par joueur x et y (float32) et
  un octet de drapeaux (orientation, au sol, mort, `key carrier`), puis un octet
  d'état du niveau (porte ouverte). Environ 90 octets pour 8 joueurs.
- Les `clients` affichent avec 100 ms de retard et interpolent entre deux
  `snapshots`. Les `clients` n'envoient jamais de position.
- Les événements (mort, porte ouverte, `level clear`, changement de niveau)
  passent en `reliable`.
- `@rpc` écrits à la main. Pas de `MultiplayerSynchronizer` : il ne gère pas
  l'interpolation.
- Le `host` continue de simuler quand sa fenêtre perd le focus (pas de
  `low processor mode`).

### Session

- Menu principal, puis « Host » (port, pseudo) ou « Join » (IP:port, pseudo).
- Lobby : liste des joueurs, couleur attribuée par ordre d'arrivée. Seul le `host`
  voit « Start » et le choix du niveau de départ.
- À la connexion : échange d'un `protocol version` (entier, incrémenté à chaque
  changement du format des messages). Refus si différent, si 8 joueurs, ou si
  une partie est en cours.
- Timeout de connexion 10 s. Messages d'erreur explicites : connexion refusée,
  version incompatible (toi X, host Y), partie pleine, partie en cours.
- Un `client` qui tombe en pleine partie : retiré, le niveau recommence pour les
  autres. Le `host` qui tombe : tout le monde revient au menu avec un message.
- Pseudo de 1 à 12 caractères. Pseudo et dernière IP sauvés dans
  `user://settings.cfg`.
- Un port hors 1 à 65535 est refusé avec un message ; un champ vide vaut 28015.
  Un pseudo contenant un caractère de contrôle est refusé par le `host`.

## Niveaux

- Un niveau s'écrit en texte dans `levels/src/level_NN.txt` (40 colonnes sur
  22 lignes : `#` solid, `^` spike, `S` spawn, `K` key, `D` door) et
  `tools/build_levels.gd` en construit la scène Godot (`TileMapLayer` avec un
  `custom data` `solid` ou `spike`, `Marker2D` pour les spawns, la clé et la
  porte). La scène reste éditable dans l'éditeur.
- Au chargement, le `sim core` lit la grille et les markers.
- Pas d'outil externe (LDtk, Tiled).
- Cinq niveaux conçus par l'agent, playtestés par le développeur : 1 marche et
  saut jusqu'à la porte, 2 `stack` obligatoire (rebord trop haut), 3 `spikes` et
  timing, 4 `push chain`, 5 combinaison.
- Pas de sauvegarde de progression : le `host` choisit le niveau de départ.
- Règle de placement : aucun `spike` à moins de 6 tuiles d'un spawn, pour qu'une
  poussée au départ laisse une seconde de réaction.

## Art et audio

- Placeholders faits maison (les packs pixel de Kenney sont en 18 px, pas 16).
- Joueurs : carrés colorés avec deux yeux. Palette fixe de 8 couleurs : rouge,
  bleu, vert, jaune, violet, orange, cyan, rose.
- Tuiles : aplats unis (sol, `spike` triangulaire rouge à pointe claire, clé,
  porte). La porte est une arche de deux tuiles de haut à cadre de pierre
  clair, battant en bois fermé ou ouverture noire ; son sprite part de la tuile
  au-dessus de la `door`, qui reste vide dans chaque niveau.
- PNG générés par un script Python (Pillow) commité dans `tools/`, donc
  reproductibles et remplaçables par du vrai pixel art.
- Effets sonores (saut, mort, clé, porte, victoire) et boucle musicale générés
  par `tools/gen_audio.py` : des placeholders remplaçables. Deux curseurs de
  volume dans les options. Huit lecteurs d'effets, un par joueur possible.

## Qualité et tests

- GDScript avec typage statique partout. Les `GDScript warnings` sont traités
  comme des erreurs dans `project.godot`.
- `gdtoolkit` (`gdformat`, `gdlint`) en CI si son parser accepte la syntaxe 4.7 ;
  sinon `gdformat` seul ou rien, sans bloquer le projet.
- TDD avec GUT 9.7 sur le `sim core` (poussée, empilement, clé, porte, mort) et
  sur l'encodage et le décodage des `snapshots`. Le ressenti reste en test
  manuel.
- Réseau testé à la main via « Run Multiple Instances » de l'éditeur, plus un
  `smoke test` en CI : un `host` et un `client` `headless` se connectent et
  échangent un `snapshot`.

## Projet et outillage

- Godot 4.7.2 épinglé dans le projet et la CI.
- Arborescence : `sim/` (règles pures), `net/` (transport, codec), `ui/`,
  `levels/`, `assets/`, `tests/`, `tools/`.
- Dépôt GitHub public `juuuuuu/stackmates`. Le dossier local reste
  `/home/ju/dev/pico`.
- Licence MIT pour le code. Les assets générés sont sous la même licence.
- Commits directs sur `main`, pas de PR, pas de branche de fonctionnalité.
- Messages de commit : préfixe Conventional Commits en anglais (`feat:`, `fix:`,
  `test:`, `docs:`, `ci:`, `chore:`), sujet en français.
- README, `docs/` et commentaires en français, termes techniques en anglais comme
  dans le code. Page itch.io en anglais.
- Logs dans `user://logs`. `export_presets.cfg` commité. `.gitignore` standard
  Godot.
- Les réglages sont écrits sur disque à la fermeture de l'écran Options et au
  basculement plein écran, pas à chaque cran de curseur.

## Distribution

- CI GitHub Actions. Lint et tests à chaque push sur `main`.
- Exports Windows x86_64, Linux x86_64, macOS universal, un `.zip` par
  plateforme, sur chaque tag `v*` et par déclenchement manuel.
- Le workflow télécharge le binaire Godot 4.7.2 et les `export templates` depuis
  les releases officielles (`godot-builds`), avec `actions/cache`. Pas d'image
  Docker tierce.
- Builds non signés : avertissement SmartScreen (Windows) et Gatekeeper (macOS :
  depuis macOS 15, Réglages Système, Confidentialité et sécurité, « Ouvrir
  quand même » ; avant, « clic droit, Ouvrir » ; ou `xattr`) documentés. Un
  compte Apple Developer coûte 99 USD par an, hors budget.
- Publication sur itch.io (slug `stackmates`) via `butler` sur chaque tag, et sur
  GitHub Releases. Le développeur crée le compte itch.io et la clé `butler` en
  secret GitHub au jalon 3.
- Version semver affichée dans le menu principal.

## Jalons

Livrés : jalon 0 (`v0.0.1`, 2026-11-06), jalon 1 (`v0.1.0`, 2026-11-06),
jalon 2 (`v0.2.0`, 2026-11-06 : cinq niveaux, choix du niveau, écran de
victoire, lobby réseau, audio, options, menu Échap, traduction), jalon 3
(`v0.3.0`, 2026-11-06 : publication itch.io par la CI, logs horodatés,
documentation d'installation et page itch.io), jalon 4 (`v0.5.0`, 2026-11-06 :
finitions avant sortie publique, mineurs des revues 0 à 3, CI robuste, Makefile,
fenêtre remplie à toute taille, porte et `spike` lisibles ; `v0.4.0` perdait une
ouverture `UPnP` demandée pendant une fermeture).

- Jalon 0 : `sim core` minimal (marche, saut, collision tuiles), transport
  réseau, lobby minimal, un niveau vide, exports des trois plateformes en CI.
  Objectif : deux joueurs connectés via Internet qui bougent et sautent.
- Jalon 1 : `push chain`, `stack`, mort, clé, porte, en TDD, jouables en ligne.
- Jalon 2 : cinq niveaux, lobby complet, audio, options.
- Jalon 3 : publication itch.io et documentation d'installation (SmartScreen,
  Gatekeeper, port forwarding).
- Jalon 4 : finitions avant sortie publique (mineurs des revues 0 à 3 qui
  touchent les joueurs, robustesse CI).
- Pas de date imposée. Le jalon 0 passe en premier car il porte le risque
  principal (réseau, NAT, exports).

## Alternatives écartées

- Moteur : Godot + C# (il faut .NET), Bevy en Rust (courbe raide, rien
  d'installé), Phaser + Electron (packaging lourd, réseau à construire).
- Réseau : WebRTC avec `STUN` seul (échoue sur les NAT stricts sans `TURN`
  payant), Steam (100 USD), `relay server` hébergé (coût et maintenance).
- Autorité : `lockstep` déterministe (la physique Godot n'est pas déterministe
  entre plateformes), `rollback` (complexité).
- Simulation : `CharacterBody2D` et la physique Godot (poussée et empilement se
  battent contre le moteur, tests liés au `scene tree`).
- Outils de niveaux : LDtk, Tiled.
- Workflow : branches et PR.
