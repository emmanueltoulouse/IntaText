using Gtk;
using IntaText.Document;

namespace IntaText {
public class WysiwygEditor : Gtk.TextView {
private Gtk.TextBuffer buffer;
private PivotDocument? pivot_doc;

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

private Gtk.CssProvider css_provider;

public signal void document_changed(PivotDocument doc);
public signal void buffer_changed();

public WysiwygEditor() {
    Object();

    // Zone d'édition simple
    this.set_wrap_mode(Gtk.WrapMode.WORD_CHAR);
    this.set_monospace(false);
    this.set_vexpand(true);
    this.set_hexpand(true);
    buffer = this.get_buffer();

    // Forcer le fond blanc
    this.set_css_classes({"wysiwyg-editor-textview"});
    // Commenté temporairement pour éviter les erreurs
    // var css = new Gtk.CssProvider();
    // css.load_from_string(".wysiwyg-editor-textview { background-color: #fff; }");
    // Gtk.StyleContext.add_provider_for_display(Gdk.Display.get_default(), css, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

    // Préparer les tags de formatage
    ensure_tags();

    // Commenté temporairement
    // buffer.changed.connect(() => {
    //     buffer_changed();
    // });
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
    if (tag_link == null) tag_link = buffer.create_tag("link", "underline", Pango.Underline.SINGLE, "foreground", "#0066cc");

    // List
    tag_list = (Gtk.TextTag) table.lookup("list");
    if (tag_list == null) tag_list = buffer.create_tag("list", "indent", 12);
}

// Exemple d'utilisation sécurisée d'un tag
public void apply_bold() {
    TextIter start, end;
    if (buffer.get_selection_bounds(out start, out end)) {
        if (tag_bold == null) {
            ensure_tags();
        }
        buffer.apply_tag(tag_bold, start, end);
    }
}

public void apply_italic() {
    TextIter start, end;
    if (buffer.get_selection_bounds(out start, out end)) {
        if (tag_italic == null) {
            ensure_tags();
        }
        buffer.apply_tag(tag_italic, start, end);
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
    TextIter start, end;
    if (buffer.get_selection_bounds(out start, out end)) {
        if (tag_code != null)
            buffer.apply_tag(tag_code, start, end);
    }
}

public void apply_quote() {
    TextIter start, end;
    if (buffer.get_selection_bounds(out start, out end)) {
        if (tag_quote != null)
            buffer.apply_tag(tag_quote, start, end);
    }
}

public void apply_format(TextFormatting format) {
    TextIter start, end;
    if (buffer.get_selection_bounds(out start, out end)) {
        switch (format) {
            case TextFormatting.UNDERLINE:
            if (tag_underline == null)
                ensure_tags();
            buffer.apply_tag(tag_underline, start, end);
            break;
        case TextFormatting.STRIKETHROUGH:
            if (tag_strikethrough == null)
                ensure_tags();
            buffer.apply_tag(tag_strikethrough, start, end);
            break;
        default:
            break;
        }
    }
}

// === ÉTAT COURANT ET BASCULE DES FORMATS ===
public bool is_bold_active() {
    if (tag_bold == null) return false;
    Gtk.TextIter it;
    buffer.get_iter_at_mark(out it, buffer.get_insert());
    return it.has_tag(tag_bold);
}

public bool is_italic_active() {
    if (tag_italic == null) return false;
    Gtk.TextIter it;
    buffer.get_iter_at_mark(out it, buffer.get_insert());
    return it.has_tag(tag_italic);
}

public bool is_underline_active() {
    if (tag_underline == null) return false;
    Gtk.TextIter it;
    buffer.get_iter_at_mark(out it, buffer.get_insert());
    return it.has_tag(tag_underline);
}

public bool is_strikethrough_active() {
    if (tag_strikethrough == null) return false;
    Gtk.TextIter it;
    buffer.get_iter_at_mark(out it, buffer.get_insert());
    return it.has_tag(tag_strikethrough);
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
    TextIter start, end;
    if (!buffer.get_selection_bounds(out start, out end)) return;
    if (tag_bold == null) tag_bold = buffer.create_tag("bold", "weight", Pango.Weight.BOLD);
    // Détecter l'état sur le début de sélection
    bool active = start.has_tag(tag_bold);
    if (active)
        buffer.remove_tag(tag_bold, start, end);
    else
        buffer.apply_tag(tag_bold, start, end);
}

public void toggle_italic() {
    TextIter start, end;
    if (!buffer.get_selection_bounds(out start, out end)) return;
    if (tag_italic == null) tag_italic = buffer.create_tag("italic", "style", Pango.Style.ITALIC);
    bool active = start.has_tag(tag_italic);
    if (active)
        buffer.remove_tag(tag_italic, start, end);
    else
        buffer.apply_tag(tag_italic, start, end);
}

public void toggle_underline() {
    TextIter start, end;
    if (!buffer.get_selection_bounds(out start, out end)) return;
    if (tag_underline == null) tag_underline = buffer.create_tag("underline", "underline", Pango.Underline.SINGLE);
    bool active = start.has_tag(tag_underline);
    if (active)
        buffer.remove_tag(tag_underline, start, end);
    else
        buffer.apply_tag(tag_underline, start, end);
}

public void toggle_strikethrough() {
    TextIter start, end;
    if (!buffer.get_selection_bounds(out start, out end)) return;
    if (tag_strikethrough == null) tag_strikethrough = buffer.create_tag("strikethrough", "strikethrough", true);
    bool active = start.has_tag(tag_strikethrough);
    if (active)
        buffer.remove_tag(tag_strikethrough, start, end);
    else
        buffer.apply_tag(tag_strikethrough, start, end);
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

    // Insérer à l'emplacement actuel
    TextIter start = iter;

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

    // Stocker l'URL pour le lien (pourrait être fait avec les données utilisateur du tag)

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

    // Pour l'instant, insérer juste une représentation textuelle
    buffer.insert(ref iter, "[Image: " + alt_text + "]", -1);

    // Note: Une implémentation complète nécessiterait d'utiliser GtkTextChildAnchor
    // pour insérer un widget d'image dans le TextView
}

public void insert_table(int rows, int cols) {
    // Créer une table pivot
    var table = new PivotTable();

    // Initialiser avec des cellules vides
    for (int i = 0; i < rows; i++) {
        var row = new Gee.ArrayList<string>();
        for (int j = 0; j < cols; j++) {
            row.add("");
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

public void load_pivot_document(PivotDocument doc) {
    this.pivot_doc = doc;
    render_pivot_to_buffer(doc);
}

private void render_pivot_to_buffer(PivotDocument doc) {
    ensure_tags();
    buffer.set_text("", 0);         // Vider le buffer

    if (doc == null || doc.children.size == 0) {
        return;         // Document vide
    }

    TextIter iter;
    buffer.get_start_iter(out iter);

    foreach (PivotNode node in doc.children) {
        if (node is PivotHeading) {
            var heading = (PivotHeading)node;

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

            // Marque pour le début du paragraphe
            TextMark para_start = buffer.create_mark(null, iter, true);

            // Pour chaque segment, appliquer le style approprié, en gérant <u>…</u>
            foreach (var segment in para.segments) {
                insert_segment_with_html_underline(ref iter, segment);
            }

            // Ajouter deux sauts de ligne après le paragraphe
            buffer.insert(ref iter, "\n\n", -1);

            // Supprimer la marque du paragraphe
            buffer.delete_mark(para_start);
        }
        else if (node is PivotList) {
            var list = (PivotList)node;
            // Début de plage de liste
            TextMark list_start = buffer.create_mark(null, iter, true);
            render_list_to_buffer(list, ref iter, 0);
            buffer.insert(ref iter, "\n", -1);
            TextIter list_begin_iter;
            buffer.get_iter_at_mark(out list_begin_iter, list_start);
            buffer.apply_tag(tag_list, list_begin_iter, iter);
            buffer.delete_mark(list_start);
        }
        else if (node is PivotCodeBlock) {
            var code = (PivotCodeBlock)node;

            // Insérer une ligne vide avant si nécessaire
            if (!iter.starts_line() && iter.get_line() > 0) {
                buffer.insert(ref iter, "\n", -1);
            }

            // Marque pour le début du bloc de code
            TextMark code_start = buffer.create_mark(null, iter, true);

            // Insérer une indication de langage si disponible
            if (code.language != null && code.language != "") {
                buffer.insert(ref iter, "[" + code.language + "]\n", -1);
            }

            // Insérer le code avec préservation des sauts de ligne
            buffer.insert(ref iter, code.code, -1);

            // Ajouter un saut de ligne après le code
            if (!iter.ends_line()) {
                buffer.insert(ref iter, "\n", -1);
            }
            buffer.insert(ref iter, "\n", -1);

            // Récupérer un itérateur valide pour le début
            TextIter start;
            buffer.get_iter_at_mark(out start, code_start);

            // Appliquer le formatage au bloc de code
            buffer.apply_tag(tag_code, start, iter);

            // Supprimer la marque
            buffer.delete_mark(code_start);
        }
        else if (node is PivotQuote) {
            var quote = (PivotQuote)node;

            // Insérer une ligne vide avant si nécessaire
            if (!iter.starts_line() && iter.get_line() > 0) {
                buffer.insert(ref iter, "\n", -1);
            }

            // Marque pour le début de la citation
            TextMark quote_start = buffer.create_mark(null, iter, true);

            // Insérer la citation (avec préfixe visuel)
            buffer.insert(ref iter, "❝ " + quote.text, -1);

            // Ajouter un saut de ligne après la citation
            if (!iter.ends_line()) {
                buffer.insert(ref iter, "\n", -1);
            }
            buffer.insert(ref iter, "\n", -1);

            // Récupérer un itérateur valide pour le début
            TextIter start;
            buffer.get_iter_at_mark(out start, quote_start);

            // Appliquer le formatage à la citation
            buffer.apply_tag(tag_quote, start, iter);

            // Supprimer la marque
            buffer.delete_mark(quote_start);
        }
        else if (node is PivotTable) {
            var table = (PivotTable)node;
            TextIter current_iter;
            buffer.get_iter_at_offset(out current_iter, buffer.get_char_count());

            buffer.insert(ref current_iter, "\n--- TABLEAU ---\n", -1);
            // Déterminer le nombre de colonnes (à partir de la première ligne si elle existe)
            int num_cols = 0;
            if (table.rows.size > 0 && table.rows[0] != null) {
                num_cols = table.rows[0].size;
            }

            // En-têtes (simplifié)
            string header_row = "|";
            string separator_row = "|";
            for (int j = 0; j < num_cols; j++) {
                header_row += " Col %d |".printf(j + 1);
                separator_row += " ----- |";
            }
            buffer.insert(ref current_iter, header_row + "\n", -1);
            buffer.insert(ref current_iter, separator_row + "\n", -1);

            // Données
            foreach (var row in table.rows) {
                string data_row = "|";
                if (row != null) {
                    for (int j = 0; j < num_cols; j++) {
                        // Accéder à la cellule en vérifiant les limites
                        string? cell_text = (j < row.size && row[j] != null) ? row[j] : "";
                        string padded_cell = (cell_text ?? "");
                        if (padded_cell.length < 5) {
                            padded_cell = padded_cell + string.nfill(5 - padded_cell.length, ' ');
                        }
                        data_row += " %s |".printf(padded_cell);
                    }
                }
                buffer.insert(ref current_iter, data_row + "\n", -1);
            }
            buffer.insert(ref current_iter, "--- FIN TABLEAU ---\n\n", -1);
        }
    }

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
        buffer.insert(ref iter, it.text ?? "", -1);
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
            var para = new PivotParagraph();
            para.segments = extract_formatted_segments(txt, start_it, end_it);
            doc.children.add(para);
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
            stacks.get(stacks.size - 1).items.add(new PivotListItem() { text = item_text });
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
private bool find_paragraph_bounds(string para_text, out TextIter start, out TextIter end) {
    buffer.get_start_iter(out start);
    buffer.get_end_iter(out end);

    // Approche plus sûre : au lieu de rechercher le texte exact,
    // rechercher ligne par ligne
    TextIter iter;
    buffer.get_start_iter(out iter);

    while (!iter.is_end()) {
        TextIter line_start = iter;
        TextIter line_end = iter;

        line_end.forward_to_line_end();

        // Extraire la ligne
        string line_text = buffer.get_text(line_start, line_end, false);

        // Si la ligne contient le début du paragraphe
        if (line_text.contains(para_text.substring(0, int.min(para_text.length, 30)))) {
            start = line_start;

            // Avancer d'autant de caractères qu'il y a dans para_text (approximativement)
            TextIter potential_end = start;
            potential_end.forward_chars(para_text.length);

            // Ne pas dépasser la fin du buffer
            if (potential_end.compare(end) > 0) {
                potential_end = end;
            }

            end = potential_end;
            return true;
        }

        // Passer à la ligne suivante
        if (!iter.forward_line()) {
            break;
        }
    }

    // Paragraphe non trouvé, retourner les itérateurs du début et de la fin
    return false;
}

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
                       segment_end.has_tag(tag_underline);

        // Avancer caractère par caractère jusqu'à un changement de format ou la fin du paragraphe
        int safety_counter = 0;
        int max_safety = 1000;          // Limite de sécurité supplémentaire

        while (!segment_end.equal(para_end) && safety_counter < max_safety) {
            safety_counter++;

            bool current_has_tag = segment_end.has_tag(tag_bold) || segment_end.has_tag(tag_italic) ||
                                   segment_end.has_tag(tag_strikethrough) || segment_end.has_tag(tag_code) ||
                                   segment_end.has_tag(tag_underline);

            // Si le formatage change, arrêter
            if (has_tag != current_has_tag) {
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

        // Créer le segment
        segments.add(new TextSegment(segment_text, formats));

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

/**
  * Analyse et applique le formatage inline dans un paragraphe
  */
private void apply_inline_formatting(TextIter start_iter, int length, string text) {
    // Formatage gras - recherche des séquences **texte**
    int pos = 0;
    while ((pos = text.index_of("**", pos)) != -1) {
        int end_pos = text.index_of("**", pos + 2);
        if (end_pos != -1) {
            TextIter bold_start = start_iter;
            bold_start.forward_chars(pos);

            TextIter bold_end = start_iter;
            bold_end.forward_chars(end_pos + 2);         // +2 pour inclure les **

            buffer.apply_tag(tag_bold, bold_start, bold_end);

            pos = end_pos + 2;
        }
        else {
            break;
        }
    }

    // Formatage italique - recherche des séquences *texte*
    pos = 0;
    while ((pos = text.index_of("*", pos)) != -1) {
        if (pos > 0 && text[pos - 1] == '*') {
            // Ignorer les ** déjà traités pour le gras
            pos++;
            continue;
        }

        int end_pos = text.index_of("*", pos + 1);
        if (end_pos != -1 && (end_pos + 1 >= text.length || text[end_pos + 1] != '*')) {
            TextIter italic_start = start_iter;
            italic_start.forward_chars(pos);

            TextIter italic_end = start_iter;
            italic_end.forward_chars(end_pos + 1);         // +1 pour inclure le *

            buffer.apply_tag(tag_italic, italic_start, italic_end);

            pos = end_pos + 1;
        }
        else {
            pos++;
        }
    }
}

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
}
}
