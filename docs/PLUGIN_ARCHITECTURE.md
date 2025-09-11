# Architecture des Plugins IntaText

## Vue d'ensemble

L'architecture des plugins d'IntaText permet d'étendre les fonctionnalités de l'application de manière modulaire et flexible. Cette architecture est conçue selon les principes suivants :

- **Modularité** : Chaque plugin est indépendant et peut être activé/désactivé
- **Sécurité** : Isolation des plugins avec contrôle des permissions
- **Extensibilité** : Support de différents types de plugins
- **Simplicité** : API claire et documentée pour les développeurs

## Structure générale

```
src/model/plugins/
├── IPlugin.vala              # Interface de base pour tous les plugins
├── IFormatPlugin.vala         # Interface pour plugins de format de fichier
├── ILanguagePlugin.vala       # Interface pour plugins linguistiques
├── IUIPlugin.vala             # Interface pour plugins d'interface utilisateur
├── PluginManager.vala         # Gestionnaire central des plugins
├── PluginService.vala         # Service d'API pour les plugins
├── PluginConfigManager.vala   # Gestion de la configuration des plugins
└── PluginMetadataReader.vala  # Lecteur des métadonnées de plugins
```

## Types de plugins

### 1. Plugins de Format (IFormatPlugin)
Permettent d'importer et exporter des formats de fichiers personnalisés.

**Cas d'usage :**
- Support de nouveaux formats de documents
- Conversion entre formats
- Import/export spécialisé

**Méthodes principales :**
- `import_file()` : Importer un fichier vers le format pivot
- `export_file()` : Exporter depuis le format pivot
- `get_supported_extensions()` : Extensions supportées
- `get_import_options()` : Options d'import configurables

### 2. Plugins Linguistiques (ILanguagePlugin)
Ajoutent des fonctionnalités de traitement de texte et linguistiques.

**Cas d'usage :**
- Correction orthographique et grammaticale
- Traduction automatique
- Analyse de texte
- Statistiques linguistiques

**Méthodes principales :**
- `check_spelling()` : Vérification orthographique
- `check_grammar()` : Vérification grammaticale
- `get_suggestions()` : Suggestions de correction
- `translate_text()` : Traduction
- `get_text_statistics()` : Statistiques du texte

### 3. Plugins d'Interface (IUIPlugin)
Étendent l'interface utilisateur avec de nouveaux composants.

**Cas d'usage :**
- Nouveaux panneaux et vues
- Boutons de barre d'outils personnalisés
- Raccourcis clavier
- Menus contextuels

**Méthodes principales :**
- `create_toolbar_button()` : Bouton de barre d'outils
- `create_sidebar_widget()` : Widget de barre latérale
- `create_panel()` : Panneau personnalisé
- `get_context_menu_items()` : Éléments de menu contextuel

## Structure d'un plugin

### Fichier de métadonnées (.plugin)
Chaque plugin doit avoir un fichier de métadonnées au format KeyFile :

```ini
[Plugin]
Id=mon-plugin
Name=Mon Plugin Exemple
Version=1.0.0
Description=Description du plugin
Author=Nom de l'auteur
Website=https://example.com
License=GPL-3.0+

[Compatibility]
MinIntaTextVersion=1.0.0
MaxIntaTextVersion=2.0.0

[Type]
PluginType=UI

[Dependencies]
# Autres plugins requis
RequiredPlugins=plugin1,plugin2

[Resources]
LibraryFile=mon-plugin.so
IconFile=icon.png
DataDirectory=data/

[Configuration]
DefaultEnabled=true
ConfigurableSettings=option1,option2,option3

[Permissions]
RequiresFileAccess=true
RequiresNetworkAccess=false
RequiresSystemAccess=false
```

### Code du plugin
```vala
using IntaText.Plugins;

namespace MonNamespace {
    public class MonPlugin : Object, IPlugin, IUIPlugin {
        private PluginService? service;

        public PluginMetadata get_metadata() {
            return PluginMetadata() {
                id = "mon-plugin",
                name = "Mon Plugin",
                version = "1.0.0",
                description = "Description du plugin",
                author = "Auteur",
                plugin_type = PluginType.UI,
                min_intatext_version = "1.0.0",
                dependencies = new string[0]
            };
        }

        public bool initialize(PluginService service) {
            this.service = service;
            return true;
        }

        public bool activate() {
            // Activer le plugin
            return true;
        }

        public bool deactivate() {
            // Désactiver le plugin
            return true;
        }

        public void cleanup() {
            // Nettoyer les ressources
        }

        // Implémentation des méthodes d'interface spécifiques...
    }
}

// Points d'entrée pour le chargement dynamique
public Type plugin_get_type() {
    return typeof(MonNamespace.MonPlugin);
}

public IntaText.Plugins.IPlugin plugin_create_instance() {
    return new MonNamespace.MonPlugin();
}
```

