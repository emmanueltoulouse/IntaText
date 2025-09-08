// Solution 2 : Amélioration de la détection des couleurs pour les listes
// À implémenter dans get_pivot_document(), section flush_list_block()

// Remplacer la logique actuelle de création des segments par :
TextIter search_start = line_start;
TextIter search_end = line_end;

// Scanner toute la ligne pour détecter la présence de formatage
bool found_color_formatting = false;
TextIter scan_pos = search_start;

while (!scan_pos.equal(search_end)) {
    // Vérifier couleurs de texte
    foreach (var name in fg_tag_names) {
        var t_fg = (Gtk.TextTag) buffer.get_tag_table().lookup(name);
        if (t_fg != null && scan_pos.has_tag(t_fg)) {
            found_color_formatting = true;
            break;
        }
    }
    if (found_color_formatting) break;

    // Vérifier couleurs de fond
    foreach (var name in bg_tag_names) {
        var t_bg = (Gtk.TextTag) buffer.get_tag_table().lookup(name);
        if (t_bg != null && scan_pos.has_tag(t_bg)) {
            found_color_formatting = true;
            break;
        }
    }
    if (found_color_formatting) break;

    if (!scan_pos.forward_char()) break;
}

if (found_color_formatting) {
    // Utiliser extract_formatted_segments avec le texte complet de la ligne
    string full_line_text = buffer.get_text(search_start, search_end, false);
    item.segments = extract_formatted_segments(full_line_text, search_start, search_end);

    // Puis nettoyer les segments pour enlever les préfixes de liste
    clean_list_prefix_from_segments(item.segments, is_bullet, is_ordered);
} else {
    // Pas de formatage, utiliser la logique simple actuelle
    var seg = new TextSegment(item_text);
    var segments = new Gee.ArrayList<TextSegment>();
    segments.add(seg);
    item.segments = segments;
}
