# Stackmates

Jeu de plateforme coopératif en ligne pour 2 à 8 joueurs, inspiré des mécaniques
de Pico Park. Un joueur héberge, les autres rejoignent via Internet. Windows,
Linux, macOS.

État : jalon 3 atteint, le dernier de la spec (publication itch.io par la
CI, logs horodatés, documentation d'installation). Voir `docs/design.md`.

## Jouer

1. Télécharger le zip de sa plateforme dans les
   [releases GitHub](https://github.com/juuuuuu/stackmates/releases) ou sur
   itch.io (page en préparation), le décompresser et lancer le jeu.
2. Les builds ne sont pas signés (aucun compte développeur payant) :
   - Windows : SmartScreen affiche un avertissement, cliquer sur
     « Informations complémentaires » puis « Exécuter quand même ».
   - macOS : Gatekeeper bloque l'application au premier lancement. Depuis
     macOS 15 : lancer une fois, fermer l'alerte, puis Réglages Système,
     Confidentialité et sécurité, « Ouvrir quand même ». Avant macOS 15, un
     clic droit sur l'application puis « Ouvrir » suffit. Dans tous les cas,
     un terminal marche aussi : `xattr -dr com.apple.quarantine Stackmates.app`.
3. Héberger : entrer un pseudo, un port (28015 par défaut), cliquer sur Host.
   Le lobby affiche l'IP locale, l'IP publique et l'état de l'ouverture du
   port par `UPnP` (bouton Copier à côté de chaque IP). Si l'`UPnP` échoue,
   ouvrir ce port en UDP sur sa box vers son ordinateur (port forwarding).
   Partager l'IP publique avec les autres joueurs ; sur un réseau local,
   l'IP locale suffit. Si le port ne peut pas s'ouvrir (CGNAT, 4G, réseau
   d'entreprise) : un VPN gratuit entre amis, [Tailscale](https://tailscale.com)
   ou [ZeroTier](https://www.zerotier.com). Chacun l'installe et rejoint le
   même réseau ; le `host` donne son IP du VPN (`100.x.y.z` chez Tailscale,
   lue avec `tailscale ip -4`) et personne n'ouvre de port.
4. Rejoindre : entrer un pseudo, l'adresse du `host` et le port, cliquer sur
   Join. Le `host` choisit le niveau de départ et lance la partie avec Start.
   Les cinq niveaux s'enchaînent jusqu'à l'écran de victoire : 1 marche et
   saut, 2 une clé en hauteur qui demande de monter sur un ami, 3 des piques
   à sauter, 4 un couloir trop bas pour sauter où l'on se pousse, 5 tout à la
   fois.
5. Commandes : flèches ou WASD (ZQSD en AZERTY) pour bouger, Espace ou flèche
   haut pour sauter, F11 pour le plein écran, Échap pour le menu de pause
   (reprendre ou quitter la partie). Les volumes de la musique et des effets
   et le plein écran se règlent dans Options, depuis le menu principal.
   L'interface suit la langue du système : anglais, ou français.
6. Règles : ramasser la clé et l'amener à la porte pour l'ouvrir, puis tout
   le monde doit entrer. Un joueur au sol pousse ceux qu'il touche, en
   chaîne. On monte sur la tête des autres et on les suit : à deux on passe
   un rebord de trois tuiles qu'un saut seul ne passe pas. Toucher un pique
   ou tomber hors du niveau fait recommencer le niveau pour tout le monde.
7. Signaler un problème : ouvrir une
   [issue GitHub](https://github.com/juuuuuu/stackmates/issues) en joignant
   le fichier `godot.log` du dossier des logs :
   `%APPDATA%\Godot\app_userdata\Stackmates\logs\` (Windows),
   `~/.local/share/godot/app_userdata/Stackmates/logs/` (Linux),
   `~/Library/Application Support/Godot/app_userdata/Stackmates/logs/`
   (macOS). Le jeu y note l'heure de chaque connexion, départ et erreur
   réseau. Ce fichier contient les adresses IP et les pseudos de la session :
   les masquer avant de le publier si on préfère.

## Développer

- Godot 4.7.2 (https://godotengine.org/download), renderer `Compatibility`.
- Lancer : `godot --path .` ou ouvrir le dossier dans l'éditeur.
- Tests : `bash tools/test.sh` (importe les ressources puis lance GUT).
- Lint : `gdlint` et `gdformat --check` sur `sim net ui levels tools tests
  main.gd` (`pip install "gdtoolkit==4.*"`, ou via Docker :
  `docker run --rm -v "$PWD:/w" -w /w python:3.12-slim sh -c 'pip install -q "gdtoolkit==4.*" && gdlint sim net ui levels tools tests main.gd && gdformat --check sim net ui levels tools tests main.gd'`).
- Smoke test réseau : `bash tools/smoke.sh` (un `host` et un `client`
  `headless` échangent inputs et snapshots). Avec un binaire exporté :
  `STACKMATES_EXPORTED=1 GODOT=export/linux/stackmates.x86_64 bash tools/smoke.sh`.
- Exports : `bash tools/export_all.sh` (il faut les `export templates`
  4.7.2 : `bash tools/install_godot.sh ~/godot-bin --templates`).
- Niveaux : éditer `levels/src/level_NN.txt` puis
  `godot --headless --path . -s tools/build_levels.gd`, ou éditer la scène
  `levels/level_NN.tscn` dans l'éditeur.
- Assets placeholders : `python3 -I tools/gen_assets.py` (images) et
  `python3 -I tools/gen_audio.py` (sons et musique).
- Traductions : `locale/strings.csv` (clés en anglais, colonne `fr`), importé
  par Godot.
- CI : lint (gdlint, gdformat, `tools/check_typography.sh`,
  `tools/publish_itch_test.sh`), tests et smoke à chaque push sur `main` ;
  exports et release GitHub sur chaque tag `v*`, puis publication itch.io par
  `tools/publish_itch.sh` si la variable `ITCH_TARGET` et le secret
  `BUTLER_API_KEY` existent sur le dépôt (`bash tools/itch_setup.sh` les
  crée). La release GitHub ne dépend pas d'itch.io.

## Documentation

- `docs/design.md` : périmètre, règles, architecture, jalons.
- `docs/adr/` : choix structurants et leurs raisons.
- `GLOSSARY.md` : termes du jeu, utilisés tels quels dans le code.

## Licence

Code sous licence MIT (voir `LICENSE`). Les assets sont générés par les
scripts de `tools/`, sous la même licence.
