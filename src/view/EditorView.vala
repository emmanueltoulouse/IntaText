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
private Gtk.Button? text_color_button;
private Gtk.Button? bg_color_button;

// Gestion de l'état initial pour l'annulation
private string initial_content = "";
private bool has_initial_state = false;

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

    // Configuration d'accessibilité pour les boutons de formatage
    btn_bold.set_accessible_role(Gtk.AccessibleRole.BUTTON);
    btn_bold.update_property(Gtk.AccessibleProperty.LABEL, "Bouton Gras");
    btn_bold.update_property(Gtk.AccessibleProperty.DESCRIPTION, "Applique le formatage gras au texte sélectionné");

    btn_italic.set_accessible_role(Gtk.AccessibleRole.BUTTON);
    btn_italic.update_property(Gtk.AccessibleProperty.LABEL, "Bouton Italique");
    btn_italic.update_property(Gtk.AccessibleProperty.DESCRIPTION, "Applique le formatage italique au texte sélectionné");

    btn_underline.set_accessible_role(Gtk.AccessibleRole.BUTTON);
    btn_underline.update_property(Gtk.AccessibleProperty.LABEL, "Bouton Souligné");
    btn_underline.update_property(Gtk.AccessibleProperty.DESCRIPTION, "Applique le soulignement au texte sélectionné");

    btn_strike.set_accessible_role(Gtk.AccessibleRole.BUTTON);
    btn_strike.update_property(Gtk.AccessibleProperty.LABEL, "Bouton Barré");
    btn_strike.update_property(Gtk.AccessibleProperty.DESCRIPTION, "Applique le barrement au texte sélectionné");

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
    // Bouton Trait: si aucune icône thème n'est trouvée, utiliser la ressource intégrée
    var rule_icon = pick_icon({ "insert-horizontal-rule-symbolic", "horizontal-rule-symbolic", "insert-text-separator-symbolic", "text-separator-symbolic" });
    Gtk.Button btn_rule;
    if (rule_icon != null) {
        btn_rule = new Gtk.Button();
        btn_rule.set_child(new Gtk.Image.from_icon_name(rule_icon));
    } else {
        btn_rule = new Gtk.Button();
        var rule_img = new Gtk.Image();
        rule_img.set_from_resource("/com/cabineteto/IntaText/icons/horizontal-rule-symbolic.svg");
        btn_rule.set_child(rule_img);
    }
    btn_rule.set_tooltip_text(_("Insérer un trait de séparation"));
    btn_rule.add_css_class("flat");
    var btn_table = make_plain_btn_from_candidates(
        { "view-grid-symbolic", "table-symbolic", "grid-symbolic" },
        "⊞",
        _("Insérer un tableau")
    );
    insert_group.append(btn_code);
    insert_group.append(btn_link);
    insert_group.append(btn_image);
    insert_group.append(btn_rule);
    insert_group.append(btn_table);
    format_bar.append(insert_group);

    // Séparateur
    var sep4 = new Gtk.Separator(Orientation.VERTICAL);
    sep4.add_css_class("spacer");
    format_bar.append(sep4);

    // Groupe Couleurs
    var color_group = new Gtk.Box(Orientation.HORIZONTAL, 0);
    color_group.add_css_class("linked");

    text_color_button = new Gtk.Button();
    text_color_button.set_tooltip_text(_("Couleur du texte"));
    text_color_button.add_css_class("flat");
    var text_color_display = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 4);
    text_color_display.append(new Gtk.Label("A"));
    text_color_display.add_css_class("text-color-display");
    text_color_button.set_child(text_color_display);

    bg_color_button = new Gtk.Button();
    bg_color_button.set_tooltip_text(_("Couleur de fond"));
    bg_color_button.add_css_class("flat");
    var bg_color_display = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 4);
    bg_color_display.append(new Gtk.Label("■"));
    bg_color_display.add_css_class("bg-color-display");
    bg_color_button.set_child(bg_color_display);

    color_group.append(text_color_button);
    color_group.append(bg_color_button);
    format_bar.append(color_group);

    // Séparateur
    var sep5 = new Gtk.Separator(Orientation.VERTICAL);
    sep5.add_css_class("spacer");
    format_bar.append(sep5);

    // Groupe Indentation
    var indent_group = new Gtk.Box(Orientation.HORIZONTAL, 0);
    indent_group.add_css_class("linked");

    var btn_indent_left = make_plain_btn_from_candidates(
        { "format-indent-less-symbolic", "format-unindent-symbolic", "go-previous-symbolic" },
        "◀",
        _("Réduire l'indentation")
    );
    var btn_indent_right = make_plain_btn_from_candidates(
        { "format-indent-more-symbolic", "format-indent-symbolic", "go-next-symbolic" },
        "▶",
        _("Augmenter l'indentation")
    );

    indent_group.append(btn_indent_left);
    indent_group.append(btn_indent_right);
    format_bar.append(indent_group);

    // Handlers pour les boutons de formatage

    // Handlers pour les boutons de couleur
    text_color_button.clicked.connect(() => {
        if (wysiwyg_editor == null) return;

        var color_dialog = new Gtk.ColorChooserDialog(_("Choisir une couleur de texte"), null);
        color_dialog.set_modal(true);
        color_dialog.set_transient_for((Gtk.Window) this.get_root());

        // Récupérer la couleur actuelle
        var current_color = wysiwyg_editor.get_current_foreground_color();
        if (current_color != null) {
            color_dialog.set_rgba(current_color);
        }

        // Timeout pour la prévisualisation
        uint timeout_id = 0;
        color_dialog.notify["rgba"].connect(() => {
            if (timeout_id > 0) {
                Source.remove(timeout_id);
            }
            timeout_id = Timeout.add(50, () => {
                wysiwyg_editor.apply_foreground_color(color_dialog.get_rgba());
                update_text_color_display();
                timeout_id = 0;
                return false;
            });
        });

        color_dialog.response.connect((response_id) => {
            if (timeout_id > 0) {
                Source.remove(timeout_id);
                timeout_id = 0;
            }

            if (response_id == Gtk.ResponseType.OK) {
                wysiwyg_editor.apply_foreground_color(color_dialog.get_rgba());
                update_text_color_display();
            }
            color_dialog.destroy();
        });

        color_dialog.show();
    });

    bg_color_button.clicked.connect(() => {
        if (wysiwyg_editor == null) return;

        var color_dialog = new Gtk.ColorChooserDialog(_("Choisir une couleur de fond"), null);
        color_dialog.set_modal(true);
        color_dialog.set_transient_for((Gtk.Window) this.get_root());

        // Récupérer la couleur actuelle
        var current_color = wysiwyg_editor.get_current_background_color();
        if (current_color != null) {
            color_dialog.set_rgba(current_color);
        }

        // Timeout pour la prévisualisation
        uint timeout_id = 0;
        color_dialog.notify["rgba"].connect(() => {
            if (timeout_id > 0) {
                Source.remove(timeout_id);
            }
            timeout_id = Timeout.add(50, () => {
                wysiwyg_editor.apply_background_color(color_dialog.get_rgba());
                update_bg_color_display();
                timeout_id = 0;
                return false;
            });
        });

        color_dialog.response.connect((response_id) => {
            if (timeout_id > 0) {
                Source.remove(timeout_id);
                timeout_id = 0;
            }

            if (response_id == Gtk.ResponseType.OK) {
                wysiwyg_editor.apply_background_color(color_dialog.get_rgba());
                update_bg_color_display();
            }
            color_dialog.destroy();
        });

        color_dialog.show();
    });
    this.append(format_bar);

    // Zone d'édition scrollable avec barres H/V automatiques
    var scroll = new Gtk.ScrolledWindow();
    scroll.set_vexpand(true);
    scroll.set_hexpand(true);
    scroll.set_policy(Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC);
    // Pour que l'ascenseur horizontal apparaisse lorsque la fenêtre est
    // plus étroite que la largeur minimale de contenu, on fixe
    // explicitement min_content_width sur le ScrolledWindow en s'appuyant
    // sur la préférence GSettings (et on réagit à ses changements).
    var ui_settings_scroll = new GLib.Settings("com.cabineteto.IntaText");
    int minw_ini_scroll = ui_settings_scroll.get_int("editor-min-content-width");
    if (minw_ini_scroll < 200) minw_ini_scroll = 200;
    scroll.set_min_content_width(minw_ini_scroll);
    // Désactive explicitement la propagation des tailles naturelles pour
    // éviter que le contenu empêche l'affichage de l'ascenseur horizontal.
    scroll.set_propagate_natural_width(false);
    ui_settings_scroll.changed["editor-min-content-width"].connect((key) => {
        int w = ui_settings_scroll.get_int(key);
        if (w < 200) w = 200;
        scroll.set_min_content_width(w);
    });
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
        // Popover pour saisir chemin et texte alternatif avec sélecteur de fichiers
        var pop = new Gtk.Popover();
        pop.set_has_arrow(true);
        pop.set_parent(btn_image);
        var box = new Gtk.Box(Orientation.VERTICAL, 6);
        box.set_margin_top(8);
        box.set_margin_bottom(8);
        box.set_margin_start(8);
        box.set_margin_end(8);

        // Ligne pour le chemin de fichier avec bouton parcourir
        var path_box = new Gtk.Box(Orientation.HORIZONTAL, 6);
        var entry_path = new Gtk.Entry();
        entry_path.set_placeholder_text(_("Chemin de l'image"));
        entry_path.set_hexpand(true);
        var browse_btn = new Gtk.Button.with_label(_("Parcourir..."));
        path_box.append(entry_path);
        path_box.append(browse_btn);

        var entry_alt = new Gtk.Entry();
        entry_alt.set_placeholder_text(_("Texte alternatif"));
        var actions = new Gtk.Box(Orientation.HORIZONTAL, 6);
        var cancel_btn = new Gtk.Button.with_label(_("Annuler"));
        var ok_btn = new Gtk.Button.with_label(_("Insérer"));
        actions.append(cancel_btn);
        actions.append(ok_btn);
        box.append(new Gtk.Label(_("Fichier")));
        box.append(path_box);
        box.append(new Gtk.Label(_("Texte alternatif")));
        box.append(entry_alt);
        box.append(actions);
        pop.set_child(box);

        // Action pour le bouton parcourir
        browse_btn.clicked.connect(() => {
            var file_dialog = new Gtk.FileDialog();
            file_dialog.set_title(_("Sélectionner une image"));

            // Filtres pour les images
            var filters = new GLib.ListStore(typeof(Gtk.FileFilter));
            var image_filter = new Gtk.FileFilter();
            image_filter.add_mime_type("image/*");
            image_filter.add_pattern("*.png");
            image_filter.add_pattern("*.jpg");
            image_filter.add_pattern("*.jpeg");
            image_filter.add_pattern("*.gif");
            image_filter.add_pattern("*.bmp");
            image_filter.add_pattern("*.svg");
            image_filter.add_pattern("*.webp");
            filters.append(image_filter);

            var all_filter = new Gtk.FileFilter();
            all_filter.add_pattern("*");
            filters.append(all_filter);

            file_dialog.set_filters(filters);
            file_dialog.set_default_filter(image_filter);

            file_dialog.open.begin(get_root() as Gtk.Window, null, (obj, res) => {
                try {
                    var file = file_dialog.open.end(res);
                    if (file != null) {
                        entry_path.set_text(file.get_path() ?? file.get_uri());
                        // Remplir automatiquement le texte alternatif avec le nom du fichier si vide
                        if (entry_alt.get_text().strip() == "") {
                            string basename = file.get_basename() ?? "";
                            // Enlever l'extension pour le texte alternatif
                            int dot_pos = basename.last_index_of(".");
                            if (dot_pos > 0) {
                                basename = basename.substring(0, dot_pos);
                            }
                            entry_alt.set_text(basename);
                        }
                    }
                } catch (Error e) {
                    // L'utilisateur a annulé ou il y a eu une erreur
                }
            });
        });

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
    btn_rule.clicked.connect(() => {
        if (wysiwyg_editor != null) {
            wysiwyg_editor.insert_horizontal_rule();
        }
    });

    btn_table.clicked.connect(() => {
        if (wysiwyg_editor != null) {
            show_table_creation_dialog();
        }
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

    // Handlers pour les boutons d'indentation
    btn_indent_left.clicked.connect(() => {
        if (wysiwyg_editor != null) wysiwyg_editor.decrease_indent();
    });
    btn_indent_right.clicked.connect(() => {
        if (wysiwyg_editor != null) wysiwyg_editor.increase_indent();
    });
    // Détection des modifications
    var buf = wysiwyg_editor.get_buffer();
    buf.changed.connect(() => {
        // Vérifier si on est revenu à l'état initial après des modifications
        if (is_at_initial_state()) {
            has_unsaved_changes = false;
        } else {
            has_unsaved_changes = true;
        }
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
    buf.notify["cursor-position"].connect(() => {
        emit_cursor_position();
        sync_toggle_states();
        update_text_color_display();
        update_bg_color_display();
    });
    buf.mark_set.connect((iter, mark) => {
        emit_cursor_position();
        sync_toggle_states();
        update_text_color_display();
        update_bg_color_display();
    });
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

    // Définir l'état initial pour les nouveaux documents vides
    set_initial_state();
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

        // Définir l'état initial pour le système d'annulation
        set_initial_state();
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

    // Écriture directe pour .md et .txt afin d'éviter toute altération
    string lower_target = target.down();
    bool is_markdown = (lower_target.has_suffix(".md") || lower_target.has_suffix(".markdown"));
    bool is_text = (lower_target.has_suffix(".txt"));
    if (is_text && wysiwyg_editor != null) {
        try {
            var buf_dir = wysiwyg_editor.get_buffer();
            Gtk.TextIter s0, e0;
            buf_dir.get_bounds(out s0, out e0);
            string raw = buf_dir.get_text(s0, e0, false);
            FileUtils.set_contents(target, raw);
            set_current_file_path(target);
            has_unsaved_changes = false;
            return true;
        } catch (Error err) {
            warning("Échec de la sauvegarde directe: %s", err.message);
            // Fallback: continuer via conversion pivot
        }
    }

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
    // Dialogue GTK4 de sauvegarde avec filtres simples
    try {
        var file_dialog = new Gtk.FileDialog();
        file_dialog.set_title(_("Enregistrer sous…"));

        // Proposer un nom initial
        string basename = _current_file_path != "" ? Path.get_basename(_current_file_path) : "document.md";
        // set_initial_name existe en GTK 4 pour FileDialog
        file_dialog.set_initial_name(basename);

        // Filtres: Markdown / HTML / Texte / Pivot
    var md = new Gtk.FileFilter();
    md.name = "Markdown (*.md)";
        md.add_mime_type("text/markdown");
        md.add_pattern("*.md");
    var html = new Gtk.FileFilter();
    html.name = "HTML (*.html, *.htm)";
        html.add_mime_type("text/html");
        html.add_pattern("*.html");
        html.add_pattern("*.htm");
    var txt = new Gtk.FileFilter();
    txt.name = "Texte (*.txt)";
        txt.add_mime_type("text/plain");
        txt.add_pattern("*.txt");
    var pivot = new Gtk.FileFilter();
    pivot.name = "Pivot (*.pivot)";
        pivot.add_pattern("*.pivot");

        var filters = new GLib.ListStore(typeof(Gtk.FileFilter));
        filters.append(md);
        filters.append(html);
        filters.append(txt);
        filters.append(pivot);
        file_dialog.set_filters(filters);

    // Trouver une fenêtre parente
    Gtk.Window? parent = this.get_root() as Gtk.Window;

        // Lancer la boîte de dialogue
        file_dialog.save.begin(parent, null, (obj, res) => {
            try {
                var gfile = file_dialog.save.end(res);
                if (gfile != null) {
                    string? path = gfile.get_path();
                    if (path != null && path != "") {
                        bool ok = save_document(path);
                        if (ok) set_current_file_path(path);
                    }
                }
            } catch (Error e) {
                // Annulation ou erreur: ne rien faire
            }
        });
        return true; // l’opération est asynchrone; on retourne true pour l’initiation
    } catch (Error e) {
        warning("Échec du dialogue Enregistrer sous: %s", e.message);
        return false;
    }
}

// Calcule la position actuelle du curseur et émet le signal
private void emit_cursor_position() {
    int line, col;
    get_cursor_position(out line, out col);
    cursor_position_changed(line, col);
}

// === GESTION DE L'ANNULATION ===

// Stocke l'état initial du buffer (appelé après le chargement d'un fichier)
public void set_initial_state() {
    if (wysiwyg_editor == null) return;

    var buffer = wysiwyg_editor.get_buffer();
    Gtk.TextIter start, end;
    buffer.get_bounds(out start, out end);
    initial_content = buffer.get_text(start, end, false);
    has_initial_state = true;
    has_unsaved_changes = false;
}

// Vérifie si le contenu actuel correspond à l'état initial
private bool is_at_initial_state() {
    if (!has_initial_state || wysiwyg_editor == null) return false;

    var buffer = wysiwyg_editor.get_buffer();
    Gtk.TextIter start, end;
    buffer.get_bounds(out start, out end);
    string current_content = buffer.get_text(start, end, false);

    return current_content == initial_content;
}

// Effectue une annulation (Ctrl+Z) avec limitation à l'état initial
public void perform_undo() {
    if (wysiwyg_editor == null) return;

    var buffer = wysiwyg_editor.get_buffer();

    // Vérifier si on peut annuler
    if (!buffer.get_can_undo()) return;

    // Si on est déjà à l'état initial, ne pas annuler davantage
    if (is_at_initial_state()) {
        return; // Bloquer l'annulation à l'état initial
    }

    // Effectuer l'annulation
    buffer.undo();

    // Vérifier si après l'annulation on est à l'état initial
    if (is_at_initial_state()) {
        has_unsaved_changes = false;
    } else {
        has_unsaved_changes = true;
    }
}

// Effectue un rétablissement (Ctrl+Shift+Z)
public void perform_redo() {
    if (wysiwyg_editor == null) return;

    var buffer = wysiwyg_editor.get_buffer();

    // Vérifier si on peut rétablir
    if (!buffer.get_can_redo()) return;

    // Effectuer le rétablissement
    buffer.redo();

    // Vérifier si après le rétablissement on est à l'état initial
    if (is_at_initial_state()) {
        has_unsaved_changes = false;
    } else {
        has_unsaved_changes = true;
    }
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

private void update_text_color_display() {
    if (wysiwyg_editor == null || text_color_button == null) return;

    var color = wysiwyg_editor.get_current_foreground_color();
    if (color != null) {
        // Appliquer la couleur au label A via CSS
        var css = @".text-color-display { color: $(color.to_string()); }";
        var provider = new Gtk.CssProvider();
        try {
            provider.load_from_string(css);
            text_color_button.get_style_context().add_provider(
                provider,
                Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
            );
        } catch (Error e) {
            warning("Erreur CSS couleur texte: %s", e.message);
        }
    } else {
        // Remettre la couleur par défaut
        text_color_button.get_style_context().remove_class("text-color-display");
    }
}

private void update_bg_color_display() {
    if (wysiwyg_editor == null || bg_color_button == null) return;

    var color = wysiwyg_editor.get_current_background_color();
    if (color != null) {
        // Appliquer la couleur au symbole ■ via CSS
        var css = @".bg-color-display { color: $(color.to_string()); }";
        var provider = new Gtk.CssProvider();
        try {
            provider.load_from_string(css);
            bg_color_button.get_style_context().add_provider(
                provider,
                Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
            );
        } catch (Error e) {
            warning("Erreur CSS couleur fond: %s", e.message);
        }
    } else {
        // Remettre la couleur par défaut
        bg_color_button.get_style_context().remove_class("bg-color-display");
    }
}

private void show_table_creation_dialog() {
    var dialog = new Gtk.Dialog() {
        title = _("Créer un tableau"),
        modal = true,
        transient_for = (Gtk.Window) this.get_root(),
        default_width = 400,
        default_height = 300
    };

    dialog.add_button(_("Annuler"), Gtk.ResponseType.CANCEL);
    dialog.add_button(_("Créer"), Gtk.ResponseType.ACCEPT);

    // S'assurer que le bouton "Créer" soit le bouton par défaut
    dialog.set_default_response(Gtk.ResponseType.ACCEPT);

    // Contenu du dialogue
    var content_area = dialog.get_content_area();
    content_area.set_spacing(12);

    var grid = new Gtk.Grid() {
        margin_top = 20,
        margin_bottom = 20,
        margin_start = 20,
        margin_end = 20,
        row_spacing = 12,
        column_spacing = 12,
        halign = Gtk.Align.FILL,
        valign = Gtk.Align.START
    };

    var label_rows = new Gtk.Label(_("Nombre de lignes:")) {
        halign = Gtk.Align.START,
        ellipsize = Pango.EllipsizeMode.END,
        xalign = 0.0f
    };
    var spin_rows = new Gtk.SpinButton.with_range(1, 20, 1) {
        value = 3
    };

    var label_cols = new Gtk.Label(_("Nombre de colonnes:")) {
        halign = Gtk.Align.START,
        ellipsize = Pango.EllipsizeMode.END,
        xalign = 0.0f
    };
    var spin_cols = new Gtk.SpinButton.with_range(1, 10, 1) {
        value = 3
    };

    var label_headers = new Gtk.Label(_("Première ligne en-tête:")) {
        halign = Gtk.Align.START,
        ellipsize = Pango.EllipsizeMode.END,
        xalign = 0.0f
    };
    var check_headers = new Gtk.CheckButton() {
        active = true
    };

    grid.attach(label_rows, 0, 0, 1, 1);
    grid.attach(spin_rows, 1, 0, 1, 1);
    grid.attach(label_cols, 0, 1, 1, 1);
    grid.attach(spin_cols, 1, 1, 1, 1);
    grid.attach(label_headers, 0, 2, 1, 1);
    grid.attach(check_headers, 1, 2, 1, 1);

    // Ajouter le grid à la zone de contenu du dialogue
    content_area.append(grid);

    dialog.response.connect((response_id) => {
        if (response_id == Gtk.ResponseType.ACCEPT) {
            int rows = (int) spin_rows.value;
            int cols = (int) spin_cols.value;
            bool has_headers = check_headers.active;

            create_and_insert_table(rows, cols, has_headers);
        }
        dialog.close();
    });

    dialog.present();
}

private void create_and_insert_table(int rows, int cols, bool has_headers) {
    if (wysiwyg_editor == null) return;

    var table = new PivotTable();

    for (int i = 0; i < rows; i++) {
        var row = new Gee.ArrayList<PivotTableCell>();
        for (int j = 0; j < cols; j++) {
            if (i == 0 && has_headers) {
                row.add(new PivotTableCell.from_text("En-tête " + (j + 1).to_string()));
            } else {
                row.add(new PivotTableCell.from_text("Cellule " + (i + 1).to_string() + "," + (j + 1).to_string()));
            }
        }
        table.rows.add(row);
    }

    wysiwyg_editor.insert_table_object(table);
}

} // Fermeture de la classe EditorView
} // Fermeture du namespace IntaText
