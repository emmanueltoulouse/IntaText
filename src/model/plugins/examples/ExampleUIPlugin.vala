/*
 * ExampleUIPlugin.vala
 * Exemple de plugin d'interface utilisateur
 * Ajoute un bouton simple dans la barre d'outils et une action de test
 */

namespace IntaText.Plugins.Examples {

    /**
     * Plugin d'exemple qui ajoute des composants UI simples
     */
    public class ExampleUIPlugin : Object, IUIPlugin {

        private PluginMetadata _metadata;
        private ApplicationController? _app_controller;
        private bool _initialized = false;

        public PluginMetadata metadata {
            get { return _metadata; }
        }

        public ExampleUIPlugin () {
            _metadata = PluginMetadata () {
                id = "example_ui_plugin",
                name = "Plugin UI d'Exemple",
                description = "Plugin de démonstration ajoutant des éléments UI",
                version = "1.0.0",
                author = "IntaText Team",
                type = PluginType.UI,
                dependencies = {},
                enabled = true
            };
        }

        public bool initialize (ApplicationController app_controller) {
            _app_controller = app_controller;
            _initialized = true;
            debug ("Plugin UI d'exemple initialisé");
            return true;
        }

        public void activate () {
            if (!_initialized) return;

            debug ("Plugin UI d'exemple activé");

            // Enregistrer nos composants UI
            var plugin_service = PluginService.instance;
            var components = get_ui_components ();

            foreach (var component in components) {
                plugin_service.add_ui_component (this, component.id);
            }
        }

        public void deactivate () {
            debug ("Plugin UI d'exemple désactivé");

            // Nettoyer nos composants UI
            var plugin_service = PluginService.instance;
            var components = get_ui_components ();

            foreach (var component in components) {
                plugin_service.remove_ui_component (component.id);
            }
        }

        public void cleanup () {
            debug ("Nettoyage du plugin UI d'exemple");
            _app_controller = null;
            _initialized = false;
        }

        // Implémentation IUIPlugin

        public UIComponentDescriptor[] get_ui_components () {
            return {
                // Bouton dans la barre d'outils
                UIComponentDescriptor () {
                    id = "example_toolbar_button",
                    type = UIComponentType.TOOLBAR_BUTTON,
                    label = "Exemple",
                    icon_name = "applications-system-symbolic",
                    tooltip = "Action d'exemple du plugin",
                    position = UIPosition.END,
                    target_id = null,
                    visible = true,
                    sensitive = true
                },

                // Élément de menu
                UIComponentDescriptor () {
                    id = "example_menu_item",
                    type = UIComponentType.MENU_ITEM,
                    label = "Action Plugin",
                    icon_name = "starred-symbolic",
                    tooltip = "Exécute une action du plugin d'exemple",
                    position = UIPosition.END,
                    target_id = "tools_menu",
                    visible = true,
                    sensitive = true
                },

                // Widget de statut
                UIComponentDescriptor () {
                    id = "example_status_widget",
                    type = UIComponentType.STATUS_WIDGET,
                    label = "Plugin OK",
                    icon_name = null,
                    tooltip = "Statut du plugin d'exemple",
                    position = UIPosition.END,
                    target_id = null,
                    visible = true,
                    sensitive = true
                }
            };
        }

        public Gtk.Widget? create_widget (string component_id, Gtk.Widget? parent = null) {
            switch (component_id) {
                case "example_toolbar_button":
                    var button = new Gtk.Button ();
                    button.set_icon_name ("applications-system-symbolic");
                    button.set_tooltip_text ("Action d'exemple du plugin");
                    button.clicked.connect (() => {
                        on_component_activated ("example_toolbar_button");
                    });
                    return button;

                case "example_menu_item":
                    var menu_item = new GLib.Menu ();
                    menu_item.append ("Action Plugin", "plugin.example_action");
                    return null; // Les éléments de menu sont gérés différemment

                case "example_status_widget":
                    var label = new Gtk.Label ("Plugin OK");
                    label.set_ellipsize (Pango.EllipsizeMode.END);
                    label.set_tooltip_text ("Statut du plugin d'exemple");
                    return label;

                default:
                    return null;
            }
        }

        public void on_component_activated (string component_id, HashTable<string, Variant>? context = null) {
            switch (component_id) {
                case "example_toolbar_button":
                case "example_menu_item":
                    execute_example_action ();
                    break;

                default:
                    debug ("Composant inconnu activé: %s", component_id);
                    break;
            }
        }

        public override string? get_keyboard_shortcut (string component_id) {
            switch (component_id) {
                case "example_toolbar_button":
                case "example_menu_item":
                    return "<Ctrl><Alt>E";
                default:
                    return null;
            }
        }

        public override void register_keyboard_shortcuts (Gtk.Application app) {
            // Enregistrer le raccourci clavier global
            const string[] accels = {"<Ctrl><Alt>E"};
            app.set_accels_for_action ("plugin.example_action", accels);
        }

        // Actions spécifiques du plugin

        private void execute_example_action () {
            debug ("Exécution de l'action d'exemple du plugin");

            var plugin_service = PluginService.instance;

            // Afficher un toast
            plugin_service.show_toast ("Plugin d'exemple activé!");

            // Afficher un message de statut
            plugin_service.show_status_message ("Action du plugin d'exemple exécutée");

            // Insérer du texte dans l'éditeur si possible
            var selection = plugin_service.get_current_selection ();
            if (selection != null && selection.length > 0) {
                plugin_service.replace_selection ("**" + selection + "**");
                plugin_service.show_status_message ("Texte sélectionné mis en gras");
            } else {
                plugin_service.insert_text_at_cursor ("Texte inséré par le plugin d'exemple!");
            }
        }
    }
}
