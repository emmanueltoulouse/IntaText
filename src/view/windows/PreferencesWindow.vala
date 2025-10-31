namespace IntaText {
using Gtk;
using Gee;
using IntaText.Plugins;

public class PreferencesWindow : Adw.PreferencesWindow {
private ApplicationController controller;
private ConfigManager config;
private PluginManager plugin_manager;
private PluginConfigManager plugin_config_manager;
private HashMap<string, Gtk.Switch> plugin_switches;
private HashMap<string, Adw.ActionRow> plugin_rows;
private bool updating_extension_switch = false;
private Adw.PreferencesGroup? extensions_group = null;
private Adw.ActionRow? extensions_placeholder_row = null;

public PreferencesWindow(ApplicationController controller) {
    Object(
        title: _("Préférences"),
        default_width: 800,
        default_height: 600,
        modal: true,
        destroy_with_parent: true,
        transient_for: controller.get_main_window()
        );

    this.controller = controller;
    this.config = controller.get_config_manager();
    this.plugin_manager = controller.get_plugin_manager();
    this.plugin_config_manager = new PluginConfigManager();
    this.plugin_switches = new HashMap<string, Gtk.Switch>();
    this.plugin_rows = new HashMap<string, Adw.ActionRow>();

    connect_plugin_signals();
    setup_ui();
}

private void connect_plugin_signals() {
    plugin_manager.plugin_loaded.connect((plugin_id, plugin) => {
        GLib.Idle.add(() => {
            add_or_update_plugin_row(plugin_id);
            return GLib.Source.REMOVE;
        });
    });

    plugin_manager.plugin_activated.connect((plugin_id, plugin) => {
        GLib.Idle.add(() => {
            plugin_config_manager.enable_plugin(plugin_id);
            sync_plugin_switch(plugin_id, true);
            return GLib.Source.REMOVE;
        });
    });

    plugin_manager.plugin_deactivated.connect((plugin_id, plugin) => {
        GLib.Idle.add(() => {
            plugin_config_manager.disable_plugin(plugin_id);
            sync_plugin_switch(plugin_id, false);
            return GLib.Source.REMOVE;
        });
    });

    plugin_manager.plugin_error.connect((plugin_id, message) => {
        GLib.Idle.add(() => {
            show_toast_error(_("Extension %s : %s").printf(plugin_id, message));
            sync_plugin_switch(plugin_id, false);
            return GLib.Source.REMOVE;
        });
    });
}

private void setup_ui() {
    // Page Général
    add_page_general();

    // Page Éditeur
    add_page_editor();

    // Page Explorateur
    add_page_explorer();

    // Page Affichage (NOUVEAU)
    add_page_display();

    // Page Thèmes
    add_page_theme();

    // Page Extensions
    add_page_extensions();
}

private void add_page_general() {
    var general_page = new Adw.PreferencesPage();
    general_page.set_title(_("Général"));
    general_page.set_icon_name("preferences-system-symbolic");

    // --- Groupe Démarrage ---
    var startup_group = new Adw.PreferencesGroup();
    startup_group.set_title(_("Démarrage"));

    // Ouvrir le dernier fichier au démarrage
    var startup_row = new Adw.ActionRow();
    startup_row.set_title(_("Ouvrir le dernier fichier au démarrage"));
    var startup_switch = new Gtk.Switch();
    startup_switch.set_active(config.get_boolean("General", "open_last_file", true));
    startup_switch.set_valign(Gtk.Align.CENTER);
    startup_row.add_suffix(startup_switch);
    startup_group.add(startup_row);

    // Dossier de travail par défaut
    var folder_row = new Adw.ActionRow();
    folder_row.set_title(_("Dossier de travail par défaut"));
    var folder_button = new Gtk.Button.with_label(config.get_string("General", "default_folder", _("Choisir...")));
    folder_button.set_valign(Gtk.Align.CENTER);
    folder_row.add_suffix(folder_button);
    startup_group.add(folder_row);

    // Nombre maximum de fichiers récents
    var recent_row = new Adw.ActionRow();
    recent_row.set_title(_("Nombre maximum de fichiers récents"));
    var recent_spin = new Gtk.SpinButton.with_range(1, 50, 1);
    recent_spin.set_value(config.get_integer("General", "max_recent_files", 10));
    recent_row.add_suffix(recent_spin);
    startup_group.add(recent_row);

    general_page.add(startup_group);

    // --- Groupe Interface ---
    var interface_group = new Adw.PreferencesGroup();
    interface_group.set_title(_("Interface"));

    // Langue de l'interface
    var language_row = new Adw.ActionRow();
    language_row.set_title(_("Langue de l'interface"));
    var language_list = new Gtk.StringList({"Français", "English", "Español"});
    var language_dropdown = new Gtk.DropDown(language_list, null);
    language_dropdown.set_selected(config.get_integer("General", "language", 0));
    language_row.add_suffix(language_dropdown);
    interface_group.add(language_row);

    // Format de la date/heure
    var dateformat_row = new Adw.ActionRow();
    dateformat_row.set_title(_("Format de la date/heure"));
    var dateformat_list = new Gtk.StringList({ "24h", "12h", "Automatique" });
    var dateformat_dropdown = new Gtk.DropDown(dateformat_list, null);
    dateformat_dropdown.set_selected(config.get_integer("General", "time_format", 0));
    dateformat_row.add_suffix(dateformat_dropdown);
    interface_group.add(dateformat_row);

    // Barre de statut
    var statusbar_row = new Adw.ActionRow();
    statusbar_row.set_title(_("Afficher la barre de statut"));
    var statusbar_switch = new Gtk.Switch();
    statusbar_switch.set_active(config.get_boolean("General", "show_statusbar", true));
    statusbar_switch.set_valign(Gtk.Align.CENTER);
    statusbar_row.add_suffix(statusbar_switch);
    interface_group.add(statusbar_row);

    // Raccourcis clavier
    var shortcuts_row = new Adw.ActionRow();
    shortcuts_row.set_title(_("Afficher les raccourcis clavier"));
    var shortcuts_switch = new Gtk.Switch();
    shortcuts_switch.set_active(config.get_boolean("General", "show_shortcuts", true));
    shortcuts_switch.set_valign(Gtk.Align.CENTER);
    shortcuts_row.add_suffix(shortcuts_switch);
    interface_group.add(shortcuts_row);

    // Mode compact
    var compact_row = new Adw.ActionRow();
    compact_row.set_title(_("Mode compact"));
    var compact_switch = new Gtk.Switch();
    compact_switch.set_active(config.get_boolean("General", "compact_mode", false));
    compact_switch.set_valign(Gtk.Align.CENTER);
    compact_row.add_suffix(compact_switch);
    interface_group.add(compact_row);

    general_page.add(interface_group);

    // --- Groupe Conseils et sauvegarde ---
    var tips_group = new Adw.PreferencesGroup();
    tips_group.set_title(_("Conseils et sauvegarde"));

    // Afficher les conseils au démarrage
    var tips_row = new Adw.ActionRow();
    tips_row.set_title(_("Afficher les conseils au démarrage"));
    var tips_switch = new Gtk.Switch();
    tips_switch.set_active(config.get_boolean("General", "show_tips", true));
    tips_switch.set_valign(Gtk.Align.CENTER);
    tips_row.add_suffix(tips_switch);
    tips_group.add(tips_row);

    // Sauvegarde automatique
    var autosave_row = new Adw.ActionRow();
    autosave_row.set_title(_("Activer la sauvegarde automatique"));
    var autosave_switch = new Gtk.Switch();
    autosave_switch.set_active(config.get_boolean("General", "autosave", false));
    autosave_switch.set_valign(Gtk.Align.CENTER);
    autosave_row.add_suffix(autosave_switch);
    var autosave_spin = new Gtk.SpinButton.with_range(1, 60, 1);
    autosave_spin.set_value(config.get_integer("General", "autosave_interval", 5));
    autosave_spin.set_tooltip_text(_("Intervalle (minutes)"));
    autosave_row.add_suffix(autosave_spin);
    tips_group.add(autosave_row);

    general_page.add(tips_group);

    // --- Groupe Sécurité ---
    var security_group = new Adw.PreferencesGroup();
    security_group.set_title(_("Sécurité"));

    // Confirmation avant de quitter
    var confirm_row = new Adw.ActionRow();
    confirm_row.set_title(_("Confirmation avant de quitter si modifications non sauvegardées"));
    var confirm_switch = new Gtk.Switch();
    confirm_switch.set_active(config.get_boolean("General", "confirm_quit", true));
    confirm_switch.set_valign(Gtk.Align.CENTER);
    confirm_row.add_suffix(confirm_switch);
    security_group.add(confirm_row);

    general_page.add(security_group);

    // --- Groupe Mises à jour ---
    var update_group = new Adw.PreferencesGroup();
    update_group.set_title(_("Mises à jour"));

    // Mises à jour automatiques
    var updates_row = new Adw.ActionRow();
    updates_row.set_title(_("Activer les mises à jour automatiques"));
    var updates_switch = new Gtk.Switch();
    updates_switch.set_active(config.get_boolean("General", "auto_updates", true));
    updates_switch.set_valign(Gtk.Align.CENTER);
    updates_row.add_suffix(updates_switch);
    update_group.add(updates_row);

    general_page.add(update_group);

    add(general_page);

    // Connecter les signaux
    startup_switch.notify["active"].connect(() => {
                config.set_boolean("General", "open_last_file", startup_switch.active);
                config.save();
            });
    folder_button.clicked.connect(() => {
                var dialog = new Gtk.FileDialog();
                dialog.set_title(_("Choisir un dossier de travail"));
                dialog.select_folder.begin(this, null, (obj, res) => {
                    try {
                        var folder = dialog.select_folder.end(res);
                        if (folder != null) {
                            string path = folder.get_path();
                            folder_button.set_label(path);
                            config.set_string("General", "default_folder", path);
                            config.save();
                        }
                    } catch (Error e) {
                        warning("Erreur lors de la sélection du dossier: %s", e.message);
                    }
                });
            });
    recent_spin.value_changed.connect(() => {
                config.set_integer("General", "max_recent_files", (int)recent_spin.get_value());
                config.save();
            });
    language_dropdown.notify["selected"].connect(() => {
                config.set_integer("General", "language", (int)language_dropdown.get_selected());
                config.save();
            });
    dateformat_dropdown.notify["selected"].connect(() => {
                config.set_integer("General", "time_format", (int)dateformat_dropdown.get_selected());
                config.save();
            });
    statusbar_switch.notify["active"].connect(() => {
                config.set_boolean("General", "show_statusbar", statusbar_switch.active);
                config.save();
            });
    shortcuts_switch.notify["active"].connect(() => {
                config.set_boolean("General", "show_shortcuts", shortcuts_switch.active);
                config.save();
            });
    compact_switch.notify["active"].connect(() => {
                config.set_boolean("General", "compact_mode", compact_switch.active);
                config.save();
            });
    tips_switch.notify["active"].connect(() => {
                config.set_boolean("General", "show_tips", tips_switch.active);
                config.save();
            });
    autosave_switch.notify["active"].connect(() => {
                config.set_boolean("General", "autosave", autosave_switch.active);
                autosave_spin.set_sensitive(autosave_switch.active);
                config.save();
            });
    autosave_spin.value_changed.connect(() => {
                config.set_integer("General", "autosave_interval", (int)autosave_spin.get_value());
                config.save();
            });
    confirm_switch.notify["active"].connect(() => {
                config.set_boolean("General", "confirm_quit", confirm_switch.active);
                config.save();
            });
    updates_switch.notify["active"].connect(() => {
                config.set_boolean("General", "auto_updates", updates_switch.active);
                config.save();
            });
}

private void add_page_editor() {
    var editor_page = new Adw.PreferencesPage();
    editor_page.set_title(_("Éditeur"));
    editor_page.set_icon_name("text-editor-symbolic");

    var editor_group = new Adw.PreferencesGroup();
    editor_group.set_title(_("Paramètres d'édition"));

    var line_numbers_row = new Adw.ActionRow();
    line_numbers_row.set_title(_("Afficher les numéros de ligne"));
    var line_numbers_switch = new Gtk.Switch();
    line_numbers_switch.set_active(config.get_boolean("Editor", "show_line_numbers", true));
    line_numbers_switch.set_valign(Gtk.Align.CENTER);
    line_numbers_row.add_suffix(line_numbers_switch);
    editor_group.add(line_numbers_row);

    var wrap_lines_row = new Adw.ActionRow();
    wrap_lines_row.set_title(_("Retour à la ligne automatique"));
    var wrap_lines_switch = new Gtk.Switch();
    wrap_lines_switch.set_active(config.get_boolean("Editor", "wrap_lines", true));
    wrap_lines_switch.set_valign(Gtk.Align.CENTER);
    wrap_lines_row.add_suffix(wrap_lines_switch);
    editor_group.add(wrap_lines_row);

    editor_page.add(editor_group);

    // Groupe Markdown — style des titres (ATX / Setext)
    var markdown_group = new Adw.PreferencesGroup();
    markdown_group.set_title(_("Markdown"));

    var md_heading_row = new Adw.ActionRow();
    md_heading_row.set_title(_("Style des titres Markdown"));

    // Liste des choix et dropdown
    var md_heading_list = new Gtk.StringList({ "ATX ( #, ##, ### )", "Setext ( ====, ---- )" });
    var md_heading_dropdown = new Gtk.DropDown(md_heading_list, null);

    // Lecture/écriture via GSettings (schéma com.cabineteto.IntaText)
    var md_settings = new GLib.Settings("com.cabineteto.IntaText");
    string current_style = md_settings.get_string("markdown-heading-style");
    if (current_style == "setext") {
        md_heading_dropdown.set_selected(1);
    } else {
        md_heading_dropdown.set_selected(0);
    }

    md_heading_row.add_suffix(md_heading_dropdown);
    markdown_group.add(md_heading_row);

    editor_page.add(markdown_group);

    // Groupe Indentation
    var indentation_group = new Adw.PreferencesGroup();
    indentation_group.set_title(_("Indentation"));
    indentation_group.set_description(_("Configuration de l'indentation des paragraphes"));

    // Lecture de la configuration actuelle
    string current_indent_mode = md_settings.get_string("indentation-mode");

    // Bouton radio "Pas d'indentation"
    var none_row = new Adw.ActionRow();
    none_row.set_title(_("Pas d'indentation"));
    none_row.set_subtitle(_("Aucune indentation appliquée"));
    var none_radio = new Gtk.CheckButton();
    none_radio.set_active(current_indent_mode == "none");
    none_row.add_prefix(none_radio);
    indentation_group.add(none_row);

    // Bouton radio "Espaces"
    var spaces_row = new Adw.ActionRow();
    spaces_row.set_title(_("Espaces"));
    spaces_row.set_subtitle(_("Utilise des espaces pour l'indentation"));
    var spaces_radio = new Gtk.CheckButton();
    spaces_radio.set_group(none_radio);
    spaces_radio.set_active(current_indent_mode == "spaces");
    spaces_row.add_prefix(spaces_radio);
    indentation_group.add(spaces_row);

    // Bouton radio "Marge visuelle" (par défaut)
    var margin_row = new Adw.ActionRow();
    margin_row.set_title(_("Marge visuelle (Tags)"));
    margin_row.set_subtitle(_("Utilise les propriétés de marge GTK"));
    var margin_radio = new Gtk.CheckButton();
    margin_radio.set_group(none_radio);
    margin_radio.set_active(current_indent_mode == "margin-tags" || current_indent_mode == "");
    margin_row.add_prefix(margin_radio);
    indentation_group.add(margin_row);

    // Bouton radio "Format enrichi"
    var rtf_row = new Adw.ActionRow();
    rtf_row.set_title(_("Format enrichi (RTF)"));
    rtf_row.set_subtitle(_("Compatible avec les formats RTF"));
    var rtf_radio = new Gtk.CheckButton();
    rtf_radio.set_group(none_radio);
    rtf_radio.set_active(current_indent_mode == "rtf-format");
    rtf_row.add_prefix(rtf_radio);
    indentation_group.add(rtf_row);

    editor_page.add(indentation_group);
    add(editor_page);

    // Connecter les signaux
    line_numbers_switch.notify["active"].connect(() => {
                config.set_boolean("Editor", "show_line_numbers", line_numbers_switch.active);
                config.save();
            });

    wrap_lines_switch.notify["active"].connect(() => {
                config.set_boolean("Editor", "wrap_lines", wrap_lines_switch.active);
                config.save();
            });

    // Persister le style des titres Markdown dans GSettings
    md_heading_dropdown.notify["selected"].connect(() => {
                var sel = (int) md_heading_dropdown.get_selected();
                md_settings.set_string("markdown-heading-style", sel == 1 ? "setext" : "atx");
            });

    // Persister le type d'indentation dans GSettings avec les boutons radio
    none_radio.notify["active"].connect(() => {
                if (none_radio.active) {
                    md_settings.set_string("indentation-mode", "none");
                }
            });

    spaces_radio.notify["active"].connect(() => {
                if (spaces_radio.active) {
                    md_settings.set_string("indentation-mode", "spaces");
                }
            });

    margin_radio.notify["active"].connect(() => {
                if (margin_radio.active) {
                    md_settings.set_string("indentation-mode", "margin-tags");
                }
            });

    rtf_radio.notify["active"].connect(() => {
                if (rtf_radio.active) {
                    md_settings.set_string("indentation-mode", "rtf-format");
                }
            });
}

private void add_page_explorer() {
    var explorer_page = new Adw.PreferencesPage();
    explorer_page.set_title(_("Explorateur"));
    explorer_page.set_icon_name("folder-symbolic");

    var display_group = new Adw.PreferencesGroup();
    display_group.set_title(_("Affichage"));

    // --- Option Fichiers Cachés ---
    var show_hidden_row = new Adw.ActionRow();
    show_hidden_row.set_title(_("Afficher les fichiers cachés"));
    var show_hidden_switch = new Gtk.Switch();
    show_hidden_switch.set_valign(Gtk.Align.CENTER);
    // Lire l'état initial depuis le modèle (qui lit la config)
    var explorer_model = ApplicationControllerExtension.get_explorer_model(controller);
    show_hidden_switch.set_active(explorer_model.show_hidden_files);
    // Connecter le changement au modèle
    show_hidden_switch.state_set.connect((state) => {
                explorer_model.show_hidden_files = state; // Le setter du modèle sauvegarde la config
                return true;
            });
    show_hidden_row.add_suffix(show_hidden_switch);
    show_hidden_row.set_activatable_widget(show_hidden_switch);
    display_group.add(show_hidden_row);

    // --- Option Fil d'Ariane ---
    var breadcrumb_row = new Adw.ActionRow();
    breadcrumb_row.set_title(_("Afficher le fil d'Ariane"));
    breadcrumb_row.set_subtitle(_("Affiche le chemin de navigation dans l'explorateur"));

    var breadcrumb_switch = new Gtk.Switch();
    breadcrumb_switch.set_valign(Gtk.Align.CENTER);
    breadcrumb_switch.set_active(explorer_model.breadcrumb_enabled);         // Lire depuis le modèle

    breadcrumb_switch.state_set.connect((state) => {
                // Mettre à jour le modèle directement
                explorer_model.breadcrumb_enabled = state;
                // Sauvegarder la configuration
                config.set_boolean("Explorer", "breadcrumb_enabled", state);
                config.save();
                return false; // Important pour que le switch change visuellement d'état
            });
    breadcrumb_row.add_suffix(breadcrumb_switch);
    display_group.add(breadcrumb_row);

    // *** NOUVEAU : Option Barre de Recherche ***
    var search_bar_row = new Adw.ActionRow();
    search_bar_row.set_title(_("Afficher la barre de recherche"));
    var search_bar_switch = new Gtk.Switch();
    search_bar_switch.set_active(explorer_model.search_bar_enabled);         // Lire depuis le modèle
    search_bar_switch.set_valign(Gtk.Align.CENTER);

    search_bar_switch.state_set.connect((state) => {
                // Mettre à jour le modèle directement
                explorer_model.search_bar_enabled = state;
                // Sauvegarder la configuration
                config.set_boolean("Explorer", "search_bar_enabled", state);
                config.save();
                return false; // Important
            });
    search_bar_row.add_suffix(search_bar_switch);
    display_group.add(search_bar_row);
    // *** FIN NOUVEAU ***

    explorer_page.add(display_group);

    this.add(explorer_page);
}

private void add_page_display() {
    var display_page = new Adw.PreferencesPage();
    display_page.set_title(_("Affichage"));
    display_page.set_icon_name("preferences-desktop-display-symbolic");

    var editor_group = new Adw.PreferencesGroup();
    editor_group.set_title(_("Éditeur - Apparence par défaut"));

    // Sélecteur de police
    var font_row = new Adw.ActionRow();
    font_row.set_title(_("Police de l'éditeur"));
    var font_button = new Gtk.FontButton();
    string font_ini = config.get_string("Editor", "font_family", "Sans");
    font_button.set_font(font_ini);
    font_row.add_suffix(font_button);
    editor_group.add(font_row);

    // Sélecteur de taille
    var size_row = new Adw.ActionRow();
    size_row.set_title(_("Taille de police"));
    int size_ini = config.get_integer("Editor", "font_size", 12);
    var size_spin = new Gtk.SpinButton.with_range(6, 48, 1);
    size_spin.set_value(size_ini);
    size_row.add_suffix(size_spin);
    editor_group.add(size_row);

    // Largeur minimale du contenu de l'éditeur (GSettings)
    var minw_row = new Adw.ActionRow();
    minw_row.set_title(_("Largeur minimale du contenu (px)"));
    var minw_spin = new Gtk.SpinButton.with_range(200, 2000, 10);
    var ui_settings = new GLib.Settings("com.cabineteto.IntaText");
    int minw_ini = ui_settings.get_int("editor-min-content-width");
    if (minw_ini < 200) minw_ini = 800; // fallback sensé
    minw_spin.set_value(minw_ini);
    minw_row.add_suffix(minw_spin);
    editor_group.add(minw_row);

    // Sélecteur de couleur
    var color_row = new Adw.ActionRow();
    color_row.set_title(_("Couleur du texte"));
    var color_button = new Gtk.ColorButton();
    Gdk.RGBA color_ini = Gdk.RGBA();
    color_ini.parse(config.get_string("Editor", "font_color", "#222222"));
    color_button.set_rgba(color_ini);
    color_row.add_suffix(color_button);
    editor_group.add(color_row);

    display_page.add(editor_group);
    add(display_page);

    // --- Connexion des signaux pour sauvegarde et application immédiate ---
    font_button.notify["font"].connect(() => {
                // Gtk.FontButton.get_font() peut retourner "FamilyName Size".
                // On ne conserve que le nom de la famille pour la CSS.
                string font = font_button.get_font();
                string family_only = font;
                try {
                    // Si le dernier token est un entier, on l'enlève
                    var parts = font.split(" ");
                    if (parts.length > 1) {
                        string last = parts[parts.length - 1];
                        // Vérifie si le dernier token est un nombre
                        bool is_number = true;
                        foreach (char c in last.to_utf8()) {
                            if (!((c >= '0' && c <= '9'))) {
                                is_number = false; break;
                            }
                        }
                        if (is_number) {
                            family_only = string.joinv(" ", parts[0 : parts.length - 1]);
                        }
                    }
                } catch (Error e) {
                    // Fallback: garder tel quel
                    family_only = font;
                }
                config.set_string("Editor", "font_family", family_only);
                config.save();
                controller.apply_editor_style_from_preferences();
            });
    size_spin.value_changed.connect(() => {
                int size = (int)size_spin.get_value();
                config.set_integer("Editor", "font_size", size);
                config.save();
                controller.apply_editor_style_from_preferences();
            });
    minw_spin.value_changed.connect(() => {
                int w = (int)minw_spin.get_value();
                if (w < 200) w = 200;
                ui_settings.set_int("editor-min-content-width", w);
            });
    color_button.color_set.connect(() => {
                Gdk.RGBA color = color_button.get_rgba();
                config.set_string("Editor", "font_color", color.to_string());
                config.save();
                controller.apply_editor_style_from_preferences();
            });
}

private void add_page_theme() {
    var theme_page = new Adw.PreferencesPage();
    theme_page.set_title(_("Thèmes"));
    theme_page.set_icon_name("preferences-desktop-appearance-symbolic");

    var appearance_group = new Adw.PreferencesGroup();
    appearance_group.set_title(_("Apparence"));

    var dark_mode_row = new Adw.ActionRow();
    dark_mode_row.set_title(_("Mode sombre"));
    var dark_mode_switch = new Gtk.Switch();
    dark_mode_switch.set_active(config.get_boolean("Theme", "dark_mode", false));
    dark_mode_switch.set_valign(Gtk.Align.CENTER);
    dark_mode_row.add_suffix(dark_mode_switch);
    appearance_group.add(dark_mode_row);

    var accent_color_row = new Adw.ActionRow();
    accent_color_row.set_title(_("Couleur d'accentuation"));

    var accent_button = new Gtk.ColorButton();
    Gdk.RGBA accent_color = Gdk.RGBA();
    accent_color.parse(config.get_string("Theme", "accent_color", "#3584e4"));
    accent_button.set_rgba(accent_color);
    accent_button.set_valign(Gtk.Align.CENTER);
    accent_color_row.add_suffix(accent_button);
    appearance_group.add(accent_color_row);

    theme_page.add(appearance_group);
    add(theme_page);

    // Connecter les signaux
    dark_mode_switch.notify["active"].connect(() => {
                config.set_boolean("Theme", "dark_mode", dark_mode_switch.active);
                config.save();

                // Appliquer immédiatement le thème
                var style_manager = Adw.StyleManager.get_default();
                style_manager.color_scheme = dark_mode_switch.active ?
                                             Adw.ColorScheme.FORCE_DARK : Adw.ColorScheme.FORCE_LIGHT;
            });

    accent_button.color_set.connect(() => {
                Gdk.RGBA color = accent_button.get_rgba();
                string color_string = color.to_string();
                config.set_string("Theme", "accent_color", color_string);
                config.save();
                // TODO: Appliquer la couleur d'accentuation
            });
}

private void add_page_extensions() {
    var extensions_page = new Adw.PreferencesPage();
    extensions_page.set_title(_("Extensions"));
    extensions_page.set_icon_name("application-x-addon-symbolic");

    extensions_group = new Adw.PreferencesGroup();
    extensions_group.set_title(_("Extensions installées"));
    extensions_group.set_description(_("Activez ou désactivez les extensions détectées par IntaText"));

    extensions_page.add(extensions_group);

    foreach (var plugin_id in plugin_manager.get_plugin_ids()) {
        add_or_update_plugin_row(plugin_id);
    }

    if (plugin_switches.size == 0) {
        add_extensions_placeholder();
    }

    add(extensions_page);
}

private void add_extensions_placeholder() {
    if (extensions_group == null || extensions_placeholder_row != null) {
        return;
    }

    var placeholder_row = new Adw.ActionRow();
    placeholder_row.set_title(_("Aucune extension détectée"));
    placeholder_row.set_subtitle(_("Copiez vos plugins compilés dans ~/.local/share/intatext/plugins"));
    placeholder_row.set_sensitive(false);

    extensions_group.add(placeholder_row);
    extensions_placeholder_row = placeholder_row;
}

private void add_or_update_plugin_row(string plugin_id) {
    if (extensions_group == null) {
        return;
    }

    var plugin_info = plugin_manager.get_plugin_info(plugin_id);
    if (plugin_info == null) {
        return;
    }

    if (extensions_placeholder_row != null) {
        extensions_placeholder_row.unparent();
        extensions_placeholder_row = null;
    }

    var metadata = plugin_info.metadata;

    Adw.ActionRow row;
    Gtk.Switch toggle;

    if (plugin_rows.has_key(plugin_id)) {
        row = plugin_rows.get(plugin_id);
        toggle = plugin_switches.get(plugin_id);
    } else {
        row = new Adw.ActionRow();
        toggle = new Gtk.Switch();
        toggle.set_valign(Gtk.Align.CENTER);
        row.add_suffix(toggle);
        row.set_activatable_widget(toggle);

        extensions_group.add(row);
        plugin_rows.set(plugin_id, row);
        plugin_switches.set(plugin_id, toggle);

        toggle.notify["active"].connect(() => {
            if (updating_extension_switch) {
                return;
            }

            bool new_state = toggle.get_active();
            if (!apply_plugin_state(plugin_id, new_state)) {
                updating_extension_switch = true;
                toggle.set_active(!new_state);
                updating_extension_switch = false;
            }
        });
    }

    row.set_title(metadata.name.length > 0 ? metadata.name : plugin_id);
    row.set_subtitle(build_plugin_subtitle(metadata, plugin_info.state));

    bool is_active = plugin_info.state == PluginState.ACTIVE;
    updating_extension_switch = true;
    toggle.set_active(is_active);
    updating_extension_switch = false;
}

private string build_plugin_subtitle(PluginMetadata metadata, PluginState state) {
    var parts = new ArrayList<string>();
    parts.add(_("Version %s").printf(metadata.version));

    if (metadata.description.length > 0) {
        parts.add(metadata.description);
    }

    parts.add(state == PluginState.ACTIVE ? _("Actif") : _("Inactif"));

    return string.joinv(" • ", parts.to_array());
}

private bool apply_plugin_state(string plugin_id, bool enable) {
    var plugin_info = plugin_manager.get_plugin_info(plugin_id);
    if (plugin_info == null) {
        return false;
    }

    var metadata = plugin_info.metadata;

    if (enable) {
        plugin_config_manager.enable_plugin(plugin_id);

        if (plugin_info.state != PluginState.ACTIVE) {
            if (!plugin_manager.activate_plugin(plugin_id)) {
                plugin_config_manager.disable_plugin(plugin_id);
                show_toast_error(_("Impossible d'activer l'extension \"%s\".").printf(metadata.name));
                return false;
            }

            show_toast_success(_("Extension \"%s\" activée").printf(metadata.name));
        }
    } else {
        plugin_config_manager.disable_plugin(plugin_id);

        if (plugin_info.state == PluginState.ACTIVE) {
            if (!plugin_manager.deactivate_plugin(plugin_id)) {
                plugin_config_manager.enable_plugin(plugin_id);
                show_toast_error(_("Impossible de désactiver l'extension \"%s\".").printf(metadata.name));
                return false;
            }

            show_toast_success(_("Extension \"%s\" désactivée").printf(metadata.name));
        }
    }

    update_plugin_row_state(plugin_id);
    return true;
}

private void sync_plugin_switch(string plugin_id, bool active) {
    if (!plugin_switches.has_key(plugin_id)) {
        return;
    }

    updating_extension_switch = true;
    plugin_switches.get(plugin_id).set_active(active);
    updating_extension_switch = false;

    update_plugin_row_state(plugin_id);
}

private void update_plugin_row_state(string plugin_id) {
    if (!plugin_rows.has_key(plugin_id)) {
        return;
    }

    var plugin_info = plugin_manager.get_plugin_info(plugin_id);
    if (plugin_info == null) {
        return;
    }

    var row = plugin_rows.get(plugin_id);
    row.set_subtitle(build_plugin_subtitle(plugin_info.metadata, plugin_info.state));
}

/**
  * Crée et configure l'onglet des préférences générales d'interface
  */
private Adw.PreferencesPage create_interface_page() {
    var page = new Adw.PreferencesPage();
    page.set_title(_("Interface"));
    page.set_icon_name("preferences-desktop-display-symbolic");

    // Groupe général
    var general_group = new Adw.PreferencesGroup();
    general_group.set_title(_("Général"));
    page.add(general_group);

    // Option pour l'explorateur détaché
    var detached_row = new Adw.ActionRow();
    detached_row.set_title(_("Explorateur détaché"));
    detached_row.set_subtitle(_("Afficher l'explorateur dans une fenêtre séparée"));

    var detached_switch = new Gtk.Switch();
    detached_switch.set_active(controller.is_using_detached_explorer());
    detached_switch.set_valign(Gtk.Align.CENTER);

    // MODIFIER: Correction du gestionnaire d'événement pour sauvegarder le paramètre
    detached_switch.state_set.connect((state) => {
                // Modifier le paramètre via le contrôleur
                controller.set_detached_explorer(state);

                // Informer l'utilisateur qu'un redémarrage est nécessaire
                var dialog = new Adw.AlertDialog(
                    _("Redémarrage nécessaire"),
                    _("Ce changement nécessite un redémarrage de l'application pour prendre effet.")
                    );
                dialog.add_response("ok", _("OK"));
                dialog.present(this.get_root() as Gtk.Window);

                return true; // Accepter le changement d'état
            });

    detached_row.add_suffix(detached_switch);
    detached_row.set_activatable_widget(detached_switch);
    general_group.add(detached_row);

    // Autres options...
    return page;
}

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
}
}
