/*
 * PluginConfigManager.vala
 * Gestionnaire de configuration pour les plugins
 * Gère la persistance des préférences et l'état d'activation des plugins
 */

using Gee;

namespace IntaText.Plugins {

    /**
     * Gestionnaire de configuration spécialisé pour les plugins
     */
    public class PluginConfigManager : Object {

        private Settings _main_settings;
        private Settings _plugin_settings;

        // Cache des configurations
        private HashMap<string, HashTable<string, string>> _plugin_configurations;

        public PluginConfigManager () {
            _main_settings = new Settings ("com.cabineteto.IntaText");
            _plugin_settings = new Settings ("com.cabineteto.IntaText.plugin");
            _plugin_configurations = new HashMap<string, HashTable<string, string>> ();

            load_plugin_configurations ();
        }

        /**
         * Vérifie si un plugin est activé
         */
        public bool is_plugin_enabled (string plugin_id) {
            var enabled_list = _main_settings.get_strv ("plugin-enabled-list");
            var disabled_list = _main_settings.get_strv ("plugin-disabled-list");

            // Si explicitement désactivé, retourner false
            foreach (var disabled_id in disabled_list) {
                if (disabled_id == plugin_id) {
                    return false;
                }
            }

            // Si explicitement activé, retourner true
            foreach (var enabled_id in enabled_list) {
                if (enabled_id == plugin_id) {
                    return true;
                }
            }

            // Par défaut, les plugins sont activés si la découverte auto est activée
            return _main_settings.get_boolean ("plugin-auto-discovery");
        }

        /**
         * Active un plugin
         */
        public void enable_plugin (string plugin_id) {
            var enabled_list = _main_settings.get_strv ("plugin-enabled-list");
            var disabled_list = _main_settings.get_strv ("plugin-disabled-list");

            // Ajouter à la liste des activés si pas déjà présent
            bool already_enabled = false;
            foreach (var enabled_id in enabled_list) {
                if (enabled_id == plugin_id) {
                    already_enabled = true;
                    break;
                }
            }

            if (!already_enabled) {
                var new_enabled = new string[enabled_list.length + 1];
                for (int i = 0; i < enabled_list.length; i++) {
                    new_enabled[i] = enabled_list[i];
                }
                new_enabled[enabled_list.length] = plugin_id;
                _main_settings.set_strv ("plugin-enabled-list", new_enabled);
            }

            // Supprimer de la liste des désactivés
            var new_disabled = new string[0];
            foreach (var disabled_id in disabled_list) {
                if (disabled_id != plugin_id) {
                    var temp = new string[new_disabled.length + 1];
                    for (int i = 0; i < new_disabled.length; i++) {
                        temp[i] = new_disabled[i];
                    }
                    temp[new_disabled.length] = disabled_id;
                    new_disabled = temp;
                }
            }
            _main_settings.set_strv ("plugin-disabled-list", new_disabled);
        }

        /**
         * Désactive un plugin
         */
        public void disable_plugin (string plugin_id) {
            var enabled_list = _main_settings.get_strv ("plugin-enabled-list");
            var disabled_list = _main_settings.get_strv ("plugin-disabled-list");

            // Supprimer de la liste des activés
            var new_enabled = new string[0];
            foreach (var enabled_id in enabled_list) {
                if (enabled_id != plugin_id) {
                    var temp = new string[new_enabled.length + 1];
                    for (int i = 0; i < new_enabled.length; i++) {
                        temp[i] = new_enabled[i];
                    }
                    temp[new_enabled.length] = enabled_id;
                    new_enabled = temp;
                }
            }
            _main_settings.set_strv ("plugin-enabled-list", new_enabled);

            // Ajouter à la liste des désactivés si pas déjà présent
            bool already_disabled = false;
            foreach (var disabled_id in disabled_list) {
                if (disabled_id == plugin_id) {
                    already_disabled = true;
                    break;
                }
            }

            if (!already_disabled) {
                var new_disabled = new string[disabled_list.length + 1];
                for (int i = 0; i < disabled_list.length; i++) {
                    new_disabled[i] = disabled_list[i];
                }
                new_disabled[disabled_list.length] = plugin_id;
                _main_settings.set_strv ("plugin-disabled-list", new_disabled);
            }
        }

        /**
         * Obtient la configuration d'un plugin
         */
        public HashTable<string, string>? get_plugin_configuration (string plugin_id) {
            return _plugin_configurations.get (plugin_id);
        }

        /**
         * Définit la configuration d'un plugin
         */
        public void set_plugin_configuration (string plugin_id, HashTable<string, string> configuration) {
            _plugin_configurations.set (plugin_id, configuration);
            save_plugin_configurations ();
        }

        /**
         * Met à jour une valeur de configuration spécifique d'un plugin
         */
        public void set_plugin_setting (string plugin_id, string key, string value) {
            var config = _plugin_configurations.get (plugin_id);
            if (config == null) {
                config = new HashTable<string, string> (str_hash, str_equal);
                _plugin_configurations.set (plugin_id, config);
            }

            config.set (key, value);
            save_plugin_configurations ();
        }

        /**
         * Obtient une valeur de configuration spécifique d'un plugin
         */
        public string? get_plugin_setting (string plugin_id, string key) {
            var config = _plugin_configurations.get (plugin_id);
            if (config != null) {
                return config.get (key);
            }
            return null;
        }

        /**
         * Obtient les plugins activés
         */
        public string[] get_enabled_plugins () {
            return _main_settings.get_strv ("plugin-enabled-list");
        }

        /**
         * Obtient les plugins désactivés
         */
        public string[] get_disabled_plugins () {
            return _main_settings.get_strv ("plugin-disabled-list");
        }

        /**
         * Active/désactive la découverte automatique des plugins
         */
        public bool get_auto_discovery_enabled () {
            return _main_settings.get_boolean ("plugin-auto-discovery");
        }

        public void set_auto_discovery_enabled (bool enabled) {
            _main_settings.set_boolean ("plugin-auto-discovery", enabled);
        }

        /**
         * Obtient le répertoire utilisateur personnalisé des plugins
         */
        public string? get_user_plugins_directory () {
            var dir = _main_settings.get_string ("plugin-user-directory");
            return (dir.length > 0) ? dir : null;
        }

        public void set_user_plugins_directory (string? directory) {
            _main_settings.set_string ("plugin-user-directory", directory ?? "");
        }

        /**
         * Supprime la configuration d'un plugin
         */
        public void remove_plugin_configuration (string plugin_id) {
            _plugin_configurations.unset (plugin_id);
            save_plugin_configurations ();
        }

        /**
         * Réinitialise toutes les configurations des plugins
         */
        public void reset_all_plugin_configurations () {
            _plugin_configurations.clear ();
            save_plugin_configurations ();
        }

        // Méthodes privées

        /**
         * Charge les configurations des plugins depuis GSettings
         */
        private void load_plugin_configurations () {
            // Pour l'instant, on utilise une approche simplifiée
            // Les configurations seront chargées à la demande
        }

        /**
         * Sauvegarde les configurations des plugins dans GSettings
         */
        private void save_plugin_configurations () {
            // Pour l'instant, on utilise une approche simplifiée
            // Les configurations seront sauvegardées plus tard
        }
    }
}
