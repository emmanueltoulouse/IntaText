using IntaText.Plugins;

namespace IntaText.Examples.Plugins {
    /**
     * Plugin d'exemple "Hello World" qui démontre l'utilisation
     * de l'architecture de plugins d'IntaText
     */
    public class HelloWorldPlugin : Object, IPlugin, IUIPlugin {
        private PluginService? plugin_service;
        private Gtk.Button? hello_button;
        private bool is_activated = false;

        public PluginMetadata get_metadata() {
            return PluginMetadata() {
                id = "hello-world",
                name = "Hello World",
                version = "1.0.0",
                description = "Plugin d'exemple qui affiche Hello World",
                author = "IntaText Team",
                plugin_type = PluginType.UI,
                min_intatext_version = "1.0.0",
                dependencies = new string[0]
            };
        }

        public bool initialize(PluginService service) {
            debug("HelloWorldPlugin: Initialisation...");
            this.plugin_service = service;
            return true;
        }

        public bool activate() {
            debug("HelloWorldPlugin: Activation...");
            if (is_activated) return true;

            // Créer le bouton
            hello_button = new Gtk.Button.with_label("Hello World!");
            hello_button.clicked.connect(() => {
                debug("HelloWorldPlugin: Bouton cliqué!");
                // Ici on pourrait utiliser plugin_service pour afficher une notification
                print("Hello World depuis le plugin!\n");
            });

            is_activated = true;
            return true;
        }

        public bool deactivate() {
            debug("HelloWorldPlugin: Désactivation...");
            if (!is_activated) return true;

            // Nettoyer les ressources
            if (hello_button != null) {
                hello_button.destroy();
                hello_button = null;
            }

            is_activated = false;
            return true;
        }

        public void cleanup() {
            debug("HelloWorldPlugin: Nettoyage...");
            deactivate();
        }

        public bool is_compatible(string intatext_version) {
            // Version simple : accepter toutes les versions
            return true;
        }

        public HashTable<string,string>? get_settings() {
            var settings = new HashTable<string,string>(str_hash, str_equal);
            settings.insert("enabled", "true");
            settings.insert("show_notifications", "true");
            return settings;
        }

        public void apply_settings(HashTable<string,string> settings) {
            debug("HelloWorldPlugin: Application des paramètres...");
            // Appliquer les paramètres du plugin
        }

        // Implémentation IUIPlugin
        public Gtk.Widget? create_toolbar_button() {
            return hello_button;
        }

        public Gtk.Widget? create_menu_item() {
            var menu_item = new Gtk.Button.with_label("Hello World");
            menu_item.clicked.connect(() => {
                print("Hello World depuis le menu!\n");
            });
            return menu_item;
        }

        public Gtk.Widget? create_sidebar_widget() {
            var widget = new Gtk.Box(Gtk.Orientation.VERTICAL, 6);
            var label = new Gtk.Label("Hello World Plugin");
            var button = new Gtk.Button.with_label("Dire Bonjour");

            button.clicked.connect(() => {
                label.set_text("Bonjour depuis le plugin!");
            });

            widget.append(label);
            widget.append(button);
            return widget;
        }

        public Gtk.Widget? create_status_widget() {
            return new Gtk.Label("Hello World actif");
        }

        public Gtk.Popover? create_panel() {
            var popover = new Gtk.Popover();
            var content = new Gtk.Box(Gtk.Orientation.VERTICAL, 12);

            var title = new Gtk.Label("Hello World Panel");
            title.add_css_class("title-4");

            var description = new Gtk.Label("Ceci est un panneau d'exemple créé par le plugin Hello World.");
            description.set_wrap(true);

            var action_button = new Gtk.Button.with_label("Action du Plugin");
            action_button.clicked.connect(() => {
                print("Action exécutée depuis le panneau!\n");
                popover.popdown();
            });

            content.append(title);
            content.append(description);
            content.append(action_button);

            popover.set_child(content);
            return popover;
        }

        // Méthodes optionnelles d'IUIPlugin avec implémentation par défaut
        public void update_component_state(string component_id, HashTable<string,string> context) {
            // Mettre à jour l'état des composants UI si nécessaire
        }

        public void style_component(Gtk.Widget component, string[] css_classes) {
            // Appliquer des styles CSS aux composants
            foreach (string css_class in css_classes) {
                component.add_css_class(css_class);
            }
        }

        public string? get_keyboard_shortcut(string action) {
            if (action == "hello_world") {
                return "<Control><Shift>h";
            }
            return null;
        }

        public void register_keyboard_shortcuts(Gtk.Application app) {
            // Enregistrer les raccourcis clavier si nécessaire
            debug("HelloWorldPlugin: Enregistrement des raccourcis clavier...");
        }

        public bool handle_context_event(string event_name, HashTable<string,string> context) {
            if (event_name == "document_changed") {
                debug("HelloWorldPlugin: Document changé");
                return true;
            }
            return false;
        }

        public Gtk.Widget[]? get_context_menu_items(HashTable<string,string> context) {
            var menu_item = new Gtk.Button.with_label("Hello World Context");
            menu_item.clicked.connect(() => {
                print("Hello World depuis le menu contextuel!\n");
            });
            return new Gtk.Widget[] { menu_item };
        }

        public void cleanup_ui_components() {
            debug("HelloWorldPlugin: Nettoyage des composants UI...");
            deactivate();
        }
    }
}

// Point d'entrée pour le chargement dynamique du plugin
public Type plugin_get_type() {
    return typeof(IntaText.Examples.Plugins.HelloWorldPlugin);
}

public IntaText.Plugins.IPlugin plugin_create_instance() {
    return new IntaText.Examples.Plugins.HelloWorldPlugin();
}
