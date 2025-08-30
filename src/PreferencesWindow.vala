private class PreferencesWindow : Adw.PreferencesWindow {
private void add_page_general() {
    var general_page = new Adw.PreferencesPage();
    general_page.set_title(_("Général"));
    general_page.set_icon_name("preferences-system-symbolic");

    var general_group = new Adw.PreferencesGroup();
    general_group.set_title(_("Application"));

    // 1. Ouvrir le dernier fichier au démarrage
    var startup_row = new Adw.ActionRow();
    startup_row.set_title(_("Ouvrir le dernier fichier au démarrage"));
    var startup_switch = new Gtk.Switch();
    startup_switch.set_valign(Gtk.Align.CENTER);
    startup_row.add_suffix(startup_switch);
    general_group.add(startup_row);

    // 4. Activer les mises à jour automatiques
    var updates_row = new Adw.ActionRow();
    updates_row.set_title(_("Activer les mises à jour automatiques"));
    var updates_switch = new Gtk.Switch();
    updates_switch.set_valign(Gtk.Align.CENTER);
    updates_row.add_suffix(updates_switch);
    general_group.add(updates_row);

    // 5. Langue de l’interface
    var language_row = new Adw.ActionRow();
    language_row.set_title(_("Langue de l’interface"));
    var language_list = new Gtk.StringList({"Français", "English", "Español"});
    var language_dropdown = new Gtk.DropDown(language_list, null);
    language_row.add_suffix(language_dropdown);
    general_group.add(language_row);

    // 6. Format de la date/heure
    var dateformat_row = new Adw.ActionRow();
    dateformat_row.set_title(_("Format de la date/heure"));
    var dateformat_list = new Gtk.StringList({ "24h", "12h", "Automatique" });
    var dateformat_dropdown = new Gtk.DropDown(dateformat_list, null);
    dateformat_row.add_suffix(dateformat_dropdown);
    general_group.add(dateformat_row);

    // 7. Dossier de travail par défaut
    var folder_row = new Adw.ActionRow();
    folder_row.set_title(_("Dossier de travail par défaut"));
    var folder_button = new Gtk.Button.with_label(_("Choisir..."));
    folder_row.add_suffix(folder_button);
    general_group.add(folder_row);

    // 8. Nombre maximum de fichiers récents
    var recent_row = new Adw.ActionRow();
    recent_row.set_title(_("Nombre maximum de fichiers récents"));
    var recent_spin = new Gtk.SpinButton.with_range(1, 50, 1);
    recent_row.add_suffix(recent_spin);
    general_group.add(recent_row);

    // 9. Afficher les conseils au démarrage
    var tips_row = new Adw.ActionRow();
    tips_row.set_title(_("Afficher les conseils au démarrage"));
    var tips_switch = new Gtk.Switch();
    tips_switch.set_valign(Gtk.Align.CENTER);
    tips_row.add_suffix(tips_switch);
    general_group.add(tips_row);

    // 10. Activer la sauvegarde automatique (avec intervalle)
    var autosave_row = new Adw.ActionRow();
    autosave_row.set_title(_("Activer la sauvegarde automatique"));
    var autosave_switch = new Gtk.Switch();
    autosave_switch.set_valign(Gtk.Align.CENTER);
    autosave_row.add_suffix(autosave_switch);
    var autosave_spin = new Gtk.SpinButton.with_range(1, 60, 1);
    autosave_spin.set_tooltip_text(_("Intervalle (minutes)"));
    autosave_row.add_suffix(autosave_spin);
    general_group.add(autosave_row);

    // 11. Afficher la barre de statut
    var statusbar_row = new Adw.ActionRow();
    statusbar_row.set_title(_("Afficher la barre de statut"));
    var statusbar_switch = new Gtk.Switch();
    statusbar_switch.set_valign(Gtk.Align.CENTER);
    statusbar_row.add_suffix(statusbar_switch);
    general_group.add(statusbar_row);

    // 12. Afficher les raccourcis clavier
    var shortcuts_row = new Adw.ActionRow();
    shortcuts_row.set_title(_("Afficher les raccourcis clavier"));
    var shortcuts_switch = new Gtk.Switch();
    shortcuts_switch.set_valign(Gtk.Align.CENTER);
    shortcuts_row.add_suffix(shortcuts_switch);
    general_group.add(shortcuts_row);

    // 13. Mode compact
    var compact_row = new Adw.ActionRow();
    compact_row.set_title(_("Mode compact"));
    var compact_switch = new Gtk.Switch();
    compact_switch.set_valign(Gtk.Align.CENTER);
    compact_row.add_suffix(compact_switch);
    general_group.add(compact_row);

    // 14. Confirmation avant de quitter si des modifications non sauvegardées
    var confirm_row = new Adw.ActionRow();
    confirm_row.set_title(_("Confirmation avant de quitter si des modifications non sauvegardées"));
    var confirm_switch = new Gtk.Switch();
    confirm_switch.set_valign(Gtk.Align.CENTER);
    confirm_row.add_suffix(confirm_switch);
    general_group.add(confirm_row);
    general_page.add(general_group);
    this.add(general_page);
}
// Exemple d'utilisation d'un toast après une action réussie ou en erreur :
private void show_toast_success(string message) {
    var toast = new Adw.Toast(message);
    toast.set_timeout(2);
    var toast_overlay = get_ancestor(typeof(Adw.ToastOverlay)) as Adw.ToastOverlay;
    if (toast_overlay != null) {
        toast_overlay.add_toast(toast);
    }
}

private void show_toast_error(string message) {
    var toast = new Adw.Toast(message);
    toast.set_timeout(4);
    var toast_overlay = get_ancestor(typeof(Adw.ToastOverlay)) as Adw.ToastOverlay;
    if (toast_overlay != null) {
        toast_overlay.add_toast(toast);
    }
}

// Utilise show_toast_success("Chargement réussi") ou show_toast_error("Erreur lors du chargement")
// dans les callbacks de chargement/sauvegarde de document.
}
