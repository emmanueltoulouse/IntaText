    }

    private void update_font_display() {
        if (wysiwyg_editor == null) return;

        var family = wysiwyg_editor.get_current_font_family();
        var size = wysiwyg_editor.get_current_font_size();

        // Mettre à jour l'affichage du bouton de police
        if (family != null && family != "") {
            font_button.set_tooltip_text(@"$family, $(size)pt");
        } else {
            font_button.set_tooltip_text(_("Police et taille"));
        }
    }

    private void update_text_color_display() {
        if (wysiwyg_editor == null) return;

        var color = wysiwyg_editor.get_current_foreground_color();
        if (color != null) {
            text_color_button.get_child().get_style_context().add_provider(
                new Gtk.CssProvider(),
                Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
            );
            // Appliquer la couleur au label A
            var css = @".text-color-display { color: $(color.to_string()); }";
            var provider = new Gtk.CssProvider();
            try {
                provider.load_from_data(css.data);
                text_color_button.get_child().get_style_context().add_provider(
                    provider,
                    Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
                );
            } catch (Error e) {
                warning("Erreur CSS couleur texte: %s", e.message);
            }
        }
    }

    private void update_bg_color_display() {
        if (wysiwyg_editor == null) return;

        var color = wysiwyg_editor.get_current_background_color();
        if (color != null) {
            bg_color_button.get_child().get_style_context().add_provider(
                new Gtk.CssProvider(),
                Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
            );
            // Appliquer la couleur au symbole ■
            var css = @".bg-color-display { color: $(color.to_string()); }";
            var provider = new Gtk.CssProvider();
            try {
                provider.load_from_data(css.data);
                bg_color_button.get_child().get_style_context().add_provider(
                    provider,
                    Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
                );
            } catch (Error e) {
                warning("Erreur CSS couleur fond: %s", e.message);
            }
        }
