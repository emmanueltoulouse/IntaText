/*
 * PluginManager.vala
 * Gestionnaire central des plugins d'IntaText
 * Gère la découverte, le chargement, l'activation et le cycle de vie des plugins
 */

using Gee;

namespace IntaText.Plugins {

    /**
     * États d'un plugin
     */
    public enum PluginState {
        DISCOVERED,    // Plugin découvert mais non chargé
        LOADED,        // Plugin chargé en mémoire
        ACTIVE,        // Plugin activé et fonctionnel
        INACTIVE,      // Plugin chargé mais inactif
        ERROR          // Plugin en erreur
    }

    /**
     * Informations sur un plugin chargé
     */
    public class PluginInfo : Object {
        public IPlugin plugin { get; set; }
        public PluginState state { get; set; }
        public string file_path { get; set; }
        public DateTime? last_loaded { get; set; }
        public string? error_message { get; set; }

        public PluginInfo (IPlugin plugin, string file_path) {
            this.plugin = plugin;
            this.file_path = file_path;
            this.state = PluginState.LOADED;
            this.last_loaded = new DateTime.now_local ();
        }
    }

    /**
     * Gestionnaire central des plugins
     */
    public class PluginManager : Object {

        // Singleton
        private static PluginManager? _instance = null;
        public static PluginManager instance {
            get {
                if (_instance == null) {
                    _instance = new PluginManager ();
                }
                return _instance;
            }
        }

        // Collections des plugins
        private HashMap<string, PluginInfo> _plugins;
        private ArrayList<string> _plugin_directories;
        private ApplicationController? _app_controller;

        // Signaux
        public signal void plugin_loaded (string plugin_id, IPlugin plugin);
        public signal void plugin_activated (string plugin_id, IPlugin plugin);
        public signal void plugin_deactivated (string plugin_id, IPlugin plugin);
        public signal void plugin_error (string plugin_id, string error_message);

        private PluginManager () {
            _plugins = new HashMap<string, PluginInfo> ();
            _plugin_directories = new ArrayList<string> ();

            // Ajouter les répertoires de plugins par défaut
            add_plugin_directory (get_user_plugins_directory ());
            add_plugin_directory (get_system_plugins_directory ());
        }

        /**
         * Initialise le gestionnaire avec le contrôleur d'application
         */
        public void initialize (ApplicationController app_controller) {
            _app_controller = app_controller;
        }

        /**
         * Ajoute un répertoire de recherche de plugins
         */
        public void add_plugin_directory (string directory) {
            if (!_plugin_directories.contains (directory)) {
                _plugin_directories.add (directory);
            }
        }

        /**
         * Découvre tous les plugins dans les répertoires configurés
         */
        public async void discover_plugins () {
            foreach (var directory in _plugin_directories) {
                yield discover_plugins_in_directory (directory);
            }
        }

        /**
         * Découvre les plugins dans un répertoire spécifique
         */
        private async void discover_plugins_in_directory (string directory) {
            try {
                var dir = File.new_for_path (directory);
                if (!dir.query_exists ()) {
                    return;
                }

                var enumerator = yield dir.enumerate_children_async (
                    FileAttribute.STANDARD_NAME + "," + FileAttribute.STANDARD_TYPE,
                    FileQueryInfoFlags.NONE
                );

                FileInfo? file_info;
                while ((file_info = enumerator.next_file ()) != null) {
                    var name = file_info.get_name ();
                    if (name.has_suffix (".plugin")) {
                        var plugin_path = Path.build_filename (directory, name);
                        yield try_load_plugin_from_metadata (plugin_path);
                    }
                }
            } catch (Error e) {
                warning ("Erreur lors de la découverte des plugins dans %s: %s", directory, e.message);
            }
        }

