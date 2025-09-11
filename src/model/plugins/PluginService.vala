/*
 * PluginService.vala
 * Service central pour l'intégration des plugins avec le core d'IntaText
 * Fournit une API pour que les plugins accèdent aux fonctionnalités de l'application
 */

using Gee;
using IntaText.Document;

namespace IntaText.Plugins {

    /**
     * Événements disponibles pour les plugins
     */
    public enum PluginEvent {
        DOCUMENT_OPENED,
        DOCUMENT_CLOSED,
        DOCUMENT_SAVED,
        DOCUMENT_MODIFIED,
        SELECTION_CHANGED,
        EDITOR_FOCUS_IN,
        EDITOR_FOCUS_OUT,
        APPLICATION_STARTED,
        APPLICATION_CLOSING,
        PREFERENCES_CHANGED
    }

    /**
     * Contexte d'événement passé aux plugins
     */
    public class EventContext : Object {
        public string event_name { get; set; }
        public HashTable<string, string> data { get; set; }
        public bool handled { get; set; default = false; }

        public EventContext (string event_name) {
            this.event_name = event_name;
            this.data = new HashTable<string, string> (str_hash, str_equal);
        }

        public void set_string (string key, string value) {
            data.set (key, value);
        }

        public void set_int (string key, int value) {
            data.set (key, value.to_string ());
        }

        public void set_boolean (string key, bool value) {
            data.set (key, value.to_string ());
        }

        public string? get_string (string key) {
            return data.get (key);
        }

        public int get_int (string key, int default_value = 0) {
            var str_value = data.get (key);
            return str_value != null ? int.parse (str_value) : default_value;
        }

        public bool get_boolean (string key, bool default_value = false) {
            var str_value = data.get (key);
            return str_value != null ? bool.parse (str_value) : default_value;
        }
    }

    /**
     * Interface pour les handlers d'événements de plugins
     */
    public interface EventHandler : Object {
        public abstract void handle_event (EventContext context);
    }

    /**
     * Service central d'intégration des plugins
     */
    public class PluginService : Object {

        // Singleton
        private static PluginService? _instance = null;
        public static PluginService instance {
            get {
                if (_instance == null) {
                    _instance = new PluginService ();
                }
                return _instance;
            }
        }

        private ApplicationController? _app_controller;
        private HashMap<string, ArrayList<EventHandler>> _event_handlers;

        private PluginService () {
            _event_handlers = new HashMap<string, ArrayList<EventHandler>> ();
        }

        /**
         * Initialise le service avec le contrôleur d'application
         */
        public void initialize (ApplicationController app_controller) {
            _app_controller = app_controller;
        }

        /**
         * Enregistre un handler d'événement pour un plugin
         */
        public void register_event_handler (string event_name, EventHandler handler) {
            if (!_event_handlers.has_key (event_name)) {
                _event_handlers.set (event_name, new ArrayList<EventHandler> ());
            }
            _event_handlers.get (event_name).add (handler);
        }

        /**
         * Désenregistre un handler d'événement
         */
        public void unregister_event_handler (string event_name, EventHandler handler) {
            if (_event_handlers.has_key (event_name)) {
                _event_handlers.get (event_name).remove (handler);
            }
        }

        /**
         * Déclenche un événement pour tous les plugins intéressés
         */
        public EventContext trigger_event (string event_name, HashTable<string, string>? data = null) {
            var context = new EventContext (event_name);

            if (data != null) {
                data.foreach ((key, value) => {
                    context.data.set (key, value);
                });
            }

            if (_event_handlers.has_key (event_name)) {
                foreach (var handler in _event_handlers.get (event_name)) {
                    handler.handle_event (context);
                    if (context.handled) {
                        break; // Si un plugin a géré l'événement, on s'arrête
                    }
                }
            }

            return context;
        }

        // API d'accès aux fonctionnalités pour les plugins
        // (Certaines méthodes sont commentées en attendant leur implémentation dans MainWindow)

        /**
         * Obtient le document actuellement ouvert
         */
        public PivotDocument? get_current_document () {
            if (_app_controller == null) return null;

            var main_window = _app_controller.get_main_window ();
            if (main_window == null) return null;

            // TODO: Implémenter get_current_document dans MainWindow
            // return main_window.get_current_document ();
            return null;
        }

