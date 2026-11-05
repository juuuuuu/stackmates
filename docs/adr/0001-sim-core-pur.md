# Sim core en GDScript pur, sans la physique Godot pour les joueurs

Les joueurs de Stackmates se poussent en chaîne et s'empilent, deux règles que la
physique Godot (`CharacterBody2D`, `move_and_slide`) rend imprécises et difficiles
à tester, car elles exigent le `scene tree`. Nous écrivons le `sim core` en
GDScript pur : grille de tuiles, joueurs en AABB, collisions et règles à la main
dans `sim/`, sans aucune dépendance aux nodes. Les nodes ne font que l'affichage.
Ce choix rend la simulation testable avec GUT sans scène, déterministe sur le
`host`, et transforme le `snapshot` réseau en simple copie de l'état du
`sim core`.

## Conséquences

- Toute règle de jeu vit dans `sim/`. Un node qui calcule une règle est une
  erreur.
- Les collisions avec le décor se limitent à une grille de tuiles. Les formes
  libres (pentes, plateformes mobiles) demanderont une extension du `sim core`,
  pas un passage à la physique Godot.
