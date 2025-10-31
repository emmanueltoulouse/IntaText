/*
 * PluginManager.vala
 * Gestionnaire central des plugins d'IntaText
 * Gère la découverte, le chargement, l'activation et le cycle de vie des plugins
 */

using Gee;

namespace IntaText.Plugins {

    /**
     * Type de fonction d'initialisation de plugin
     * Chaque plugin doit exporter une fonction plugin_init qui retourne le Type du plugin
     */
    [CCode (has_target = false)]
    public delegate Type PluginInitFunc ();

    /**
     * Adaptateur pour les plugins qui n'implémentent pas IPlugin
     */
    public class PluginAdapter : Object, IPlugin {
        private Object plugin_obj;
        private PluginMetadata _metadata;
        private unowned Module? plugin_module;

        public PluginAdapter (Object obj, PluginMetadata metadata, Module? module = null) {
            this.plugin_obj = obj;
            this._metadata = metadata;
            this.plugin_module = module;
        }

        public PluginMetadata get_metadata () {
            return _metadata;
        }

        public bool initialize (ApplicationController app_controller) {
            // Obtenir le nom du type pour construire le nom de la fonction C
            var type_name = plugin_obj.get_type ().name ();
            
            // Convertir CamelCase en snake_case et ajouter le nom de la méthode
            // HelloWorldPlugin -> hello_world_plugin_initialize
            string func_name = to_snake_case (type_name) + "_initialize";
            
            if (plugin_module != null) {
                void* function;
                if (plugin_module.symbol (func_name, out function)) {
                    // Type de la fonction: gboolean (*)(HelloWorldPlugin*, GObject*)
                    PluginInitializeFunc init_func = (PluginInitializeFunc) function;
                    bool result = init_func (plugin_obj, app_controller);
                    return result;
                }
            }
            
            // Fallback: retourner true
            return true;
        }

        private string to_snake_case (string camel) {
            var result = new StringBuilder ();
            for (int i = 0; i < camel.length; i++) {
                char c = camel[i];
                if (c.isupper () && i > 0) {
                    result.append_c ('_');
                }
                result.append_c (c.tolower ());
            }
            return result.str;
        }

        public void activate () {
            call_void_method ("activate");
        }

        public void deactivate () {
            call_void_method ("deactivate");
        }

        public void cleanup () {
            call_void_method ("cleanup");
        }

        private void call_void_method (string method_name) {
            if (plugin_module == null) return;
            
            var type_name = plugin_obj.get_type ().name ();
            string func_name = to_snake_case (type_name) + "_" + method_name;
            
            void* function;
            if (plugin_module.symbol (func_name, out function)) {
                PluginVoidFunc void_func = (PluginVoidFunc) function;
                void_func (plugin_obj);
            }
        }
    }

    [CCode (has_target = false)]
    private delegate bool PluginInitializeFunc (Object plugin, Object controller);
    
    [CCode (has_target = false)]
    private delegate void PluginVoidFunc (Object plugin);

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
    public IPlugin plugin { get; private set; }
        public PluginState state { get; set; }
        public string file_path { get; set; }
        public DateTime? last_loaded { get; set; }
        public string? error_message { get; set; }
        public PluginMetadata metadata { get; private set; }

        public PluginInfo (IPlugin plugin, string file_path, PluginMetadata metadata) {
            this.plugin = plugin;
            this.file_path = file_path;
            this.state = PluginState.LOADED;
            this.last_loaded = new DateTime.now_local ();
            this.metadata = metadata;
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
            // Préparer le service d'intégration pour les plugins dynamiques
            PluginService.instance.initialize (app_controller);
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
                    debug ("PluginManager: directory %s does not exist", directory);
                    return;
                }

                debug ("PluginManager: scanning directory %s", directory);

                var enumerator = yield dir.enumerate_children_async (
                    FileAttribute.STANDARD_NAME + "," + FileAttribute.STANDARD_TYPE,
                    FileQueryInfoFlags.NONE
                );

