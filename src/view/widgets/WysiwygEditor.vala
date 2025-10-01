using Gtk;
using IntaText.Document;
using Graphene;

namespace IntaText {

/** Enum pour les modes d'indentation */
public enum IndentationMode {
    NONE,           // Pas d'indentation
    SPACES,         // Espaces classiques (problème de wrapping)
    MARGIN_TAGS,    // TextTags avec left-margin (solution actuelle)
    RTF_FORMAT      // Format enrichi (RTF/ODT)
}

public class WysiwygEditor : Gtk.TextView {
    // Largeur minimale souhaitée pour le contenu de l'éditeur.
    // Valeur initiale; sera surchargée par GSettings (editor-min-content-width)
    private int min_content_width = 800;
// Masque intentionnellement Gtk.TextView.buffer
private new Gtk.TextBuffer buffer;
private PivotDocument? pivot_doc;

// Mode d'indentation actuel
private IndentationMode current_indentation_mode = IndentationMode.MARGIN_TAGS;

private Gtk.TextTag tag_bold;
private Gtk.TextTag tag_italic;
private Gtk.TextTag tag_heading1;
private Gtk.TextTag tag_heading2;
private Gtk.TextTag tag_heading3;
private Gtk.TextTag tag_code;
private Gtk.TextTag tag_quote;
private Gtk.TextTag tag_strikethrough;
private Gtk.TextTag tag_link;
private Gtk.TextTag tag_list;
private Gtk.TextTag tag_underline;
private Gtk.TextTag tag_image;
private Gtk.TextTag tag_rule;
private Gtk.TextTag tag_rule_line; // Tag minimal pour isoler la ligne du trait (éviter fuite attributs)
private Gtk.TextTag tag_table_header;
private Gtk.TextTag tag_table_cell;
private Gtk.TextTag tag_table_border;
// Flag pour empêcher une réinsertion immédiate de trait lors d'un Enter après création.
private bool suppress_next_rule_insert = false;
// Debug: activation logs internes (contrôlé par variable d'env INTATEXT_DEBUG_RULES)
private bool debug_rules = false;
// Désactivation dynamique du recalcul de la largeur des traits (INTATEXT_DISABLE_RULE_RESIZE=1)
private bool disable_rule_resize = false;

// Variable pour mémoriser la dernière largeur calculée pour les traits
private int last_calculated_rule_length = 0;

// Variable pour tracker le TextView actif dans une cellule de tableau
private weak Gtk.TextView? active_cell_textview = null;

private Gtk.CssProvider css_provider;
// Registre local des noms de tags dynamiques créés (pour retrouver href/src/alt)
private Gee.ArrayList<string> link_tag_names = new Gee.ArrayList<string>();
    // Registres pour tags dynamiques de couleur
    private Gee.ArrayList<string> fg_tag_names = new Gee.ArrayList<string>();
    private Gee.ArrayList<string> bg_tag_names = new Gee.ArrayList<string>();
private Gee.ArrayList<string> image_src_tag_names = new Gee.ArrayList<string>();
private Gee.ArrayList<string> image_alt_tag_names = new Gee.ArrayList<string>();

// Variables pour gérer les attributs en attente (quand pas de sélection)
private string? current_font_family = null;
private int current_font_size = 0;
private bool has_pending_attributes = false;

// (Code debug supprimé) : plus d'overlay, de toggling wrap ou de contenu artificiel.

public signal void document_changed(PivotDocument doc);
public signal void buffer_changed();

public WysiwygEditor() {
    Object();

    // Zone d'édition simple
    // Désactiver le wrapping pour permettre le défilement horizontal
    // Restaure le wrapping pour éviter l’ascenseur horizontal quand le texte peut se replier
    this.set_wrap_mode(Gtk.WrapMode.WORD_CHAR);
    // Aide le ScrolledWindow à décider quand afficher les barres de défilement
    // En politique MINIMUM, le calcul se base sur la taille minimale déclarée
    // (utile avec un width minimal configuré via GSettings)
    this.set_hscroll_policy(Gtk.ScrollablePolicy.MINIMUM);
    this.set_vscroll_policy(Gtk.ScrollablePolicy.MINIMUM);
    // Charger la préférence GSettings pour la largeur minimale de contenu
    var ui_settings = new GLib.Settings("com.cabineteto.IntaText");
    this.min_content_width = ui_settings.get_int("editor-min-content-width");
    this.set_size_request(this.min_content_width, -1);
    // Écouter les changements de préférence et appliquer en direct
    ui_settings.changed["editor-min-content-width"].connect((key) => {
        var new_width = ui_settings.get_int(key);
        if (new_width < 200) new_width = 200; // garde-fou basique
        this.min_content_width = new_width;
        this.set_size_request(this.min_content_width, -1);
        // rafraîchir la longueur des règles pour prendre en compte le nouveau layout
        this.refresh_horizontal_rules();
    });
    this.set_monospace(false);
    this.set_vexpand(true);
    this.set_hexpand(true);
    buffer = this.get_buffer();

    // Configuration d'accessibilité
    this.set_accessible_role(Gtk.AccessibleRole.TEXT_BOX);
    this.update_property(Gtk.AccessibleProperty.LABEL, "Zone d'édition WYSIWYG");
    this.update_property(Gtk.AccessibleProperty.DESCRIPTION, "Zone de texte principale pour l'édition WYSIWYG");
    this.update_state(Gtk.AccessibleState.BUSY, false);

    // Forcer le fond blanc
    // Applique une classe CSS dédiée au TextView (GTK4: préférer add_css_class)
    this.add_css_class("wysiwyg-editor-textview");
    // Commenté temporairement pour éviter les erreurs
    // var css = new Gtk.CssProvider();
    // css.load_from_string(".wysiwyg-editor-textview { background-color: #fff; }");
    // Gtk.StyleContext.add_provider_for_display(Gdk.Display.get_default(), css, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

    // Préparer les tags de formatage
    ensure_tags();

    // Initialiser flags debug depuis l'environnement (évalués une fois)
    string? dbg = GLib.Environment.get_variable("INTATEXT_DEBUG_RULES");
    if (dbg != null && (dbg == "1" || dbg.down() == "true")) debug_rules = true;
    string? dis = GLib.Environment.get_variable("INTATEXT_DISABLE_RULE_RESIZE");
    if (dis != null && (dis == "1" || dis.down() == "true")) disable_rule_resize = true;

    // Gestionnaire pour appliquer les attributs en attente lors de la saisie
    buffer.insert_text.connect((ref iter, text, len) => {
        if (has_pending_attributes) {
            apply_pending_attributes(iter, text.length);
        }
    });

    // Gestionnaire pour redimensionnement de la fenêtre (mise à jour des traits)
    this.notify["allocated-width"].connect(this.on_size_changed);
    this.notify["allocated-height"].connect(this.on_size_changed);

    // Gestionnaire pour mise à jour lors du changement de l'état de la fenêtre
    this.notify["visible"].connect(() => {
        if (this.get_visible()) {
            Idle.add(() => {
                on_size_changed();
                return false;
            });
        }
    });

    // Gestionnaires pour les interactions avec les liens
    setup_link_interactions();

    // Initialiser les préférences d'indentation
    setup_indentation_preferences();

    // Intercepter Enter juste après une ligne de trait pour éviter d'insérer un nouveau trait
    // Contrôleur en phase capture pour intercepter AVANT traitement standard
    var key_controller = new Gtk.EventControllerKey();
    key_controller.set_propagation_phase(Gtk.PropagationPhase.CAPTURE);
    key_controller.key_pressed.connect((keyval, keycode, state) => {
        // Ne pas intercepter les touches si un widget enfant (p.ex. cellule de tableau) a le focus
        if (!this.has_focus) return false;
        if (keyval != Gdk.Key.Return && keyval != Gdk.Key.KP_Enter)
            return false;

        Gtk.TextIter cur_iter;
        buffer.get_iter_at_mark(out cur_iter, buffer.get_insert());
        Gtk.TextIter line_start = cur_iter; line_start.set_line_offset(0);
        Gtk.TextIter line_end = line_start; line_end.forward_to_line_end();

        // Inclure cas: curseur n'importe où sur la ligne de trait
        if (is_line_full_rule(line_start, line_end)) {
            if (debug_rules) log_rule_debug("ENTER on rule line: line=" + line_start.get_line().to_string());
            if (!cur_iter.equal(line_end)) cur_iter = line_end;
            buffer.insert(ref cur_iter, "\n", -1);
            buffer.place_cursor(cur_iter);
            suppress_next_rule_insert = true;
            if (debug_rules) log_rule_debug("Inserted newline after rule; suppress_next_rule_insert set");
            return true;
        }
        return false;
    });
    this.add_controller(key_controller);

    // Ajouter un gestionnaire de focus pour l'éditeur principal
    // pour réinitialiser active_cell_textview quand on revient éditer le document principal
    var main_focus_controller = new Gtk.EventControllerFocus();
    main_focus_controller.enter.connect(() => {
        active_cell_textview = null;
    });
    this.add_controller(main_focus_controller);

    // Commenté temporairement
    // buffer.changed.connect(() => {
    //     buffer_changed();
    // });

    // Code debug retiré.
}

// Override measure: impose une largeur minimale = min_content_width pour
// que le ScrolledWindow perçoive un contenu plus large que la zone visible.
public override void measure(Gtk.Orientation orientation, int for_size,
                             out int minimum, out int natural,
                             out int minimum_baseline, out int natural_baseline) {
    base.measure(orientation, for_size, out minimum, out natural, out minimum_baseline, out natural_baseline);
    if (orientation == Gtk.Orientation.HORIZONTAL) {
        // Forcer le minimum à min_content_width pour déclencher l’ascenseur quand alloc < min
        if (minimum < min_content_width) minimum = min_content_width;
        if (natural < minimum) natural = minimum;
        // Supprimer tout baseline horizontal (non valide pour cette orientation) pour éviter le warning GTK
        minimum_baseline = -1;
        natural_baseline = -1;
    }
}

// Code debug supprimé: suppression des toggles wrap et size_allocate custom.

/**
 * Définit le mode d'indentation à utiliser
 */
public void set_indentation_mode(IndentationMode mode) {
    if (current_indentation_mode != mode) {
        convert_indentation_from_to(current_indentation_mode, mode);
        current_indentation_mode = mode;
    }
}

/**
 * Obtient le mode d'indentation actuel
 */
public IndentationMode get_indentation_mode() {
    return current_indentation_mode;
}

/**
 * Configure les préférences d'indentation
 */
private void setup_indentation_preferences() {
    try {
        var settings = new GLib.Settings("com.cabineteto.IntaText");

        // Charger le mode initial
        string mode_str = settings.get_string("indentation-mode");
        var mode = string_to_indentation_mode(mode_str);
        set_indentation_mode(mode);

        // Écouter les changements
        settings.changed["indentation-mode"].connect((key) => {
            string new_mode_str = settings.get_string(key);
            var new_mode = string_to_indentation_mode(new_mode_str);
            set_indentation_mode(new_mode);
        });

    } catch (Error e) {
        // En cas d'erreur, utiliser le mode par défaut
        set_indentation_mode(IndentationMode.MARGIN_TAGS);
    }
}

/**
 * Convertit une chaîne en mode d'indentation
 */
private IndentationMode string_to_indentation_mode(string mode_str) {
    switch (mode_str) {
        case "none": return IndentationMode.NONE;
        case "spaces": return IndentationMode.SPACES;
        case "margin-tags": return IndentationMode.MARGIN_TAGS;
        case "rtf-format": return IndentationMode.RTF_FORMAT;
        default: return IndentationMode.MARGIN_TAGS;
    }
}

// Assure que tous les TextTags nécessaires existent et met à jour les champs
private void ensure_tags() {
    var table = buffer.get_tag_table();

    // Bold
    tag_bold = (Gtk.TextTag) table.lookup("bold");
    if (tag_bold == null) tag_bold = buffer.create_tag("bold", "weight", Pango.Weight.BOLD);

    // Italic
    tag_italic = (Gtk.TextTag) table.lookup("italic");
    if (tag_italic == null) tag_italic = buffer.create_tag("italic", "style", Pango.Style.ITALIC);

    // Underline
    tag_underline = (Gtk.TextTag) table.lookup("underline");
    if (tag_underline == null) tag_underline = buffer.create_tag("underline", "underline", Pango.Underline.SINGLE);

    // Strikethrough
    tag_strikethrough = (Gtk.TextTag) table.lookup("strikethrough");
    if (tag_strikethrough == null) tag_strikethrough = buffer.create_tag("strikethrough", "strikethrough", true);

    // Code
    tag_code = (Gtk.TextTag) table.lookup("code");
    if (tag_code == null) {
        // Monospace + légère coloration de fond
        tag_code = buffer.create_tag("code",
            "family", "monospace",
            "background", "#f5f5f7");
    }

    // Headings
    tag_heading1 = (Gtk.TextTag) table.lookup("heading1");
    if (tag_heading1 == null) tag_heading1 = buffer.create_tag("heading1", "weight", Pango.Weight.BOLD, "scale", 1.6);
    tag_heading2 = (Gtk.TextTag) table.lookup("heading2");
    if (tag_heading2 == null) tag_heading2 = buffer.create_tag("heading2", "weight", Pango.Weight.BOLD, "scale", 1.3);
    tag_heading3 = (Gtk.TextTag) table.lookup("heading3");
    if (tag_heading3 == null) tag_heading3 = buffer.create_tag("heading3", "weight", Pango.Weight.BOLD, "scale", 1.15);

    // Quote
    tag_quote = (Gtk.TextTag) table.lookup("quote");
    if (tag_quote == null) tag_quote = buffer.create_tag("quote", "foreground", "#666666", "indent", 20);

    // Link
    tag_link = (Gtk.TextTag) table.lookup("link");
    if (tag_link == null) {
        tag_link = buffer.create_tag("link", "underline", Pango.Underline.SINGLE, "foreground", "#0066cc");
        // pas de propriété standard pour stocker l'URL; on utilisera attributes dynamiques via set_data
    }

    // List
    tag_list = (Gtk.TextTag) table.lookup("list");
    if (tag_list == null) tag_list = buffer.create_tag("list", "indent", 12);

    // Créer les tags d'indentation pour gérer les lignes wrappées
    create_indentation_tags();

    // Image (marqueur générique)
    tag_image = (Gtk.TextTag) table.lookup("image");
    if (tag_image == null) tag_image = buffer.create_tag("image");

    // Rule (trait de séparation horizontal)
    tag_rule = (Gtk.TextTag) table.lookup("rule");
    if (tag_rule == null) {
        // Tag STRICTEMENT limité au style du glyph (couleur + poids) sans taille exagérée qui peut
        // influencer la hauteur de ligne suivante dans certains caches de layout.
        tag_rule = buffer.create_tag("rule",
                                   "foreground", "#CCCCCC",
                                   "weight", Pango.Weight.LIGHT);
    }
    // Tag appliqué à toute la ligne pour neutraliser d'anciens attributs potentiels (p.ex. list/quote)
    tag_rule_line = (Gtk.TextTag) table.lookup("rule_line");
    if (tag_rule_line == null) {
        tag_rule_line = buffer.create_tag("rule_line"); // neutre
    }

    // Table header (en-têtes grisés)
    tag_table_header = (Gtk.TextTag) table.lookup("table_header");
    if (tag_table_header == null) {
        tag_table_header = buffer.create_tag("table_header",
                                           "background", "#f0f0f0",
                                           "weight", Pango.Weight.BOLD,
                                           "foreground", "#333333");
    }

    // Table cell (cellules normales)
    tag_table_cell = (Gtk.TextTag) table.lookup("table_cell");
    if (tag_table_cell == null) {
        tag_table_cell = buffer.create_tag("table_cell",
                                         "background", "#ffffff",
                                         "foreground", "#000000");
    }
}

/**
 * Crée les tags d'indentation pour gérer les lignes wrappées
 */
private void create_indentation_tags() {
    var table = buffer.get_tag_table();

    // Créer jusqu'à 10 niveaux d'indentation (devrait être suffisant)
    for (int level = 1; level <= 10; level++) {
        string tag_name = "indent-level-%d".printf(level);
        var existing_tag = table.lookup(tag_name);

        if (existing_tag == null) {
            int margin = level * 20; // 20 pixels par niveau d'indentation
            buffer.create_tag(tag_name, "left-margin", margin);
        }
    }

    // Ajouter les tags de table manquants
    var table_tag_table = buffer.get_tag_table();

    // Table border (bordures de tableau)
    tag_table_border = (Gtk.TextTag) table_tag_table.lookup("table_border");
    if (tag_table_border == null) {
        tag_table_border = buffer.create_tag("table_border",
                                           "foreground", "#CCCCCC",
                                           "family", "monospace");
    }
}

// Configure les interactions avec les liens (survol et ctrl+click)
private void setup_link_interactions() {
    // Gestionnaire de mouvement de souris pour le survol des liens
    var motion_controller = new Gtk.EventControllerMotion();
    motion_controller.motion.connect(on_mouse_motion);
    this.add_controller(motion_controller);

    // Gestionnaire de clics pour Ctrl+Click sur les liens
    var click_controller = new Gtk.GestureClick();
    // Éviter d'interférer avec les widgets enfants: traiter au plus près de la cible
    click_controller.set_propagation_phase(Gtk.PropagationPhase.TARGET);
    click_controller.pressed.connect((_n_press, _x, _y) => {
        // Si on n'est pas en Ctrl, ne rien réclamer (laisser enfants gérer)
        var event = click_controller.get_last_event(click_controller.get_last_updated_sequence());
        if (event == null) { click_controller.set_state(Gtk.EventSequenceState.DENIED); return; }
        var modifiers = event.get_modifier_state();
        if ((modifiers & (int)Gdk.ModifierType.CONTROL_MASK) == 0) {
            click_controller.set_state(Gtk.EventSequenceState.DENIED);
            return;
        }
        // Si le clic est sur un widget enfant (p.ex. cellule), ne pas gérer ici
        Gtk.Widget? picked = this.pick(_x, _y, Gtk.PickFlags.DEFAULT);
        if (picked != null && picked != this) {
            click_controller.set_state(Gtk.EventSequenceState.DENIED);
            return;
        }
        on_mouse_click(click_controller, _n_press, _x, _y);
    });
    this.add_controller(click_controller);
}

// Gestionnaire du mouvement de souris pour changer le curseur sur les liens
private void on_mouse_motion(double x, double y) {
    // Convertir les coordonnées fenêtre en coordonnées buffer
    int buffer_x, buffer_y;
    this.window_to_buffer_coords(Gtk.TextWindowType.TEXT, (int)x, (int)y, out buffer_x, out buffer_y);

    // Obtenir l'itérateur à cette position
    TextIter iter;
    if (this.get_iter_at_location(out iter, buffer_x, buffer_y)) {
        bool is_on_link = false;

        // Vérifier si on est sur un lien (tag_link générique)
        if (iter.has_tag(tag_link)) {
            is_on_link = true;
        } else {
            // Vérifier si on est sur un lien avec URL (tags "link::u:...")
            var tags = iter.get_tags();
            foreach (var tag in tags) {
                if (tag.name != null && tag.name.has_prefix("link::u:")) {
                    is_on_link = true;
                    break;
                }
            }
        }

        if (is_on_link) {
            // Changer le curseur en main
            this.set_cursor_from_name("pointer");
        } else {
            // Remettre le curseur normal
            this.set_cursor_from_name("text");
        }
    } else {
        // Si on ne peut pas obtenir d'itérateur, remettre le curseur normal
        this.set_cursor_from_name("text");
    }
}

// Gestionnaire des clics pour ouvrir les liens avec Ctrl+Click
private void on_mouse_click(Gtk.GestureClick gesture, int n_press, double x, double y) {
    // Vérifier si c'est un Ctrl+Click
    var event = gesture.get_last_event(gesture.get_last_updated_sequence());
    if (event == null) return;

    var modifiers = event.get_modifier_state();
    // Utiliser une comparaison directe avec la valeur du masque
    if ((modifiers & (int)Gdk.ModifierType.CONTROL_MASK) == 0) {
        return; // Pas un Ctrl+Click
    }

    // Convertir les coordonnées fenêtre en coordonnées buffer
    int buffer_x, buffer_y;
    this.window_to_buffer_coords(Gtk.TextWindowType.TEXT, (int)x, (int)y, out buffer_x, out buffer_y);

    // Obtenir l'itérateur à cette position
    TextIter iter;
    if (this.get_iter_at_location(out iter, buffer_x, buffer_y)) {
        if (iter.has_tag(tag_link)) {
            // Trouver l'URL du lien
            string? url = get_link_url_at_iter(iter);
            if (url != null && url.length > 0) {
                open_link(url);
            }
        }
    }
}

// Récupère l'URL d'un lien à partir de l'itérateur
private string? get_link_url_at_iter(TextIter iter) {
    // D'abord, chercher dans les tags dynamiques pour trouver l'URL stockée
    // Les URLs sont stockées dans des tags avec le format "link::u:encoded_url"

    var tags = iter.get_tags();
    foreach (var tag in tags) {
        string tag_name = tag.name;
        if (tag_name != null && tag_name.has_prefix("link::u:")) {
            // Décoder l'URL du nom du tag
            string encoded_url = tag_name.substring("link::u:".length);
            string decoded_url = GLib.Uri.unescape_string(encoded_url, null);
            return decoded_url;
        }
    }

    // Fallback: extraire le texte visible du lien et voir si c'est une URL
    TextIter link_start = iter;
    TextIter link_end = iter;

    // Aller au début du lien
    while (link_start.backward_char() && link_start.has_tag(tag_link)) {
        // Continue
    }
    if (!link_start.has_tag(tag_link)) {
        link_start.forward_char();
    }

    // Aller à la fin du lien
    while (link_end.forward_char() && link_end.has_tag(tag_link)) {
        // Continue
    }

    // Extraire le texte du lien
    string link_text = buffer.get_text(link_start, link_end, false);

    // Si le texte visible est une URL valide, l'utiliser
    if (is_valid_url(link_text)) {
        return link_text;
    }

    return null;
}

// Vérifie si une chaîne est une URL valide
private bool is_valid_url(string text) {
    return text.has_prefix("http://") || text.has_prefix("https://") ||
           text.has_prefix("ftp://") || text.has_prefix("mailto:");
}

// Ouvre une URL ou navigue vers un lien interne
private void open_link(string url) {
    // Vérifier si c'est un lien interne (ancre)
    if (url.has_prefix("#")) {
        scroll_to_anchor(url);
    } else if (url.has_prefix("http://") || url.has_prefix("https://") || 
               url.has_prefix("ftp://") || url.has_prefix("mailto:")) {
        // Lien externe absolu - ouvrir dans le navigateur
        try {
            GLib.AppInfo.launch_default_for_uri(url, null);
        } catch (Error e) {
            warning("Impossible d'ouvrir l'URL %s : %s", url, e.message);
        }
    } else {
        // Lien relatif - pas encore supporté
        warning("Les liens relatifs ne sont pas encore supportés : %s", url);
    }
}

// Fait défiler le document jusqu'à une ancre spécifique
private void scroll_to_anchor(string anchor) {
    // Retirer le # du début
    string anchor_id = anchor.has_prefix("#") ? anchor.substring(1) : anchor;
    
    // Normaliser l'ancre recherchée pour la comparaison
    string normalized_anchor = generate_heading_id_for_comparison(anchor_id);
    
    // Rechercher le titre correspondant dans le document
    TextIter start, end;
    buffer.get_bounds(out start, out end);
    
    // Parcourir le document ligne par ligne pour trouver un titre
    TextIter iter = start;
    while (!iter.equal(end)) {
        TextIter line_start = iter;
        line_start.set_line_offset(0);
        TextIter line_end = line_start;
        line_end.forward_to_line_end();
        
        // Vérifier si cette ligne a un tag de titre
        bool is_heading = false;
        if (tag_heading1 != null && line_start.has_tag(tag_heading1)) is_heading = true;
        if (tag_heading2 != null && line_start.has_tag(tag_heading2)) is_heading = true;
        if (tag_heading3 != null && line_start.has_tag(tag_heading3)) is_heading = true;
        
        if (is_heading) {
            // Extraire le texte du titre
            string heading_text = buffer.get_text(line_start, line_end, false);
            
            // Générer l'ID du titre (même logique que dans le markdown)
            string generated_id = generate_heading_id(heading_text);
            
            // Comparer avec l'ancre recherchée (les deux normalisés)
            if (generated_id == normalized_anchor) {
                // Trouvé ! Faire défiler jusqu'à cette position
                var mark = buffer.create_mark(null, line_start, true);
                scroll_to_mark(mark, 0.0, true, 0.0, 0.1);
                buffer.delete_mark(mark);
                return;
            }
        }
        
        // Passer à la ligne suivante
        if (!iter.forward_line()) break;
    }
    
    warning("Ancre non trouvée : %s", anchor_id);
}

// Normalise une chaîne pour la comparaison d'ancres (enlève les accents)
private string generate_heading_id_for_comparison(string text) {
    // Convertir en minuscules d'abord
    string lowered = text.down();
    
    // Remplacer les caractères accentués courants manuellement
    string normalized = lowered
        .replace("é", "e").replace("è", "e").replace("ê", "e").replace("ë", "e")
        .replace("à", "a").replace("â", "a").replace("ä", "a")
        .replace("ù", "u").replace("û", "u").replace("ü", "u")
        .replace("ô", "o").replace("ö", "o")
        .replace("î", "i").replace("ï", "i")
        .replace("ç", "c")
        .replace("ñ", "n");
    
    // Construire l'ID en ne gardant que les caractères ASCII alphanumériques et les tirets
    StringBuilder result = new StringBuilder();
    unichar c;
    for (int i = 0; normalized.get_next_char(ref i, out c);) {
        if ((c >= 'a' && c <= 'z') || (c >= '0' && c <= '9')) {
            result.append_unichar(c);
        } else if (c == '-') {
            result.append_c('-');
        }
        // Ignorer tout le reste
    }
    
    return result.str;
}

// Génère un ID de titre compatible avec les ancres markdown
private string generate_heading_id(string text) {
    // Convertir en minuscules d'abord
    string lowered = text.down();
    
    // Remplacer les caractères accentués courants manuellement
    string normalized = lowered
        .replace("é", "e").replace("è", "e").replace("ê", "e").replace("ë", "e")
        .replace("à", "a").replace("â", "a").replace("ä", "a")
        .replace("ù", "u").replace("û", "u").replace("ü", "u")
        .replace("ô", "o").replace("ö", "o")
        .replace("î", "i").replace("ï", "i")
        .replace("ç", "c")
        .replace("ñ", "n");
    
    // Construire l'ID en ne gardant que les caractères alphanumériques ASCII et les tirets
    StringBuilder result = new StringBuilder();
    unichar c;
    for (int i = 0; normalized.get_next_char(ref i, out c);) {
        if ((c >= 'a' && c <= 'z') || (c >= '0' && c <= '9')) {
            // Caractères alphanumériques ASCII
            result.append_unichar(c);
        } else if (c.isspace() || c == '-' || c == '.') {
            // Espaces, tirets et points deviennent des tirets
            // Ajouter un tiret seulement si le dernier caractère n'en est pas un
            if (result.len > 0 && result.str[result.len - 1] != '-') {
                result.append_c('-');
            }
        }
        // Ignorer les autres caractères
    }
    
    // Retirer les tirets en début et fin
    string final_id = result.str.strip();
    while (final_id.has_prefix("-")) {
        final_id = final_id.substring(1);
    }
    while (final_id.has_suffix("-")) {
        final_id = final_id.substring(0, final_id.length - 1);
    }
    
    return final_id;
}

// Applique les attributs en attente au texte qui vient d'être inséré
private void apply_pending_attributes(TextIter iter, int text_length) {
    if (!has_pending_attributes) return;

    try {
        // Vérification de sécurité des paramètres
        if (text_length <= 0) return;

        // Calculer les itérateurs de début et fin du texte inséré
        TextIter start = iter;
        if (!start.backward_chars(text_length)) {
            warning("Impossible de déplacer l'itérateur de début");
            return;
        }

        // Vérification que les itérateurs sont valides
        if (!start.is_start() && !start.is_end() && !iter.is_start() && !iter.is_end()) {
            // Appliquer la police si définie
            if (current_font_family != null && current_font_family.strip() != "") {
                try {
                    var font_tag = buffer.create_tag(null, "family", current_font_family);
                    if (font_tag != null) {
                        buffer.apply_tag(font_tag, start, iter);
                    }
                } catch (Error font_error) {
                    warning("Erreur lors de l'application de la police: %s", font_error.message);
                }
            }

            // Appliquer la taille si définie
            if (current_font_size > 0) {
                try {
                    var size_tag = buffer.create_tag(null, "size-points", current_font_size);
                    if (size_tag != null) {
                        buffer.apply_tag(size_tag, start, iter);
                    }
                } catch (Error size_error) {
                    warning("Erreur lors de l'application de la taille: %s", size_error.message);
                }
            }
        }

        // Réinitialiser les attributs en attente après application
        // Note: on garde les attributs pour la suite de la saisie
        // has_pending_attributes = false;
    } catch (Error e) {
        warning("Erreur lors de l'application des attributs en attente: %s", e.message);
    }
}

// Méthode helper pour obtenir le buffer actif (cellule de tableau ou buffer principal)
private Gtk.TextBuffer get_active_buffer() {
    if (active_cell_textview != null) {
        return active_cell_textview.get_buffer();
    }
    return buffer;
}

// Exemple d'utilisation sécurisée d'un tag
public void apply_bold() {
    var active_buffer = get_active_buffer();
    TextIter start, end;
    if (active_buffer.get_selection_bounds(out start, out end)) {
        var tag_table = active_buffer.get_tag_table();
        var bold_tag = tag_table.lookup("bold");
        if (bold_tag == null) {
            bold_tag = active_buffer.create_tag("bold", "weight", Pango.Weight.BOLD);
        }
        active_buffer.apply_tag(bold_tag, start, end);
    }
}

public void apply_italic() {
    var active_buffer = get_active_buffer();
    TextIter start, end;
    if (active_buffer.get_selection_bounds(out start, out end)) {
        var tag_table = active_buffer.get_tag_table();
        var italic_tag = tag_table.lookup("italic");
        if (italic_tag == null) {
            italic_tag = active_buffer.create_tag("italic", "style", Pango.Style.ITALIC);
        }
        active_buffer.apply_tag(italic_tag, start, end);
    }
}

public void apply_heading(int level) {
    TextIter start, end;
    if (buffer.get_selection_bounds(out start, out end)) {
        if (level == 1 && tag_heading1 != null) {
            buffer.apply_tag(tag_heading1, start, end);
        }
        else if (level == 2 && tag_heading2 != null) {
            buffer.apply_tag(tag_heading2, start, end);
        }
        else if (level >= 3 && tag_heading3 != null) {
            buffer.apply_tag(tag_heading3, start, end);
        }
    }
}

// Applique un style de titre (H1/H2/H3) sur la sélection ou la ligne courante
public void apply_heading_action(int level) {
    ensure_tags();
    TextIter start, end;
    if (buffer.get_selection_bounds(out start, out end)) {
        // Nettoyer les autres niveaux de titres puis appliquer
        buffer.remove_tag(tag_heading1, start, end);
        buffer.remove_tag(tag_heading2, start, end);
        buffer.remove_tag(tag_heading3, start, end);
        if (level == 1) buffer.apply_tag(tag_heading1, start, end);
        else if (level == 2) buffer.apply_tag(tag_heading2, start, end);
        else buffer.apply_tag(tag_heading3, start, end);
        return;
    }

    // Pas de sélection: appliquer au contenu de la ligne courante
    Gtk.TextIter cursor;
    buffer.get_iter_at_mark(out cursor, buffer.get_insert());
    Gtk.TextIter line_start = cursor;
    line_start.set_line_offset(0);
    Gtk.TextIter line_end = cursor;
    line_end.forward_to_line_end();
    if (line_start.equal(line_end)) {
        // Ligne vide: rien à faire (éviter d'insérer du texte automatiquement)
        return;
    }
    buffer.remove_tag(tag_heading1, line_start, line_end);
    buffer.remove_tag(tag_heading2, line_start, line_end);
    buffer.remove_tag(tag_heading3, line_start, line_end);
    if (level == 1) buffer.apply_tag(tag_heading1, line_start, line_end);
    else if (level == 2) buffer.apply_tag(tag_heading2, line_start, line_end);
    else buffer.apply_tag(tag_heading3, line_start, line_end);
}

// Supprime tout style de titre (H1/H2/H3) sur la sélection ou la ligne courante
public void clear_heading_action() {
    ensure_tags();
    TextIter start, end;
    if (buffer.get_selection_bounds(out start, out end)) {
        buffer.remove_tag(tag_heading1, start, end);
        buffer.remove_tag(tag_heading2, start, end);
        buffer.remove_tag(tag_heading3, start, end);
        return;
    }
    Gtk.TextIter cursor;
    buffer.get_iter_at_mark(out cursor, buffer.get_insert());
    Gtk.TextIter line_start = cursor;
    line_start.set_line_offset(0);
    Gtk.TextIter line_end = cursor;
    line_end.forward_to_line_end();
    if (line_start.equal(line_end)) return; // ligne vide
    buffer.remove_tag(tag_heading1, line_start, line_end);
    buffer.remove_tag(tag_heading2, line_start, line_end);
    buffer.remove_tag(tag_heading3, line_start, line_end);
}

public void apply_code() {
    var active_buffer = get_active_buffer();
    TextIter start, end;
    if (active_buffer.get_selection_bounds(out start, out end)) {
        var tag_table = active_buffer.get_tag_table();
        var code_tag = tag_table.lookup("code");
        if (code_tag == null) {
            code_tag = active_buffer.create_tag("code", "family", "monospace", "background", "#f0f0f0");
        }
        active_buffer.apply_tag(code_tag, start, end);
    }
}

public void apply_quote() {
    var active_buffer = get_active_buffer();
    TextIter start, end;
    if (active_buffer.get_selection_bounds(out start, out end)) {
        var tag_table = active_buffer.get_tag_table();
        var quote_tag = tag_table.lookup("quote");
        if (quote_tag == null) {
            quote_tag = active_buffer.create_tag("quote", "style", Pango.Style.ITALIC, "foreground", "#555555");
        }
        active_buffer.apply_tag(quote_tag, start, end);
    }
}

public void apply_format(TextFormatting format) {
    var active_buffer = get_active_buffer();
    var tag_table = active_buffer.get_tag_table();
    TextIter start, end;
    if (active_buffer.get_selection_bounds(out start, out end)) {
        switch (format) {
            case TextFormatting.UNDERLINE:
            var underline_tag = tag_table.lookup("underline");
            if (underline_tag == null) {
                underline_tag = active_buffer.create_tag("underline", "underline", Pango.Underline.SINGLE);
            }
            active_buffer.apply_tag(underline_tag, start, end);
            break;
        case TextFormatting.STRIKETHROUGH:
            var strikethrough_tag = tag_table.lookup("strikethrough");
            if (strikethrough_tag == null) {
                strikethrough_tag = active_buffer.create_tag("strikethrough", "strikethrough", true);
            }
            active_buffer.apply_tag(strikethrough_tag, start, end);
            break;
        default:
            break;
        }
    }
}

// === ÉTAT COURANT ET BASCULE DES FORMATS ===
public bool is_bold_active() {
    var active_buffer = get_active_buffer();
    var tag_table = active_buffer.get_tag_table();
    var bold_tag = tag_table.lookup("bold");
    if (bold_tag == null) return false;
    Gtk.TextIter it;
    active_buffer.get_iter_at_mark(out it, active_buffer.get_insert());
    return it.has_tag(bold_tag);
}

public bool is_italic_active() {
    var active_buffer = get_active_buffer();
    var tag_table = active_buffer.get_tag_table();
    var italic_tag = tag_table.lookup("italic");
    if (italic_tag == null) return false;
    Gtk.TextIter it;
    active_buffer.get_iter_at_mark(out it, active_buffer.get_insert());
    return it.has_tag(italic_tag);
}

public bool is_underline_active() {
    var active_buffer = get_active_buffer();
    var tag_table = active_buffer.get_tag_table();
    var underline_tag = tag_table.lookup("underline");
    if (underline_tag == null) return false;
    Gtk.TextIter it;
    active_buffer.get_iter_at_mark(out it, active_buffer.get_insert());
    return it.has_tag(underline_tag);
}

public bool is_strikethrough_active() {
    var active_buffer = get_active_buffer();
    var tag_table = active_buffer.get_tag_table();
    var strikethrough_tag = tag_table.lookup("strikethrough");
    if (strikethrough_tag == null) return false;
    Gtk.TextIter it;
    active_buffer.get_iter_at_mark(out it, active_buffer.get_insert());
    return it.has_tag(strikethrough_tag);
}

// Renvoie 0 si aucun titre n'est actif, sinon 1, 2 ou 3
public int get_active_heading_level() {
    ensure_tags();
    Gtk.TextIter it;
    buffer.get_iter_at_mark(out it, buffer.get_insert());
    if (it.has_tag(tag_heading1)) return 1;
    if (it.has_tag(tag_heading2)) return 2;
    if (it.has_tag(tag_heading3)) return 3;
    return 0;
}
public void toggle_bold() {
    var active_buffer = get_active_buffer();
    var tag_table = active_buffer.get_tag_table();
    TextIter start, end;
    if (!active_buffer.get_selection_bounds(out start, out end)) return;
    var bold_tag = tag_table.lookup("bold");
    if (bold_tag == null) bold_tag = active_buffer.create_tag("bold", "weight", Pango.Weight.BOLD);
    // Détecter l'état sur le début de sélection
    bool active = start.has_tag(bold_tag);
    if (active)
        active_buffer.remove_tag(bold_tag, start, end);
    else
        active_buffer.apply_tag(bold_tag, start, end);
}

public void toggle_italic() {
    var active_buffer = get_active_buffer();
    var tag_table = active_buffer.get_tag_table();
    TextIter start, end;
    if (!active_buffer.get_selection_bounds(out start, out end)) return;
    var italic_tag = tag_table.lookup("italic");
    if (italic_tag == null) italic_tag = active_buffer.create_tag("italic", "style", Pango.Style.ITALIC);
    bool active = start.has_tag(italic_tag);
    if (active)
        active_buffer.remove_tag(italic_tag, start, end);
    else
        active_buffer.apply_tag(italic_tag, start, end);
}

public void toggle_underline() {
    var active_buffer = get_active_buffer();
    var tag_table = active_buffer.get_tag_table();
    TextIter start, end;
    if (!active_buffer.get_selection_bounds(out start, out end)) return;
    var underline_tag = tag_table.lookup("underline");
    if (underline_tag == null) underline_tag = active_buffer.create_tag("underline", "underline", Pango.Underline.SINGLE);
    bool active = start.has_tag(underline_tag);
    if (active)
        active_buffer.remove_tag(underline_tag, start, end);
    else
        active_buffer.apply_tag(underline_tag, start, end);
}

public void toggle_strikethrough() {
    var active_buffer = get_active_buffer();
    var tag_table = active_buffer.get_tag_table();
    TextIter start, end;
    if (!active_buffer.get_selection_bounds(out start, out end)) return;
    var strikethrough_tag = tag_table.lookup("strikethrough");
    if (strikethrough_tag == null) strikethrough_tag = active_buffer.create_tag("strikethrough", "strikethrough", true);
    bool active = start.has_tag(strikethrough_tag);
    if (active)
        active_buffer.remove_tag(strikethrough_tag, start, end);
    else
        active_buffer.apply_tag(strikethrough_tag, start, end);
}

public void insert_list(bool ordered) {
    var list = new PivotList();
    list.ordered = ordered;

    // Créer quelques éléments par défaut
    for (int i = 0; i < 3; i++) {
        var item = new PivotListItem();
        item.text = "";
        list.items.add(item);
    }

    // Obtenir la position actuelle du curseur
    TextIter iter;
    buffer.get_iter_at_mark(out iter, buffer.get_insert());

    // (variable locale 'start' supprimée car non utilisée)

    // Insérer un marqueur pour le début de la liste
    TextMark list_start = buffer.create_mark(null, iter, true);

    // Insérer chaque élément de la liste
    foreach (var item in list.items) {
        if (ordered) {
            buffer.insert(ref iter, "%d. ".printf(list.items.index_of(item) + 1), -1);
        }
        else {
            buffer.insert(ref iter, "• ", -1);
        }
        buffer.insert(ref iter, "\n", -1);
    }

    // Appliquer un style spécial à toute la liste
    TextIter end = iter;
    TextIter list_iter;
    buffer.get_iter_at_mark(out list_iter, list_start);
    buffer.apply_tag(tag_list, list_iter, end);

    // Supprimer le marqueur
    buffer.delete_mark(list_start);
}

public void insert_code_block() {
    // Créer un bloc de code vide
    var code_block = new PivotCodeBlock();
    code_block.language = "";
    code_block.code = "";

    // Obtenir la position actuelle du curseur
    TextIter iter;
    buffer.get_iter_at_mark(out iter, buffer.get_insert());

    // S'assurer qu'on est sur une nouvelle ligne
    if (!iter.starts_line()) {
        buffer.insert(ref iter, "\n", -1);
    }

    // Marque pour le début du bloc de code
    TextMark code_start = buffer.create_mark(null, iter, true);

    // Insérer le texte par défaut
    buffer.insert(ref iter, "[language]\n", -1);
    buffer.insert(ref iter, "// Votre code ici\n", -1);

    // Obtenir l'itérateur pour la fin du bloc
    TextIter start;
    buffer.get_iter_at_mark(out start, code_start);

    // Appliquer le style de bloc de code
    buffer.apply_tag(tag_code, start, iter);

    // Supprimer le marqueur
    buffer.delete_mark(code_start);
}

// Applique une liste à la sélection si présente, sinon insère une nouvelle liste
public void apply_list_action(bool ordered) {
    ensure_tags();
    if (has_selection()) {
        apply_list_to_selection(ordered);
    } else {
        insert_list(ordered);
    }
}

// Transforme les lignes sélectionnées en liste à puces ou numérotée
private void apply_list_to_selection(bool ordered) {
    TextIter start, end;
    if (!buffer.get_selection_bounds(out start, out end)) return;

    // Extraire le texte sélectionné
    string selected = buffer.get_text(start, end, false);
    // Fractionner en lignes en préservant structure simple
    string[] lines = selected.split("\n");
    if (lines.length == 0) return;

    // Construire le nouveau bloc
    StringBuilder sb = new StringBuilder();
    int idx = 1;
    for (int i = 0; i < lines.length; i++) {
        string ln = lines[i];
        // Conserver les lignes vides mais préfixer uniquement si non vide
        if (ln.strip().length > 0) {
            if (ordered) sb.append("%d. ".printf(idx++));
            else sb.append("\u2022 ");
        }
        sb.append(ln);
        if (i < lines.length - 1) sb.append("\n");
    }

    // Remplacer la sélection par le nouveau texte et appliquer le tag_list
    buffer.begin_user_action();
    buffer.delete(ref start, ref end);
    TextIter insert_at;
    buffer.get_iter_at_mark(out insert_at, buffer.get_insert());
    TextMark mark_begin = buffer.create_mark(null, insert_at, true);
    buffer.insert(ref insert_at, sb.str, -1);
    TextIter list_start, list_end;
    buffer.get_iter_at_mark(out list_start, mark_begin);
    list_end = insert_at;
    buffer.apply_tag(tag_list, list_start, list_end);
    buffer.delete_mark(mark_begin);
    buffer.end_user_action();
}

public void insert_link(string url, string text) {
    // Créer un lien pivot
    var link = new PivotLink();
    link.href = url;
    link.text = text;

    // Obtenir la position actuelle du curseur
    TextIter iter;
    buffer.get_iter_at_mark(out iter, buffer.get_insert());

    // Marque pour le début du lien
    TextMark link_start = buffer.create_mark(null, iter, true);

    // Insérer le texte du lien
    buffer.insert(ref iter, text, -1);

    // Appliquer le style de lien
    TextIter start;
    buffer.get_iter_at_mark(out start, link_start);

    // Créer un tag pour les liens si nécessaire
    if (tag_link == null) {
        tag_link = buffer.create_tag("link",
            "underline", Pango.Underline.SINGLE,
            "foreground", "#0066cc");
    }

    buffer.apply_tag(tag_link, start, iter);

    // Stocker l'URL pour le lien aux itérateurs via marque
    // Astuce: créer un tag spécifique portant l'URL comme nom unique
    // (table de tags exige unicité). Préfixe pour éviter collisions.
    // Encoder l'URL directement dans le nom du tag (échappée URI)
    string enc = GLib.Uri.escape_string(url, null, false);
    string unique = "link::u:" + enc;
    Gtk.TextTag url_tag = (Gtk.TextTag) buffer.get_tag_table().lookup(unique);
    if (url_tag == null) url_tag = buffer.create_tag(unique);
    buffer.apply_tag(url_tag, start, iter);
    if (!link_tag_names.contains(unique)) link_tag_names.add(unique);

    // Supprimer le marqueur
    buffer.delete_mark(link_start);
}

public void insert_image(string path, string alt_text) {
    // Créer une image pivot
    var image = new PivotImage();
    image.src = path;
    image.alt = alt_text;

    // Obtenir la position actuelle du curseur
    TextIter iter;
    buffer.get_iter_at_mark(out iter, buffer.get_insert());

    try {
        // Créer un anchor pour insérer le widget image
        var anchor = buffer.create_child_anchor(iter);

        // Créer un conteneur pour contrôler la taille de l'image
        var image_container = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        image_container.set_halign(Gtk.Align.START);

        // Créer un widget image
        var image_widget = new Gtk.Image();

        // Charger l'image avec gestion d'erreur
        if (GLib.FileUtils.test(path, GLib.FileTest.EXISTS)) {
            // Charger l'image originale pour obtenir ses dimensions
            var original_pixbuf = new Gdk.Pixbuf.from_file(path);
            var orig_width = original_pixbuf.get_width();
            var orig_height = original_pixbuf.get_height();

            int target_width, target_height;

            // Définir les limites de taille d'affichage dans l'éditeur
            int max_display_width = 600;   // Largeur max dans l'éditeur
            int max_display_height = 400;  // Hauteur max dans l'éditeur
            int min_display_size = 80;     // Taille minimum pour les très petites images

            // Cas 1: Image très petite (moins de 80px dans toute dimension)
            if (orig_width < min_display_size || orig_height < min_display_size) {
                // Agrandir en gardant les proportions jusqu'à atteindre min_display_size
                double scale = (double)min_display_size / (orig_width > orig_height ? orig_height : orig_width);
                target_width = (int)(orig_width * scale);
                target_height = (int)(orig_height * scale);
            }
            // Cas 2: Image trop grande (dépasse les limites d'affichage)
            else if (orig_width > max_display_width || orig_height > max_display_height) {
                // Réduire en gardant les proportions
                double scale_w = (double)max_display_width / orig_width;
                double scale_h = (double)max_display_height / orig_height;
                double scale = (scale_w < scale_h) ? scale_w : scale_h; // Prendre le plus petit facteur
                target_width = (int)(orig_width * scale);
                target_height = (int)(orig_height * scale);
            }
            // Cas 3: Image de taille appropriée (entre 80px et les limites max)
            else {
                // Garder la taille originale ou la réduire légèrement pour l'éditeur
                double display_scale = 0.8; // Afficher à 80% de la taille originale pour un meilleur rendu
                target_width = (int)(orig_width * display_scale);
                target_height = (int)(orig_height * display_scale);

                // S'assurer qu'on ne descend pas en dessous du minimum
                if (target_width < min_display_size || target_height < min_display_size) {
                    target_width = orig_width;
                    target_height = orig_height;
                }
            }

            // Redimensionner l'image
            var pixbuf = new Gdk.Pixbuf.from_file_at_scale(path, target_width, target_height, false);
            var texture = Gdk.Texture.for_pixbuf(pixbuf);
            image_widget.set_from_paintable(texture);

            // Forcer explicitement la taille du widget
            image_widget.set_size_request(target_width, target_height);
            image_container.set_size_request(target_width, target_height);

            // Debug : afficher les tailles calculées
            print("Image: %s - Original: %dx%d → Target: %dx%d\n",
                  GLib.Path.get_basename(path), orig_width, orig_height, target_width, target_height);

            image_widget.set_tooltip_text(alt_text ?? "");
        } else {
            // Image non trouvée, afficher un placeholder plus grand
            image_widget.set_from_icon_name("image-missing");
            image_widget.set_pixel_size(64); // Taille plus grande en pixels
            image_widget.set_tooltip_text("Image introuvable: " + path);
        }

        // Ajouter l'image au conteneur
        image_container.append(image_widget);

        // Ajouter le conteneur à l'éditeur
        this.add_child_at_anchor(image_container, anchor);

        // Stocker les métadonnées de l'image dans des tags pour la conversion
        TextIter anchor_iter;
        buffer.get_iter_at_child_anchor(out anchor_iter, anchor);

        string enc_src = GLib.Uri.escape_string(path, null, false);
        Gtk.TextTag src_tag = buffer.create_tag("image-src::u:" + enc_src);
        buffer.apply_tag_by_name("image-src::u:" + enc_src, anchor_iter, anchor_iter);
        string src_name = "image-src::u:" + enc_src;
        if (!image_src_tag_names.contains(src_name)) image_src_tag_names.add(src_name);

        string enc_alt = GLib.Uri.escape_string(alt_text ?? "", null, false);
        Gtk.TextTag alt_tag = buffer.create_tag("image-alt::u:" + enc_alt);
        buffer.apply_tag_by_name("image-alt::u:" + enc_alt, anchor_iter, anchor_iter);
        string alt_name = "image-alt::u:" + enc_alt;
        if (!image_alt_tag_names.contains(alt_name)) image_alt_tag_names.add(alt_name);

    } catch (Error e) {
        // En cas d'erreur, insérer un placeholder textuel
        warning("Erreur lors du chargement de l'image %s: %s", path, e.message);
        string placeholder = alt_text != null && alt_text.strip() != "" ? alt_text : GLib.Path.get_basename(path);
        if (placeholder == null || placeholder == "") placeholder = "[Image non trouvée]";

        TextMark img_start = buffer.create_mark(null, iter, true);
        buffer.insert(ref iter, placeholder, -1);
        TextIter start;
        buffer.get_iter_at_mark(out start, img_start);
        buffer.delete_mark(img_start);
        buffer.apply_tag(tag_image, start, iter);
    }
}

public void insert_table(int rows, int cols) {
    // Créer une table pivot
    var table = new PivotTable();

    // Initialiser avec des cellules vides
    for (int i = 0; i < rows; i++) {
        var row = new Gee.ArrayList<PivotTableCell>();
        for (int j = 0; j < cols; j++) {
            row.add(new PivotTableCell.from_text(""));
        }
        table.rows.add(row);
    }

    // Obtenir la position actuelle du curseur
    TextIter iter;
    buffer.get_iter_at_mark(out iter, buffer.get_insert());

    // Insérer un représentation ASCII simple de la table
    buffer.insert(ref iter, "\n", -1);

    // Marque pour le début de la table
    TextMark table_start = buffer.create_mark(null, iter, true);

    // En-têtes
    string header_row = "|";
    string separator_row = "|";

    // Utiliser la variable 'cols' passée en argument
    for (int j = 0; j < cols; j++) {
        header_row += " Colonne " + (j + 1).to_string() + " |";
        separator_row += " -------- |";
    }

    buffer.insert(ref iter, header_row + "\n", -1);
    buffer.insert(ref iter, separator_row + "\n", -1);

    // Lignes de données
    // Utiliser la variable 'rows' passée en argument
    for (int i = 1; i < rows; i++) {
        string data_row = "|";
        // Utiliser la variable 'cols' passée en argument
        for (int j = 0; j < cols; j++) {
            data_row += "          |";         // Cellule vide par défaut
        }
        buffer.insert(ref iter, data_row + "\n", -1);
    }

    buffer.insert(ref iter, "\n", -1);

    // Appliquer un tag spécifique si nécessaire (optionnel)
    // TextIter table_end = iter;
    // TextIter start_iter;
    // buffer.get_iter_at_mark(out start_iter, table_start);
    // buffer.apply_tag(tag_table, start_iter, table_end);

    buffer.delete_mark(table_start);

    // Note: Une implémentation complète nécessiterait une interface utilisateur
    // plus sophistiquée pour l'édition de tableau
}

// Gestionnaire de redimensionnement pour mettre à jour les traits horizontaux
private void on_size_changed() {
    if (disable_rule_resize) {
        if (debug_rules) log_rule_debug("on_size_changed skipped (dynamic resize disabled)");
        return;
    }
    if (debug_rules) log_rule_debug("on_size_changed triggered: width=" + this.get_width().to_string());
    update_existing_horizontal_rules();
}

/**
 * Force la mise à jour de tous les traits horizontaux.
 * Utile après le chargement d'un document ou un changement de configuration.
 */
public void refresh_horizontal_rules() {
    last_calculated_rule_length = 0; // Force la recalculation
    update_existing_horizontal_rules();
}

// Met à jour tous les traits horizontaux existants avec la nouvelle largeur
private void update_existing_horizontal_rules() {
    // S'assurer que les tags sont créés
    ensure_tags();

    if (disable_rule_resize) {
        if (debug_rules) log_rule_debug("update_existing_horizontal_rules skipped (dynamic resize disabled)");
        return;
    }

    // Calculer la nouvelle longueur
    int new_length = calculate_rule_length();

    // Si la longueur n'a pas changé d'au moins 1 caractère, ne pas mettre à jour
    if (last_calculated_rule_length > 0 && (new_length - last_calculated_rule_length).abs() < 1) {
        if (debug_rules) log_rule_debug(@"No significant rule length change (old=$last_calculated_rule_length new=$new_length)");
        return;
    }

    if (debug_rules) log_rule_debug(@"Rule length updated from $last_calculated_rule_length to $new_length");
    last_calculated_rule_length = new_length;

    // Créer le texte du trait cible
    var rule_text = new StringBuilder();
    for (int i = 0; i < new_length; i++) {
        rule_text.append_unichar('─');
    }

    // 1) Premier passage: convertir les règles Markdown (---, ***, ___) en traits Unicode tagués
    int total_lines = buffer.get_line_count();
    buffer.begin_user_action();
    for (int li = 0; li < total_lines; li++) {
        Gtk.TextIter line_start;
        buffer.get_iter_at_line(out line_start, li);
        Gtk.TextIter line_end = line_start;
        line_end.forward_to_line_end();
        string raw_line = buffer.get_text(line_start, line_end, false);
        string stripped = raw_line.strip();
        if (is_markdown_hr(stripped)) {
            // Remplacer le contenu de la ligne par le trait calculé et appliquer le tag
            Gtk.TextIter s = line_start;
            Gtk.TextIter e = line_end;
            buffer.delete(ref s, ref e);
            // Réinsérer à la position de début de ligne
            buffer.insert_with_tags(ref s, rule_text.str, -1, tag_rule);
            if (debug_rules) log_rule_debug(@"Normalized MD HR at line $li to unicode rule (len=$new_length)");
        }
    }
    buffer.end_user_action();

    // Parcourir tout le buffer pour trouver les traits existants
    Gtk.TextIter start_iter, end_iter;
    buffer.get_start_iter(out start_iter);
    buffer.get_end_iter(out end_iter);

    // Variable pour éviter les boucles infinies
    int iterations = 0;
    const int MAX_ITERATIONS = 1000;

    Gtk.TextIter match_start, match_end;
    while (start_iter.forward_search("─", Gtk.TextSearchFlags.TEXT_ONLY, out match_start, out match_end, end_iter)
           && iterations < MAX_ITERATIONS) {

        iterations++;

        // Vérifier si ce trait a le tag_rule OU s'il s'agit d'une ligne complète de traits
        bool is_rule_tagged = match_start.has_tag(tag_rule);

        // Vérifier aussi si c'est une ligne qui ne contient que des caractères de trait
        Gtk.TextIter line_start = match_start;
        line_start.set_line_offset(0);
        Gtk.TextIter line_end = match_start;
        if (!line_end.ends_line()) {
            line_end.forward_to_line_end();
        }

        string line_text = buffer.get_text(line_start, line_end, false).strip();
        bool is_rule_line = line_text.length > 10 && line_text.replace("─", "").strip().length == 0;

        if (is_rule_tagged || is_rule_line) {
            // Trouver le début et la fin complète du trait
            Gtk.TextIter rule_start = match_start;
            Gtk.TextIter rule_end = match_end;

            // Étendre vers la gauche
            while (rule_start.backward_char() && rule_start.get_char() == '─') {
                // Continue
            }
            if (rule_start.get_char() != '─') {
                rule_start.forward_char();
            }

            // Étendre vers la droite
            while (rule_end.forward_char() && rule_end.get_char() == '─') {
                // Continue
            }
            if (rule_end.get_char() != '─') {
                rule_end.backward_char();
            }

            // Vérifier que nous avons un trait significatif (au moins 10 caractères)
            int rule_length_found = rule_end.get_offset() - rule_start.get_offset();
            if (rule_length_found >= 10) {
                // Remplacer le trait existant par le nouveau
                buffer.delete(ref rule_start, ref rule_end);
                // Réinsérer uniquement les glyphes avec tag de glyphes
                buffer.insert_with_tags(ref rule_start, rule_text.str, -1, tag_rule);
                // Appliquer un tag neutre sur la ligne entière pour purger anciens attributs
                Gtk.TextIter full_line_start = rule_start; full_line_start.set_line_offset(0);
                Gtk.TextIter full_line_end = full_line_start; full_line_end.forward_to_line_end();
                buffer.apply_tag(tag_rule_line, full_line_start, full_line_end);
                if (debug_rules) log_rule_debug("Resized existing rule at line %d to len=%d".printf(full_line_start.get_line(), new_length));
                // Nettoyer complètement la ligne suivante
                Gtk.TextIter next_line_start = full_line_end;
                if (next_line_start.forward_line()) {
                    Gtk.TextIter next_line_end = next_line_start; next_line_end.forward_to_line_end();
                    buffer.remove_tag(tag_rule, next_line_start, next_line_end);
                    buffer.remove_tag(tag_rule_line, next_line_start, next_line_end);
                }

                // Mettre à jour les itérateurs pour continuer la recherche
                buffer.get_iter_at_offset(out start_iter, rule_start.get_offset() + rule_text.str.length);
                buffer.get_end_iter(out end_iter);
                continue;
            }
        }

        // Continuer la recherche depuis la fin du match actuel
        start_iter = match_end;
    }
}

// Détermine si la ligne comprise entre line_start et line_end est une ligne de trait (suite de '─')
private bool is_line_full_rule(Gtk.TextIter line_start, Gtk.TextIter line_end) {
    string line_text = buffer.get_text(line_start, line_end, false);
    string stripped = line_text.strip();
    if (stripped.length < 5) return false; // longueur mini
    // Vérifier uniquement des '─'
    // Remplacement: enlever tous les glyphes '─'; si plus rien => homogène
    if (stripped.replace("─", "").strip().length == 0) return true;
    return false;
}

// Calcule la largeur optimale pour un trait horizontal en fonction de la taille du widget
private int calculate_rule_length() {
    // 1) Essayer d'utiliser la largeur réellement visible du contenu
    Gdk.Rectangle vis;
    this.get_visible_rect(out vis);
    int visible_width = vis.width;

    // 2) Fallbacks si la vue n'est pas encore réalisée
    if (visible_width <= 0) {
    // GTK4: get_allocated_width() est déprécié, utiliser get_width()
    visible_width = this.get_width();
    }
    if (visible_width <= 0) {
        int w = this.get_width();
        visible_width = (w > 0) ? w : 600;
    }

    // 3) Mesurer précisément la largeur d'un caractère avec Pango
    // Utiliser un layout pour le caractère de trait
    var layout = this.create_pango_layout("─");
    int char_w_units, char_h_units;
    layout.get_size(out char_w_units, out char_h_units); // en unités Pango (1/ Pango.SCALE)
    double char_px = (double) char_w_units / (double) Pango.SCALE;
    if (char_px <= 0.0) {
        // Fallback sur un M approximatif
        var layout2 = this.create_pango_layout("M");
        layout2.get_size(out char_w_units, out char_h_units);
        char_px = (double) char_w_units / (double) Pango.SCALE;
    }
    if (char_px <= 0.0) char_px = 7.0; // dernier recours

    // 4) Déduire une petite marge pour scrollbars/paddings (~2ch de sécurité)
    int margin_px = (int) (2 * char_px);
    int available_px = int.max(visible_width - margin_px, 1);

    // 5) Calcul du nombre de glyphes
    int rule_length = (int) ((double) available_px / char_px); // troncature suffisante pour valeurs positives

    // Longueur minimale de sécurité
    if (rule_length < 3) rule_length = 3;

    return rule_length;
}

// Détecte si une ligne texte correspond à une règle Markdown (---, ***, ___) avec espaces optionnels
private bool is_markdown_hr(string s) {
    if (s == null || s.length < 3) return false;
    try {
        // ^\s*([-*_])(?:\s*\1){2,}\s*$
        var regex = new Regex("^\\s*([-*_])(?:\\s*\\1){2,}\\s*$");
        return regex.match(s);
    } catch (RegexError e) {
        // Fallback simple si Regex indisponible
        string t = s.replace(" ", "");
        if (t.length < 3) return false;
        char c = t[0];
        if (c != '-' && c != '*' && c != '_') return false;
        for (int i = 1; i < t.length; i++) { if (t[i] != c) return false; }
        return true;
    }
}

// (Supprimé) ancienne fonction is_unicode_rule_line non utilisée

public void insert_horizontal_rule() {
    ensure_tags();
    if (suppress_next_rule_insert) {
        suppress_next_rule_insert = false; // consomme le flag sans insérer
        if (debug_rules) log_rule_debug("Suppressed rule insertion due to flag");
        return;
    }
    // Obtenir la position actuelle du curseur
    TextIter iter;
    buffer.get_iter_at_mark(out iter, buffer.get_insert());

    // S'assurer qu'on est au début d'une ligne
    if (!iter.starts_line()) {
        buffer.insert(ref iter, "\n", -1);
    }

    // Calculer la largeur optimale
    int rule_length = calculate_rule_length();
    if (disable_rule_resize) {
        // Si désactivé, figer à la dernière valeur connue (sinon calcul initial)
        if (last_calculated_rule_length > 0) rule_length = last_calculated_rule_length;
    }
    if (rule_length < 30) rule_length = 30;
    if (rule_length > 180) rule_length = 180;
    int rem = rule_length % 3;
    if (rem == 1) rule_length -= 1; else if (rem == 2) rule_length += 1;

    // Construire la ligne de trait
    StringBuilder rule_builder = new StringBuilder();
    for (int i = 0; i < rule_length; i++) rule_builder.append_unichar('─');
    string rule_line = rule_builder.str;

    // Insérer le trait (pas de saut de ligne ajouté après)
    buffer.insert_with_tags(ref iter, rule_line, -1, tag_rule);
    if (debug_rules) log_rule_debug("Inserted new rule len=%d at line %d".printf(rule_length, iter.get_line()));

    // Appliquer tag neutre sur la ligne complète
    TextIter line_start = iter; line_start.set_line_offset(0);
    TextIter line_end = line_start; line_end.forward_to_line_end();
    buffer.apply_tag(tag_rule_line, line_start, line_end);

    // Stratégie de visibilité du curseur:
    // - Mettre le curseur juste avant le dernier glyph pour qu'il soit clairement visible
    // - Si la ligne est trop courte (< 4) on le laisse en fin (cas théorique)
    if (rule_length >= 4) {
        TextIter caret_iter = line_start;
        // Avancer de rule_length - 1 glyphes
        for (int i = 0; i < rule_length - 1; i++) {
            if (!caret_iter.forward_char()) break;
        }
        buffer.place_cursor(caret_iter);
    } else {
        buffer.place_cursor(iter);
    }
    // Marquer suppression prochaine insertion (si Enter immédiat)
    suppress_next_rule_insert = true;
}

// --- Logging utilitaire pour diagnostics règles ---
private void log_rule_debug(string msg) {
    // Préfixer avec horodatage simple + compteur règles
    int count = count_rule_lines();
    GLib.message("[RULEDBG] (rules=" + count.to_string() + ") " + msg);
}

private int count_rule_lines() {
    int total = buffer.get_line_count();
    int count = 0;
    for (int li = 0; li < total; li++) {
        Gtk.TextIter ls; buffer.get_iter_at_line(out ls, li);
        Gtk.TextIter le = ls; le.forward_to_line_end();
        if (is_line_full_rule(ls, le)) count++;
    }
    return count;
}


public void insert_table_object(PivotTable table) {
    ensure_tags();

    // Obtenir la position actuelle du curseur
    TextIter iter;
    buffer.get_iter_at_mark(out iter, buffer.get_insert());

    // S'assurer qu'on est au début d'une ligne
    if (!iter.starts_line()) {
        buffer.insert(ref iter, "\n", -1);
    }

    // Insérer une ligne vide avant le tableau
    buffer.insert(ref iter, "\n", -1);

    // Créer et insérer un widget de tableau dynamique
    insert_dynamic_table_widget(table, ref iter);

    // Ajouter un saut de ligne après le tableau
    buffer.insert(ref iter, "\n", -1);

    // Positionner le curseur après le tableau
    buffer.place_cursor(iter);
}

// Nouvelle méthode pour insérer un widget de tableau dynamique
private void insert_dynamic_table_widget(PivotTable table, ref TextIter iter) {
    if (table.rows.size == 0) return;

    // Déterminer le nombre de colonnes
    int num_cols = 0;
    foreach (var row in table.rows) {
        if (row != null && row.size > num_cols) {
            num_cols = row.size;
        }
    }

    if (num_cols == 0) return;

    // Créer un Grid GTK pour le tableau (on va insérer des poignées entre les cellules)
    var table_grid = new Gtk.Grid();
    table_grid.set_column_spacing(0);
    table_grid.set_row_spacing(0);
    table_grid.set_margin_top(8);
    table_grid.set_margin_bottom(8);
    table_grid.set_margin_start(8);
    table_grid.set_margin_end(8);
    table_grid.add_css_class("table-grid");

    // Ajouter des styles CSS pour les bordures continues
    var table_css_provider = new Gtk.CssProvider();
    try {
        string css_content = @"
            .table-cell-textview {
                border: 1px solid #cccccc;
                background: white;
                padding: 8px;
                min-width: 80px;
                min-height: 30px;
                font-family: inherit;
            }
            .table-header-textview {
                border: 1px solid #888888;
                background: #f0f0f0;
                font-weight: bold;
                padding: 10px;
                min-width: 80px;
                min-height: 30px;
                font-family: inherit;
            }
            .table-grid {
                margin: 8px 0;
            }
            .col-resize-grip {
                background: rgba(0,0,0,0.08);
                min-width: 1px;
            }
            .col-resize-grip:hover {
                background: rgba(0,0,0,0.18);
            }
            .row-resize-grip {
                background: rgba(0,0,0,0.08);
                min-height: 1px;
            }
            .row-resize-grip:hover {
                background: rgba(0,0,0,0.18);
            }
            .col-move-handle, .row-move-handle {
                background: transparent;
                min-width: 12px;
                min-height: 12px;
            }
            .handle-decor {
                color: #666666;
                padding-right: 4px;
            }
            .handle-decor:hover {
                color: #333333;
            }
        ";
        table_css_provider.load_from_string(css_content);
        Gtk.StyleContext.add_provider_for_display(
            this.get_display(),
            table_css_provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        );
    } catch (Error e) {
        warning("Impossible de charger le CSS du tableau : %s", e.message);
    }

    // Créer les cellules du tableau avec TextView pour supporter le formatage
    var text_views = new Gtk.TextView[table.rows.size, num_cols];

    int content_rows = table.rows.size;
    int content_cols = num_cols;
    int grid_rows = content_rows * 2 - 1;

    for (int i = 0; i < content_rows; i++) {
        var row = table.rows[i];
        bool is_header = (i == 0);

        for (int j = 0; j < content_cols; j++) {
            // Utiliser TextView au lieu d'Entry pour supporter le formatage
            var text_view = new Gtk.TextView();
            text_view.set_wrap_mode(Gtk.WrapMode.WORD_CHAR);
            text_view.set_accepts_tab(false);
            text_view.set_editable(true);  // S'assurer que le TextView est éditable
            text_view.set_cursor_visible(true);  // Afficher le curseur
            text_view.set_can_focus(true);  // Permettre au TextView de recevoir le focus
            text_view.set_focusable(true);

            // Créer un buffer et configurer les tags de formatage
            var cell_buffer = text_view.get_buffer();
            setup_text_tags_for_cell_buffer(cell_buffer);

            // Contenu de la cellule avec formatage
            if (row != null && j < row.size && row[j] != null) {
                render_segments_to_cell_buffer(row[j].segments, cell_buffer);
            }

            // Appliquer le style approprié
            if (is_header) {
                text_view.add_css_class("table-header-textview");
            } else {
                text_view.add_css_class("table-cell-textview");
            }

            // Stocker la référence pour les callbacks
            text_views[i, j] = text_view;

            // Connecter le signal de changement de texte pour synchronisation
            cell_buffer.changed.connect(() => {
                // Repérer les indices actuels de la cellule (peu coûteux car tableaux modestes)
                int mapped_row = -1;
                int mapped_col = -1;
                for (int rr = 0; rr < content_rows && mapped_row == -1; rr++) {
                    for (int cc = 0; cc < content_cols; cc++) {
                        if (text_views[rr, cc] == text_view) {
                            mapped_row = rr;
                            mapped_col = cc;
                            break;
                        }
                    }
                }
                if (mapped_row == -1 || mapped_col == -1)
                    return;

                // Extraire les segments du buffer et mettre à jour le modèle
                var segments = extract_segments_from_cell_buffer(cell_buffer);
                if (table.rows.size > mapped_row) {
                    var mapped_list = table.rows[mapped_row];
                    if (mapped_list != null && mapped_list.size > mapped_col) {
                        mapped_list[mapped_col] = new PivotTableCell.from_segments(segments);
                    }
                }
            });

            // Ajouter un gestionnaire de clic pour empêcher la propagation excessive
            // qui causerait la sélection de tout le tableau sur triple/double clic
            // IMPORTANT : Utiliser la phase BUBBLE (après que le TextView ait traité le clic)
            // pour que la sélection de texte fonctionne normalement dans la cellule
            var click_controller = new Gtk.GestureClick();
            click_controller.set_propagation_phase(Gtk.PropagationPhase.BUBBLE);
            click_controller.pressed.connect((n_press, x, y) => {
                // Vérifier d'abord si on clique sur un lien avec Ctrl
                var event = click_controller.get_last_event(click_controller.get_last_updated_sequence());
                if (event != null) {
                    var modifiers = event.get_modifier_state();
                    if ((modifiers & (int)Gdk.ModifierType.CONTROL_MASK) != 0) {
                        // Convertir les coordonnées en coordonnées buffer
                        int buffer_x, buffer_y;
                        text_view.window_to_buffer_coords(Gtk.TextWindowType.TEXT, (int)x, (int)y, out buffer_x, out buffer_y);
                        
                        // Obtenir l'itérateur à cette position
                        TextIter link_iter;
                        if (text_view.get_iter_at_location(out link_iter, buffer_x, buffer_y)) {
                            // Chercher un tag de lien
                            var tags = link_iter.get_tags();
                            foreach (var tag in tags) {
                                if (tag.name != null && tag.name.has_prefix("link::u:")) {
                                    // Extraire l'URL du nom du tag
                                    string url = tag.name.substring("link::u:".length);
                                    url = Uri.unescape_string(url);
                                    
                                    // Ouvrir l'URL ou naviguer vers l'ancre
                                    open_link(url);
                                    
                                    // Ne pas propager l'événement
                                    click_controller.set_state(Gtk.EventSequenceState.CLAIMED);
                                    return;
                                }
                            }
                        }
                    }
                }
                
                // Le TextView a déjà traité le clic (sélection, curseur, etc.)
                // Maintenant on empêche la propagation vers les parents
                // qui pourraient sélectionner tout le tableau
                click_controller.set_state(Gtk.EventSequenceState.CLAIMED);
            });
            text_view.add_controller(click_controller);

            // Gestionnaire de mouvement de souris pour changer le curseur sur les liens
            var motion_controller = new Gtk.EventControllerMotion();
            motion_controller.motion.connect((x, y) => {
                int buffer_x, buffer_y;
                text_view.window_to_buffer_coords(Gtk.TextWindowType.TEXT, (int)x, (int)y, out buffer_x, out buffer_y);
                
                TextIter motion_iter;
                if (text_view.get_iter_at_location(out motion_iter, buffer_x, buffer_y)) {
                    bool is_on_link = false;
                    var tags = motion_iter.get_tags();
                    foreach (var tag in tags) {
                        if (tag.name != null && tag.name.has_prefix("link::u:")) {
                            is_on_link = true;
                            break;
                        }
                    }
                    
                    if (is_on_link) {
                        text_view.set_cursor_from_name("pointer");
                    } else {
                        text_view.set_cursor_from_name("text");
                    }
                }
            });
            text_view.add_controller(motion_controller);

            // Tracker le focus pour savoir quelle cellule est active (pour les enrichissements)
            var focus_controller = new Gtk.EventControllerFocus();
            focus_controller.enter.connect(() => {
                active_cell_textview = text_view;
            });
            focus_controller.leave.connect(() => {
                // NE PAS réinitialiser active_cell_textview à null !
                // On garde la référence pour que les enrichissements fonctionnent
                // même après avoir cliqué sur un bouton de la barre d'outils
                // active_cell_textview sera mis à jour quand une autre cellule gagne le focus
            });
            text_view.add_controller(focus_controller);

            // Déterminer la largeur/hauteur initiale
            int initial_width = 0; if (table.column_widths.size > j) initial_width = table.column_widths[j];
            int initial_height = 0; if (table.row_heights.size > i) initial_height = table.row_heights[i];

            // Appliquer contraintes minimales + tailles existantes
            int min_w = 80;
            int min_h = 30;
            text_view.set_size_request(initial_width > 0 ? initial_width : min_w, initial_height > 0 ? initial_height : 60);

            // Forcer le wrap à respecter la largeur allouée
            text_view.set_hexpand(false);
            text_view.set_vexpand(false);

            // Ajouter le widget de cellule au grid à une coordonnée paire (2*j, 2*i)
            table_grid.attach(text_view, 2 * j, 2 * i, 1, 1);
        }
        // Ajouter une poignée de redimensionnement de ligne (entre lignes et après la dernière)
        if (i < content_rows) {
            // Une poignée par segment de colonne pour éviter le chevauchement avec les poignées de colonne
            for (int sj = 0; sj < content_cols; sj++) {
                var row_grip = new Gtk.DrawingArea();
                row_grip.set_content_width(1);
                row_grip.set_content_height(1);
                row_grip.add_css_class("row-resize-grip");
                row_grip.set_tooltip_text("Glissez pour redimensionner la ligne");
                row_grip.set_cursor_from_name("row-resize");
                // Placer dans la colonne paire correspondante (2*sj)
                table_grid.attach(row_grip, 2 * sj, 2 * i + 1, 1, 1);

                var row_drag = new Gtk.GestureDrag();
                row_drag.set_propagation_phase(Gtk.PropagationPhase.CAPTURE);
                double row_start_h = 0;
                int target_row_index = i;  // Capturer l'indice de ligne pour cette poignée
                row_drag.drag_begin.connect((x, y) => {
                    row_drag.set_state(Gtk.EventSequenceState.CLAIMED);
                    // Hauteur initiale = max des hauteurs allouées de la ligne cible
                    int h = 0;
                    for (int cj = 0; cj < content_cols; cj++) {
                        var tv_ref = text_views[target_row_index, cj];
                        if (tv_ref == null) continue;
                        int ch = tv_ref.get_allocated_height();
                        if (ch > h) h = ch;
                    }
                    // Si taille déjà définie
                    if (table.row_heights.size > target_row_index && table.row_heights[target_row_index] > 0) {
                        h = table.row_heights[target_row_index];
                    }
                    row_start_h = h;
                });
                row_drag.drag_update.connect((dx, dy) => {
                    int target = (int) (row_start_h + dy);
                    if (target < 30) target = 30;
                    // Appliquer à toutes les cellules de la ligne cible
                    for (int cj = 0; cj < content_cols; cj++) {
                        var tv = text_views[target_row_index, cj];
                        if (tv == null) continue;
                        int cw = tv.get_allocated_width();
                        if (table.column_widths.size > cj && table.column_widths[cj] > 0) {
                            cw = table.column_widths[cj];
                        }
                        tv.set_size_request(cw > 0 ? cw : 80, target);
                    }
                    // Stocker dans le modèle
                    while (table.row_heights.size <= target_row_index) table.row_heights.add(0);
                    table.row_heights[target_row_index] = target;
                });
                row_grip.add_controller(row_drag);
            }
        }
    }

    // Ajouter des poignées de redimensionnement de colonnes (entre colonnes et après la dernière)
    for (int j = 0; j < content_cols; j++) {
        var col_grip = new Gtk.DrawingArea();
        col_grip.set_content_width(1);
        col_grip.set_content_height(1);
        col_grip.add_css_class("col-resize-grip");
        col_grip.set_tooltip_text("Glissez pour redimensionner la colonne");
        col_grip.set_cursor_from_name("col-resize");
        // Couvre toute la hauteur de la grille
        table_grid.attach(col_grip, 2 * j + 1, 0, 1, grid_rows);

        var drag = new Gtk.GestureDrag();
        drag.set_propagation_phase(Gtk.PropagationPhase.CAPTURE);
        double start_w_left = 0;
        int target_col_index = j;  // Capturer l'indice de colonne pour cette poignée
        drag.drag_begin.connect((x, y) => {
            drag.set_state(Gtk.EventSequenceState.CLAIMED);
            // largeur initiale = largeur allouée de la colonne gauche cible
            int w = 0;
            for (int ri = 0; ri < content_rows; ri++) {
                int cw = text_views[ri, target_col_index].get_allocated_width();
                if (cw > w) w = cw;
            }
            if (table.column_widths.size > target_col_index && table.column_widths[target_col_index] > 0) {
                w = table.column_widths[target_col_index];
            }
            start_w_left = w;
        });
        drag.drag_update.connect((dx, dy) => {
            int target_left = (int) (start_w_left + dx);
            if (target_left < 80) target_left = 80;
            // Appliquer à toutes les cellules de la colonne gauche cible
            for (int ri = 0; ri < content_rows; ri++) {
                var tv_left = text_views[ri, target_col_index];
                int ch = tv_left.get_allocated_height();
                tv_left.set_size_request(target_left, ch > 0 ? ch : 60);
            }
            while (table.column_widths.size <= target_col_index) table.column_widths.add(0);
            table.column_widths[target_col_index] = target_left;
        });
        col_grip.add_controller(drag);
    }

    // CORRECTION CRITIQUE : Utiliser une copie de l'itérateur pour create_child_anchor
    // pour éviter d'invalider l'itérateur iter passé en référence
    TextIter local_iter;
    buffer.get_iter_at_offset(out local_iter, iter.get_offset());
    var anchor = buffer.create_child_anchor(local_iter);

    // Mettre à jour iter à la position après l'anchor en utilisant l'offset
    buffer.get_iter_at_offset(out iter, local_iter.get_offset());

    // Ajouter le widget au TextView
    add_child_at_anchor(table_grid, anchor);

    // Dans GTK4, on utilise set_visible(true) au lieu de show()
    table_grid.set_visible(true);
}

// Méthodes utilitaires pour le formatage dans les cellules de tableau
private void setup_text_tags_for_cell_buffer(Gtk.TextBuffer cell_buffer) {
    var tag_table = cell_buffer.get_tag_table();

    // Créer les tags de base pour le formatage si ils n'existent pas
    if (tag_table.lookup("bold") == null) {
        var bold_tag = cell_buffer.create_tag("bold");
        bold_tag.weight = Pango.Weight.BOLD;
    }

    if (tag_table.lookup("italic") == null) {
        var italic_tag = cell_buffer.create_tag("italic");
        italic_tag.style = Pango.Style.ITALIC;
    }

    if (tag_table.lookup("underline") == null) {
        var underline_tag = cell_buffer.create_tag("underline");
        underline_tag.underline = Pango.Underline.SINGLE;
    }

    if (tag_table.lookup("strikethrough") == null) {
        var strikethrough_tag = cell_buffer.create_tag("strikethrough");
        strikethrough_tag.strikethrough = true;
    }

    if (tag_table.lookup("code") == null) {
        var code_tag = cell_buffer.create_tag("code");
        code_tag.family = "monospace";
        code_tag.background = "#f0f0f0";
    }

    // Tag de base pour les liens
    if (tag_table.lookup("link") == null) {
        var link_tag = cell_buffer.create_tag("link");
        link_tag.foreground = "#0066cc";
        link_tag.underline = Pango.Underline.SINGLE;
    }
}

private void render_segments_to_cell_buffer(Gee.List<TextSegment> segments, Gtk.TextBuffer cell_buffer) {
    cell_buffer.set_text("", 0);

    foreach (var segment in segments) {
        TextIter end_iter;
        cell_buffer.get_end_iter(out end_iter);

        var start_offset = end_iter.get_offset();
        cell_buffer.insert(ref end_iter, segment.text, -1);

        // Appliquer les tags de formatage
        TextIter start_iter;
        cell_buffer.get_iter_at_offset(out start_iter, start_offset);
        cell_buffer.get_end_iter(out end_iter);

        // Gestion des couleurs personnalisées (créer des tags dynamiques)
        string? color_tag_name = null;
        if (segment.fg_color != null || segment.bg_color != null) {
            color_tag_name = "color_" + start_offset.to_string();
            var tag_table = cell_buffer.get_tag_table();
            if (tag_table.lookup(color_tag_name) == null) {
                var color_tag = cell_buffer.create_tag(color_tag_name);
                if (segment.fg_color != null && segment.fg_color != "") {
                    color_tag.foreground = segment.fg_color;
                    color_tag.set_data("fg_color", segment.fg_color);
                }
                if (segment.bg_color != null && segment.bg_color != "") {
                    color_tag.background = segment.bg_color;
                    color_tag.set_data("bg_color", segment.bg_color);
                }
            }
        }

        // Appliquer les formats de base
        foreach (var format in segment.formats) {
            string tag_name = "";
            switch (format) {
                case TextFormatting.BOLD:
                    tag_name = "bold";
                    break;
                case TextFormatting.ITALIC:
                    tag_name = "italic";
                    break;
                case TextFormatting.UNDERLINE:
                    tag_name = "underline";
                    break;
                case TextFormatting.STRIKETHROUGH:
                    tag_name = "strikethrough";
                    break;
                case TextFormatting.CODE:
                    tag_name = "code";
                    break;
            }

            if (tag_name != "") {
                cell_buffer.apply_tag_by_name(tag_name, start_iter, end_iter);
            }
        }

        // Appliquer le tag de couleur si nécessaire
        if (color_tag_name != null) {
            cell_buffer.apply_tag_by_name(color_tag_name, start_iter, end_iter);
        }

        // Gestion des liens
        if (segment.link_href != null && segment.link_href != "") {
            cell_buffer.apply_tag_by_name("link", start_iter, end_iter);
            // Stocker l'URL dans les données du tag pour une utilisation future
            var tag_table = cell_buffer.get_tag_table();
            var link_tag = tag_table.lookup("link");
            link_tag.set_data("href", segment.link_href);
        }

        // Gestion des images (afficher texte alt avec indication visuelle)
        if (segment.image_src != null && segment.image_src != "") {
            // Créer un tag spécial pour les images si il n'existe pas
            var tag_table = cell_buffer.get_tag_table();
            if (tag_table.lookup("image") == null) {
                var image_tag = cell_buffer.create_tag("image");
                image_tag.foreground = "#666666";
                image_tag.style = Pango.Style.ITALIC;
                image_tag.background = "#f5f5f5";
            }
            cell_buffer.apply_tag_by_name("image", start_iter, end_iter);
            // Stocker l'URL de l'image
            var image_tag = tag_table.lookup("image");
            image_tag.set_data("src", segment.image_src);
        }
    }
}

private Gee.List<TextSegment> extract_segments_from_cell_buffer(Gtk.TextBuffer cell_buffer) {
    var segments = new Gee.ArrayList<TextSegment>();

    TextIter start_iter, end_iter;
    cell_buffer.get_bounds(out start_iter, out end_iter);

    string text = cell_buffer.get_text(start_iter, end_iter, false);
    if (text.length == 0) {
        return segments;
    }

    // Pour simplifier, on extrait tout le texte comme un seul segment
    // Une implémentation plus avancée analyserait les tags appliqués caractère par caractère
    var formatting_set = new Gee.HashSet<TextFormatting>();
    string? link_href = null;
    string? image_src = null;
    string? fg_color = null;
    string? bg_color = null;

    // Vérifier quels tags sont appliqués au début du texte
    var tags = start_iter.get_tags();
    foreach (var tag in tags) {
        string tag_name = tag.name ?? "";
        switch (tag_name) {
            case "bold":
                formatting_set.add(TextFormatting.BOLD);
                break;
            case "italic":
                formatting_set.add(TextFormatting.ITALIC);
                break;
            case "underline":
                formatting_set.add(TextFormatting.UNDERLINE);
                break;
            case "strikethrough":
                formatting_set.add(TextFormatting.STRIKETHROUGH);
                break;
            case "code":
                formatting_set.add(TextFormatting.CODE);
                break;
            case "link":
                // Récupérer l'URL stockée dans les données du tag
                link_href = tag.get_data<string>("href");
                break;
            case "image":
                // Récupérer l'URL de l'image stockée dans les données du tag
                image_src = tag.get_data<string>("src");
                break;
        }

        // Vérifier les tags de couleur dynamiques
        if (tag_name.has_prefix("color_")) {
            // Récupérer les couleurs stockées dans les données du tag
            fg_color = tag.get_data<string>("fg_color");
            bg_color = tag.get_data<string>("bg_color");
        }
    }

    var segment = new TextSegment(text, formatting_set);
    if (link_href != null) {
        segment.link_href = link_href;
    }
    if (image_src != null) {
        segment.image_src = image_src;
    }
    if (fg_color != null) {
        segment.fg_color = fg_color;
    }
    if (bg_color != null) {
        segment.bg_color = bg_color;
    }

    segments.add(segment);
    return segments;
}
// (Supprimé) safe_insert_at_end non utilisée

public void load_pivot_document(PivotDocument doc) {
    this.pivot_doc = doc;
    render_pivot_to_buffer(doc);

    // Programmer la mise à jour des traits horizontaux après le rendu
    Idle.add(() => {
        refresh_horizontal_rules();
        return false;
    });
}

private void render_pivot_to_buffer(PivotDocument doc) {
    ensure_tags();
    buffer.set_text("", 0);         // Vider le buffer

    if (doc == null || doc.children.size == 0) {
        return;         // Document vide
    }

    foreach (PivotNode node in doc.children) {
        if (node is PivotHeading) {
            var heading = (PivotHeading)node;

            // Obtenir un itérateur frais à la fin du buffer
            TextIter iter;
            buffer.get_end_iter(out iter);

            // Créer une marque pour le début du texte
            TextMark start_mark = buffer.create_mark(null, iter, true);

            // Insérer le texte
            buffer.insert(ref iter, heading.text + "\n\n", -1);

            // Obtenir de nouveaux itérateurs valides à partir des marques
            TextIter start, end;
            buffer.get_iter_at_mark(out start, start_mark);
            end = start;
            end.forward_chars(heading.text.length);

            // Appliquer le tag approprié
            if (heading.level == 1) {
                buffer.apply_tag(tag_heading1, start, end);
            }
            else if (heading.level == 2) {
                buffer.apply_tag(tag_heading2, start, end);
            }
            else if (heading.level >= 3) {
                buffer.apply_tag(tag_heading3, start, end);
            }

            // Supprimer la marque qui n'est plus nécessaire
            buffer.delete_mark(start_mark);
        }
        else if (node is PivotParagraph) {
            var para = (PivotParagraph)node;

            // Marquer le début du paragraphe pour l'indentation
            TextIter para_start;
            buffer.get_end_iter(out para_start);

            // Pour chaque segment, appliquer le style approprié, en gérant <u>…</u>
            foreach (var segment in para.segments) {
                // Obtenir un nouvel itérateur à chaque insertion
                TextIter segment_iter;
                buffer.get_end_iter(out segment_iter);
                insert_segment_with_html_underline(ref segment_iter, segment);
            }

            // Appliquer l'indentation si nécessaire
            if (para.indent_level > 0) {
                TextIter para_end;
                buffer.get_end_iter(out para_end);

                // Appliquer le tag d'indentation correspondant
                string tag_name = @"indent-$(para.indent_level)";
                var indent_tag = buffer.get_tag_table().lookup(tag_name);
                if (indent_tag == null) {
                    // Créer le tag d'indentation s'il n'existe pas
                    indent_tag = buffer.create_tag(tag_name, null);
                    int margin = para.indent_level * 20; // 20 pixels par niveau
                    indent_tag.set("left-margin", margin);
                }
                buffer.apply_tag(indent_tag, para_start, para_end);
            }

            // Ajouter deux sauts de ligne après le paragraphe
            TextIter final_iter;
            buffer.get_end_iter(out final_iter);
            buffer.insert(ref final_iter, "\n\n", -1);
        }
        else if (node is PivotList) {
            var list = (PivotList)node;

            // Obtenir un itérateur frais à la fin du buffer
            TextIter list_iter;
            buffer.get_end_iter(out list_iter);

            // Début de plage de liste
            TextMark list_start = buffer.create_mark(null, list_iter, true);
            render_list_to_buffer(list, ref list_iter, 0);

            // Ajouter saut de ligne final
            TextIter final_iter;
            buffer.get_end_iter(out final_iter);
            buffer.insert(ref final_iter, "\n", -1);

            // Appliquer le tag à toute la liste
            TextIter list_begin_iter, list_end_iter;
            buffer.get_iter_at_mark(out list_begin_iter, list_start);
            buffer.get_end_iter(out list_end_iter);
            buffer.apply_tag(tag_list, list_begin_iter, list_end_iter);
            buffer.delete_mark(list_start);
        }
        else if (node is PivotLink) {
            var pl = (PivotLink) node;

            // Obtenir un itérateur frais à la fin du buffer
            TextIter link_iter;
            buffer.get_end_iter(out link_iter);

            TextMark lmk = buffer.create_mark(null, link_iter, true);
            buffer.insert(ref link_iter, pl.text ?? pl.href ?? "", -1);

            // Obtenir un nouvel itérateur pour la fin du lien
            TextIter link_end_iter;
            buffer.get_end_iter(out link_end_iter);
            buffer.insert(ref link_end_iter, "\n\n", -1);

            // Appliquer les tags
            TextIter s, e;
            buffer.get_iter_at_mark(out s, lmk);
            e = s;
            e.forward_chars((pl.text ?? pl.href ?? "").length);
            buffer.apply_tag(tag_link, s, e);

            // attacher un tag unique pour href
            string enc = GLib.Uri.escape_string(pl.href ?? "", null, false);
            string unique = "link::u:" + enc;
            Gtk.TextTag url_tag = (Gtk.TextTag) buffer.get_tag_table().lookup(unique);
            if (url_tag == null) url_tag = buffer.create_tag(unique);
            buffer.apply_tag(url_tag, s, e);
            if (!link_tag_names.contains(unique)) link_tag_names.add(unique);
            buffer.delete_mark(lmk);
        }
        else if (node is PivotImage) {
            var pi = (PivotImage) node;
            string placeholder = (pi.alt != null && pi.alt != "") ? pi.alt : (pi.src != null ? GLib.Path.get_basename(pi.src) : "Image");

            // Obtenir un itérateur frais à la fin du buffer
            TextIter image_iter;
            buffer.get_end_iter(out image_iter);

            TextMark im = buffer.create_mark(null, image_iter, true);
            buffer.insert(ref image_iter, placeholder, -1);

            // Obtenir un nouvel itérateur pour la fin de l'image
            TextIter image_end_iter;
            buffer.get_end_iter(out image_end_iter);
            buffer.insert(ref image_end_iter, "\n\n", -1);

            // Appliquer les tags
            TextIter s, e;
            buffer.get_iter_at_mark(out s, im);
            e = s;
            e.forward_chars(placeholder.length);
            buffer.apply_tag(tag_image, s, e);

            string encs = GLib.Uri.escape_string(pi.src ?? "", null, false);
            Gtk.TextTag src_tag = (Gtk.TextTag) buffer.get_tag_table().lookup("image-src::u:" + encs);
            if (src_tag == null) src_tag = buffer.create_tag("image-src::u:" + encs);
            buffer.apply_tag(src_tag, s, e);
            string srcn = "image-src::u:" + encs; if (!image_src_tag_names.contains(srcn)) image_src_tag_names.add(srcn);
            string enca = GLib.Uri.escape_string(pi.alt ?? "", null, false);
            Gtk.TextTag alt_tag = (Gtk.TextTag) buffer.get_tag_table().lookup("image-alt::u:" + enca);
            if (alt_tag == null) alt_tag = buffer.create_tag("image-alt::u:" + enca);
            buffer.apply_tag(alt_tag, s, e);
            string altn = "image-alt::u:" + enca; if (!image_alt_tag_names.contains(altn)) image_alt_tag_names.add(altn);
            buffer.delete_mark(im);
        }
        else if (node is PivotCodeBlock) {
            var code = (PivotCodeBlock)node;

            // Obtenir un itérateur frais à la fin du buffer
            TextIter code_iter;
            buffer.get_end_iter(out code_iter);

            // Insérer une ligne vide avant si nécessaire
            if (!code_iter.starts_line() && code_iter.get_line() > 0) {
                buffer.insert(ref code_iter, "\n", -1);
            }

            // Marque pour le début du bloc de code
            TextMark code_start = buffer.create_mark(null, code_iter, true);

            // Insérer une indication de langage si disponible
            if (code.language != null && code.language != "") {
                buffer.insert(ref code_iter, "[" + code.language + "]\n", -1);
            }

            // Insérer le code avec préservation des sauts de ligne
            buffer.insert(ref code_iter, code.code, -1);

            // Ajouter un saut de ligne après le code
            if (!code_iter.ends_line()) {
                buffer.insert(ref code_iter, "\n", -1);
            }
            buffer.insert(ref code_iter, "\n", -1);

            // Récupérer un itérateur valide pour la fin
            TextIter code_end_iter;
            buffer.get_end_iter(out code_end_iter);

            // Récupérer un itérateur valide pour le début
            TextIter start;
            buffer.get_iter_at_mark(out start, code_start);

            // Appliquer le formatage au bloc de code
            buffer.apply_tag(tag_code, start, code_end_iter);

            // Supprimer la marque
            buffer.delete_mark(code_start);
        }
        else if (node is PivotQuote) {
            var quote = (PivotQuote)node;

            // Obtenir un itérateur frais à la fin du buffer
            TextIter quote_iter;
            buffer.get_end_iter(out quote_iter);

            // Insérer une ligne vide avant si nécessaire
            if (!quote_iter.starts_line() && quote_iter.get_line() > 0) {
                buffer.insert(ref quote_iter, "\n", -1);
            }

            // Marque pour le début de la citation
            TextMark quote_start = buffer.create_mark(null, quote_iter, true);

            // Insérer la citation (avec préfixe visuel)
            buffer.insert(ref quote_iter, "❝ " + quote.text, -1);

            // Ajouter un saut de ligne après la citation
            if (!quote_iter.ends_line()) {
                buffer.insert(ref quote_iter, "\n", -1);
            }
            buffer.insert(ref quote_iter, "\n", -1);

            // Récupérer un itérateur valide pour la fin
            TextIter quote_end_iter;
            buffer.get_end_iter(out quote_end_iter);

            // Récupérer un itérateur valide pour le début
            TextIter start;
            buffer.get_iter_at_mark(out start, quote_start);

            // Appliquer le formatage à la citation
            buffer.apply_tag(tag_quote, start, quote_end_iter);

            // Supprimer la marque
            buffer.delete_mark(quote_start);
        }
        else if (node is PivotTable) {
            var table = (PivotTable)node;

            // Obtenir un itérateur frais à la fin du buffer
            TextIter table_iter;
            buffer.get_end_iter(out table_iter);

            if (table.rows.size == 0) {
                buffer.insert(ref table_iter, "\n[Tableau vide]\n\n", -1);
                continue;
            }

            // Insérer un saut de ligne avant le tableau
            if (!table_iter.starts_line()) {
                buffer.insert(ref table_iter, "\n", -1);
            }
            buffer.insert(ref table_iter, "\n", -1);

            // Utiliser la nouvelle méthode de rendu dynamique
            insert_dynamic_table_widget(table, ref table_iter);

            // Obtenir un nouvel itérateur à la fin pour continuer
            TextIter table_end_iter;
            buffer.get_end_iter(out table_end_iter);
            buffer.insert(ref table_end_iter, "\n", -1);
        }
        else if (node is PivotRule) {
            // Obtenir un itérateur frais à la fin du buffer
            TextIter rule_iter;
            buffer.get_end_iter(out rule_iter);

            // Créer un trait de séparation qui s'étend sur toute la largeur
            TextMark rule_start = buffer.create_mark(null, rule_iter, true);

            // Utiliser la fonction utilitaire pour calculer la largeur optimale
            int rule_length = calculate_rule_length();

            // Créer un trait continu et élégant avec des caractères Unicode
            StringBuilder rule_builder = new StringBuilder();
            for (int i = 0; i < rule_length; i++) {
                rule_builder.append_unichar('─');
            }
            string rule_line = rule_builder.str;

            buffer.insert(ref rule_iter, rule_line + "\n\n", -1);

            // Appliquer le tag de règle
            TextIter start, end;
            buffer.get_iter_at_mark(out start, rule_start);
            end = start;
            end.forward_chars(rule_line.length);
            buffer.apply_tag(tag_rule, start, end);

            buffer.delete_mark(rule_start);
        }
    }

    // Supprimer la marque de fin

    // Rien à nettoyer: les marqueurs Markdown sont supprimés en amont, et <u>…</u> est géré à l’insertion
}

// Insère un segment de texte en appliquant ses formats et en traitant <u>…</u> comme souligné
private void insert_segment_with_html_underline(ref TextIter iter, TextSegment segment) {
    ensure_tags();
    string txt = segment.text ?? "";
    int pos = 0;
    while (pos < txt.length) {
        int open = txt.index_of("<u>", pos);
        if (open == -1) {
            // Insérer le reste tel quel
            insert_run_with_formats(ref iter, txt.substring(pos), segment, false);
            break;
        }
        // Insérer la partie avant <u>
        if (open > pos) {
            insert_run_with_formats(ref iter, txt.substring(pos, open - pos), segment, false);
        }
        int close = txt.index_of("</u>", open + 3);
        if (close == -1) {
            // Pas de fermeture: insérer le reste brut (sans enlever <u>)
            insert_run_with_formats(ref iter, txt.substring(open), segment, false);
            break;
        }
        // Contenu à souligner
        string under = txt.substring(open + 3, close - (open + 3));
    insert_run_with_formats(ref iter, under, segment, true);
        pos = close + 4; // après </u>
    }
}

// Rendu récursif des listes (avec imbrication)
private void render_list_to_buffer(PivotList l, ref TextIter iter, int level) {
    string indent = string.nfill(level * 3, ' ');
    int local = 1;
    foreach (var it in l.items) {
        if (l.ordered) buffer.insert(ref iter, indent + "%d. ".printf(local++), -1);
        else buffer.insert(ref iter, indent + "• ", -1);
        // Rendre les segments enrichis si disponibles
        if (it.segments != null && it.segments.size > 0) {
            foreach (var seg in it.segments) {
                insert_segment_with_html_underline(ref iter, seg);
            }
        } else {
            // Fallback compat: utiliser le texte brut
            buffer.insert(ref iter, it.text ?? "", -1);
        }
        buffer.insert(ref iter, "\n", -1);
        if (it.children != null && it.children.items.size > 0) {
            render_list_to_buffer(it.children, ref iter, level + 1);
        }
    }
}

// Insère du texte et applique tous les tags du segment, plus éventuellement le soulignement HTML
private void insert_run_with_formats(ref TextIter iter, string run_text, TextSegment segment, bool add_underline) {
    if (run_text == null || run_text.length == 0) return;
    TextMark mark = buffer.create_mark(null, iter, true);
    buffer.insert(ref iter, run_text, -1);
    TextIter start;
    buffer.get_iter_at_mark(out start, mark);
    buffer.delete_mark(mark);

    // Appliquer les tags
    if (segment.has_format(TextFormatting.BOLD)) buffer.apply_tag(tag_bold, start, iter);
    if (segment.has_format(TextFormatting.ITALIC)) buffer.apply_tag(tag_italic, start, iter);
    if (segment.has_format(TextFormatting.STRIKETHROUGH)) buffer.apply_tag(tag_strikethrough, start, iter);
    if (segment.has_format(TextFormatting.CODE)) buffer.apply_tag(tag_code, start, iter);
    if (segment.has_format(TextFormatting.UNDERLINE) || add_underline) buffer.apply_tag(tag_underline, start, iter);
    // Couleurs dynamiques
    if (segment.fg_color != null && segment.fg_color.strip() != "") {
        string cname = "fg::" + segment.fg_color.strip();
        Gtk.TextTag t = (Gtk.TextTag) buffer.get_tag_table().lookup(cname);
        if (t == null) {
            t = buffer.create_tag(cname, "foreground", segment.fg_color.strip());
        }
        buffer.apply_tag(t, start, iter);
        if (!fg_tag_names.contains(cname)) fg_tag_names.add(cname);
    }
    if (segment.bg_color != null && segment.bg_color.strip() != "") {
        string cname = "bg::" + segment.bg_color.strip();
        Gtk.TextTag t = (Gtk.TextTag) buffer.get_tag_table().lookup(cname);
        if (t == null) {
            t = buffer.create_tag(cname, "background", segment.bg_color.strip());
        }
        buffer.apply_tag(t, start, iter);
        if (!bg_tag_names.contains(cname)) bg_tag_names.add(cname);
    }
    if (segment.link_href != null && segment.link_href.strip() != "") {
        // Appliquer style lien + tag URL
        buffer.apply_tag(tag_link, start, iter);
        string enc = GLib.Uri.escape_string(segment.link_href, null, false);
        string unique = "link::u:" + enc;
        Gtk.TextTag url_tag = (Gtk.TextTag) buffer.get_tag_table().lookup(unique);
        if (url_tag == null) url_tag = buffer.create_tag(unique);
        buffer.apply_tag(url_tag, start, iter);
    if (!link_tag_names.contains(unique)) link_tag_names.add(unique);
    }
}

/**
  * Convertit le contenu actuel du buffer en document pivot
  * Cette méthode est l'inverse de render_pivot_to_buffer
  */
public PivotDocument get_pivot_document() {
    ensure_tags();
    var doc = pivot_doc ?? new PivotDocument();
    doc.children.clear();

    // Parcours linéaire par lignes
    TextIter iter;
    buffer.get_start_iter(out iter);

    // États courants
    bool in_code = false;
    bool in_quote = false;
    bool in_list = false;
    bool in_paragraph = false;

    // Bornes de bloc (initialisés au début du buffer)
    TextIter block_start; buffer.get_start_iter(out block_start); // valide quand un bloc est actif
    TextIter line_start; buffer.get_start_iter(out line_start);
    TextIter line_end; buffer.get_start_iter(out line_end);

    // Accumulateurs pour blocs qui combinent plusieurs lignes
    Gee.ArrayList<string> lines_accum = new Gee.ArrayList<string>();

    void flush_paragraph_block(TextIter start_it, TextIter end_it) {
        if (!in_paragraph) return;
        // Vérifier des itérateurs valides
        if (start_it.get_buffer() != buffer || end_it.get_buffer() != buffer) { in_paragraph = false; return; }
        string txt = buffer.get_text(start_it, end_it, false).strip();
        if (txt.length > 0) {
            // Vérifier si ce n'est pas déjà un titre - si c'est le cas, ne pas traiter comme paragraphe
            if (start_it.has_tag(tag_heading1) || start_it.has_tag(tag_heading2) || start_it.has_tag(tag_heading3)) {
                in_paragraph = false;
                return;
            }

            // Si l'intégralité de la ligne (ou plage) est taguée lien, produire un PivotLink
            Gtk.TextIter s = start_it; Gtk.TextIter e = end_it;
            bool whole_is_link = true;
            Gtk.TextIter it = s;
            while (it.compare(e) < 0) {
                if (!it.has_tag(tag_link)) { whole_is_link = false; break; }
                if (!it.forward_char()) break;
            }
            if (whole_is_link) {
                // Trouver l'URL associée via registre
                string? href = null;
                foreach (var name in link_tag_names) {
                    var t = (Gtk.TextTag) buffer.get_tag_table().lookup(name);
                    if (t != null && range_has_tag(s, e, t)) {
                        string enc = name.substring("link::u:".length);
                        href = GLib.Uri.unescape_string(enc);
                        break;
                    }
                }
                var link = new PivotLink(); link.text = txt; link.href = href ?? txt;
                doc.children.add(link);
            } else if (s.has_tag(tag_image)) {
                // Image: récupérer src et alt depuis tags nommés (registre)
                string? src = null; string? alt = txt;
                foreach (var name in image_src_tag_names) {
                    var t = (Gtk.TextTag) buffer.get_tag_table().lookup(name);
                    if (t != null && range_has_tag(s, e, t)) {
                        string enc = name.substring("image-src::u:".length);
                        src = GLib.Uri.unescape_string(enc);
                        break;
                    }
                }
                foreach (var name in image_alt_tag_names) {
                    var t = (Gtk.TextTag) buffer.get_tag_table().lookup(name);
                    if (t != null && range_has_tag(s, e, t)) {
                        string enc = name.substring("image-alt::u:".length);
                        alt = GLib.Uri.unescape_string(enc);
                        break;
                    }
                }
                var pi = new PivotImage(); pi.alt = alt ?? ""; pi.src = src ?? "";
                doc.children.add(pi);
            } else {
                var para = new PivotParagraph();
                para.segments = extract_formatted_segments(txt, start_it, end_it);

                // Capturer le niveau d'indentation depuis les TextTags
                para.indent_level = 0;
                for (int level = 1; level <= 10; level++) {
                    string tag_name = @"indent-$level";
                    var tag = buffer.get_tag_table().lookup(tag_name);
                    if (tag != null && start_it.has_tag(tag)) {
                        para.indent_level = level;
                        break;
                    }
                }

                doc.children.add(para);
            }
        }
        in_paragraph = false;
    }

    void flush_code_block() {
        if (!in_code) return;
        // Récupérer le texte du bloc code
        TextIter end_it = line_end; // fin de la dernière ligne vue
        if (block_start.get_buffer() != buffer || end_it.get_buffer() != buffer) { in_code = false; return; }
        string code_text = buffer.get_text(block_start, end_it, false);
        // Découper par lignes pour retirer une éventuelle première ligne [lang]
        string[] code_lines = code_text.split("\n");
        var code = new PivotCodeBlock();
        if (code_lines.length > 0 && code_lines[0].strip().has_prefix("[") && code_lines[0].strip().has_suffix("]")) {
            string lang_line = code_lines[0].strip();
            code.language = lang_line.substring(1, lang_line.length - 2);
            code.code = string.joinv("\n", code_lines[1 : code_lines.length]);
        } else {
            code.language = "";
            code.code = code_text;
        }
        doc.children.add(code);
        in_code = false;
    }

    void flush_quote_block() {
        if (!in_quote) return;
        string joined = string.joinv("\n", (string[]) lines_accum.to_array());
        // Retirer le préfixe visuel «❝ » par ligne
        var cleaned_lines = new Gee.ArrayList<string>();
        foreach (string l in joined.split("\n")) {
            string t = l.strip();
            if (t.has_prefix("❝ ")) t = t.substring(2);
            if (t.has_prefix("> ")) t = t.substring(2);
            cleaned_lines.add(t);
        }
        var quote = new PivotQuote();
        quote.text = string.joinv("\n", (string[]) cleaned_lines.to_array());
        doc.children.add(quote);
        lines_accum.clear();
        in_quote = false;
    }

    void flush_list_block() {
        if (!in_list) return;
        // Construire via pile d'indentation
        Gee.ArrayList<int> indents = new Gee.ArrayList<int>();
        Gee.ArrayList<PivotList> stacks = new Gee.ArrayList<PivotList>();
        PivotList root = new PivotList(); root.ordered = false;
        indents.add(0); stacks.add(root);
        foreach (string l in lines_accum) {
            // calcul indentation
            int leading = 0; while (leading < l.length && (l[leading] == ' ' || l[leading] == '\t')) leading++;
            string t = l.strip();
            bool is_bullet = t.has_prefix("• ") || t.has_prefix("- ") || t.has_prefix("* ") || t.has_prefix("+ ");
            int di = t.index_of(". ");
            bool is_ordered = false;
            if (di > 0) { is_ordered = true; for (int k = 0; k < di; k++) { if (!(t[k] >= '0' && t[k] <= '9')) { is_ordered = false; break; } } }
            string item_text = null;
            if (is_bullet) {
                int off = 2; if (t.has_prefix("• ")) off = "• ".length; item_text = t.substring(off).strip();
            } else if (is_ordered) {
                item_text = t.substring(di + 2).strip();
            } else {
                continue; // ignorer ligne qui n'est pas un item
            }
            int level = leading / 3;
            // niveau racine a indents.size == 1
            while (level + 1 < indents.size) { indents.remove_at(indents.size - 1); stacks.remove_at(stacks.size - 1); }
            while (level + 1 > indents.size) {
                var nl = new PivotList(); nl.ordered = is_ordered; // hérite du type rencontré
                var parent = stacks.get(stacks.size - 1);
                if (parent.items.size == 0) parent.items.add(new PivotListItem() { text = "" });
                var last = parent.items.get(parent.items.size - 1);
                last.children = nl;
                indents.add(indents.size); stacks.add(nl);
            }
            var current = stacks.get(stacks.size - 1);
            // si le type diffère (ordered vs unordered), créer un sous-list dédié
            if (current.ordered != is_ordered) {
                var nl2 = new PivotList(); nl2.ordered = is_ordered;
                var parent2 = current;
                if (parent2.items.size == 0) parent2.items.add(new PivotListItem() { text = "" });
                var last2 = parent2.items.get(parent2.items.size - 1);
                last2.children = nl2;
                stacks.add(nl2);
            }
            // Construire des segments enrichis pour l'item à partir du buffer courant
            var item = new PivotListItem();

            // Solution 2 : Détection précoce des couleurs et formatage
            TextIter search_start = line_start;
            TextIter search_end = line_end;

            // Scanner toute la ligne pour détecter la présence de formatage ou couleurs
            bool found_formatting = false;
            TextIter scan_pos = search_start;

            while (!scan_pos.equal(search_end)) {
                // Vérifier le formatage basique
                if (scan_pos.has_tag(tag_bold) || scan_pos.has_tag(tag_italic) ||
                    scan_pos.has_tag(tag_strikethrough) || scan_pos.has_tag(tag_code) ||
                    scan_pos.has_tag(tag_underline)) {
                    found_formatting = true;
                    break;
                }

                // Vérifier couleurs de texte
                foreach (var name in fg_tag_names) {
                    var t_fg = (Gtk.TextTag) buffer.get_tag_table().lookup(name);
                    if (t_fg != null && scan_pos.has_tag(t_fg)) {
                        found_formatting = true;
                        break;
                    }
                }
                if (found_formatting) break;

                // Vérifier couleurs de fond
                foreach (var name in bg_tag_names) {
                    var t_bg = (Gtk.TextTag) buffer.get_tag_table().lookup(name);
                    if (t_bg != null && scan_pos.has_tag(t_bg)) {
                        found_formatting = true;
                        break;
                    }
                }
                if (found_formatting) break;

                if (!scan_pos.forward_char()) break;
            }

            if (found_formatting) {
                // Il y a du formatage, utiliser extract_formatted_segments avec le texte complet de la ligne
                string full_line_text = buffer.get_text(search_start, search_end, false);
                var formatted_segments = extract_formatted_segments(full_line_text, search_start, search_end);

                // Nettoyer les segments pour enlever les préfixes de liste
                clean_list_prefix_from_segments(formatted_segments, is_bullet, is_ordered);

                item.segments = formatted_segments;
            } else {
                // Pas de formatage, utiliser la logique simple
                var seg = new TextSegment(item_text);
                var segments = new Gee.ArrayList<TextSegment>();
                segments.add(seg);
                item.segments = segments;
            }

            stacks.get(stacks.size - 1).items.add(item);
        }
        if (root.items.size > 0) doc.children.add(root);
        lines_accum.clear();
        in_list = false;
    }

    while (true) {
        // Fin du buffer ?
        if (iter.is_end()) {
            // Flush des blocs actifs
            if (in_code) flush_code_block();
            if (in_quote) flush_quote_block();
            if (in_list) flush_list_block();
            // Paragraphe: block_start -> dernier line_end connu
            if (in_paragraph) flush_paragraph_block(block_start, line_end);
            break;
        }

        // Début/fin de ligne courante
        line_start = iter;
        line_start.set_line_offset(0);
        line_end = line_start;
        line_end.forward_to_line_end();

    string line_text = buffer.get_text(line_start, line_end, false);
    string tline = line_text.strip();
    bool is_blank = tline.length == 0;

        // Détection des tags de bloc au début de la ligne
        bool lh1 = line_start.has_tag(tag_heading1);
        bool lh2 = line_start.has_tag(tag_heading2);
        bool lh3 = line_start.has_tag(tag_heading3);
        bool lcode = line_start.has_tag(tag_code);
        bool lquote = line_start.has_tag(tag_quote) || tline.has_prefix("❝") || tline.has_prefix("> ");
        bool llist = line_start.has_tag(tag_list) || tline.has_prefix("• ") || tline.has_prefix("- ") || tline.has_prefix("* ") || tline.has_prefix("+ ");
        if (!llist) {
            int di = tline.index_of(". ");
            if (di > 0) {
                bool numeric = true;
                for (int k = 0; k < di; k++) {
                    if (!(tline[k] >= '0' && tline[k] <= '9')) { numeric = false; break; }
                }
                if (numeric) llist = true;
            }
        }
        // Détection des règles horizontales (lignes avec le tag rule)
        bool lrule = line_start.has_tag(tag_rule);

        // Délimiteurs de blocs: ligne vide sépare tout
        if (is_blank) {
            if (in_code) flush_code_block();
            if (in_quote) flush_quote_block();
            if (in_list) flush_list_block();
            if (in_paragraph) flush_paragraph_block(block_start, line_end);
            in_code = in_quote = in_list = in_paragraph = false;
            // Avancer à la ligne suivante
            if (!iter.forward_line()) break;
            continue;
        }

        // Headings: ligne autonome
        if (lh1 || lh2 || lh3) {
            // Flush blocs précédents
            if (in_code) flush_code_block();
            if (in_quote) flush_quote_block();
            if (in_list) flush_list_block();
            if (in_paragraph) flush_paragraph_block(block_start, line_end);
            in_code = in_quote = in_list = in_paragraph = false;

            var heading = new PivotHeading();
            heading.text = line_text.strip();
            heading.level = lh1 ? 1 : (lh2 ? 2 : 3);
            doc.children.add(heading);
            if (!iter.forward_line()) break;
            continue;
        }

        // Rule horizontale: ligne autonome
        if (lrule) {
            // Flush blocs précédents
            if (in_code) flush_code_block();
            if (in_quote) flush_quote_block();
            if (in_list) flush_list_block();
            if (in_paragraph) flush_paragraph_block(block_start, line_end);
            in_code = in_quote = in_list = in_paragraph = false;

            doc.children.add(new PivotRule());
            if (!iter.forward_line()) break;
            continue;
        }

        // Code block
        if (lcode) {
            if (!in_code) {
                // démarrage bloc code
                block_start = line_start;
                in_code = true;
            }
            // Avancer et continuer à accumuler jusqu’à fin ou ligne vide (gérée plus haut)
            if (!iter.forward_line()) { /* handled by loop top */ }
            continue;
        }

        // Quote block
        if (lquote) {
            if (!in_quote) {
                lines_accum.clear();
                in_quote = true;
            }
            lines_accum.add(line_text);
            if (!iter.forward_line()) { /* handled by loop top */ }
            continue;
        }

        // List block
        if (llist) {
            if (!in_list) {
                lines_accum.clear();
                in_list = true;
            }
            lines_accum.add(line_text);
            if (!iter.forward_line()) { /* handled by loop top */ }
            continue;
        }

        // Paragraphe (aucun tag de bloc)
        if (!in_paragraph) {
            block_start = line_start;
            in_paragraph = true;
        }
        // Avancer à la ligne suivante; la fermeture sera gérée par ligne vide ou fin
        if (!iter.forward_line()) { /* handled by loop top */ }
    }

    return doc;
}


/**
  * Trouve les limites d'un paragraphe dans le buffer - Méthode améliorée
  */

/**
  * Extrait les segments de texte formatés d'un paragraphe - Méthode améliorée
  */
private Gee.List<TextSegment> extract_formatted_segments(string text, TextIter para_start, TextIter para_end) {
    var segments = new Gee.ArrayList<TextSegment>();

    // Si on n'a pas trouvé les limites précises ou si les itérateurs sont invalides, créer un segment simple
    if (para_start.equal(para_end) || para_start.get_buffer() != buffer || para_end.get_buffer() != buffer) {
        segments.add(new TextSegment(text));
        return segments;
    }

    // Protection contre les boucles infinies
    int max_iterations = text.length * 2;          // Limite raisonnable
    int iteration_count = 0;

    // Diviser le paragraphe en segments selon le formatage
    TextIter current = para_start;
    while (!current.equal(para_end) && iteration_count < max_iterations) {
        iteration_count++;

        TextIter segment_end = current;
        // Inclure underline dans la détection pour découper correctement
        bool has_tag = segment_end.has_tag(tag_bold) || segment_end.has_tag(tag_italic) ||
                       segment_end.has_tag(tag_strikethrough) || segment_end.has_tag(tag_code) ||
                       segment_end.has_tag(tag_underline) || segment_end.has_tag(tag_link);

        // Détecter les couleurs actuelles
        string? current_fg_color = null;
        string? current_bg_color = null;
        foreach (var name in fg_tag_names) {
            var t = (Gtk.TextTag) buffer.get_tag_table().lookup(name);
            if (t != null && segment_end.has_tag(t)) {
                current_fg_color = name.substring("fg::".length);
                break;
            }
        }
        foreach (var name in bg_tag_names) {
            var t = (Gtk.TextTag) buffer.get_tag_table().lookup(name);
            if (t != null && segment_end.has_tag(t)) {
                current_bg_color = name.substring("bg::".length);
                break;
            }
        }

        // Avancer caractère par caractère jusqu'à un changement de format ou la fin du paragraphe
        int safety_counter = 0;
        int max_safety = 1000;          // Limite de sécurité supplémentaire

        while (!segment_end.equal(para_end) && safety_counter < max_safety) {
            safety_counter++;

            bool current_has_tag = segment_end.has_tag(tag_bold) || segment_end.has_tag(tag_italic) ||
                                   segment_end.has_tag(tag_strikethrough) || segment_end.has_tag(tag_code) ||
                                   segment_end.has_tag(tag_underline) || segment_end.has_tag(tag_link);

            // Détecter les nouvelles couleurs
            string? new_fg_color = null;
            string? new_bg_color = null;
            foreach (var name in fg_tag_names) {
                var t = (Gtk.TextTag) buffer.get_tag_table().lookup(name);
                if (t != null && segment_end.has_tag(t)) {
                    new_fg_color = name.substring("fg::".length);
                    break;
                }
            }
            foreach (var name in bg_tag_names) {
                var t = (Gtk.TextTag) buffer.get_tag_table().lookup(name);
                if (t != null && segment_end.has_tag(t)) {
                    new_bg_color = name.substring("bg::".length);
                    break;
                }
            }

            // Si le formatage OU les couleurs changent, arrêter
            if (has_tag != current_has_tag ||
                current_fg_color != new_fg_color ||
                current_bg_color != new_bg_color) {
                break;
            }

            // Avancer d'un caractère
            if (!segment_end.forward_char()) {
                break;          // Fin du buffer
            }
        }

        // Si on a atteint la limite de sécurité, passer à la fin du paragraphe
        if (safety_counter >= max_safety) {
            warning("Limite de sécurité atteinte lors de l'extraction des segments formatés");
            segment_end = para_end;
        }

        // Extraire ce segment de texte
        string segment_text = buffer.get_text(current, segment_end, false);

        // Détecter le formatage appliqué
    var formats = new Gee.HashSet<TextFormatting>();
    if (current.has_tag(tag_bold))
            formats.add(TextFormatting.BOLD);
        if (current.has_tag(tag_italic))
            formats.add(TextFormatting.ITALIC);
        if (current.has_tag(tag_strikethrough))
            formats.add(TextFormatting.STRIKETHROUGH);
        if (current.has_tag(tag_code))
            formats.add(TextFormatting.CODE);
    // N’ajouter souligné que si le segment courant possède réellement le tag
    if (current.has_tag(tag_underline))
            formats.add(TextFormatting.UNDERLINE);

        // Détecter liens/images en parcourant les tags appliqués à 'current'
        string? link_href = null;
        if (current.has_tag(tag_link)) {
            // Chercher un tag au nom "link::..." couvrant cette position
            var table = buffer.get_tag_table();
            // Itération grossière: on ne peut pas lister depuis une position, alors on reconstitue par heuristique
            // Simplification: retrouver la chaîne potentielle entre crochets n'existe pas; on associe à l’URL par tag unique
            // Nous allons scanner tous les tags du tableau dont le nom commence par "link::" et tester une courte plage
            // Pour éviter O(n^2), on accepte ce coût car le nombre de tags reste modeste dans un éditeur.
            // NB: Gtk.TextTagTable n'offre pas itération en Vala directement; on s'abstient et estimons en reformatting à l'insertion/rendu.
        }

        // Créer le segment
        var seg = new TextSegment(segment_text, formats);
        if (current.has_tag(tag_link)) {
            string? found = null;
            foreach (var name in link_tag_names) {
                var t = (Gtk.TextTag) buffer.get_tag_table().lookup(name);
                if (t != null && current.has_tag(t)) {
                    string enc = name.substring("link::u:".length);
                    found = GLib.Uri.unescape_string(enc);
                    break;
                }
            }
            seg.link_href = found;
        }

        // Extraire les couleurs des tags dynamiques
        foreach (var name in fg_tag_names) {
            var t = (Gtk.TextTag) buffer.get_tag_table().lookup(name);
            if (t != null && current.has_tag(t)) {
                seg.fg_color = name.substring("fg::".length);
                break;
            }
        }
        foreach (var name in bg_tag_names) {
            var t = (Gtk.TextTag) buffer.get_tag_table().lookup(name);
            if (t != null && current.has_tag(t)) {
                seg.bg_color = name.substring("bg::".length);
                break;
            }
        }

        segments.add(seg);

        // Passer au segment suivant
        current = segment_end;
    }

    // Si on a atteint la limite ou si aucun segment n'a été extrait, créer un segment par défaut
    if (iteration_count >= max_iterations || segments.size == 0) {
        warning("Limite d'itérations atteinte ou aucun segment trouvé. Création d'un segment par défaut.");
        segments.clear();
        segments.add(new TextSegment(text));
    }

    return segments;
}

// Détecte si une plage contient un tag donné
private bool range_has_tag(Gtk.TextIter start, Gtk.TextIter end, Gtk.TextTag tag) {
    Gtk.TextIter it = start;
    while (it.compare(end) < 0) {
        if (it.has_tag(tag)) return true;
        if (!it.forward_char()) break;
    }
    return false;
}

// Helper pour nettoyer les préfixes de liste des segments
private void clean_list_prefix_from_segments(Gee.List<TextSegment> segments, bool is_bullet, bool is_ordered) {
    if (segments.size == 0) return;

    var first_segment = segments.get(0);
    string text = first_segment.text;

    if (is_bullet) {
        // Enlever "• " ou "- " au début
        if (text.has_prefix("• ")) {
            first_segment.text = text.substring("• ".length);
        } else if (text.has_prefix("- ")) {
            first_segment.text = text.substring(2);
        } else if (text.has_prefix("* ")) {
            first_segment.text = text.substring(2);
        } else if (text.has_prefix("+ ")) {
            first_segment.text = text.substring(2);
        }
    } else if (is_ordered) {
        // Enlever "N. " au début
        int dot_pos = text.index_of(". ");
        if (dot_pos > 0) {
            // Vérifier que c'est bien numérique avant le point
            bool is_numeric = true;
            for (int i = 0; i < dot_pos; i++) {
                if (!(text[i] >= '0' && text[i] <= '9')) {
                    is_numeric = false;
                    break;
                }
            }
            if (is_numeric) {
                first_segment.text = text.substring(dot_pos + 2);
            }
        }
    }

    // Enlever les espaces d'indentation au début si présent
    first_segment.text = first_segment.text.strip();
}

/**
  * Analyse et applique le formatage inline dans un paragraphe
  */

public void set_style(int size, string family, string color) {
    if (css_provider == null) {
        css_provider = new Gtk.CssProvider();
        Gtk.StyleContext.add_provider_for_display(
            Gdk.Display.get_default(),
            css_provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
            );
    }
    // Échapper les quotes simples dans le nom de police et toujours quoter
    string family_sanitized = family.replace("'", "\\'");
    var css_string =
        """
                textview {
            font-family: '%s';
                    font-size: %dpx;
                    color: %s;
                }
        """
        .printf(family_sanitized, size, color);
    css_provider.load_from_string(css_string);
}

public bool has_selection() {
    TextIter start, end;
    return buffer.get_selection_bounds(out start, out end);
}

public void apply_font_to_selection(string font_family) {
    TextIter start, end;
    if (buffer.get_selection_bounds(out start, out end)) {
        var tag = buffer.create_tag(null, "font-desc", font_family);
        buffer.apply_tag(tag, start, end);
    }
}

public void apply_font_size_to_selection(int size) {
    TextIter start, end;
    if (buffer.get_selection_bounds(out start, out end)) {
        var tag = buffer.create_tag(null, "size-points", size);
        buffer.apply_tag(tag, start, end);
    }
}

public void apply_color_to_selection(string color) {
    TextIter start, end;
    if (buffer.get_selection_bounds(out start, out end)) {
        var tag = buffer.create_tag(null, "foreground", color);
        buffer.apply_tag(tag, start, end);
    }
}

public void apply_background_to_selection(string color) {
    TextIter start, end;
    if (buffer.get_selection_bounds(out start, out end)) {
        var tag = buffer.create_tag(null, "background", color);
        buffer.apply_tag(tag, start, end);
    }
}

// --- Méthodes avancées pour les nouveaux blocs insérables ---
/** Insère un bloc info/astuce/avertissement */
public void insert_callout_info() {
}
/** Insère une liste de tâches à cocher */
public void insert_todo_list() {
}
/** Insère un séparateur personnalisé */
public void insert_separator_custom() {
}
/** Insère une citation multi-niveaux */
public void insert_quote_multilevel() {
}
/** Insère un bloc d’alerte/erreur */
public void insert_alert_block() {
}
/** Insère un bloc de code interactif */
public void insert_code_interactive() {
}
/** Insère un bloc de référence/source */
public void insert_reference_block() {
}
/** Insère un bloc repliable/accordéon */
public void insert_collapsible_block() {
}
/** Insère une chronologie */
public void insert_timeline() {
}
/** Insère un bloc graphique/diagramme */
public void insert_chart_block() {
}
/** Insère une variable dynamique */
public void insert_dynamic_variable() {
}
/** Insère un commentaire/feedback */
public void insert_comment_block() {
}

// Returns the current cursor position as line and column (zero-based)
public void get_cursor_position(out int line, out int column) {
    var buffer = this.get_buffer();
    Gtk.TextIter iter;
    buffer.get_iter_at_mark(out iter, buffer.get_insert());
    line = iter.get_line();
    column = iter.get_line_offset();
}

// === MÉTHODES POUR RÉCUPÉRER LES VALEURS COURANTES ===

/** Récupère la famille de police courante au curseur */
public string? get_current_font_family() {
    var buffer = this.get_buffer();
    TextIter iter;
    buffer.get_iter_at_mark(out iter, buffer.get_insert());

    // Parcourir les tags actifs au curseur
    foreach (var tag in iter.get_tags()) {
        // Vérifier d'abord la propriété family
        Value family_value = Value(typeof(string));
        tag.get_property("family", ref family_value);
        if (family_value.holds(typeof(string))) {
            string family = family_value.get_string();
            if (family != null && family != "") {
                return family;
            }
        }

        // Fallback : extraire de font-desc si disponible
        Value font_desc_value = Value(typeof(string));
        tag.get_property("font-desc", ref font_desc_value);
        if (font_desc_value.holds(typeof(string))) {
            string font_desc = font_desc_value.get_string();
            if (font_desc != null && font_desc != "") {
                // Extraire juste la famille du font-desc
                var parts = font_desc.split(" ");
                if (parts.length > 0) {
                    return parts[0];
                }
            }
        }
    }
    return null;
}

/** Récupère la taille de police courante au curseur */
public int get_current_font_size() {
    var buffer = this.get_buffer();
    TextIter iter;
    buffer.get_iter_at_mark(out iter, buffer.get_insert());

    // Parcourir les tags actifs au curseur
    foreach (var tag in iter.get_tags()) {
        Value size_value = Value(typeof(int));
        tag.get_property("size-points", ref size_value);
        if (size_value.holds(typeof(int))) {
            return size_value.get_int();
        }
    }
    return 11; // Taille par défaut
}

/** Récupère la couleur de texte courante au curseur */
public Gdk.RGBA? get_current_foreground_color() {
    var active_buffer = get_active_buffer();
    TextIter iter;
    active_buffer.get_iter_at_mark(out iter, active_buffer.get_insert());

    // Parcourir les tags actifs au curseur
    foreach (var tag in iter.get_tags()) {
        Value color_value = Value(typeof(Gdk.RGBA));
        tag.get_property("foreground-rgba", ref color_value);
        if (color_value.holds(typeof(Gdk.RGBA))) {
            Gdk.RGBA* rgba_ptr = (Gdk.RGBA*)color_value.get_boxed();
            if (rgba_ptr != null) {
                return *rgba_ptr;
            }
        }
    }
    return null; // Couleur par défaut
}

/** Récupère la couleur de fond courante au curseur */
public Gdk.RGBA? get_current_background_color() {
    var active_buffer = get_active_buffer();
    TextIter iter;
    active_buffer.get_iter_at_mark(out iter, active_buffer.get_insert());

    // Parcourir les tags actifs au curseur
    foreach (var tag in iter.get_tags()) {
        Value color_value = Value(typeof(Gdk.RGBA));
        tag.get_property("background-rgba", ref color_value);
        if (color_value.holds(typeof(Gdk.RGBA))) {
            Gdk.RGBA* rgba_ptr = (Gdk.RGBA*)color_value.get_boxed();
            if (rgba_ptr != null) {
                return *rgba_ptr;
            }
        }
    }
    return null; // Couleur par défaut
}

/** Applique la police et la taille en une seule fois */
public void apply_font_and_size(string? font_family, int size) {
    // Protection: vérifier que le widget est réalisé et stable
    if (!this.get_realized() || this.get_buffer() == null) {
        warning("Widget non réalisé, application différée");
        Idle.add(() => {
            if (this.get_realized() && this.get_buffer() != null) {
                apply_font_and_size(font_family, size);
            }
            return false;
        });
        return;
    }

    try {
        TextIter start, end;
        if (buffer.get_selection_bounds(out start, out end)) {
            // Vérification des itérateurs de sélection
            if (start.compare(end) >= 0) {
                warning("Sélection invalide détectée");
                return;
            }

            // Mode ultra-sécurisé: toujours différer même pour les sélections
            Idle.add(() => {
                try {
                    TextIter start_deferred, end_deferred;
                    if (buffer.get_selection_bounds(out start_deferred, out end_deferred)) {
                        // Appliquer à la sélection avec protection renforcée
                        if (font_family != null && font_family.strip() != "") {
                            try {
                                var font_tag = buffer.create_tag(null, "family", font_family);
                                if (font_tag != null) {
                                    buffer.apply_tag(font_tag, start_deferred, end_deferred);
                                }
                            } catch (Error font_error) {
                                warning("Impossible d'appliquer la police: %s", font_error.message);
                            }
                        }
                        if (size > 0) {
                            try {
                                var size_tag = buffer.create_tag(null, "size-points", size);
                                if (size_tag != null) {
                                    buffer.apply_tag(size_tag, start_deferred, end_deferred);
                                }
                            } catch (Error size_error) {
                                warning("Impossible d'appliquer la taille: %s", size_error.message);
                            }
                        }
                    } else {
                        // Plus de sélection, basculer sur les attributs en attente
                        current_font_family = font_family;
                        current_font_size = size;
                        has_pending_attributes = true;
                    }
                } catch (Error deferred_error) {
                    warning("Erreur lors de l'application différée: %s", deferred_error.message);
                    // Fallback sur attributs en attente
                    current_font_family = font_family;
                    current_font_size = size;
                    has_pending_attributes = true;
                }
                return false;
            });
        } else {
            // Si pas de sélection, on applique à l'emplacement du curseur
            // en créant un tag temporaire qui sera utilisé pour le prochain texte saisi
            current_font_family = font_family;
            current_font_size = size;

            // Marquer que nous avons des attributs en attente
            has_pending_attributes = true;
        }
    } catch (Error e) {
        warning("Erreur lors de l'application de la police: %s", e.message);
        // En cas d'erreur, on bascule sur le mode attributs en attente
        current_font_family = font_family;
        current_font_size = size;
        has_pending_attributes = true;
    }
}

/** Applique la couleur de texte */
public void apply_foreground_color(Gdk.RGBA color) {
    var active_buffer = get_active_buffer();
    TextIter start, end;
    if (active_buffer.get_selection_bounds(out start, out end)) {
        var tag = active_buffer.create_tag(null, "foreground-rgba", color);
        active_buffer.apply_tag(tag, start, end);
    } else {
        // Marquer la couleur courante pour les futures insertions
        var tag_table = active_buffer.get_tag_table();
        var color_tag = tag_table.lookup("current-foreground");
        if (color_tag == null) {
            color_tag = active_buffer.create_tag("current-foreground", "foreground-rgba", color);
        } else {
            color_tag.set_property("foreground-rgba", color);
        }
    }
}

/** Applique la couleur de fond */
public void apply_background_color(Gdk.RGBA color) {
    var active_buffer = get_active_buffer();
    TextIter start, end;
    if (active_buffer.get_selection_bounds(out start, out end)) {
        var tag = active_buffer.create_tag(null, "background-rgba", color);
        active_buffer.apply_tag(tag, start, end);
    } else {
        // Marquer la couleur de fond courante pour les futures insertions
        var tag_table = active_buffer.get_tag_table();
        var bg_tag = tag_table.lookup("current-background");
        if (bg_tag == null) {
            bg_tag = active_buffer.create_tag("current-background", "background-rgba", color);
        } else {
            bg_tag.set_property("background-rgba", color);
        }
    }
}

/** Augmente l'indentation de la ligne courante ou sélection */
public void increase_indent() {
    TextIter start, end;
    if (buffer.get_selection_bounds(out start, out end)) {
        // Augmenter l'indentation de toutes les lignes sélectionnées
        indent_lines_with_smart_numbering(start, end, true);
    } else {
        // Détecter le type de contenu sous le curseur
        Gtk.TextIter cursor;
        buffer.get_iter_at_mark(out cursor, buffer.get_insert());

        if (is_heading_line(cursor)) {
            // Si c'est un titre, indenter seulement cette ligne
            Gtk.TextIter line_start = cursor;
            line_start.set_line_offset(0);
            Gtk.TextIter line_end = cursor;
            line_end.forward_to_line_end();
            indent_lines_with_smart_numbering(line_start, line_end, true);
        } else {
            // Pour tout le reste (paragraphe normal, liste), indenter tout le paragraphe
            Gtk.TextIter para_start, para_end;
            find_current_paragraph_bounds(cursor, out para_start, out para_end);
            indent_lines_with_smart_numbering(para_start, para_end, true);
        }
    }
}

/** Diminue l'indentation de la ligne courante ou sélection */
public void decrease_indent() {
    TextIter start, end;
    if (buffer.get_selection_bounds(out start, out end)) {
        // Diminuer l'indentation de toutes les lignes sélectionnées
        indent_lines_with_smart_numbering(start, end, false);
    } else {
        // Détecter le type de contenu sous le curseur
        Gtk.TextIter cursor;
        buffer.get_iter_at_mark(out cursor, buffer.get_insert());

        if (is_heading_line(cursor)) {
            // Si c'est un titre, désindenter seulement cette ligne
            Gtk.TextIter line_start = cursor;
            line_start.set_line_offset(0);
            Gtk.TextIter line_end = cursor;
            line_end.forward_to_line_end();
            indent_lines_with_smart_numbering(line_start, line_end, false);
        } else {
            // Pour tout le reste (paragraphe normal, liste), désindenter tout le paragraphe
            Gtk.TextIter para_start, para_end;
            find_current_paragraph_bounds(cursor, out para_start, out para_end);
            indent_lines_with_smart_numbering(para_start, para_end, false);
        }
    }
}

/** Trouve les limites d'un paragraphe à partir d'une position de curseur */
private void find_current_paragraph_bounds(TextIter cursor, out TextIter start, out TextIter end) {
    start = cursor;
    end = cursor;

    // Trouver le début du paragraphe
    // Un paragraphe commence après une ligne vide ou au début du buffer
    while (!start.is_start()) {
        TextIter line_start = start;
        line_start.set_line_offset(0);

        // Vérifier la ligne précédente
        if (!line_start.backward_line()) {
            // On est à la première ligne, le paragraphe commence ici
            start.set_line_offset(0);
            break;
        }

        TextIter prev_line_start = line_start;
        TextIter prev_line_end = prev_line_start;
        prev_line_end.forward_to_line_end();

        string prev_line_text = buffer.get_text(prev_line_start, prev_line_end, false).strip();

        if (prev_line_text == "") {
            // Ligne précédente vide, le paragraphe commence à la ligne courante
            line_start.forward_line();
            start = line_start;
            start.set_line_offset(0);
            break;
        }

        // Continuer à remonter
        start = line_start;
    }

    // Trouver la fin du paragraphe
    // Un paragraphe se termine avant une ligne vide ou à la fin du buffer
    while (!end.is_end()) {
        TextIter line_start = end;
        line_start.set_line_offset(0);
        TextIter line_end = line_start;
        line_end.forward_to_line_end();

        string line_text = buffer.get_text(line_start, line_end, false).strip();

        // Si la ligne courante est vide, on a atteint la fin du paragraphe
        if (line_text == "") {
            // Le paragraphe se termine à la ligne précédente
            if (end.get_line() > 0) {
                end.backward_line();
                end.forward_to_line_end();
            }
            break;
        }

        // Vérifier la ligne suivante
        TextIter next_line_start = line_end;
        if (!next_line_start.forward_line()) {
            // On est à la dernière ligne, le paragraphe se termine ici
            end.forward_to_line_end();
            break;
        }

        TextIter next_line_end = next_line_start;
        next_line_end.forward_to_line_end();

        string next_line_text = buffer.get_text(next_line_start, next_line_end, false).strip();

        if (next_line_text == "") {
            // Ligne suivante vide, le paragraphe se termine à la ligne courante
            end.forward_to_line_end();
            break;
        }

        // Continuer à descendre
        end = next_line_start;
    }

    // S'assurer que start est au début de sa ligne
    start.set_line_offset(0);
}

/** Détecte si la ligne courante est un titre Markdown */
private bool is_heading_line(TextIter cursor) {
    TextIter line_start = cursor;
    line_start.set_line_offset(0);
    TextIter line_end = cursor;
    line_end.forward_to_line_end();

    string line_text = buffer.get_text(line_start, line_end, false).strip();

    // Vérifier si la ligne commence par des # (titre ATX)
    if (line_text.has_prefix("#")) {
        return true;
    }

    // Vérifier si la ligne suivante contient des = ou - (titre Setext)
    if (!line_end.forward_line()) {
        return false; // Pas de ligne suivante
    }

    TextIter next_line_end = line_end;
    next_line_end.forward_to_line_end();

    string next_line_text = buffer.get_text(line_end, next_line_end, false).strip();

    // Titre Setext niveau 1 (====) ou niveau 2 (----)
    if (next_line_text.length > 0) {
        char first_char = next_line_text[0];
        if (first_char == '=' || first_char == '-') {
            // Vérifier que toute la ligne contient le même caractère
            bool is_uniform = true;
            for (int i = 1; i < next_line_text.length; i++) {
                if (next_line_text[i] != first_char) {
                    is_uniform = false;
                    break;
                }
            }
            return is_uniform;
        }
    }

    return false;
}

/** Méthode utilitaire pour indenter/désindenter des lignes avec gestion intelligente de la numérotation */
private void indent_lines_with_smart_numbering(TextIter start, TextIter end, bool increase) {
    // Si mode NONE, ne rien faire
    if (current_indentation_mode == IndentationMode.NONE) {
        return;
    }

    var start_line = start.get_line();
    var end_line = end.get_line();

    // Bloquer les signaux temporairement pour éviter les notifications multiples
    buffer.begin_user_action();

    // Appliquer l'indentation selon le mode
    for (int line = start_line; line <= end_line; line++) {
        Gtk.TextIter line_start;
        buffer.get_iter_at_line(out line_start, line);
        Gtk.TextIter line_end = line_start;
        line_end.forward_to_line_end();

        switch (current_indentation_mode) {
            case IndentationMode.SPACES:
                if (increase) {
                    apply_spaces_indentation_increase(line_start);
                } else {
                    apply_spaces_indentation_decrease(line_start);
                }
                break;

            case IndentationMode.MARGIN_TAGS:
                if (increase) {
                    apply_indentation_increase(line_start, line_end);
                } else {
                    apply_indentation_decrease(line_start, line_end);
                }
                break;

            case IndentationMode.RTF_FORMAT:
                // Pour RTF, on utilise les tags mais on sauvera en format enrichi
                if (increase) {
                    apply_indentation_increase(line_start, line_end);
                } else {
                    apply_indentation_decrease(line_start, line_end);
                }
                break;

            case IndentationMode.NONE:
            default:
                // Ne rien faire
                break;
        }
    }

    buffer.end_user_action();
}

/** Applique une indentation par espaces à une ligne */
private void apply_spaces_indentation_increase(TextIter line_start) {
    buffer.insert(ref line_start, "    ", -1);
}

/** Retire une indentation par espaces d'une ligne */
private void apply_spaces_indentation_decrease(TextIter line_start) {
    var line_end = line_start;
    line_end.forward_to_line_end();
    var line_text = buffer.get_text(line_start, line_end, false);

    if (line_text.has_prefix("    ")) {
        var end_iter = line_start;
        end_iter.forward_chars(4);
        buffer.delete(ref line_start, ref end_iter);
    } else if (line_text.has_prefix("\t")) {
        var end_iter = line_start;
        end_iter.forward_char();
        buffer.delete(ref line_start, ref end_iter);
    }
}

/**
 * Applique une augmentation d'indentation à une ligne en utilisant les tags de marge
 */
private void apply_indentation_increase(TextIter line_start, TextIter line_end) {
    // Chercher le niveau d'indentation actuel
    int current_level = get_indentation_level(line_start, line_end);

    if (current_level < 10) { // Limiter à 10 niveaux
        // Supprimer l'ancien tag d'indentation s'il existe
        if (current_level > 0) {
            string old_tag_name = "indent-level-%d".printf(current_level);
            var old_tag = buffer.get_tag_table().lookup(old_tag_name);
            if (old_tag != null) {
                buffer.remove_tag(old_tag, line_start, line_end);
            }
        }

        // Appliquer le nouveau tag d'indentation
        int new_level = current_level + 1;
        string new_tag_name = "indent-level-%d".printf(new_level);
        var new_tag = buffer.get_tag_table().lookup(new_tag_name);
        if (new_tag != null) {
            buffer.apply_tag(new_tag, line_start, line_end);
        }
    }
}

/**
 * Applique une diminution d'indentation à une ligne en utilisant les tags de marge
 */
private void apply_indentation_decrease(TextIter line_start, TextIter line_end) {
    // Chercher le niveau d'indentation actuel
    int current_level = get_indentation_level(line_start, line_end);

    if (current_level > 0) {
        // Supprimer l'ancien tag d'indentation
        string old_tag_name = "indent-level-%d".printf(current_level);
        var old_tag = buffer.get_tag_table().lookup(old_tag_name);
        if (old_tag != null) {
            buffer.remove_tag(old_tag, line_start, line_end);
        }

        // Appliquer le nouveau tag d'indentation s'il y en a un
        int new_level = current_level - 1;
        if (new_level > 0) {
            string new_tag_name = "indent-level-%d".printf(new_level);
            var new_tag = buffer.get_tag_table().lookup(new_tag_name);
            if (new_tag != null) {
                buffer.apply_tag(new_tag, line_start, line_end);
            }
        }
    }
}

/**
 * Détermine le niveau d'indentation actuel d'une ligne
 */
private int get_indentation_level(TextIter line_start, TextIter line_end) {
    var table = buffer.get_tag_table();

    // Chercher les tags d'indentation appliqués à cette ligne
    for (int level = 10; level >= 1; level--) {
        string tag_name = "indent-level-%d".printf(level);
        var tag = table.lookup(tag_name);
        if (tag != null) {
            var iter = line_start;
            if (iter.has_tag(tag)) {
                return level;
            }
        }
    }

    return 0; // Pas d'indentation
}

/** Structure pour stocker les informations d'une ligne de liste numérotée */
private struct NumberedListInfo {
    public bool is_numbered_list;
    public int current_number;
    public string prefix; // Les espaces/indentation avant le numéro
    public string suffix; // Le texte après le numéro (généralement ". ")
    public string content; // Le contenu après le marqueur
}

/** Parse une ligne pour extraire les informations de liste numérotée */
private NumberedListInfo? parse_numbered_list_line(string line_text) {
    // Regex pour détecter les listes numérotées : espaces optionnels + numéro + point + espace + contenu
    MatchInfo match_info;
    try {
        var regex = new Regex("^(\\s*)(\\d+)(\\.\\s)(.*)$");
        if (regex.match(line_text, 0, out match_info)) {
            var info = NumberedListInfo();
            info.is_numbered_list = true;
            info.prefix = match_info.fetch(1);
            info.current_number = int.parse(match_info.fetch(2));
            info.suffix = ". ";
            info.content = match_info.fetch(4);
            return info;
        }
    } catch (RegexError e) {
        warning("Erreur regex: %s", e.message);
    }

    var info = NumberedListInfo();
    info.is_numbered_list = false;
    return info;
}

/** Renumérote les listes après indentation selon l'algorithme n°=present_n°.i++ */

/** Conversion d'un mode d'indentation vers un autre */
public void convert_indentation_from_to(IndentationMode from_mode, IndentationMode to_mode) {
    if (from_mode == to_mode) {
        return;
    }

    buffer.begin_user_action();

    // Parcourir tout le buffer ligne par ligne
    var total_lines = buffer.get_line_count();

    for (int line = 0; line < total_lines; line++) {
        Gtk.TextIter line_start;
        buffer.get_iter_at_line(out line_start, line);
        Gtk.TextIter line_end = line_start;
        line_end.forward_to_line_end();

        var line_text = buffer.get_text(line_start, line_end, false);

        // Détecter le niveau d'indentation actuel selon le mode source
        int indent_level = 0;

        switch (from_mode) {
            case IndentationMode.SPACES:
                // Compter les espaces/tabs au début
                for (int i = 0; i < line_text.length; i++) {
                    if (line_text[i] == ' ') {
                        indent_level++;
                    } else if (line_text[i] == '\t') {
                        indent_level += 4; // Conversion tab = 4 espaces
                    } else {
                        break;
                    }
                }
                indent_level = indent_level / 4; // Niveau logique
                break;

            case IndentationMode.MARGIN_TAGS:
            case IndentationMode.RTF_FORMAT:
                // Détecter les tags d'indentation
                for (int level = 10; level >= 1; level--) {
                    var tag = buffer.tag_table.lookup(@"indent-level-$level");
                    if (tag != null && line_start.has_tag(tag)) {
                        indent_level = level;
                        break;
                    }
                }
                break;

            case IndentationMode.NONE:
            default:
                indent_level = 0;
                break;
        }

        // Si il y a de l'indentation à convertir
        if (indent_level > 0) {
            // Supprimer l'ancienne indentation
            remove_line_indentation(line_start, line_end, from_mode);

            // Appliquer la nouvelle indentation
            apply_line_indentation(line_start, line_end, to_mode, indent_level);
        }
    }

    buffer.end_user_action();
}

/** Supprime l'indentation d'une ligne selon le mode spécifié */
private void remove_line_indentation(TextIter line_start, TextIter line_end, IndentationMode mode) {
    switch (mode) {
        case IndentationMode.SPACES:
            // Supprimer espaces/tabs au début
            var line_text = buffer.get_text(line_start, line_end, false);
            int chars_to_remove = 0;
            for (int i = 0; i < line_text.length; i++) {
                if (line_text[i] == ' ' || line_text[i] == '\t') {
                    chars_to_remove++;
                } else {
                    break;
                }
            }
            if (chars_to_remove > 0) {
                var end_remove = line_start;
                end_remove.forward_chars(chars_to_remove);
                buffer.delete(ref line_start, ref end_remove);
            }
            break;

        case IndentationMode.MARGIN_TAGS:
        case IndentationMode.RTF_FORMAT:
            // Supprimer tous les tags d'indentation
            for (int level = 1; level <= 10; level++) {
                var tag = buffer.tag_table.lookup(@"indent-level-$level");
                if (tag != null) {
                    buffer.remove_tag(tag, line_start, line_end);
                }
            }
            break;

        case IndentationMode.NONE:
        default:
            break;
    }
}

/** Applique l'indentation à une ligne selon le mode et le niveau spécifiés */
private void apply_line_indentation(TextIter line_start, TextIter line_end, IndentationMode mode, int level) {
    switch (mode) {
        case IndentationMode.SPACES:
            // Insérer les espaces appropriés
            var spaces = string.nfill(level * 4, ' ');
            buffer.insert(ref line_start, spaces, -1);
            break;

        case IndentationMode.MARGIN_TAGS:
        case IndentationMode.RTF_FORMAT:
            // Appliquer le tag approprié
            if (level >= 1 && level <= 10) {
                var tag = buffer.tag_table.lookup(@"indent-level-$level");
                if (tag != null) {
                    buffer.apply_tag(tag, line_start, line_end);
                }
            }
            break;

        case IndentationMode.NONE:
        default:
            break;
    }
}

} // Fermeture de la classe WysiwygEditor
} // Fermeture du namespace IntaText