        /**
         * Charge un plugin depuis un fichier de métadonnées .plugin
         */
        public async bool try_load_plugin_from_metadata (string metadata_file) {
            try {
                var metadata = PluginMetadataReader.read_metadata (metadata_file);
                if (metadata == null) {
                    return false;
                }

                // Vérifier si le plugin est déjà chargé
                if (_plugins.has_key (metadata.id)) {
                    return true;
                }

                // Vérifier la compatibilité
                if (!metadata.enabled) {
                    debug ("Plugin %s désactivé", metadata.id);
                    return false;
                }

                // Chercher le fichier .so correspondant
                var plugin_dir = Path.get_dirname (metadata_file);
                var so_file = Path.build_filename (plugin_dir, metadata.id + ".so");

                if (!File.new_for_path (so_file).query_exists ()) {
                    warning ("Fichier plugin %s introuvable pour %s", so_file, metadata.id);
                    return false;
                }

                // Créer une instance de plugin
                IPlugin? plugin = yield create_plugin_instance_with_metadata (so_file, metadata);
                if (plugin == null) {
                    return false;
                }

                var plugin_info = new PluginInfo (plugin, so_file);
                plugin_info.state = PluginState.DISCOVERED;
                _plugins.set (metadata.id, plugin_info);

                plugin_loaded (metadata.id, plugin);
                return true;

            } catch (Error e) {
                warning ("Erreur lors du chargement du plugin %s: %s", metadata_file, e.message);
                plugin_error (get_plugin_id_from_metadata_path (metadata_file), e.message);
                return false;
            }
        }

        /**
         * Tente de charger un plugin depuis un fichier
         */
        public async bool try_load_plugin (string file_path) {
            try {
                // Pour l'instant, on simule le chargement dynamique
                // Dans une vraie implémentation, on utiliserait Module.open()

                // Vérifier si le plugin est déjà chargé
                var plugin_id = get_plugin_id_from_path (file_path);
                if (_plugins.has_key (plugin_id)) {
                    return true;
                }

                // Créer une instance de plugin factice pour les tests
                // TODO: Implémenter le vrai chargement dynamique
                IPlugin? plugin = null; // yield create_plugin_instance_with_metadata (file_path, metadata);
                if (plugin == null) {
                    return false;
                }

                var plugin_info = new PluginInfo (plugin, file_path);
                _plugins.set (plugin_id, plugin_info);

                plugin_loaded (plugin_id, plugin);
                return true;

            } catch (Error e) {
                warning ("Erreur lors du chargement du plugin %s: %s", file_path, e.message);
                plugin_error (get_plugin_id_from_path (file_path), e.message);
                return false;
            }
        }

        /**
         * Crée une instance de plugin avec métadonnées
         */
        private async IPlugin? create_plugin_instance_with_metadata (string so_file, PluginMetadata metadata) {
            // Ici on devrait utiliser Module.open() et Module.symbol()
            // pour charger dynamiquement le plugin depuis la bibliothèque partagée

            // Pour l'instant, on crée un plugin factice basé sur le type
            return create_mock_plugin (metadata);
        }

        /**
         * Crée un plugin factice pour les tests (à remplacer par le chargement dynamique)
         */
        private IPlugin? create_mock_plugin (PluginMetadata metadata) {
            // Cette méthode sera remplacée par le vrai chargement de plugin
            // Pour l'instant, on retourne null
            return null;
        }

        // Méthodes utilitaires privées

        private string get_plugin_id_from_path (string file_path) {
            return Path.get_basename (file_path).replace (".so", "").replace (".plugin", "");
        }

        private string get_plugin_id_from_metadata_path (string metadata_file) {
            return Path.get_basename (metadata_file).replace (".plugin", "");
        }

        /**
         * Active un plugin
         */
        public bool activate_plugin (string plugin_id) {
            var plugin_info = _plugins.get (plugin_id);
            if (plugin_info == null) {
                warning ("Plugin %s non trouvé", plugin_id);
                return false;
            }

            if (plugin_info.state == PluginState.ACTIVE) {
                return true; // Déjà actif
            }

            try {
                if (_app_controller != null && plugin_info.plugin.initialize (_app_controller)) {
                    plugin_info.plugin.activate ();
                    plugin_info.state = PluginState.ACTIVE;
                    plugin_activated (plugin_id, plugin_info.plugin);
                    return true;
                } else {
                    plugin_info.state = PluginState.ERROR;
                    plugin_info.error_message = "Échec de l'initialisation";
                    plugin_error (plugin_id, "Échec de l'initialisation du plugin");
                    return false;
                }
            } catch (Error e) {
                plugin_info.state = PluginState.ERROR;
                plugin_info.error_message = e.message;
                plugin_error (plugin_id, e.message);
                return false;
            }
        }