                FileInfo? file_info;
                while ((file_info = enumerator.next_file ()) != null) {
                    var name = file_info.get_name ();

                    if (file_info.get_file_type () == FileType.DIRECTORY) {
                        var subdir = Path.build_filename (directory, name);
                        debug ("PluginManager: descending into %s", subdir);
                        yield discover_plugins_in_directory (subdir);
                        continue;
                    }

                    if (name.has_suffix (".plugin")) {
                        var plugin_path = Path.build_filename (directory, name);
                        debug ("PluginManager: found metadata %s", plugin_path);
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
                    debug ("PluginManager: échec de création de %s", metadata.id);
                    return false;
                }

                var instance_metadata = metadata;
                var provided_metadata = plugin.get_metadata ();

                if (provided_metadata.id != null && provided_metadata.id.length > 0) {
                    instance_metadata = provided_metadata;
                }

                if (instance_metadata.id == null || instance_metadata.id.length == 0) {
                    instance_metadata.id = metadata.id;
                }

                instance_metadata.enabled = metadata.enabled;

                var plugin_info = new PluginInfo (plugin, so_file, instance_metadata);
                plugin_info.state = PluginState.DISCOVERED;
                _plugins.set (metadata.id, plugin_info);

                debug ("PluginManager: plugin %s chargé depuis %s", metadata.id, so_file);

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

                var plugin_info = new PluginInfo (plugin, file_path, plugin.get_metadata ());
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
            if (!Module.supported ()) {
                warning ("Les modules dynamiques ne sont pas supportés sur cette plateforme");
                return null;
            }

            Module module = Module.open (so_file, ModuleFlags.BIND_LAZY);
            if (module == null) {
                warning ("Impossible de charger le module %s : %s", so_file, Module.error ());
                return null;
            }

            void* function;
            if (!module.symbol ("plugin_init", out function)) {
                warning ("Le module %s n'exporte pas de fonction plugin_init", so_file);
                return null;
            }

            PluginInitFunc plugin_init = (PluginInitFunc) function;
            Type plugin_type = plugin_init ();

            if (plugin_type == Type.INVALID) {
                warning ("Le module %s a retourné un type invalide", so_file);
                return null;
            }

            // Accepter n'importe quel type d'Object, pas seulement IPlugin
            if (!plugin_type.is_a (typeof (Object))) {
                warning ("Le module %s n'a pas retourné un type Object", so_file);
                return null;
            }

            // Si c'est un IPlugin, l'utiliser directement
            if (plugin_type.is_a (typeof (IPlugin))) {
                IPlugin? plugin = (IPlugin?) Object.new (plugin_type);
                if (plugin == null) {
                    warning ("Échec de l'instanciation du plugin depuis %s", so_file);
                    return null;
                }
                module.make_resident ();
                return plugin;
            }

            // Sinon, créer un wrapper qui adapte l'objet à l'interface IPlugin
            Object plugin_obj = Object.new (plugin_type);
            if (plugin_obj == null) {
                warning ("Échec de l'instanciation de l'objet plugin depuis %s", so_file);
                return null;
            }

            // Créer un adaptateur avec le module pour pouvoir appeler les fonctions
            var adapter = new PluginAdapter (plugin_obj, metadata, module);
            module.make_resident ();
            return adapter;
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

            if (_app_controller == null) {
                plugin_info.state = PluginState.ERROR;
                plugin_info.error_message = "Contrôleur d'application non initialisé";
                warning ("Plugin %s: Activation impossible, contrôleur nul", plugin_id);
                plugin_error (plugin_id, plugin_info.error_message);
                return false;
            }

            bool initialized = false;

            try {
                initialized = plugin_info.plugin.initialize (_app_controller);
                debug ("Plugin %s: initialize() a retourné %s", plugin_id, initialized.to_string());
            } catch (Error e) {
                plugin_info.state = PluginState.ERROR;
                plugin_info.error_message = e.message;
                warning ("Plugin %s: Exception pendant initialize(): %s", plugin_id, e.message);
                plugin_error (plugin_id, e.message);
                return false;
            }

            if (!initialized) {
                plugin_info.state = PluginState.ERROR;
                plugin_info.error_message = "initialize() a retourné false";
                warning ("Plugin %s: initialize() a retourné false", plugin_id);
                plugin_error (plugin_id, plugin_info.error_message);
                return false;
            }

            try {
                plugin_info.plugin.activate ();
            } catch (Error e) {
                plugin_info.state = PluginState.ERROR;
                plugin_info.error_message = e.message;
                warning ("Plugin %s: Exception pendant activate(): %s", plugin_id, e.message);
                plugin_error (plugin_id, e.message);
                return false;
            }

            plugin_info.state = PluginState.ACTIVE;
            plugin_info.error_message = null;
            plugin_activated (plugin_id, plugin_info.plugin);
            return true;
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
                if (plugin_info.metadata.type == type && plugin_info.state == PluginState.ACTIVE) {
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
