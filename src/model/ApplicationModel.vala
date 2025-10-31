using IntaText.Plugins;

namespace IntaText {
public class ApplicationModel {
// Structure pour stocker la configuration
public ConfigManager config_manager;
// Gestionnaire de plugins
public PluginManager plugin_manager;
public PluginConfigManager plugin_config_manager;

// Structures pour stocker les données des trois zones
public ExplorerModel explorer;
public EditorModel editor;

public ApplicationModel(ApplicationController controller) {
    config_manager = new ConfigManager();
    plugin_manager = PluginManager.instance;
    plugin_config_manager = new PluginConfigManager ();
    explorer = new ExplorerModel(controller);
    editor = new EditorModel();

    // Initialiser le gestionnaire de plugins
    init_plugins_async.begin (controller);
}

/**
 * Initialisation asynchrone des plugins
 */
private async void init_plugins_async (ApplicationController controller) {
    try {
        // Initialiser le gestionnaire avec le contrôleur
        plugin_manager.initialize (controller);

        // S'assurer que les répertoires de plugins existent
        plugin_manager.ensure_plugin_directories ();

        // Découvrir et charger les plugins
        yield plugin_manager.discover_plugins ();

        // Activer les plugins marqués comme activés
        yield activate_enabled_plugins ();

        debug ("Initialisation des plugins terminée");

    } catch (Error e) {
        warning ("Erreur lors de l'initialisation des plugins: %s", e.message);
    }
}

/**
 * Active tous les plugins marqués comme activés
 */
private async void activate_enabled_plugins () {
    foreach (var plugin_id in plugin_manager.get_plugin_ids ()) {
        var plugin_info = plugin_manager.get_plugin_info (plugin_id);
        if (plugin_info == null) {
            continue;
        }

        bool should_enable = plugin_config_manager.is_plugin_enabled (plugin_id);

        if (should_enable) {
            if (plugin_info.state == PluginState.LOADED || plugin_info.state == PluginState.DISCOVERED) {
                if (plugin_manager.activate_plugin (plugin_id)) {
                    debug ("Plugin %s activé", plugin_id);
                } else {
                    warning ("Échec de l'activation du plugin %s", plugin_id);
                }
            }
        } else {
            if (plugin_info.state == PluginState.ACTIVE) {
                if (plugin_manager.deactivate_plugin (plugin_id)) {
                    debug ("Plugin %s désactivé suite à la configuration", plugin_id);
                } else {
                    warning ("Échec de la désactivation du plugin %s", plugin_id);
                }
            }
        }
    }
}

/**
 * Nettoyage lors de la fermeture de l'application
 */
public void cleanup () {
    plugin_manager.cleanup ();
}
}
}