        /**
         * Désactive un plugin
         */
        public bool deactivate_plugin (string plugin_id) {
            var plugin_info = _plugins.get (plugin_id);
            if (plugin_info == null) {
                return false;
            }

            if (plugin_info.state != PluginState.ACTIVE) {
                return true; // Déjà inactif
            }

            try {
                plugin_info.plugin.deactivate ();
                plugin_info.state = PluginState.INACTIVE;
                plugin_deactivated (plugin_id, plugin_info.plugin);
                return true;
            } catch (Error e) {
                warning ("Erreur lors de la désactivation du plugin %s: %s", plugin_id, e.message);
                return false;
            }
        }

        /**
         * Décharge un plugin de la mémoire
         */
        public bool unload_plugin (string plugin_id) {
            var plugin_info = _plugins.get (plugin_id);
            if (plugin_info == null) {
                return false;
            }

            // Désactiver d'abord si nécessaire
            if (plugin_info.state == PluginState.ACTIVE) {
                deactivate_plugin (plugin_id);
            }

            try {
                plugin_info.plugin.cleanup ();
                _plugins.unset (plugin_id);
                return true;
            } catch (Error e) {
                warning ("Erreur lors du déchargement du plugin %s: %s", plugin_id, e.message);
                return false;
            }
        }

        /**
         * Obtient la liste de tous les plugins chargés
         */
        public Gee.Collection<string> get_plugin_ids () {
            return _plugins.keys;
        }

        /**
         * Obtient les informations d'un plugin
         */
        public PluginInfo? get_plugin_info (string plugin_id) {
            return _plugins.get (plugin_id);
        }

        /**
         * Obtient un plugin par son ID
         */
        public IPlugin? get_plugin (string plugin_id) {
            var info = _plugins.get (plugin_id);
            return info?.plugin;
        }

        /**
         * Obtient tous les plugins d'un type donné
         */
        public ArrayList<IPlugin> get_plugins_by_type (PluginType type) {
            var result = new ArrayList<IPlugin> ();
            foreach (var plugin_info in _plugins.values) {
                if (plugin_info.plugin.metadata.type == type && plugin_info.state == PluginState.ACTIVE) {
                    result.add (plugin_info.plugin);
                }
            }
            return result;
        }

        /**
         * Rechargement à chaud d'un plugin
         */
        public async bool reload_plugin (string plugin_id) {
            var plugin_info = _plugins.get (plugin_id);
            if (plugin_info == null) {
                return false;
            }

            var file_path = plugin_info.file_path;
            unload_plugin (plugin_id);
            return yield try_load_plugin (file_path);
        }

        /**
         * Nettoyage global
         */
        public void cleanup () {
            foreach (var plugin_id in get_plugin_ids ().to_array ()) {
                unload_plugin (plugin_id);
            }
            _plugins.clear ();
        }

        // Méthodes utilitaires privées

        private string get_user_plugins_directory () {
            return Path.build_filename (Environment.get_user_data_dir (), "intatext", "plugins");
        }

        private string get_system_plugins_directory () {
            return Path.build_filename ("/usr", "lib", "intatext", "plugins");
        }

        /**
         * Crée les répertoires de plugins s'ils n'existent pas
         */
        public void ensure_plugin_directories () {
            var user_dir = get_user_plugins_directory ();
            var user_dir_file = File.new_for_path (user_dir);
            if (!user_dir_file.query_exists ()) {
                try {
                    user_dir_file.make_directory_with_parents ();
                } catch (Error e) {
                    warning ("Impossible de créer le répertoire utilisateur de plugins: %s", e.message);
                }
            }
        }
    }
}
