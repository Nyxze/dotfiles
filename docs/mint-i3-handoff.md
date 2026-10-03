# Handoff — Mint/Xfce/i3

État au 3 octobre 2026. Les changements du dépôt restent non commités.

## Comportement demandé

- Workspace 0 (`Super+0`) : barre Mint/Xfce native en haut, avec menu,
  lanceurs, liste des fenêtres et tray à droite. Aucun sélecteur de workspaces.
- Workspaces 1 à 5 : boutons de workspaces numérotés à gauche et tray à
  droite. Aucun menu ni liste de fenêtres.
- Même fond d'écran qu'Arch (`home/common/.config/theme/greeter.png`).
- Bordures jaunes sur la fenêtre active, grises sur les autres.

## Solution actuelle

Un seul panneau Xfce contient les plugins Mint d'origine
`[1, 2, 14, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13]`. Son séparateur 7
s'étend pour garder le tray à droite. `i3-workspace-panel` laisse le panneau
entier visible sur le workspace 0 et limite sa zone visible au tray sur les
autres workspaces. Il lit la position X11 réelle du plugin systray 8 chaque
seconde ; la limite suit donc l'ajout d'icônes et les changements de taille.
Un passage de workspace ne redémarre aucun panneau. `i3-workspace-buttons`
affiche les numéros sur 1–5 et se masque sur 0. La position du panneau revient
en bas lorsque `i3-workspace-panel` s'arrête proprement, pour la session Xfce
de repli.
`i3-workspace-panel-watchdog` relance l'intégration si elle s'arrête pendant
qu'i3 fonctionne et évite ainsi que la barre Mint reste en bas sur 1–5.

Le prototype a été vérifié dans la session live : workspace 1 et 2 visibles,
processus Xfce inchangé, taille d'icône systray réduite de 20 à 16 puis
restaurée. Le bord gauche du systray a bougé de x=1629 à x=1649, et la zone
visible a suivi exactement (`xwininfo -shape` : `271x33+1649+0`, puis
`291x33+1629+0`). Une icône temporaire GTK a aussi fait grandir le systray
de 41 à 61 px : sa limite est passée à x=1609, la zone visible à
`311x33+1609+0`, puis les deux sont revenues à leur position initiale dès
le retrait de l'icône. Après `xfce4-panel --restart`, le processus
`i3-workspace-panel` est resté actif et a recalculé la forme du nouveau
panneau. La session a ensuite été verrouillée par `light-locker` après
inactivité, donc la vérification visuelle post-redémarrage reste à faire
après déverrouillage. Un redémarrage de session complète reste à vérifier.
Le fond Arch a ensuite été appliqué dans la session courante avec
`~/.local/scripts/i3-wallpaper` et contrôlé visuellement sur le workspace 4.
Le déploiement du fichier seul et `i3-msg reload` ne l'avaient pas lancé.

## Fichiers

| Emplacement | Rôle |
| --- | --- |
| `home/mint-xfce/.local/scripts/i3-workspace-panel` | Affichage sélectif du panneau Xfce unique. |
| `home/mint-xfce/.local/scripts/i3-workspace-panel-watchdog` | Relance le panneau après une déconnexion transitoire. |
| `home/mint-xfce/.local/scripts/i3-workspace-buttons` | Boutons 1 à 5 avec indicateur du workspace actif. |
| `home/mint-xfce/.local/scripts/i3-wallpaper` | Fond Arch sur X11. |
| `home/mint-xfce/.config/i3/config` | Démarre les scripts et règle les bordures. |
| `platform/mint/configure-i3-panels.py` | Migration facultative de l'ancien montage à deux panneaux vers le panneau Mint unique. |
| `docs/mint-i3-panels.md` | Fonctionnement et déploiement. |

Le fichier Xfce actif est
`~/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml` et n'est pas
suivi dans le dépôt. Une copie de la configuration précédente à deux panneaux
est dans `/tmp/xfce4-panel-before-single-top.xml`. Le script de migration
enregistre également une sauvegarde persistante dans
`~/.local/state/dotfiles/panel-backups/` quand il modifie le profil.

## Suite

1. Vérifier le comportement après un redémarrage du panneau ou de la session.
2. Finir le styling selon la config Arch/Waybar : fond, hauteur, couleurs,
   espacement, icônes, bordures. Vérifier particulièrement VS Code sur le 3.
3. Vérifier les contrôles réseau, Bluetooth, son, alimentation et notifications
   au clic, ainsi que la liste des fenêtres sur le workspace 0.

Commandes utiles :

```bash
./apply-config --profile mint-xfce i3 scripts
./platform/mint/configure-i3-panels.py  # seulement pour migrer l'ancien montage
~/.local/scripts/i3-wallpaper
i3-msg 'exec --no-startup-id ~/.local/scripts/i3-workspace-panel-watchdog'
i3-msg -t get_workspaces
xfconf-query -c xfce4-panel -p /panels
```
