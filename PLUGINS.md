# Architecture de Plugins IntaText

## Vue d'ensemble

L'architecture de plugins d'IntaText permet d'étendre les fonctionnalités de l'application sans modifier le code principal. Le système supporte trois types de plugins :

- **Plugins de Format** : Import/export de nouveaux formats de documents
- **Plugins de Langage** : Services linguistiques (correction, traduction, etc.)
- **Plugins d'Interface** : Nouveaux composants UI (boutons, panneaux, etc.)

## Structure des Fichiers

```
src/model/plugins/
├── IPlugin.vala                 # Interface de base pour tous les plugins
├── IFormatPlugin.vala           # Interface pour les plugins de format
├── ILanguagePlugin.vala         # Interface pour les plugins linguistiques
├── IUIPlugin.vala              # Interface pour les plugins d'interface
├── PluginManager.vala          # Gestionnaire central des plugins
├── PluginMetadataReader.vala   # Lecteur de métadonnées .plugin
├── PluginService.vala          # Service d'intégration avec l'application
├── PluginConfigManager.vala    # Gestionnaire de configuration
└── examples/
    └── ExampleUIPlugin.vala    # Exemple de plugin UI
```

## Fichiers de Métadonnées

Chaque plugin doit avoir un fichier `.plugin` décrivant ses caractéristiques :

```ini
[Plugin]
Id=my_plugin
Name=Mon Plugin
Version=1.0.0
Author=Nom Auteur
Type=UI
Description=Description du plugin
Enabled=true
Dependencies=

[Configuration]
# Options spécifiques au plugin
OptionExample=true
```

## Répertoires de Plugins

- **Système** : `/usr/lib/intatext/plugins/`
- **Utilisateur** : `~/.local/share/intatext/plugins/`
- **Exemples** : `/usr/share/intatext/plugins/examples/`

## Développement de Plugins

### 1. Plugin de Format

```vala
public class MyFormatPlugin : Object, IFormatPlugin {
    public PluginMetadata metadata { get { return _metadata; } }

    public bool initialize(ApplicationController app_controller) {
        // Initialisation
        return true;
    }

    public string[] get_supported_extensions() {
        return {".myext"};
    }

    public PivotDocument? import_document(string file_path) throws GLib.Error {
        // Logique d'import
        return null;
    }

    public void export_document(PivotDocument document, string file_path) throws GLib.Error {
        // Logique d'export
    }
}
```

### 2. Plugin de Langage

```vala
public class MyLanguagePlugin : Object, ILanguagePlugin {
    public PluginMetadata metadata { get { return _metadata; } }

    public string[] get_supported_languages() {
        return {"fr", "en"};
    }

    public LanguageSuggestion[] analyze_text(string text, string lang, LanguageService service) {
        // Analyse du texte
        return {};
    }
}
```

### 3. Plugin d'Interface

```vala
public class MyUIPlugin : Object, IUIPlugin {
    public PluginMetadata metadata { get { return _metadata; } }

    public UIComponentDescriptor[] get_ui_components() {
        return {
            UIComponentDescriptor() {
                id = "my_button",
                type = UIComponentType.TOOLBAR_BUTTON,
                label = "Mon Bouton",
                icon_name = "document-new-symbolic"
            }
        };
    }

    public Gtk.Widget? create_widget(string component_id, Gtk.Widget? parent) {
        if (component_id == "my_button") {
            var button = new Gtk.Button();
            button.clicked.connect(() => on_component_activated(component_id));
            return button;
        }
        return null;
    }
}
```

## API du PluginService

Le `PluginService` fournit une API pour que les plugins interagissent avec l'application :

```vala
var service = PluginService.instance;

// Accès au document courant
var document = service.get_current_document();

// Manipulation du texte
service.insert_text_at_cursor("Hello World");
service.replace_selection("New text");

// Interface utilisateur
service.show_toast("Message");
service.show_status_message("Status");

// Fichiers
service.open_file("/path/to/file");
service.save_current_document();
```

## Configuration GSettings

Les plugins peuvent stocker leur configuration dans GSettings :

```vala
var config_manager = PluginConfigManager();
config_manager.set_plugin_setting("my_plugin", "option1", new Variant.boolean(true));
var value = config_manager.get_plugin_setting("my_plugin", "option1");
```

## Installation d'un Plugin

1. Créer le fichier `.plugin` avec les métadonnées
2. Compiler le code Vala en bibliothèque partagée (.so)
3. Copier les fichiers dans le répertoire de plugins
4. Redémarrer IntaText ou recharger les plugins

```bash
# Compilation d'un plugin
valac --library=my_plugin --shared --pkg=gtk4 my_plugin.vala -o my_plugin.so

# Installation
mkdir -p ~/.local/share/intatext/plugins
cp my_plugin.so ~/.local/share/intatext/plugins/
cp my_plugin.plugin ~/.local/share/intatext/plugins/
```

## Événements Disponibles

Les plugins peuvent réagir aux événements de l'application :

- `DOCUMENT_OPENED`
- `DOCUMENT_CLOSED`
- `DOCUMENT_SAVED`
- `DOCUMENT_MODIFIED`
- `SELECTION_CHANGED`
- `EDITOR_FOCUS_IN/OUT`
- `APPLICATION_STARTED/CLOSING`
- `PREFERENCES_CHANGED`

```vala
service.register_event_handler("DOCUMENT_OPENED", (context) => {
    var file_path = context.get_string("file_path");
    // Réagir à l'ouverture d'un document
});
```

## Sécurité et Bonnes Pratiques

- Les plugins s'exécutent dans le même processus que l'application
- Gérer les erreurs proprement avec try/catch
- Nettoyer les ressources dans cleanup()
- Respecter les conventions de nommage GNOME
- Tester avec différentes versions d'IntaText
- Documenter les dépendances externes

## Dépannage

### Plugin non chargé
- Vérifier le fichier .plugin
- Contrôler les permissions
- Consulter les logs de debug

### Erreurs au démarrage
- Vérifier les dépendances
- Contrôler la compatibilité des versions
- S'assurer que initialize() retourne true

### Problèmes UI
- Vérifier les IDs des composants
- S'assurer que create_widget() retourne un widget valide
- Contrôler les signaux et callbacks
