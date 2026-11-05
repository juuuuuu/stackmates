# Stackmates

Jeu de plateforme coopératif en ligne, inspiré des mécaniques de Pico Park. Les
termes ci-dessous sont ceux du code et de la documentation. Un concept, un terme.

## Langage

### Session

**Session** :
Une partie hébergée par un joueur, que d'autres rejoignent. Elle va du lobby à
la fin du dernier niveau.
_À éviter_ : partie, game, room

**Host** :
Le joueur dont la machine fait tourner la session et dont la simulation fait
autorité.
_À éviter_ : server, serveur, hébergeur

**Client** :
Un joueur qui a rejoint une session hébergée par un autre.
_À éviter_ : guest, invité, peer

**Lobby** :
L'écran d'attente d'une session, avant le premier niveau et entre deux parties.
_À éviter_ : salle d'attente, waiting room

**Player** :
Un participant de la session. Il a un `player slot`, une couleur et un pseudo.
_À éviter_ : user, utilisateur, joueur (dans le code)

**Player slot** :
La place d'un `player` dans la session, de 1 à 8. Elle fixe sa couleur.
_À éviter_ : index, id de joueur, peer id

**Protocol version** :
Le numéro qui dit si deux versions du jeu peuvent se parler.
_À éviter_ : version du jeu, game version

### Niveau

**Level** :
Un écran de jeu : une grille de `tiles`, des `spawns`, une `key` et une `door`.
_À éviter_ : map, stage, carte, scène

**Tile** :
Une case de la grille d'un `level` : vide, `solid` ou `spike`.
_À éviter_ : bloc, cellule, case

**Spike** :
Une `tile` qui tue un `player` au contact.
_À éviter_ : pique, piège, hazard

**Spawn** :
La `tile` où un `player` apparaît au début d'un `level`.
_À éviter_ : point de départ, start

**Key** :
L'objet qu'un `player` ramasse et porte pour ouvrir la `door`.
_À éviter_ : clé (dans le code)

**Key carrier** :
Le `player` qui porte la `key`.
_À éviter_ : holder, porteur, owner

**Door** :
La sortie du `level`. Fermée jusqu'à ce que le `key carrier` la touche ; ensuite
chaque `player` y entre.
_À éviter_ : exit, sortie, goal

### Règles

**Stack** :
Des `players` posés les uns sur les autres. Celui du dessous porte ceux du
dessus.
_À éviter_ : pile, tour, empilement (dans le code)

**Push chain** :
Une suite de `players` contigus au sol, poussés ensemble par un `player` qui
marche contre le premier.
_À éviter_ : poussée, push group

**Death** :
Un `player` qui touche un `spike` ou sort du `level` par le bas. Elle fait
recommencer le `level` pour tous.
_À éviter_ : game over, respawn

**Level clear** :
L'état d'un `level` dont tous les `players` sont entrés dans la `door`.
_À éviter_ : victoire, win, completed

### Simulation et réseau

**Tick** :
Un pas de la simulation. Il y en a 60 par seconde sur le `host`.
_À éviter_ : frame, step

**Input** :
Les commandes d'un `player` pour un `tick` : gauche, droite, saut.
_À éviter_ : commande, action, contrôle

**Snapshot** :
L'état d'un `level` à un `tick` donné, tel que le `host` l'envoie aux `clients`.
_À éviter_ : state, état, sync, update
