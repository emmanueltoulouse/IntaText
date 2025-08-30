/* EditorView.vala
 *
 * Copyright 2023
 */

using Gtk;
using IntaText.Document;

namespace IntaText {
    public class EditorView : Gtk.Box {
        private ApplicationController controller;
        public PivotDocument? current_document;
        private WysiwygEditor wysiwyg_editor;
        private bool _has_unsaved_changes = false;

        public bool has_unsaved_changes {
            get { return _has_unsaved_changes; }
            set {
                if (_has_unsaved_changes != value) {
                    _has_unsaved_changes = value;
                    save_state_changed();
                }
            }
        }

        // Notifie les changements d'état de sauvegarde
        private void save_state_changed() {
            // Implémentation vide pour l'instant
        }

        public EditorView(ApplicationController controller) {
            Object(orientation: Orientation.VERTICAL, spacing: 6);
            this.controller = controller;

            // Version minimale pour déboguer l'erreur GTK
            var label = new Gtk.Label("Editor View (Minimal)");
            this.append(label);
        }

        // === MÉTHODES DE LA CLASSE ===

        public void set_editor_style(int size, string family, string color) {
            // Implémentation vide pour l'instant
        }

        public enum DocumentSource {
            UNKNOWN,
            EXPLORER,
            FILE_DIALOG
        }

        public void set_document_source(DocumentSource source) {
            // Implémentation vide pour l'instant
        }

        public void set_current_file_path(string path) {
            // Implémentation vide pour l'instant
        }

        public void load_document(PivotDocument document) {
            // Implémentation vide pour l'instant
        }

        public bool save_document(string? path = null) {
            return false;
        }

        public async bool save_document_as() {
            return false;
        }
    }
}
