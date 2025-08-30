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
    private WysiwygEditor? wysiwyg_editor;
        private bool _has_unsaved_changes = false;
    private string _current_file_path = "";

    private DocumentSource _source = DocumentSource.UNKNOWN;

        public bool has_unsaved_changes {
            get { return _has_unsaved_changes; }
            set {
                if (_has_unsaved_changes != value) {
                    _has_unsaved_changes = value;
                    save_state_changed();
                }
            }
        }

    // Signale les changements de position du curseur (1-based pour l'affichage)
    public signal void cursor_position_changed(int line, int column);

        // Notifie les changements d'état de sauvegarde
        private void save_state_changed() {
            // Notifier les observateurs pour la mise à jour des onglets
            this.notify_property("has-unsaved-changes");
        }

        public EditorView(ApplicationController controller) {
            Object(orientation: Orientation.VERTICAL, spacing: 6);
            this.controller = controller;
            // Initialiser immédiatement l'UI afin que load_document
            // fonctionne aussi pour les onglets créés non encore réalisés.
            initialize_ui();
        }

        private void initialize_ui() {
            // Éviter toute double initialisation si appelée plusieurs fois
            if (this.get_first_child() != null) {
                return;
            }
            // Barre d'icônes de formatage
            var format_bar = new Gtk.Box(Orientation.HORIZONTAL, 6);
            format_bar.add_css_class("toolbar");

            Gtk.Button make_btn(string icon_name, string tooltip) {
                var btn = new Gtk.Button();
                var img = new Gtk.Image.from_icon_name(icon_name);
                btn.set_child(img);
                btn.set_tooltip_text(tooltip);
                btn.add_css_class("flat");
                return btn;
            }

            var btn_bold = make_btn("format-text-bold-symbolic", _("Gras"));
            var btn_italic = make_btn("format-text-italic-symbolic", _("Italique"));
            var btn_underline = make_btn("format-text-underline-symbolic", _("Souligné"));
            var btn_strike = make_btn("format-text-strikethrough-symbolic", _("Barré"));

            format_bar.append(btn_bold);
            format_bar.append(btn_italic);
            format_bar.append(btn_underline);
            format_bar.append(btn_strike);

            this.append(format_bar);

            // Zone d'édition scrollable minimale
            var scroll = new Gtk.ScrolledWindow();
            scroll.set_vexpand(true);
            scroll.set_hexpand(true);
            wysiwyg_editor = new WysiwygEditor();
            // Connexions boutons => actions d'édition
            btn_bold.clicked.connect(() => {
                if (wysiwyg_editor != null) wysiwyg_editor.apply_bold();
            });
            btn_italic.clicked.connect(() => {
                if (wysiwyg_editor != null) wysiwyg_editor.apply_italic();
            });
            btn_underline.clicked.connect(() => {
                if (wysiwyg_editor != null) wysiwyg_editor.apply_format(IntaText.Document.TextFormatting.UNDERLINE);
            });
            btn_strike.clicked.connect(() => {
                if (wysiwyg_editor != null) wysiwyg_editor.apply_format(IntaText.Document.TextFormatting.STRIKETHROUGH);
            });
            // Détection des modifications
            var buf = wysiwyg_editor.get_buffer();
            buf.changed.connect(() => {
                has_unsaved_changes = true;
            });
            // Suivre la position du curseur
            buf.notify["cursor-position"].connect(() => {
                emit_cursor_position();
            });
            buf.mark_set.connect((iter, mark) => {
                emit_cursor_position();
            });
            scroll.set_child(wysiwyg_editor);
            this.append(scroll);
            // Position initiale
            emit_cursor_position();

            // Appliquer le style par défaut depuis les préférences
            var cfg = controller.get_config_manager();
            int size = cfg.get_integer("Editor", "font_size", 12);
            string family = cfg.get_string("Editor", "font_family", "Sans");
            // Si la famille contient une taille (ex: "Sans 12"), ne garder que le nom
            family = sanitize_font_family(family);
            string color = cfg.get_string("Editor", "font_color", "#222222");
            set_editor_style(size, family, color);
        }

        // === MÉTHODES DE LA CLASSE ===

        public void set_editor_style(int size, string family, string color) {
            if (wysiwyg_editor == null) return;
            // Applique un style simple via CSS
            try {
                var css = new Gtk.CssProvider();
                // Utiliser des quotes pour le nom de police (peut contenir des espaces)
                // et échapper les quotes simples éventuelles.
                string family_sanitized = family.replace("'", "\\'");
                css.load_from_string("""
                    .editor-text { font-family: '%s'; font-size: %dpt; color: %s; }
                """.printf(family_sanitized, size, color));
                wysiwyg_editor.add_css_class("editor-text");
                Gtk.StyleContext.add_provider_for_display(
                    Gdk.Display.get_default(), css, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
            } catch (Error e) {
                warning("Style éditeur non appliqué: %s", e.message);
            }
        }

        public enum DocumentSource {
            UNKNOWN,
            EXPLORER,
            FILE_DIALOG
        }

        public void set_document_source(DocumentSource source) {
            _source = source;
        }

        public void set_current_file_path(string path) {
            _current_file_path = path;
        }

        // Permet à la vue principale d'afficher le chemin dans la barre de statut
        public string get_current_file_path() {
            return _current_file_path;
        }

        public void load_document(PivotDocument document) {
            current_document = document;
            if (wysiwyg_editor != null) {
                var buf = wysiwyg_editor.get_buffer();
                // Affichage simple du contenu textuel
                string text = document.content ?? "";
                buf.set_text(text, -1);
                has_unsaved_changes = false;
            }
        }

        public bool save_document(string? path = null) {
            string target = path ?? _current_file_path;
            if (target == null || target == "") {
                // Pas de chemin: utiliser save as
                save_document_as();
                return false;
            }
            if (wysiwyg_editor != null) {
                var buf = wysiwyg_editor.get_buffer();
                Gtk.TextIter start;
                Gtk.TextIter end;
                buf.get_bounds(out start, out end);
                string text = buf.get_text(start, end, false);
                try {
                    FileUtils.set_contents(target, text);
                    has_unsaved_changes = false;
                    return true;
                } catch (Error e) {
                    warning("Échec sauvegarde: %s", e.message);
                    return false;
                }
            }
            return false;
        }

        public async bool save_document_as() {
            // Implémentation minimaliste sans interaction (fallback HOME)
            string home = Environment.get_home_dir();
            string basename = _current_file_path != "" ? Path.get_basename(_current_file_path) : "document.txt";
            string target = Path.build_filename(home, basename);
            bool ok = save_document(target);
            if (ok) set_current_file_path(target);
            return ok;
        }

        // Calcule la position actuelle du curseur et émet le signal
        private void emit_cursor_position() {
            int line, col;
            get_cursor_position(out line, out col);
            cursor_position_changed(line, col);
        }

        // Récupère la position du curseur (1-based pour ligne/colonne)
        public void get_cursor_position(out int line, out int column) {
            line = 1;
            column = 1;
            if (wysiwyg_editor == null) return;
            var buf = wysiwyg_editor.get_buffer();
            if (buf == null) return;
            Gtk.TextIter iter;
            var insert_mark = buf.get_insert();
            buf.get_iter_at_mark(out iter, insert_mark);
            // Gtk.TextIter.get_line() est 0-based; get_line_offset() aussi; on convertit en 1-based
            line = iter.get_line() + 1;
            column = iter.get_line_offset() + 1;
        }

        // Supprime un dernier token numérique (souvent la taille) d'un nom de police
        private string sanitize_font_family(string input) {
            if (input == null || input.length == 0) return "Sans";
            var parts = input.split(" ");
            if (parts.length <= 1) return input;
            string last = parts[parts.length - 1];
            bool numeric = true;
            foreach (char c in last.to_utf8()) {
                if (!(c >= '0' && c <= '9')) { numeric = false; break; }
            }
            if (numeric) {
                return string.joinv(" ", parts[0:parts.length - 1]);
            }
            return input;
        }
    }
}