        /**
         * Obtient la sélection actuelle dans l'éditeur
         */
        public string? get_current_selection () {
            if (_app_controller == null) return null;

            var main_window = _app_controller.get_main_window ();
            if (main_window == null) return null;

            // TODO: Implémenter get_selected_text dans MainWindow
            // return main_window.get_selected_text ();
            return null;
        }

        /**
         * Insère du texte à la position du curseur
         */
        public bool insert_text_at_cursor (string text) {
            if (_app_controller == null) return false;

            var main_window = _app_controller.get_main_window ();
            if (main_window == null) return false;

            // TODO: Implémenter insert_text_at_cursor dans MainWindow
            // main_window.insert_text_at_cursor (text);
            return false;
        }

        /**
         * Remplace la sélection actuelle
         */
        public bool replace_selection (string new_text) {
            if (_app_controller == null) return false;

            var main_window = _app_controller.get_main_window ();
            if (main_window == null) return false;

            // TODO: Implémenter replace_selected_text dans MainWindow
            // main_window.replace_selected_text (new_text);
            return false;
        }

        /**
         * Ouvre un fichier dans l'éditeur
         */
        public bool open_file (string file_path) {
            if (_app_controller == null) return false;

            var main_window = _app_controller.get_main_window ();
            if (main_window == null) return false;

            // TODO: Implémenter open_file dans MainWindow
            // main_window.open_file (file_path);
            return false;
        }

        /**
         * Sauvegarde le document actuel
         */
        public bool save_current_document () {
            if (_app_controller == null) return false;

            var main_window = _app_controller.get_main_window ();
            if (main_window == null) return false;

            // TODO: Vérifier la visibilité de save_current_document dans MainWindow
            // main_window.save_current_document ();
            return false;
        }

        /**
         * Affiche un message dans la barre de statut
         */
        public void show_status_message (string message) {
            if (_app_controller == null) return;

            var main_window = _app_controller.get_main_window ();
            if (main_window == null) return;

            // TODO: Implémenter show_status_message dans MainWindow
            // main_window.show_status_message (message);
            debug ("Status message: %s", message);
        }

        /**
         * Affiche une notification toast
         */
        public void show_toast (string message) {
            if (_app_controller == null) return;

            var main_window = _app_controller.get_main_window ();
            if (main_window == null) return;

            // TODO: Implémenter show_toast dans MainWindow
            // main_window.show_toast (message);
            debug ("Toast message: %s", message);
        }

        /**
         * Obtient les préférences de l'application
         */
        public ConfigManager? get_config_manager () {
            return _app_controller?.get_config_manager ();
        }

        /**
         * Enregistre un nouveau format de fichier
         */
        public void register_file_format (IFormatPlugin format_plugin) {
            // TODO: Implémenter add_file_format dans MainWindow
            debug ("Format plugin registered: %s", format_plugin.metadata.id);
        }

        /**
         * Désenregistre un format de fichier
         */
        public void unregister_file_format (IFormatPlugin format_plugin) {
            // TODO: Implémenter remove_file_format dans MainWindow
            debug ("Format plugin unregistered: %s", format_plugin.metadata.id);
        }

        /**
         * Ajoute un composant UI à l'interface
         */
        public bool add_ui_component (IUIPlugin ui_plugin, string component_id) {
            // TODO: Implémenter add_plugin_ui_component dans MainWindow
            debug ("UI component added: %s", component_id);
            return false;
        }

        /**
         * Supprime un composant UI de l'interface
         */
        public bool remove_ui_component (string component_id) {
            // TODO: Implémenter remove_plugin_ui_component dans MainWindow
            debug ("UI component removed: %s", component_id);
            return false;
        }

        /**
         * Exécute une commande de menu
         */
        public bool execute_menu_action (string action_name, Variant? parameter = null) {
            if (_app_controller == null) return false;

            var main_window = _app_controller.get_main_window ();
            if (main_window == null) return false;

            var action = main_window.lookup_action (action_name);
            if (action != null) {
                action.activate (parameter);
                return true;
            }
            return false;
        }

        /**
         * Obtient la liste des documents ouverts
         */
        public string[] get_open_documents () {
            // TODO: Implémenter get_open_documents dans MainWindow
            return {};
        }
    }
}
