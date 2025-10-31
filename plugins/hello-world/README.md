# Plugin Hello World pour IntaText

Plugin d'exemple qui démontre comment créer un plugin UI pour IntaText.

## Fonctionnalités

- Ajoute un bouton avec une icône 😊 dans la barre d'outils
- Au clic, affiche une fenêtre "Hello World"
- Exemple d'implémentation de l'interface `IUIPlugin`

## Installation

### Compilation avec Meson

```bash
# Depuis le répertoire du plugin
meson setup builddir
meson compile -C builddir

# Installation
sudo meson install -C builddir
```

### Installation manuelle

```bash
# Créer le répertoire de plugins
mkdir -p ~/.local/share/intatext/plugins/hello-world

# Copier les fichiers compilés
cp builddir/libhello-world.so ~/.local/share/intatext/plugins/hello-world/
cp hello-world.plugin ~/.local/share/intatext/plugins/hello-world/
```

## Utilisation

1. Lancer IntaText
2. Le plugin sera automatiquement découvert et chargé
3. Un bouton avec une icône 😊 apparaîtra dans la barre d'outils
4. Cliquer sur le bouton pour afficher la fenêtre Hello World

## Structure du plugin

- `HelloWorldPlugin.vala` : Code source du plugin
- `hello-world.plugin` : Fichier de métadonnées
- `meson.build` : Configuration de compilation Meson

## Développement

Ce plugin implémente l'interface `IUIPlugin` qui fournit :
- `initialize()` : Initialisation du plugin
- `activate()` : Activation (ajout du bouton)
- `deactivate()` : Désactivation (retrait du bouton)
- `cleanup()` : Nettoyage des ressources
- `get_sidebar_widget()` : Widget optionnel pour la sidebar
- `get_preferences_widget()` : Widget de préférences

## APIs utilisées

- `PluginService.add_toolbar_button()` : Ajouter un bouton à la barre d'outils
- `PluginService.remove_toolbar_button()` : Retirer un bouton
- `PluginService.get_main_window()` : Obtenir la fenêtre principale

## Licence

GPL-3.0
