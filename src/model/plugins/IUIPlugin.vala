/*
 * IUIPlugin.vala
 * Interface pour les plugins d'interface utilisateur
 */

namespace IntaText.Plugins {

    /**
     * Type de composant UI
     */
    public enum UIComponentType {
        TOOLBAR_BUTTON,     // Bouton dans la barre d'outils
        MENU_ITEM,         // Élément de menu
        SIDEBAR_PANEL,     // Panneau dans la sidebar
        STATUS_WIDGET,     // Widget dans la barre de statut
        DIALOG,            // Dialogue modal
        DOCK_PANEL,        // Panneau ancrable
        EDITOR_OVERLAY     // Superposition sur l'éditeur
    }

    /**
     * Position d'un composant UI
     */
    public enum UIPosition {
        BEFORE,    // Avant les éléments existants
        AFTER,     // Après les éléments existants
        START,     // Au début
        END,       // À la fin
        REPLACE    // Remplace un élément existant
    }

    /**
     * Descripteur de composant UI
     */
    public struct UIComponentDescriptor {
        public string id;
        public UIComponentType type;
        public string label;
        public string? icon_name;
        public string? tooltip;
        public UIPosition position;
        public string? target_id;  // ID de l'élément cible pour position relative
        public bool visible;
        public bool sensitive;
    }

    /**
     * Interface pour les plugins d'interface utilisateur
     * Permet d'étendre l'interface d'IntaText avec de nouveaux composants
     */
    public interface IUIPlugin : IPlugin {

        /**
         * Composants UI fournis par ce plugin
         * @return Liste des descripteurs de composants
         */
        public abstract UIComponentDescriptor[] get_ui_components ();

        /**
         * Crée un widget pour un composant donné
         * @param component_id ID du composant
         * @param parent Widget parent (optionnel)
         * @return Widget créé ou null
         */
        public abstract Gtk.Widget? create_widget (string component_id, Gtk.Widget? parent = null);

        /**
         * Gère l'activation d'un composant UI
         * @param component_id ID du composant activé
         * @param context Contexte d'activation (document courant, sélection, etc.)
         */
        public abstract void on_component_activated (string component_id, HashTable<string, Variant>? context = null);

        /**
         * Met à jour l'état d'un composant UI
         * @param component_id ID du composant
         * @param context Contexte actuel
         * @return Nouvel état du composant
         */
        public virtual UIComponentDescriptor? update_component_state (string component_id, HashTable<string, Variant>? context = null) {
            return null;
        }

        /**
         * Configure l'apparence d'un composant
         * @param component_id ID du composant
         * @param css_classes Classes CSS à appliquer
         */
        public virtual void style_component (string component_id, string[] css_classes) {
            // Implémentation par défaut vide
        }

        /**
         * Obtient le raccourci clavier pour un composant
         * @param component_id ID du composant
         * @return Raccourci clavier ou null
         */
        public virtual string? get_keyboard_shortcut (string component_id) {
            return null;
        }

        /**
         * Enregistre les raccourcis clavier du plugin
         * @param app Application principale
         */
        public virtual void register_keyboard_shortcuts (Gtk.Application app) {
            // Implémentation par défaut vide
        }

        /**
         * Gère les événements contextuels (clic droit, etc.)
         * @param component_id ID du composant
         * @param event_type Type d'événement
         * @param context Contexte de l'événement
         * @return true si l'événement a été géré
         */
        public virtual bool handle_context_event (string component_id, string event_type, HashTable<string, Variant>? context = null) {
            return false;
        }

        /**
         * Fournit des éléments pour les menus contextuels
         * @param context Contexte du menu (position, sélection, etc.)
         * @return Liste des éléments de menu
         */
        public virtual UIComponentDescriptor[]? get_context_menu_items (HashTable<string, Variant>? context = null) {
            return null;
        }

        /**
         * Nettoie les composants UI avant désactivation
         */
        public virtual void cleanup_ui_components () {
            // Implémentation par défaut vide
        }
    }
}
