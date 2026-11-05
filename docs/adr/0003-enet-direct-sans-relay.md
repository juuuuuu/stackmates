# ENet en direct avec UPnP, sans relay server

Le budget est nul, donc aucun serveur hébergé. Le `host` ouvre un port `ENet`
(28015 par défaut), tente `UPnP`, et partage son IP publique ; les `clients`
entrent `IP:port`. Les secours documentés sont le port forwarding manuel sur la
box, puis un VPN gratuit entre amis (ZeroTier, Tailscale). Nous avons écarté
WebRTC avec `STUN` seul (échoue sur les NAT stricts sans serveur `TURN`
payant), Steam (100 USD) et un `relay server` sur un hébergeur gratuit (compte,
carte bancaire, maintenance).

## Conséquences

- La connexion échoue chez certains joueurs sans action manuelle de leur part.
  La documentation d'installation (jalon 3) couvre ces cas.
- Si un jour un `relay` devient gratuit et simple, il s'ajoute derrière le même
  `transport` sans changer le `sim core` ni le codec.
