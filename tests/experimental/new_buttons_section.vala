    // Boutons de formatage individuels
    var font_button = make_plain_btn_from_candidates(
        { "preferences-desktop-font", "font-select-symbolic" },
        "Aa",
        _("Police et taille")
    );
    format_bar.append(font_button);

    var text_color_button = new Gtk.Button();
    text_color_button.set_tooltip_text(_("Couleur du texte"));
    var text_color_display = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 4);
    text_color_display.append(new Gtk.Label("A"));
    text_color_display.add_css_class("text-color-display");
    text_color_button.set_child(text_color_display);
    format_bar.append(text_color_button);

    var bg_color_button = new Gtk.Button();
    bg_color_button.set_tooltip_text(_("Couleur de fond"));
    var bg_color_display = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 4);
    bg_color_display.append(new Gtk.Label("■"));
    bg_color_display.add_css_class("bg-color-display");
    bg_color_button.set_child(bg_color_display);
    format_bar.append(bg_color_button);

    // Handlers pour les boutons de formatage
    font_button.clicked.connect(() => {
        if (wysiwyg_editor == null) return;

        var font_dialog = new Gtk.FontChooserDialog(_("Choisir une police"), null);
        font_dialog.set_modal(true);
        font_dialog.set_transient_for((Gtk.Window) this.get_root());

        // Récupérer la police et taille actuelles
        var current_family = wysiwyg_editor.get_current_font_family();
        var current_size = wysiwyg_editor.get_current_font_size();

        if (current_family != null && current_family != "") {
            var font_desc = new Pango.FontDescription();
            font_desc.set_family(current_family);
            font_desc.set_size(current_size * Pango.SCALE);
            font_dialog.set_font_desc(font_desc);
        }

        // Timeout pour la prévisualisation
        uint timeout_id = 0;
        font_dialog.notify["font-desc"].connect(() => {
            if (timeout_id > 0) {
                Source.remove(timeout_id);
            }
            timeout_id = Timeout.add(50, () => {
                var desc = font_dialog.get_font_desc();
                if (desc != null) {
                    var family = desc.get_family();
                    var size = desc.get_size() / Pango.SCALE;
                    if (family != null && size > 0) {
                        wysiwyg_editor.apply_font_and_size(family, (int)size);
                        update_font_display();
                    }
                }
                timeout_id = 0;
                return false;
            });
        });

        font_dialog.response.connect((response_id) => {
            if (timeout_id > 0) {
                Source.remove(timeout_id);
                timeout_id = 0;
            }

            if (response_id == Gtk.ResponseType.OK) {
                var desc = font_dialog.get_font_desc();
                if (desc != null) {
                    var family = desc.get_family();
                    var size = desc.get_size() / Pango.SCALE;
                    if (family != null && size > 0) {
                        wysiwyg_editor.apply_font_and_size(family, (int)size);
                        update_font_display();
                    }
                }
            }
            font_dialog.destroy();
        });

        font_dialog.show();
    });

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