## Cycle de vie d'un plugin

1. **Découverte** : Le PluginManager scanne les répertoires de plugins
2. **Chargement** : Les métadonnées sont lues et validées
3. **Initialisation** : `initialize()` est appelé avec le PluginService
4. **Activation** : `activate()` est appelé si le plugin est activé
5. **Utilisation** : Le plugin fonctionne et répond aux événements
6. **Désactivation** : `deactivate()` est appelé si nécessaire
7. **Nettoyage** : `cleanup()` est appelé avant déchargement

## Gestion de la configuration

Les plugins peuvent sauvegarder leurs paramètres via le PluginConfigManager :

```vala
// Sauvegarder un paramètre
config_manager.set_plugin_setting("mon-plugin", "ma_option", "valeur");

// Récupérer un paramètre
string? valeur = config_manager.get_plugin_setting("mon-plugin", "ma_option");

// Activer/désactiver un plugin
config_manager.enable_plugin("mon-plugin");
config_manager.disable_plugin("mon-plugin");
```

## Service API pour les plugins

Le PluginService fournit l'accès aux fonctionnalités de base d'IntaText :

```vala
public interface PluginService : Object {
    // Gestion des documents
    public abstract string? get_current_document_content();
    public abstract bool set_current_document_content(string content);

    // Interface utilisateur
    public abstract void show_notification(string message);
    public abstract void show_error(string error);

    // Système d'événements
    public abstract void trigger_event(string event_name, HashTable<string,string>? data = null);
}
```

## Répertoires de plugins

### Système
- `/usr/lib/intatext/plugins/` : Bibliothèques des plugins système
- `/usr/share/intatext/plugins/` : Métadonnées des plugins système

### Utilisateur
- `~/.local/lib/intatext/plugins/` : Bibliothèques des plugins utilisateur
- `~/.local/share/intatext/plugins/` : Métadonnées des plugins utilisateur

## Développement d'un plugin

### 1. Créer la structure
```bash
mkdir mon-plugin
cd mon-plugin
touch MonPlugin.vala
touch mon-plugin.plugin
touch meson.build
```

### 2. Implémenter les interfaces
- Hériter de `Object` et implémenter au minimum `IPlugin`
- Implémenter les interfaces spécialisées selon le type
- Définir les points d'entrée `plugin_get_type()` et `plugin_create_instance()`

### 3. Configurer la compilation
```meson
shared_library(
    'mon-plugin',
    'MonPlugin.vala',
    dependencies: [glib_dep, gtk_dep, gio_dep],
    install: true,
    install_dir: get_option('libdir') / 'intatext' / 'plugins'
)
```

### 4. Installer et tester
```bash
meson compile -C build
meson install -C build
```

## Sécurité et permissions

Les plugins déclarent leurs besoins en permissions dans le fichier `.plugin` :

- `RequiresFileAccess` : Accès au système de fichiers
- `RequiresNetworkAccess` : Accès réseau
- `RequiresSystemAccess` : Accès aux fonctions système

## Debugging et logs

Utilisez les fonctions de debug Vala :
```vala
debug("Mon message de debug");
warning("Attention : %s", message);
critical("Erreur critique");
```

Lancer avec debug activé :
```bash
G_MESSAGES_DEBUG=all intatext
```

## Exemples

Voir le répertoire `examples/plugins/` pour des exemples complets :
- `hello-world/` : Plugin UI basique
- `markdown-exporter/` : Plugin de format
- `spell-checker/` : Plugin linguistique

## Bonnes pratiques

1. **Gestion d'erreurs** : Toujours vérifier les retours et gérer les erreurs
2. **Nettoyage** : Libérer toutes les ressources dans `cleanup()`
3. **Thread-safety** : L'interface utilisateur doit être utilisée depuis le thread principal
4. **Performance** : Éviter les opérations bloquantes dans les callbacks
5. **Compatibilité** : Tester avec différentes versions d'IntaText
