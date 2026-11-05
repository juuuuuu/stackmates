# Host-authoritative, sans prediction ni rollback

Un joueur héberge (`listen server`) et les autres rejoignent via Internet. Le
`host` fait seul tourner le `sim core` ; les `clients` envoient leurs `inputs`,
reçoivent des `snapshots` et affichent avec 100 ms de retard par interpolation.
Un `client` voit donc son propre personnage réagir avec la latence aller-retour.
Nous acceptons ce délai : c'est un jeu de coopération lente entre amis, et
l'original a la même limite. Les alternatives coûtent trop : le `lockstep`
exige une simulation déterministe entre Windows, Linux et macOS, et le
`rollback` ou la `prediction` côté client multiplient la complexité du code
réseau pour un gain faible ici.

## Conséquences

- Les `clients` n'ont aucune autorité : ils n'envoient jamais de position.
- Ajouter la `prediction` plus tard reste possible car le `sim core` est pur et
  peut tourner aussi côté `client` (voir ADR 0001).
