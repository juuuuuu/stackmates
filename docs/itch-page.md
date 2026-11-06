# Page itch.io

Texte de la page, en anglais, à coller dans « Edit game » du projet
`stackmates`. Métadonnées suggérées : Classification `Game`, Kind of project
`Downloadable`, Pricing `No payments`, Genre `Platformer`, Tags `co-op`,
`multiplayer`, `online`, `pixel-art`. Visibility `Public` une fois les trois
uploads (Windows, Linux, macOS) visibles sur la page.

## Short description (under 140 characters)

Online co-op platformer for 2 to 8 friends: push, stack, grab the key, and get everyone through the door.

## Description

**Stackmates** is a cooperative platformer for 2 to 8 players over the Internet. One player hosts, the others join. Each level has one key and one door: bring the key to the door to open it, then everybody has to get in. You push the players you walk into, in a chain. You can stand on a friend's head and ride along: two players stacked clear a ledge that a single jump cannot. Touching a spike or falling out of the level restarts it for everyone.

Five levels: walk and jump, a key too high for one player, spikes and timing, a corridor too low to jump in where you push each other, and everything at once.

Free and open source (MIT): https://github.com/juuuuuu/stackmates

### Download and run

Download the zip for your system, unzip it, and run the game. The builds are not signed (no paid developer account), so your system warns you once:

- Windows: SmartScreen shows "Windows protected your PC". Click "More info", then "Run anyway".
- macOS: Gatekeeper blocks the app on first launch. Right-click `Stackmates.app`, choose "Open", then confirm. Or, in Terminal: `xattr -dr com.apple.quarantine Stackmates.app`
- Linux: run `stackmates.x86_64`. If it does not start, make it executable first: `chmod +x stackmates.x86_64`

All players need the same game version.

### Hosting a game

1. Enter a name and a port (28015 by default), then click Host.
2. The lobby shows your local IP, your public IP, and whether the port was opened automatically with UPnP. A Copy button sits next to each IP.
3. If UPnP fails, open that UDP port on your router and forward it to your computer (port forwarding). Then share your public IP with your friends. On the same local network, the local IP is enough.
4. If you cannot open the port (CGNAT, mobile connection, office network): use a free VPN between friends such as Tailscale or ZeroTier. Everyone installs it and joins the same network; the host shares its VPN IP (100.x.y.z with Tailscale, shown by `tailscale ip -4`) and nobody opens a port.
5. Pick the starting level and click Start when everyone is in.

### Joining a game

Enter a name, the host's address and port, then click Join. Wait for the host to start.

### Controls

Arrow keys or WASD (ZQSD on AZERTY) to move, Space or Up to jump, F11 for fullscreen, Escape for the pause menu (resume or leave). Music and sound volumes and fullscreen are in Options on the main menu. The interface follows your system language: English or French.

### Reporting a problem

Open an issue at https://github.com/juuuuuu/stackmates/issues and attach `godot.log` from the logs folder:

- Windows: `%APPDATA%\Stackmates\logs\`
- Linux: `~/.local/share/Stackmates/logs/`
- macOS: `~/Library/Application Support/Stackmates/logs/`

Every connection, departure, and network error is logged with its time.

### Requirements

Windows, Linux, or macOS, 64-bit. An integrated GPU is enough (tested on an Intel Iris Xe laptop).
