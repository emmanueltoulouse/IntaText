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

    Gtk.ToggleButton make_btn(string icon_name, string tooltip) {
        var btn = new Gtk.ToggleButton();
        var img = new Gtk.Image.from_icon_name(icon_name);
        btn.set_child(img);
        btn.set_tooltip_text(tooltip);
        btn.add_css_class("flat");
        return btn;
    }

    var btn_bold = make_btn("format-text-bold-symbolic", _("Mettre en gras"));
    var btn_italic = make_btn("format-text-italic-symbolic", _("Mettre en italique"));
    var btn_underline = make_btn("format-text-underline-symbolic", _("Souligner"));
    var btn_strike = make_btn("format-text-strikethrough-symbolic", _("Barrer"));

    // Groupe visuel des boutons (coins liés)
    var format_group = new Gtk.Box(Orientation.HORIZONTAL, 0);
    format_group.add_css_class("linked");
    format_group.append(btn_bold);
    format_group.append(btn_italic);
    format_group.append(btn_underline);
    format_group.append(btn_strike);

    format_bar.append(format_group);

    // Séparateur visuel pour préparer d'autres groupes d'icônes
    var sep = new Gtk.Separator(Orientation.VERTICAL);
    sep.add_css_class("spacer");
    format_bar.append(sep);

    // Groupe listes (à puces et ordonnée)
    var list_group = new Gtk.Box(Orientation.HORIZONTAL, 0);
    list_group.add_css_class("linked");

    // Sélection d'icône résiliente: choisit la première existante, sinon label
    string? pick_icon(string[] names) {
        var theme = Gtk.IconTheme.get_for_display(Gdk.Display.get_default());
        foreach (var n in names) {
            if (theme.has_icon(n)) return n;
        }
        return null;
    }

    Gtk.ToggleButton make_btn_from_candidates(string[] icons, string fallback_label, string tooltip) {
        var btn = new Gtk.ToggleButton();
        var icon = pick_icon(icons);
        if (icon != null) {
            btn.set_child(new Gtk.Image.from_icon_name(icon));
        } else {
            btn.set_child(new Gtk.Label(fallback_label));
        }
        btn.set_tooltip_text(tooltip);
        btn.add_css_class("flat");
        return btn;
    }

    var btn_bulleted = make_btn_from_candidates(
        { "format-list-bulleted-symbolic", "format-unordered-list-symbolic", "view-list-symbolic" },
        "•",
        _("Liste à puces")
    );
    var btn_numbered = make_btn_from_candidates(
        { "format-list-numbered-symbolic", "format-ordered-list-symbolic", "view-list-symbolic" },
        "1.",
        _("Liste ordonnée")
    );
    list_group.append(btn_bulleted);
    list_group.append(btn_numbered);
    format_bar.append(list_group);

    // Séparateur
    var sep2 = new Gtk.Separator(Orientation.VERTICAL);
    sep2.add_css_class("spacer");
    format_bar.append(sep2);

    // Groupe Titres H1/H2/H3
    Gtk.ToggleButton make_text_btn(string label, string tooltip) {
        var btn = new Gtk.ToggleButton.with_label(label);
        btn.set_tooltip_text(tooltip);
        btn.add_css_class("flat");
        return btn;
    }
    var heading_group = new Gtk.Box(Orientation.HORIZONTAL, 0);
    heading_group.add_css_class("linked");
    var btn_p = make_text_btn("P", _("Paragraphe (réinitialiser le titre)"));
    var btn_h1 = make_text_btn("H1", _("Titre niveau 1"));
    var btn_h2 = make_text_btn("H2", _("Titre niveau 2"));
    var btn_h3 = make_text_btn("H3", _("Titre niveau 3"));
    heading_group.append(btn_p);
    heading_group.append(btn_h1);
    heading_group.append(btn_h2);
    heading_group.append(btn_h3);
    format_bar.append(heading_group);

    // Séparateur
    var sep3 = new Gtk.Separator(Orientation.VERTICAL);
    sep3.add_css_class("spacer");
    format_bar.append(sep3);

    // Groupe Insertion: code, lien, image (boutons simples)
    Gtk.Button make_plain_btn_from_candidates(string[] icons, string fallback_label, string tooltip) {
        var btn = new Gtk.Button();
        var icon = pick_icon(icons);
        if (icon != null) {
            btn.set_child(new Gtk.Image.from_icon_name(icon));
        } else {
            btn.set_child(new Gtk.Label(fallback_label));
        }
        btn.set_tooltip_text(tooltip);
        btn.add_css_class("flat");
        return btn;
    }

    var insert_group = new Gtk.Box(Orientation.HORIZONTAL, 0);
    insert_group.add_css_class("linked");

    var btn_code = make_plain_btn_from_candidates(
        { "code-symbolic", "format-text-code-symbolic", "utilities-terminal-symbolic" },
        "{}",
        _("Insérer du code / appliquer au texte sélectionné")
    );
    var btn_link = make_plain_btn_from_candidates(
        { "insert-link-symbolic", "link-symbolic", "emblem-symbolic-link" },
        "🔗",
        _("Insérer un lien")
    );
    var btn_image = make_plain_btn_from_candidates(
        { "insert-image-symbolic", "image-x-generic-symbolic", "image-missing-symbolic" },
        "🖼",
        _("Insérer une image")
    );
    insert_group.append(btn_code);
    insert_group.append(btn_link);
    insert_group.append(btn_image);
    format_bar.append(insert_group);

    this.append(format_bar);

    // Zone d'édition scrollable minimale
    var scroll = new Gtk.ScrolledWindow();
    scroll.set_vexpand(true);
    scroll.set_hexpand(true);
    wysiwyg_editor = new WysiwygEditor();
    // Connexions boutons => actions d'édition
    btn_bold.clicked.connect(() => { if (wysiwyg_editor != null) wysiwyg_editor.toggle_bold(); });
    btn_italic.clicked.connect(() => { if (wysiwyg_editor != null) wysiwyg_editor.toggle_italic(); });
    btn_underline.clicked.connect(() => { if (wysiwyg_editor != null) wysiwyg_editor.toggle_underline(); });
    btn_strike.clicked.connect(() => { if (wysiwyg_editor != null) wysiwyg_editor.toggle_strikethrough(); });
    btn_bulleted.clicked.connect(() => { if (wysiwyg_editor != null) wysiwyg_editor.apply_list_action(false); });
    btn_numbered.clicked.connect(() => { if (wysiwyg_editor != null) wysiwyg_editor.apply_list_action(true); });
    btn_code.clicked.connect(() => {
        if (wysiwyg_editor == null) return;
        var buf_local = wysiwyg_editor.get_buffer();
        Gtk.TextIter s, e;
        if (buf_local.get_selection_bounds(out s, out e)) {
            wysiwyg_editor.apply_code();
        } else {
            wysiwyg_editor.insert_code_block();
        }
    });
    btn_link.clicked.connect(() => {
        if (wysiwyg_editor == null) return;
        // Popover simple pour saisir URL et texte
        var pop = new Gtk.Popover();
        pop.set_has_arrow(true);
        pop.set_parent(btn_link);
        var box = new Gtk.Box(Orientation.VERTICAL, 6);
        box.set_margin_top(8);
        box.set_margin_bottom(8);
        box.set_margin_start(8);
        box.set_margin_end(8);
        var entry_url = new Gtk.Entry();
        entry_url.set_placeholder_text("https://…");
        var entry_text = new Gtk.Entry();
        entry_text.set_placeholder_text(_("Texte du lien"));
        // Pré-remplir avec la sélection si présente
        var buf_local = wysiwyg_editor.get_buffer();
        Gtk.TextIter s, e;
        if (buf_local.get_selection_bounds(out s, out e)) {
            entry_text.set_text(buf_local.get_text(s, e, false));
        }
        var actions = new Gtk.Box(Orientation.HORIZONTAL, 6);
        var cancel_btn = new Gtk.Button.with_label(_("Annuler"));
        var ok_btn = new Gtk.Button.with_label(_("Insérer"));
        actions.append(cancel_btn);
        actions.append(ok_btn);
        box.append(new Gtk.Label(_("URL")));
        box.append(entry_url);
        box.append(new Gtk.Label(_("Texte")));
        box.append(entry_text);
        box.append(actions);
        pop.set_child(box);
        cancel_btn.clicked.connect(() => pop.popdown());
        ok_btn.clicked.connect(() => {
            string url = entry_url.get_text();
            string text = entry_text.get_text();
            if (text == null || text.strip() == "") text = url;
            if (url != null && url.strip() != "") {
                wysiwyg_editor.insert_link(url.strip(), text ?? "");
            }
            pop.popdown();
        });
        pop.popup();
    });
    btn_image.clicked.connect(() => {
        if (wysiwyg_editor == null) return;
        // Popover simple pour saisir chemin et texte alternatif
        var pop = new Gtk.Popover();
        pop.set_has_arrow(true);
        pop.set_parent(btn_image);
        var box = new Gtk.Box(Orientation.VERTICAL, 6);
        box.set_margin_top(8);
        box.set_margin_bottom(8);
        box.set_margin_start(8);
        box.set_margin_end(8);
        var entry_path = new Gtk.Entry();
        entry_path.set_placeholder_text(_("Chemin de l'image"));
        var entry_alt = new Gtk.Entry();
        entry_alt.set_placeholder_text(_("Texte alternatif"));
        var actions = new Gtk.Box(Orientation.HORIZONTAL, 6);
        var cancel_btn = new Gtk.Button.with_label(_("Annuler"));
        var ok_btn = new Gtk.Button.with_label(_("Insérer"));
        actions.append(cancel_btn);
        actions.append(ok_btn);
        box.append(new Gtk.Label(_("Fichier")));
        box.append(entry_path);
        box.append(new Gtk.Label(_("Texte alternatif")));
        box.append(entry_alt);
        box.append(actions);
        pop.set_child(box);
        cancel_btn.clicked.connect(() => pop.popdown());
        ok_btn.clicked.connect(() => {
            string p = entry_path.get_text();
            string alt = entry_alt.get_text();
            if (p != null && p.strip() != "") {
                wysiwyg_editor.insert_image(p.strip(), alt ?? "");
            }
            pop.popdown();
        });
        pop.popup();
    });
    void set_heading_buttons(int level) {
        btn_p.active = (level == 0);
        btn_h1.active = (level == 1);
        btn_h2.active = (level == 2);
        btn_h3.active = (level == 3);
    }
    btn_p.clicked.connect(() => {
        if (wysiwyg_editor == null) return;
        wysiwyg_editor.clear_heading_action();
        set_heading_buttons(0);
    });
    btn_h1.clicked.connect(() => { if (wysiwyg_editor != null) { wysiwyg_editor.apply_heading_action(1); set_heading_buttons(1);} });
    btn_h2.clicked.connect(() => { if (wysiwyg_editor != null) { wysiwyg_editor.apply_heading_action(2); set_heading_buttons(2);} });
    btn_h3.clicked.connect(() => { if (wysiwyg_editor != null) { wysiwyg_editor.apply_heading_action(3); set_heading_buttons(3);} });
    // Détection des modifications
    var buf = wysiwyg_editor.get_buffer();
    buf.changed.connect(() => {
                has_unsaved_changes = true;
            });
    // Suivre la position du curseur
    void sync_toggle_states() {
        if (wysiwyg_editor == null) return;
        btn_bold.active = wysiwyg_editor.is_bold_active();
        btn_italic.active = wysiwyg_editor.is_italic_active();
        btn_underline.active = wysiwyg_editor.is_underline_active();
        btn_strike.active = wysiwyg_editor.is_strikethrough_active();
        // titres
        int h = wysiwyg_editor.get_active_heading_level();
        set_heading_buttons(h);
    }
    buf.notify["cursor-position"].connect(() => { emit_cursor_position(); sync_toggle_states(); });
    buf.mark_set.connect((iter, mark) => { emit_cursor_position(); sync_toggle_states(); });
    scroll.set_child(wysiwyg_editor);
    this.append(scroll);
    // Position initiale
    emit_cursor_position();
    // Synchroniser l'état des boutons au chargement initial
    sync_toggle_states();

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
        css.load_from_string(
            """
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
    // Rendu riche à partir du document pivot
    wysiwyg_editor.load_pivot_document(document);
        has_unsaved_changes = false;
    }
}

public bool save_document(string? path = null) {
    // 1) Déterminer la cible: paramètre, chemin courant, sinon défaut .md
    string target = path ?? _current_file_path;
    if (target == null || target == "") {
        // Nouveau document: défaut Markdown “pango” (assimilé à .md)
        string home = Environment.get_home_dir();
        target = Path.build_filename(home, "document.md");
    }

    if (wysiwyg_editor == null) return false;

    // 2) Construire un PivotDocument depuis le buffer courant
    PivotDocument pivot;
    try {
        pivot = wysiwyg_editor.get_pivot_document();
    } catch (Error e) {
        // Fallback minimal si la reconstruction échoue
        var buf = wysiwyg_editor.get_buffer();
        Gtk.TextIter s, e2;
        buf.get_bounds(out s, out e2);
        string txt = buf.get_text(s, e2, false);
        pivot = new PivotDocument();
        pivot.children.add(new PivotParagraph() { text = txt });
    }
    // Propager le chemin/format source si connu
    if (_current_file_path != null && _current_file_path != "") {
        pivot.source_path = _current_file_path;
        // Déduire un format simple d’après l’extension
        if (_current_file_path.has_suffix(".md")) pivot.source_format = "md";
        else if (_current_file_path.has_suffix(".html") || _current_file_path.has_suffix(".htm")) pivot.source_format = "html";
        else if (_current_file_path.has_suffix(".pivot")) pivot.source_format = "pivot";
        else pivot.source_format = "txt";
    } else {
        pivot.source_path = target;
        pivot.source_format = "md"; // défaut
    }

    // 3) Sauvegarder via le manager de conversion selon l’extension de la cible
    try {
        var conv = DocumentConverterManager.get_instance();
        conv.save_pivot_to_file(pivot, target);
        set_current_file_path(target);
        has_unsaved_changes = false;
        return true;
    } catch (Error e) {
        warning("Échec sauvegarde via converters: %s", e.message);
        return false;
    }
}

public async bool save_document_as() {
    // Implémentation minimaliste sans interaction (fallback HOME)
    string home = Environment.get_home_dir();
    // Si on a déjà un chemin, proposer le même nom; sinon défaut .md
    string basename = _current_file_path != "" ? Path.get_basename(_current_file_path) : "document.md";
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
        if (!(c >= '0' && c <= '9')) {
            numeric = false; break;
        }
    }
    if (numeric) {
        return string.joinv(" ", parts[0 : parts.length - 1]);
    }
    return input;
}
}
}
