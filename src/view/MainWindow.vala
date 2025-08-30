using Gtk;
using Adw;
using Gee;

namespace IntaText {

public enum DocumentSource {
    UNKNOWN,
    EXPLORER,
    FILE_DIALOG
}

public class MainWindow : Adw.ApplicationWindow {
private ApplicationController controller;

private Adw.HeaderBar header_bar;
private Box main_box;
private Paned main_paned;
private Paned top_paned;

private ExplorerView? explorer_view;

private Notebook editor_notebook;
private Gee.List<EditorView> editor_tabs = new Gee.ArrayList<EditorView>();
private bool use_detached_explorer = false;
// Barre de statut
private Gtk.Box status_bar;
private Gtk.Label status_label;
private Gtk.Label cursor_label;
private bool show_statusbar_pref = true;

public signal void file_opened(string path);
public signal void directory_changed(string path);

public MainWindow(Gtk.Application app, ApplicationController controller, bool detached_explorer_mode = false) {
    Object(
        application: app,
        title: "IntaText",
        default_width: 1200,
        default_height: 600,
        resizable: true
        );
    this.controller = controller;
    this.use_detached_explorer = detached_explorer_mode;

    setup_ui();
    setup_actions();
    connect_signals();

    // Restaurer la fenêtre au démarrage
    this.map.connect(() => {
                Timeout.add(100, () => {
                    restore_window_state();
                    return false;
                });
            });
}

// === UI ===
private void setup_ui() {
    main_box = new Box(Orientation.VERTICAL, 0);

    // HeaderBar
    header_bar = new Adw.HeaderBar();

    // Menu hamburger à droite
    var menu_button = new MenuButton();
    menu_button.set_icon_name("open-menu-symbolic");
    menu_button.set_tooltip_text("Menu principal");
    menu_button.set_menu_model(build_app_menu());
    header_bar.pack_end(menu_button);

    main_box.append(header_bar);

    // Paned principal
    main_paned = new Paned(Orientation.VERTICAL);
    main_paned.set_vexpand(true);
    main_paned.set_wide_handle(true);

    if (use_detached_explorer) {
        explorer_view = null;
        top_paned = null;
        editor_notebook = new Notebook();
        main_box.append(editor_notebook);
    }
    else {
        top_paned = new Paned(Orientation.HORIZONTAL);
        top_paned.set_wide_handle(true);
        top_paned.set_vexpand(true);
        // trace supprimée

        var explorer_model = ApplicationControllerExtension.get_explorer_model(controller);
        explorer_view = new ExplorerView(explorer_model);
        top_paned.set_start_child(explorer_view);

        editor_notebook = new Notebook();
        top_paned.set_end_child(editor_notebook);

        main_paned.set_start_child(top_paned);

        main_paned.set_resize_start_child(false);
        main_paned.set_shrink_start_child(false);
        main_paned.set_resize_end_child(false);
        main_paned.set_shrink_end_child(false);
        top_paned.set_resize_start_child(false);
        top_paned.set_shrink_start_child(false);

        top_paned.set_position(280);
        main_paned.set_position(500);
    }

    // Mettre à jour la barre de statut lors des changements d'onglet
    editor_notebook.switch_page.connect((page, page_num) => {
                update_status_bar();
            });

    main_box.append(main_paned);

    // Barre de statut en bas
    status_bar = new Gtk.Box(Orientation.HORIZONTAL, 6);
    status_bar.add_css_class("toolbar");
    status_bar.add_css_class("statusbar");
    status_bar.set_margin_top(0);
    status_label = new Gtk.Label("");
    status_label.set_xalign(0.0f);
    status_label.set_hexpand(true); // pousse le label du curseur à droite
    status_bar.append(status_label);
    // Label curseur à droite "Lig :xxxx  Col:xxx"
    cursor_label = new Gtk.Label("");
    cursor_label.set_xalign(1.0f);
    cursor_label.set_hexpand(false);
    status_bar.append(cursor_label);
    // Charger préférence
    var cfg = controller.get_config_manager();
    show_statusbar_pref = cfg.get_boolean("General", "show_statusbar", true);
    status_bar.set_visible(show_statusbar_pref);
    main_box.append(status_bar);

    // Créer un ToastOverlay autour de main_box
    var toast_overlay = new Adw.ToastOverlay();
    toast_overlay.set_child(main_box);
    set_content(toast_overlay);

    // Onglet par défaut
    var default_editor = new EditorView(controller);
    default_editor.set_document_source((EditorView.DocumentSource)DocumentSource.UNKNOWN);
    default_editor.set_current_file_path("");
    // MAJ en direct des coordonnées du curseur
    default_editor.cursor_position_changed.connect((l, c) => { update_status_bar(); });
    editor_tabs.add(default_editor);
    var default_tab_box = create_tab_box(_("Nouveau document"), default_editor);
    editor_notebook.append_page(default_editor, default_tab_box);
    editor_notebook.set_tab_reorderable(default_editor, true);
    editor_notebook.set_current_page(0);
    update_status_bar();
}

// === Actions et menus ===
private void setup_actions() {
    var quit_action = new SimpleAction("quit", null);
    quit_action.activate.connect(() => {
                if (should_confirm_quit()) {
                    var dialog = new Adw.AlertDialog(
                        _("Quitter l'application"),
                        _("Êtes-vous sûr de vouloir quitter ? Les modifications non enregistrées seront perdues.")
                        );
                    dialog.add_response("cancel", _("Annuler"));
                    dialog.add_response("quit", _("Quitter"));
                    dialog.set_response_appearance("quit", Adw.ResponseAppearance.DESTRUCTIVE);
                    dialog.response.connect((response) => {
                        if (response == "quit") {
                            save_window_state();
                            application.quit();
                        }
                    });
                    dialog.present(this);
                }
                else {
                    save_window_state();
                    application.quit();
                }
            });

    var preferences_action = new SimpleAction("preferences", null);
    preferences_action.activate.connect(() => {
                var prefs_window = new PreferencesWindow(controller);
                prefs_window.present();
            });

    var about_action = new SimpleAction("about", null);
    about_action.activate.connect(() => {
                var about = new Gtk.AboutDialog();
                about.transient_for = this;
                about.program_name = "IntaText";
                about.logo_icon_name = "com.cabineteto.IntaText";
                about.version = "0.1.0";
                about.copyright = "© 2023 Cabinet ETO";
                about.license_type = Gtk.License.GPL_3_0;
                about.website = "https://cabineteto.com";
                about.website_label = _("Site Web");
                // Supprimé les auteurs pour éviter les problèmes de type
                about.present();
            });

    add_action(quit_action);
    add_action(preferences_action);
    add_action(about_action);

    application.set_accels_for_action("win.quit", {"<Control>q"});
    application.set_accels_for_action("win.preferences", {"<Control>comma"});

    var save_action = new SimpleAction("save-file", null);
    save_action.activate.connect(() => { save_current_document(); });
    this.add_action(save_action);

    var save_as_action = new SimpleAction("save-file-as", null);
    save_as_action.activate.connect(() => { save_current_document_as(); });
    this.add_action(save_as_action);

    application.set_accels_for_action("win.save-file", {"<Control>s"});
    application.set_accels_for_action("win.save-file-as", {"<Control><Shift>s"});

    var toggle_explorer_action = new SimpleAction("toggle-explorer", null);
    toggle_explorer_action.activate.connect(() => {
                // Toggle: si l'explorateur est visible, on le masque, sinon on l'affiche
                bool current_visible = (top_paned != null && top_paned.get_start_child() == explorer_view);
                controller.toggle_explorer_visibility(!current_visible);
            });
    this.add_action(toggle_explorer_action);

    // Action: Nouveau fichier (onglet vierge)
    var new_file_action = new SimpleAction("new-file", null);
    new_file_action.activate.connect(() => {
                create_new_blank_tab();
            });
    this.add_action(new_file_action);
    application.set_accels_for_action("win.new-file", {"<Control>n"});

    // Action: Ouvrir fichier (dialogue de fichiers)
    var open_file_action = new SimpleAction("open-file", null);
    open_file_action.activate.connect(() => {
                var open_dialog = new FileDialog();
                open_dialog.set_title(_("Ouvrir un fichier"));
                // Filtres standard
                var filter = new FileFilter();
                filter.add_mime_type("text/plain");
                filter.add_mime_type("text/markdown");
                filter.add_mime_type("text/html");
                filter.add_pattern("*.txt");
                filter.add_pattern("*.md");
                filter.add_pattern("*.html");
                var list = new GLib.ListStore(typeof(FileFilter));
                list.append(filter);
                open_dialog.set_filters(list);
                open_dialog.open.begin(this, null, (obj, res) => {
                            try {
                                var file = open_dialog.open.end(res);
                                if (file != null) {
                                    controller.handle_file_open_request(file.get_path());
                                }
                            } catch (Error e) {
                                // Annulation ou erreur: toast non intrusif
                                add_toast(new Adw.Toast(_("Ouverture annulée")));
                            }
                        });
            });
    this.add_action(open_file_action);
    application.set_accels_for_action("win.open-file", {"<Control>o"});
}

private GLib.MenuModel build_app_menu() {
    var menu = new GLib.Menu();
    var file_menu = new GLib.Menu();
    file_menu.append(_("Nouveau"), "win.new-file");
    file_menu.append(_("Ouvrir..."), "win.open-file");
    file_menu.append(_("Enregistrer"), "win.save-file");
    file_menu.append(_("Enregistrer sous..."), "win.save-file-as");
    file_menu.append(_("Fermer"), "win.close-file");
    file_menu.append(_("Quitter"), "win.quit");

    var edit_menu = new GLib.Menu();
    edit_menu.append(_("Annuler"), "win.undo");
    edit_menu.append(_("Rétablir"), "win.redo");
    edit_menu.append(_("Couper"), "win.cut");
    edit_menu.append(_("Copier"), "win.copy");
    edit_menu.append(_("Coller"), "win.paste");

    var view_menu = new GLib.Menu();
    view_menu.append(_("Plein écran"), "win.fullscreen");
    view_menu.append(_("Mode sombre"), "win.dark-mode");
    // AJOUT ICI :
    view_menu.append(_("Afficher/Masquer l'explorateur"), "win.toggle-explorer");

    var tools_menu = new GLib.Menu();
    tools_menu.append(_("Préférences"), "win.preferences");
    tools_menu.append(_("Comparer des fichiers..."), "win.compare-files");
    tools_menu.append(_("Extensions..."), "win.extensions");

    var help_menu = new GLib.Menu();
    help_menu.append(_("Documentation"), "win.documentation");
    help_menu.append(_("À propos"), "win.about");

    menu.append_submenu(_("Fichier"), file_menu);
    menu.append_submenu(_("Affichage"), view_menu);
    menu.append_submenu(_("Outils"), tools_menu);
    menu.append_submenu(_("Aide"), help_menu);

    return menu;
}

// === Signaux et gestion d'état ===
private void connect_signals() {
    this.close_request.connect(on_close_request);

    main_paned.notify["position"].connect(() => {
                int width, height;
                this.get_default_size(out width, out height);
                int min_comm_height = 150;
                int max_top_height = height - min_comm_height;
                if (main_paned.get_position() > max_top_height) {
                    main_paned.set_position(max_top_height);
                }
            });
}

public void set_integrated_explorer_visible(bool show) {
    if (use_detached_explorer || explorer_view == null || top_paned == null) return;
    if (show) {
        explorer_view.set_visible(true);
    }
    else {
        explorer_view.set_visible(false);
    }
}

// === Gestion des onglets ===
public void open_document_in_tab(IntaText.Document.PivotDocument doc, string file_path, DocumentSource source = DocumentSource.EXPLORER) {
    int current_page = editor_notebook.get_current_page();
    bool is_empty_first_tab = false;
    if (current_page >= 0 && current_page < editor_tabs.size) {
        var current_editor = editor_tabs[current_page];
        is_empty_first_tab = (current_editor.current_document == null);
    }

    EditorView editor;
    if (is_empty_first_tab) {
        editor = editor_tabs[current_page];
        editor.load_document(doc);
        var tab_box = create_tab_box(Path.get_basename(file_path), editor);
        editor_notebook.set_tab_label(editor_notebook.get_nth_page(current_page), tab_box);
        editor_notebook.set_tab_reorderable(editor, true);
    }
    else {
        editor = new EditorView(controller);
        editor.load_document(doc);
        var tab_box = create_tab_box(Path.get_basename(file_path), editor);
        editor_tabs.add(editor);
        int page_num = editor_notebook.append_page(editor, tab_box);
        editor_notebook.set_current_page(page_num);
        editor_notebook.set_tab_reorderable(editor, true);
    }

    // Définir la provenance et le chemin du fichier pour la barre d'état
    editor.set_document_source((EditorView.DocumentSource)source);
    editor.set_current_file_path(file_path);

    var page_num = editor_notebook.page_num(editor);
    var tab_label = editor_notebook.get_tab_label(editor);
    update_tab_appearance(editor, tab_label);
    // Écoute de la position du curseur pour MAJ status bar
    editor.cursor_position_changed.connect((l, c) => { update_status_bar(); });
    update_status_bar();
}

private Box create_tab_box(string title, EditorView editor) {
    var tab_box = new Box(Orientation.HORIZONTAL, 6);
    var label = new Label(title);
    label.add_css_class("tab-label-black");
    var close_button = new Button.from_icon_name("window-close-symbolic");
    close_button.add_css_class("flat");
    close_button.add_css_class("circular");
    close_button.set_tooltip_text(_("Fermer"));
    close_button.set_valign(Align.CENTER);
    tab_box.append(label);
    tab_box.append(close_button);
    tab_box.show();

    close_button.clicked.connect(() => {
                close_tab(editor);
            });

    // Connexion du signal de changement d'état de sauvegarde
    // Connect to document changes using a public method/property instead
    editor.notify["has-unsaved-changes"].connect(() => {
                update_tab_appearance(editor, tab_box);
                update_status_bar();
            });

    return tab_box;
}

private void update_tab_appearance(EditorView editor, Gtk.Widget tab_label) {
    if (tab_label is Box) {
        var box = (Box)tab_label;
        var label = box.get_first_child();
        while (label != null && !(label is Label)) {
            label = label.get_next_sibling();
        }
        // Correction ici : appel de la propriété ou méthode selon la déclaration dans EditorView
        bool has_changes = false;
            #if HAS_UNSAVED_CHANGES_IS_PROPERTY
        has_changes = editor.has_unsaved_changes;
            #else
        has_changes = editor.has_unsaved_changes;
            #endif
        if (label is Label) {
            var text_label = (Label)label;
            if (editor_tabs.size == 1 && editor == editor_tabs[0] &&
                editor.current_document == null && !has_changes) {
                text_label.add_css_class("tab-label-black");
                text_label.remove_css_class("tab-label-green");
                text_label.remove_css_class("tab-label-yellow");
            }
            else if (!has_changes) {
                text_label.add_css_class("tab-label-green");
                text_label.remove_css_class("tab-label-yellow");
                text_label.remove_css_class("tab-label-black");
            }
            else {
                text_label.add_css_class("tab-label-yellow");
                text_label.remove_css_class("tab-label-green");
                text_label.remove_css_class("tab-label-black");
            }
        }
    }
}

public void close_tab(EditorView editor_to_close) {
    int editor_index = -1;
    for (int i = 0; i < editor_tabs.size; i++) {
        if (editor_tabs[i] == editor_to_close) {
            editor_index = i;
            break;
        }
    }
    if (editor_index >= 0) {
        // Correction ici : appel de la propriété ou méthode selon la déclaration dans EditorView
        bool has_changes = false;
            #if HAS_UNSAVED_CHANGES_IS_PROPERTY
        has_changes = editor_to_close.has_unsaved_changes;
            #else
        has_changes = editor_to_close.has_unsaved_changes;
            #endif
        if (has_changes) {
            var dialog = new Gtk.MessageDialog(
                this,
                DialogFlags.MODAL,
                MessageType.QUESTION,
                ButtonsType.NONE,
                _(
                    "Ce document contient des modifications non sauvegardées. Souhaitez-vous l'enregistrer avant de fermer?")
                );
            dialog.add_button(_("Abandonner les modifications"), 0);
            dialog.add_button(_("Annuler"), 1);
            dialog.add_button(_("Enregistrer"), 2);
            var captured_editor = editor_to_close;
            var captured_index = editor_index;
            dialog.response.connect((id) => {
                        dialog.destroy();
                        if (id == 0) {
                            remove_tab(captured_index);
                        }
                        else if (id == 2) {
                            if (captured_editor.save_document()) {
                                remove_tab(captured_index);
                            }
                        }
                    });
            dialog.show();
        }
        else {
            remove_tab(editor_index);
        }
    }
}

private void remove_tab(int index) {
    if (index >= 0 && index < editor_tabs.size) {
        var editor = editor_tabs[index];
        editor_tabs.remove_at(index);
        editor_notebook.remove_page(index);
        if (editor_tabs.size == 0) {
            var new_editor = new EditorView(controller);
            // MAJ en direct des coordonnées du curseur pour le nouvel onglet vierge
            new_editor.cursor_position_changed.connect((l, c) => { update_status_bar(); });
            editor_tabs.add(new_editor);
            editor_notebook.append_page(new_editor, new Label(_("Nouveau document")));
        }
        update_status_bar();
    }
}

// Crée un nouvel onglet vierge et le sélectionne
private void create_new_blank_tab() {
    var editor = new EditorView(controller);
    editor.set_document_source((EditorView.DocumentSource)DocumentSource.UNKNOWN);
    editor.set_current_file_path("");
    // MAJ en direct des coordonnées du curseur pour la barre de statut
    editor.cursor_position_changed.connect((l, c) => { update_status_bar(); });
    editor_tabs.add(editor);
    var tab_box = create_tab_box(_("Nouveau document"), editor);
    int page_num = editor_notebook.append_page(editor, tab_box);
    editor_notebook.set_tab_reorderable(editor, true);
    editor_notebook.set_current_page(page_num);
    update_status_bar();
}

// === Fermeture et sauvegarde ===
private bool should_confirm_quit() {
    foreach (var editor in editor_tabs) {
        // Correction ici : appel de la propriété ou méthode selon la déclaration dans EditorView
        bool has_changes = false;
            #if HAS_UNSAVED_CHANGES_IS_PROPERTY
        has_changes = editor.has_unsaved_changes;
            #else
        has_changes = editor.has_unsaved_changes;
            #endif
        if (has_changes) {
            var dialog = new Adw.MessageDialog(this,
                _("Modifications non sauvegardées"),
                _("Certains documents ont des modifications non sauvegardées. Voulez-vous vraiment quitter?")
                );
            dialog.add_response("cancel", _("Annuler"));
            dialog.add_response("save_quit", _("Sauvegarder et quitter"));
            dialog.add_response("quit", _("Quitter sans sauvegarder"));
            dialog.set_response_appearance("quit", Adw.ResponseAppearance.DESTRUCTIVE);
            dialog.set_response_appearance("save_quit", Adw.ResponseAppearance.SUGGESTED);
            dialog.set_default_response("cancel");
            dialog.response.connect((response) => {
                        if (response == "save_quit") {
                            save_all_documents();
                            this.application.quit();
                        }
                        else if (response == "quit") {
                            this.application.quit();
                        }
                    });
            dialog.present();
            return true;
        }
    }
    return false;
}

private void save_all_documents() {
    foreach (var editor in editor_tabs) {
        // Correction ici : appel de la propriété ou méthode selon la déclaration dans EditorView
        bool has_changes = false;
            #if HAS_UNSAVED_CHANGES_IS_PROPERTY
        has_changes = editor.has_unsaved_changes;
            #else
        has_changes = editor.has_unsaved_changes;
            #endif
        if (has_changes) {
            editor.save_document();
        }
    }
}

private bool on_close_request() {
    save_window_state();
    if (should_confirm_quit()) {
        return true;
    }
    application.quit();
    return true;
}

private void save_window_state() {
    int width, height;
    this.get_default_size(out width, out height);
    var main_position = top_paned != null ? top_paned.get_position() : 0;
    var config = controller.get_config_manager();
    config.set_integer("Window", "width", width);
    config.set_integer("Window", "height", height);
    config.set_integer("Window", "main_paned_position", main_position);
    config.save();
}

private void restore_window_state() {
    var config = controller.get_config_manager();
    int width = config.get_integer("Window", "width", 800);
    int height = config.get_integer("Window", "height", 600);
    width = int.max(width, 600);
    height = int.max(height, 450);
    this.set_default_size(width, height);
    bool show_explorer = true;
    Timeout.add(50, () => {
                controller.toggle_explorer_visibility(show_explorer);
                return false;
            });
    if (!use_detached_explorer) {
        int main_position = config.get_integer("Window", "main_paned_position", 280);
        Timeout.add(150, () => {
                    if (top_paned != null) top_paned.set_position(main_position);
                    return false;
                });
    }
}

// === Utilitaires ===
public Adw.HeaderBar? get_header_bar() {
    return header_bar;
}
public ExplorerView? get_explorer_view() {
    return explorer_view;
}

private void save_current_document() {
    int current_page = editor_notebook.get_current_page();
    if (current_page >= 0 && current_page < editor_tabs.size) {
        var editor = editor_tabs[current_page];
        editor.save_document();
        update_status_bar();
    }
}

private void save_current_document_as() {
    int current_page = editor_notebook.get_current_page();
    if (current_page >= 0 && current_page < editor_tabs.size) {
        var editor = editor_tabs[current_page];
        editor.save_document_as();
        update_status_bar();
    }
}

public void apply_editor_style_to_all_tabs(int size, string family, string color) {
    foreach (var editor in editor_tabs) {
        editor.set_editor_style(size, family, color);
    }
}

public void add_toast(Adw.Toast toast) {
    unowned Adw.ToastOverlay? overlay = find_descendant_of_type<Adw.ToastOverlay>();
    if (overlay != null) {
        overlay.add_toast(toast);
    }
}

// Formatte le texte du label curseur selon le masque demandé
private void update_cursor_label(EditorView? editor = null) {
    if (cursor_label == null) return;
    EditorView? ed = editor;
    if (ed == null) {
        int current_page = editor_notebook.get_current_page();
        if (current_page >= 0 && current_page < editor_tabs.size) {
            ed = editor_tabs[current_page];
        }
    }
    if (ed == null) {
        cursor_label.set_text("");
        return;
    }
    int line = 1;
    int col = 1;
    ed.get_cursor_position(out line, out col);
    // Masque exact: "Lig :xxxx  Col:xxx" (champs largeur 4 et 3)
    cursor_label.set_text(@"Lig :%4d  Col:%3d".printf(line, col));
}

// Met à jour le contenu de la barre de statut
private void update_status_bar() {
    if (status_label == null) return;
    int current_page = editor_notebook.get_current_page();
    if (current_page < 0 || current_page >= editor_tabs.size) {
        status_label.set_text("");
        update_cursor_label(null);
        return;
    }
    var editor = editor_tabs[current_page];
    string path = editor.get_current_file_path();
    bool changed = editor.has_unsaved_changes;
    string mark = changed ? _("(modifié)") : _("(enregistré)");
    if (path == null || path == "") path = _("Nouveau document");
    status_label.set_text(@"$path  $mark");
    update_cursor_label(editor);
}

public unowned T? find_descendant_of_type<T>() {
    return find_widget_recursive<T>(this);
}

private unowned T? find_widget_recursive<T>(Gtk.Widget widget) {
    if (widget is T) return (T)widget;
    var child = widget.get_first_child();
    while (child != null) {
        unowned T? result = find_widget_recursive<T>(child);
        if (result != null) return result;
        child = child.get_next_sibling();
    }
    return null;
}
}

}
