/* WysiwygEditor.vala
 *
 * Copyright 2023
 */

using Gtk;

namespace IntaText {
    public class WysiwygEditor : Gtk.TextView {
        public WysiwygEditor() {
            Object();
            // Configuration minimale pour éviter les erreurs
            this.set_editable(true);
            this.set_wrap_mode(Gtk.WrapMode.WORD);
        }

        // Méthodes de base pour éviter les erreurs de compilation
        public void set_editor_style(int size, string family, string color) {
            // Implémentation vide pour l'instant
        }

        public void load_content(string content) {
            // Implémentation vide pour l'instant
        }

        public string get_content() {
            return "";
        }
    }
}
