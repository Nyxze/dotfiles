# Panneau Mint avec i3

Le panneau Xfce natif reste en haut. Sur le workspace 0 (`Super+0`), il montre
le menu Mint, les lanceurs, la liste des fenêtres et le tray. Sur les workspaces
1 à 5, seule sa zone tray est visible à droite ; `i3-workspace-buttons` montre
les numéros de workspace à gauche. Le même systray Xfce reste actif partout.
Le workspace actif porte un trait jaune ; un autre workspace dont une fenêtre
demande l'attention porte un trait rouge, alimenté par l'état urgent d'i3.
`Super+0` ouvre le bureau Mint ; `Super+1` à `Super+5` ouvrent les cinq bureaux
au rendu Hyprland. `Super+Shift+0` déplace la fenêtre active vers le bureau
Mint, comme `Super+Shift+1` à `Super+Shift+5` pour les autres bureaux.

`i3-workspace-panel` lit la position réelle du plugin systray et adapte la
zone visible du panneau et de son conteneur i3. Ce second découpage laisse
apparaître le papier peint entre les workspaces et le tray. Le fond des boutons
et du tray prend la couleur du bord supérieur du papier peint pendant les
workspaces 1 à 5 ; sur le workspace 0, le style Xfce d'origine revient.
Ajouter ou retirer une icône, ou changer sa taille,
déplace automatiquement cette limite (vérification toutes les secondes). Les
changements de workspace ne redémarrent ni i3 ni Xfce. Le script réagit aussi
aux événements de workspace i3. À l'arrêt, il rend au panneau sa forme entière
et sa position Mint en bas, pour la session Xfce de repli. Il vérifie la
disposition Mint avant de la déplacer et refuse un profil personnalisé.
`i3-workspace-panel-watchdog` le relance si sa connexion à i3 ou X11 tombe ;
un verrou évite de lancer plusieurs superviseurs après un rechargement d'i3.

`Super+D` ouvre ou ferme la sidebar Endfield. Sur Mint, ses panneaux Quickshell
sont des fenêtres flottantes placées sous la barre Xfce : ils se superposent aux
applications sans agrandir la zone réservée. i3 les redimensionne quand le
contenu d'une page change ; les pages longues défilent dans l'espace disponible.
La règle i3 est dans la configuration copiée par `apply-config`.

Un profil Mint d'origine avec un panneau unique n'exige aucun réglage Xfce
supplémentaire. Si l'ancienne version à deux panneaux a déjà été installée,
exécuter une fois `./platform/mint/configure-i3-panels.py` dans la session
Xfce+i3 avant de lancer le nouveau script. Cette commande vérifie la
disposition connue, sauvegarde le XML dans
`~/.local/state/dotfiles/panel-backups/`, puis restaure le panneau unique.
Elle refuse une disposition Xfce personnalisée. `apply-config` ne copie aucun
réglage Xfce.

Déployer les scripts et les configurations i3 et Quickshell avec
`./apply-config --profile mint-xfce i3 quickshell scripts`. Les scripts démarrent à la
prochaine ouverture de session i3. Pour appliquer le changement dans une
session déjà ouverte, lancer
`~/.local/scripts/i3-wallpaper`, puis
`i3-msg 'exec --no-startup-id ~/.local/scripts/i3-workspace-panel-watchdog'`
après le déploiement. Le premier pose le fond Arch sur la racine X11 ; le
second démarre la gestion du panneau. Le prochain démarrage d'i3 les lancera
depuis sa config ; un simple `i3-msg reload` ne lance pas les commandes
`exec_always`.
