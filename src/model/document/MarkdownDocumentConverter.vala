using Gee;
using GLib;

namespace IntaText.Document {
public class MarkdownDocumentConverter : Object, DocumentConverter {
private string heading_style;
public MarkdownDocumentConverter() {
    try {
        var settings = new GLib.Settings("com.cabineteto.IntaText");
        heading_style = settings.get_string("markdown-heading-style");
    } catch (Error e) {
        heading_style = "atx"; // fallback
    }
}
// Lors de la conversion Markdown -> PivotDocument (to_pivot)
public PivotDocument to_pivot(string content, string path) {
    var pivot = new PivotDocument();
    pivot.source_path = path;
    pivot.source_format = "md";

    // --- Extraction des métadonnées de style si présentes ---
    foreach (string line in content.split("\n")) {
        if (line.strip().has_prefix("<!--") && line.contains("font:")) {
            var meta = line.strip().replace("<!--", "").replace("-->", "").strip();
            foreach (string part in meta.split(";")) {
                var kv = part.strip().split(":");
                if (kv.length == 2) {
                    string key = kv[0].strip();
                    string val = kv[1].strip();
                    if (key == "font") pivot.meta_font_family = val;
                    else if (key == "size") pivot.meta_font_size = int.parse(val);
                    else if (key == "color") pivot.meta_font_color = val;
                }
            }
        }
    }

    // Traitement ligne par ligne avec gestion d'états
    var lines = content.split("\n");
    int i = 0;
    bool in_code = false;
    StringBuilder code_buf = null;
    string code_lang = "";
    var para_buf = new StringBuilder();

    void flush_paragraph() {
        var text = para_buf.str.strip();
        if (text.length > 0) {
            // Détection d'une ligne qui est uniquement un lien ou image Markdown comme bloc isolé
            // Cas image seul
            string t = text.strip();
            if (t.has_prefix("![")) {
                var img = try_parse_image_inline(t);
                if (img != null) pivot.children.add(img);
                else {
                    var para = new PivotParagraph();
                    para.segments = parse_inline_formatting(text);
                    pivot.children.add(para);
                }
            } else if (t.has_prefix("[")) {
                var lnk = try_parse_link_inline(t);
                if (lnk != null) pivot.children.add(lnk);
                else {
                    var para = new PivotParagraph();
                    para.segments = parse_inline_formatting(text);
                    pivot.children.add(para);
                }
            } else {
                var para = new PivotParagraph();
                para.segments = parse_inline_formatting(text);
                pivot.children.add(para);
            }
        }
        para_buf.truncate(0);
    }

    while (i < lines.length) {
        string raw = lines[i];
        string t = raw.strip();

        // Bloc de code démarre
    if (!in_code && t.has_prefix("```") ) {
            flush_paragraph();
            in_code = true;
            code_lang = t.substring(3).strip();
            code_buf = new StringBuilder();
            i++;
            // Accumuler jusqu'à la clôture ```
            while (i < lines.length) {
                string r = lines[i];
                string tr = r.strip();
                if (tr == "```") {
                    break;
                }
                code_buf.append(r + "\n");
                i++;
            }
            // Fermer le bloc de code si clôture trouvée
            pivot.children.add(new PivotCodeBlock() { language = code_lang, code = code_buf.str });
            in_code = false;
            // Sauter la ligne de clôture si présente
            if (i < lines.length && lines[i].strip() == "```") i++;
            continue;
        }

        // Bloc de code style [lang] suivi de lignes jusqu'à la prochaine ligne vide
        // Exemple:
        // [vala]
        // ...code...
        if (!in_code && t.length >= 3 && t[0] == '[' && t.has_suffix("]")) {
            // Heuristique douce: considérer que c'est un en-tête de bloc code si la ligne suivante n'est pas une liste/heading/citation
            string lang_label = t.substring(1, t.length - 2).strip();
            if (lang_label.length > 0) {
                flush_paragraph();
                code_buf = new StringBuilder();
                code_lang = lang_label;
                i++;
                while (i < lines.length) {
                    string r = lines[i];
                    string tr = r.strip();
                    // Arrêt sur séparation évidente de bloc
                    if (tr == "" || tr.has_prefix("#") || tr.has_prefix(">") || tr.has_prefix("```") || tr.has_prefix("- ") || tr.has_prefix("* ") || tr.has_prefix("+ ")) {
                        break;
                    }
                    // Éviter d'avaler une règle horizontale
                    bool hr = (tr == "---" || tr == "***" || tr == "___");
                    if (hr) break;
                    code_buf.append(r + "\n");
                    i++;
                }
                pivot.children.add(new PivotCodeBlock() { language = code_lang, code = code_buf.str });
                continue;
            }
        }

        // Ligne vide -> fin de paragraphe
        if (t == "") {
            flush_paragraph();
            i++;
            continue;
        }

        // Titres ATX
        if (t.has_prefix("#")) {
            int level = 0;
            while (level < t.length && t[level] == '#') level++;
            if (level > 0 && level <= 6 && t.length > level && t[level] == ' ') {
                flush_paragraph();
                string heading_text = t.substring(level).strip();
                pivot.children.add(new PivotHeading() { level = level, text = heading_text });
                i++;
                continue;
            }
        }

        // Titres Setext (ligne suivante === ou ---)
        if (i + 1 < lines.length) {
            string next = lines[i + 1].strip();
            bool h1 = next.length > 0 && next.replace("=", "").strip().length == 0; // que des '='
            bool h2 = next.length > 0 && next.replace("-", "").strip().length == 0; // que des '-'
            if (h1 || h2) {
                flush_paragraph();
                pivot.children.add(new PivotHeading() { level = h1 ? 1 : 2, text = t });
                i += 2;
                continue;
            }
        }

        // Citations: regrouper lignes commençant par '>'
        if (t.has_prefix(">")) {
            flush_paragraph();
            var qlines = new Gee.ArrayList<string>();
            while (i < lines.length) {
                string r = lines[i];
                string tr = r.strip();
                if (!tr.has_prefix(">")) break;
                string body = tr.substring(1).strip();
                qlines.add(body);
                i++;
            }
            pivot.children.add(new PivotQuote() { text = string.joinv("\n", (string[]) qlines.to_array()) });
            continue;
        }

        // Citations avec glyphe décoratif '❝' (legacy). On convertit en vraie citation Markdown
        if (t.has_prefix("❝")) {
            flush_paragraph();
            var qlines = new Gee.ArrayList<string>();
            while (i < lines.length) {
                string r = lines[i];
                string tr = r.strip();
                if (!tr.has_prefix("❝")) break;
                int prefix_len = tr.has_prefix("❝ ") ? "❝ ".length : "❝".length;
                string body = tr.substring(prefix_len).strip();
                qlines.add(body);
                i++;
            }
            pivot.children.add(new PivotQuote() { text = string.joinv("\n", (string[]) qlines.to_array()) });
            continue;
        }

        // Listes non ordonnées et imbriquées par indentation (inclut la puce Unicode '• ')
        if (t.has_prefix("- ") || t.has_prefix("* ") || t.has_prefix("+ ") || t.has_prefix("• ")) {
            flush_paragraph();
            // Pile de niveaux: (indent, list)
            Gee.ArrayList<int> indents = new Gee.ArrayList<int>();
            Gee.ArrayList<PivotList> stack = new Gee.ArrayList<PivotList>();
            PivotList root = new PivotList(); root.ordered = false;
            indents.add(0); stack.add(root);
            while (i < lines.length) {
                string r = lines[i];
                int leading = 0; while (leading < r.length && (r[leading] == ' ' || r[leading] == '\t')) leading++;
                string tr = r.strip();
                bool is_bullet = (tr.has_prefix("- ") || tr.has_prefix("* ") || tr.has_prefix("+ ") || tr.has_prefix("• "));
                if (!is_bullet) break;
                string item_text;
                if (tr.has_prefix("• ")) item_text = tr.substring("• ".length).strip(); else item_text = tr.substring(2).strip();
                // Monter/descendre la pile selon indentation (groupes de 3 espaces)
                int level = leading / 3;
                while (level + 1 < indents.size) { indents.remove_at(indents.size - 1); stack.remove_at(stack.size - 1); }
                while (level + 1 > indents.size) {
                    var nl = new PivotList(); nl.ordered = false;
                    var parent = stack.get(stack.size - 1);
                    // Attacher au dernier item du parent
                    if (parent.items.size == 0) parent.items.add(new PivotListItem() { text = "" });
                    var last = parent.items.get(parent.items.size - 1);
                    last.children = nl;
                    indents.add(indents.size); stack.add(nl);
                }
                // Ajouter l'item au niveau courant (avec emphase enrichie)
                var li_unordered = new PivotListItem();
                li_unordered.segments = parse_inline_formatting(item_text);
                stack.get(stack.size - 1).items.add(li_unordered);
                i++;
            }
            pivot.children.add(root);
            continue;
        }

        // Listes ordonnées: regrouper blocs consécutifs
        // Détection simple: nombre(s) + ". " au début
        bool is_ordered_start = false;
        int dot_idx = t.index_of(". ");
        if (dot_idx > 0) {
            is_ordered_start = true;
            for (int k = 0; k < dot_idx; k++) { if (t[k] < '0' || t[k] > '9') { is_ordered_start = false; break; } }
        }
        if (is_ordered_start) {
            flush_paragraph();
            Gee.ArrayList<int> indents = new Gee.ArrayList<int>();
            Gee.ArrayList<PivotList> stack = new Gee.ArrayList<PivotList>();
            PivotList root = new PivotList(); root.ordered = true;
            indents.add(0); stack.add(root);
            while (i < lines.length) {
                string r = lines[i];
                int leading = 0; while (leading < r.length && (r[leading] == ' ' || r[leading] == '\t')) leading++;
                string tr = r.strip();
                int di = tr.index_of(". ");
                bool match = di > 0;
                if (match) {
                    for (int k = 0; k < di; k++) { if (tr[k] < '0' || tr[k] > '9') { match = false; break; } }
                }
                if (!match) break;
                string item_text = tr.substring(di + 2).strip();
                int level = leading / 3;
                while (level + 1 < indents.size) { indents.remove_at(indents.size - 1); stack.remove_at(stack.size - 1); }
                while (level + 1 > indents.size) {
                    var nl = new PivotList(); nl.ordered = true;
                    var parent = stack.get(stack.size - 1);
                    if (parent.items.size == 0) parent.items.add(new PivotListItem() { text = "" });
                    var last = parent.items.get(parent.items.size - 1);
                    last.children = nl;
                    indents.add(indents.size); stack.add(nl);
                }
                var li_ordered = new PivotListItem();
                li_ordered.segments = parse_inline_formatting(item_text);
                stack.get(stack.size - 1).items.add(li_ordered);
                i++;
            }
            pivot.children.add(root);
            continue;
        }

        // Tableaux : ligne avec | et potentiellement ligne de séparation suivante
        if (t.contains("|")) {
            flush_paragraph();
            var table = new PivotTable();

            // Fonction helper pour fusionner les lignes de tableau multi-lignes (format Microsoft Copilot)
            string merge_multiline_table_row(int start_idx, out int end_idx) {
                StringBuilder merged = new StringBuilder(lines[start_idx].strip());
                end_idx = start_idx;

                // Si la ligne se termine par |, c'est une ligne complète
                if (merged.str.has_suffix("|")) {
                    return merged.str;
                }

                // Sinon, chercher les lignes de continuation
                for (int k = start_idx + 1; k < lines.length; k++) {
                    string next = lines[k].strip();
                    if (next == "") break; // Ligne vide = fin du tableau

                    // Si la ligne suivante commence par |, c'est une nouvelle ligne de tableau
                    if (next.has_prefix("|") && !merged.str.has_suffix("|")) {
                        // C'est une continuation, ajouter sans le | initial
                        merged.append(" ");
                        merged.append(next.substring(1));
                        end_idx = k;
                        if (next.has_suffix("|")) break; // Ligne complète maintenant
                    } else if (next.has_prefix("|")) {
                        // Nouvelle ligne de tableau
                        break;
                    } else {
                        // Ligne sans | au début = fin du tableau
                        break;
                    }
                }
                return merged.str;
            }

            // Parser la première ligne (headers) avec support multi-ligne
            int header_end;
            string header_line = merge_multiline_table_row(i, out header_end);
            i = header_end;

            // Enlever les | en début et fin de ligne avant de split
            if (header_line.has_prefix("|")) {
                header_line = header_line.substring(1);
            }
            if (header_line.has_suffix("|")) {
                header_line = header_line.substring(0, header_line.length - 1);
            }
            var header_cells = header_line.split("|");
            var header_row = new Gee.ArrayList<PivotTableCell>();
            for (int j = 0; j < header_cells.length; j++) {
                string cell = header_cells[j].strip();
                // Ajouter même si vide pour préserver la structure du tableau
                var segments = parse_inline_formatting(cell);
                header_row.add(new PivotTableCell.from_segments(segments));
            }
            if (header_row.size > 0) {
                table.rows.add(header_row);
            }

            i++; // passer à la ligne suivante

            // Vérifier si la ligne suivante est une ligne de séparation (avec -, : et |)
            bool has_separator = false;
            if (i < lines.length) {
                int sep_end;
                string sep_line = merge_multiline_table_row(i, out sep_end);
                if (sep_line.contains("|") && (sep_line.contains("-") || sep_line.contains(":"))) {
                    has_separator = true;
                    i = sep_end + 1; // ignorer la ligne de séparation
                }
            }

            // Continuer à parser les lignes de données avec support multi-ligne
            while (i < lines.length) {
                string first_line = lines[i].strip();
                if (first_line == "" || !first_line.contains("|")) {
                    break;
                }

                int row_end;
                string row_line = merge_multiline_table_row(i, out row_end);
                i = row_end;

                // Enlever les | en début et fin de ligne avant de split
                string clean_row = row_line;
                if (clean_row.has_prefix("|")) {
                    clean_row = clean_row.substring(1);
                }
                if (clean_row.has_suffix("|")) {
                    clean_row = clean_row.substring(0, clean_row.length - 1);
                }
                var data_cells = clean_row.split("|");
                var data_row = new Gee.ArrayList<PivotTableCell>();
                for (int j = 0; j < data_cells.length; j++) {
                    string cell = data_cells[j].strip();
                    // Ajouter même si vide pour préserver la structure du tableau
                    var segments = parse_inline_formatting(cell);
                    data_row.add(new PivotTableCell.from_segments(segments));
                }
                if (data_row.size > 0) {
                    table.rows.add(data_row);
                }
                i++;
            }

            pivot.children.add(table);
            continue;
        }

        // Règles horizontales: ---, ***, ___
        if (t == "---" || t == "***" || t == "___") {
            flush_paragraph();
            pivot.children.add(new PivotRule());
            i++;
            continue;
        }

    // Paragraphe standard: accumuler
        para_buf.append(raw + "\n");
        i++;
    }

    // Flush restant
    flush_paragraph();

    // Le return doit être HORS de la boucle foreach
    return pivot;
}

private string process_inline_formatting(string text) {
    // Ici vous pouvez implémenter la détection des éléments inline
    // comme **gras**, *italique*, etc.
    // Pour l'instant, on retourne le texte tel quel
    return text;
}

public string from_pivot(PivotDocument pivot) {
    StringBuilder builder = new StringBuilder();

    // --- Écriture des métadonnées si présentes ---
    if (pivot.meta_font_family != null || pivot.meta_font_size != null || pivot.meta_font_color != null) {
        builder.append("<!--");
        if (pivot.meta_font_family != null)
            builder.append(" font:%s;".printf(pivot.meta_font_family));
        if (pivot.meta_font_size != null)
            builder.append(" size:%d;".printf(pivot.meta_font_size));
        if (pivot.meta_font_color != null)
            builder.append(" color:%s;".printf(pivot.meta_font_color));
        builder.append(" -->\n\n");
    }

    // Appliquer la préférence de style de titres à l'export
    if (heading_style == null || heading_style == "") heading_style = "atx";
    builder.append(apply_heading_style(pivot.to_markdown(), heading_style));
    return builder.str;
}

private string apply_heading_style(string md, string style) {
    if (style == "atx") return md; // déjà ATX dans notre export par défaut
    if (style != "setext") return md;
    // Convertir H1/H2 ATX en Setext lorsque possible
    var lines = md.split("\n");
    var out = new StringBuilder();
    for (int i = 0; i < lines.length; i++) {
        string l = lines[i];
        if (l.has_prefix("# ")) {
            string text = l.substring(2).strip();
            out.append(text).append("\n");
            out.append(string.nfill(text.length, '=')).append("\n\n");
            // sauter éventuelle ligne vide suivante
            continue;
        } else if (l.has_prefix("## ")) {
            string text = l.substring(3).strip();
            out.append(text).append("\n");
            out.append(string.nfill(text.length, '-')).append("\n\n");
            continue;
        } else {
            out.append(l).append("\n");
        }
    }
    return out.str;
}

private Gee.List<TextSegment> parse_inline_formatting(string text) {
    // Traite d'abord les segments <u>…</u> en les convertissant en segments UNDERLINE,
    // et gère aussi les balises HTML inline basiques (<em>/<i>, <strong>/<b>, <code>, <del>).
    // À l'intérieur de ces zones, on applique ensuite la détection Markdown (gras/italique/barré/code/liens).
    return parse_inline_with_html_u(text, new Gee.HashSet<TextFormatting>());
}

// Découpe le texte selon les balises HTML <u>…</u> et délègue l'analyse du contenu
// à parse_inline_recursive_with_links en ajoutant le flag UNDERLINE.
// Analyse <u> et délègue au parseur HTML inline basique + liens/markdown
private Gee.List<TextSegment> parse_inline_with_html_u(string text, Gee.HashSet<TextFormatting> active_formats) {
    var segments = new Gee.ArrayList<TextSegment>();
    int pos = 0;
    while (pos < text.length) {
        int open = text.index_of("<u>", pos);
        if (open == -1) {
            // Pas de soulignement HTML restant: parser le reste avec les balises HTML inline basiques
            foreach (var seg in parse_inline_with_basic_html_and_links(text.substring(pos), active_formats))
                segments.add(seg);
            break;
        }
        // Avant <u>
        if (open > pos) {
            foreach (var seg in parse_inline_with_basic_html_and_links(text.substring(pos, open - pos), active_formats))
                segments.add(seg);
        }
        int close = text.index_of("</u>", open + 3);
        if (close == -1) {
            // Balise d'ouverture sans fermeture: traiter le reste comme texte normal
            foreach (var seg in parse_inline_with_basic_html_and_links(text.substring(open), active_formats))
                segments.add(seg);
            break;
        }
        // Contenu souligné
        string inner = text.substring(open + 3, close - (open + 3));
        var under_formats = new Gee.HashSet<TextFormatting>();
        under_formats.add_all(active_formats);
        under_formats.add(TextFormatting.UNDERLINE);
        foreach (var seg in parse_inline_with_basic_html_and_links(inner, under_formats))
            segments.add(seg);
        pos = close + 4; // après </u>
    }
    return segments;
}

// Gère les balises HTML inline basiques (<em>/<i>, <strong>/<b>, <code>, <del>, <span style=...>)
// et délègue le texte hors balises au parseur Markdown+liens
private Gee.List<TextSegment> parse_inline_with_basic_html_and_links(string text, Gee.HashSet<TextFormatting> active_formats) {
    var segments = new Gee.ArrayList<TextSegment>();
    int i = 0;
    while (i < text.length) {
        int next = text.length;
        string? tag = null;
        // Ordre d'analyse: tags plus longs/forts d'abord
    string[] tags = { "<span", "</span>", "<strong>", "</strong>", "<em>", "</em>", "<b>", "</b>", "<i>", "</i>", "<code>", "</code>", "<del>", "</del>" };
        foreach (var t in tags) {
            int p = text.index_of(t, i);
            if (p != -1 && p < next) { next = p; tag = t; }
        }

        if (tag == null) {
            // Pas de balise HTML connue -> déléguer le reste au parseur Markdown
            if (i < text.length) {
                foreach (var seg in parse_inline_recursive_with_links(text.substring(i), active_formats)) segments.add(seg);
            }
            break;
        }

        // Avant la balise -> Markdown
        if (next > i) {
            foreach (var seg in parse_inline_recursive_with_links(text.substring(i, next - i), active_formats)) segments.add(seg);
        }

        // Balise ouvrante/fermante: ne rien insérer littéralement; appliquer le format sur le contenu entre ouvrant/fermant
        // Déterminer le couple de balises et le format
        string open_tag = null; string close_tag = null; TextFormatting? fmt = null; string bold_marker = null; string italic_marker = null;
        bool is_span = false; string? span_fg = null; string? span_bg = null;
        switch (tag) {
        case "<span":    // <span style="...">
            // Chercher la fin de la balise ouvrante '>' et extraire style="..."
            int gt = text.index_of(">", next + 5);
            if (gt == -1) { i = next + 5; continue; }
            string open_full = text.substring(next, gt - next + 1); // inclut '>'
            // Par parse simple du style="..."
            int sidx = open_full.index_of("style=");
            if (sidx != -1) {
                int q1 = open_full.index_of_char('"', sidx);
                if (q1 != -1) {
                    int q2 = open_full.index_of_char('"', q1 + 1);
                    if (q2 != -1) {
                        string style = open_full.substring(q1 + 1, q2 - (q1 + 1));
                        // parser propriétés simples: color:...; background(-color):...;
                        foreach (var part in style.split(";")) {
                            string p = part.strip(); if (p == "") continue;
                            int colon = p.index_of(":"); if (colon == -1) continue;
                            string key = p.substring(0, colon).strip().down();
                            string val = p.substring(colon + 1).strip();
                            if (key == "color") span_fg = val;
                            else if (key == "background" || key == "background-color") span_bg = val;
                        }
                    }
                }
            }
            open_tag = open_full; close_tag = "</span>"; is_span = true; break;
        case "<strong>": open_tag = "<strong>"; close_tag = "</strong>"; fmt = TextFormatting.BOLD; bold_marker = "**"; break;
        case "<b>":      open_tag = "<b>";      close_tag = "</b>";      fmt = TextFormatting.BOLD; bold_marker = "**"; break;
        case "<em>":     open_tag = "<em>";     close_tag = "</em>";     fmt = TextFormatting.ITALIC; italic_marker = "*"; break;
        case "<i>":      open_tag = "<i>";      close_tag = "</i>";      fmt = TextFormatting.ITALIC; italic_marker = "*"; break;
        case "<code>":   open_tag = "<code>";   close_tag = "</code>";   fmt = TextFormatting.CODE; break;
        case "<del>":    open_tag = "<del>";    close_tag = "</del>";    fmt = TextFormatting.STRIKETHROUGH; break;
        default:
            // Balise fermante isolée ou non gérée -> ignorer et avancer d’un caractère
            i = next + (tag != null ? tag.length : 1);
            continue;
        }

        // Chercher la fermeture correspondante à partir de la fin de l’ouvrant
    int content_start = next + open_tag.length;
        int close = text.index_of(close_tag, content_start);
        if (close == -1) {
            // Pas de fermeture -> traiter la balise comme texte brut via Markdown
            foreach (var seg in parse_inline_recursive_with_links(text.substring(next, 1), active_formats)) segments.add(seg);
            i = next + 1;
            continue;
        }

        string inner = text.substring(content_start, close - content_start);
        var new_formats = new Gee.HashSet<TextFormatting>(); new_formats.add_all(active_formats);
        if (fmt != null) new_formats.add((TextFormatting) fmt);

        // Pour <code>, ne pas analyser Markdown à l'intérieur
        if (fmt == TextFormatting.CODE) {
            var seg = new TextSegment(inner, new_formats);
            if (is_span) { seg.fg_color = span_fg; seg.bg_color = span_bg; }
            segments.add(seg);
        } else {
            // Analyse récursive HTML+Markdown à l’intérieur
            foreach (var seg in parse_inline_with_basic_html_and_links(inner, new_formats)) {
                if (bold_marker != null && seg.formats.contains(TextFormatting.BOLD) && (seg.bold_marker == null || seg.bold_marker.length == 0)) seg.bold_marker = bold_marker;
                if (italic_marker != null && seg.formats.contains(TextFormatting.ITALIC) && (seg.italic_marker == null || seg.italic_marker.length == 0)) seg.italic_marker = italic_marker;
                if (is_span) {
                    // Propager la couleur aux sous-segments qui n'en ont pas
                    if (seg.fg_color == null || seg.fg_color == "") seg.fg_color = span_fg;
                    if (seg.bg_color == null || seg.bg_color == "") seg.bg_color = span_bg;
                }
                segments.add(seg);
            }
        }
        i = close + close_tag.length;
    }
    return segments;
}

private PivotLink? try_parse_link_inline(string t) {
    // [text](href)
    int o = t.index_of("["); int c = t.index_of("]");
    int p = t.index_of("("); int q = t.last_index_of(")");
    if (o == 0 && c > o && p == c + 1 && q > p) {
        var link = new PivotLink();
        link.text = t.substring(o + 1, c - (o + 1));
        link.href = t.substring(p + 1, q - (p + 1));
        return link;
    }
    return null;
}

private PivotImage? try_parse_image_inline(string t) {
    // ![alt](src)
    if (!t.has_prefix("!")) return null;
    int o = t.index_of("["); int c = t.index_of("]");
    int p = t.index_of("("); int q = t.last_index_of(")");
    if (o == 1 && c > o && p == c + 1 && q > p) {
        var img = new PivotImage();
        img.alt = t.substring(o + 1, c - (o + 1));
        img.src = t.substring(p + 1, q - (p + 1));
        return img;
    }
    return null;
}

private Gee.List<TextSegment> parse_inline_recursive_with_links(string text, Gee.HashSet<TextFormatting> active_formats) {
    var segments = new Gee.ArrayList<TextSegment>();
    int i = 0;
    while (i < text.length) {
        // Cherche le prochain marqueur
        int next = text.length;
        string? found_marker = null;
    // Important: tester d'abord les marqueurs les plus longs pour éviter les collisions
    // Inclure les triples pour bold+italic (*** et ___)
    string[] markers = { "***", "___", "**", "__", "~~", "`", "*", "_", "[", "!" };
        foreach (var marker in markers) {
            int idx = text.index_of(marker, i);
            if (idx != -1 && idx < next) {
                next = idx;
                found_marker = marker;
            }
        }

        // Texte avant le marqueur (ou tout le texte s'il n'y a pas de marqueur)
        if (found_marker == null) {
            if (i < text.length) {
                var copy = new Gee.HashSet<TextFormatting>();
                copy.add_all(active_formats);
                segments.add(new TextSegment(text.substring(i), copy));
            }
            break;
        }

        // Ajouter le segment avant le marqueur
        if (next > i) {
            var copy = new Gee.HashSet<TextFormatting>();
            copy.add_all(active_formats);
            segments.add(new TextSegment(text.substring(i, next - i), copy));
        }

        // Gestion spéciale des liens/images
        if (found_marker == "[" || found_marker == "!") {
            bool is_img = (found_marker == "!") && next + 1 < text.length && text[next + 1] == '[';
            int o = next + (is_img ? 1 : 0);
            int c = text.index_of("]", o + 1);
            if (c != -1 && c + 1 < text.length && text[c + 1] == '(') {
                int p = c + 1;
                int q = text.index_of(")", p + 1);
                if (q != -1) {
                    string label = text.substring(o + 1, c - (o + 1));
                    // p pointe sur '(', l'URL commence à p + 1 et s'étend jusqu'à juste avant ')'
                    string target = text.substring(p + 1, q - (p + 1));
                    if (is_img) {
                        // Image => créer segment avec alt text et URL de l'image
                        var copy = new Gee.HashSet<TextFormatting>();
                        copy.add_all(active_formats);
                        var seg = new TextSegment(label, copy);
                        seg.image_src = target;
                        segments.add(seg);
                    } else {
                        var copy = new Gee.HashSet<TextFormatting>();
                        copy.add_all(active_formats);
                        var seg = new TextSegment(label, copy);
                        seg.link_href = target;
                        segments.add(seg);
                    }
                    i = q + 1;
                    continue;
                }
            }
            // Si la structure n'est pas complète, traiter le caractère comme texte brut et avancer d'un pas
            var lit = new Gee.HashSet<TextFormatting>();
            lit.add_all(active_formats);
            segments.add(new TextSegment(text.substring(next, 1), lit));
            i = next + 1;
            continue;
        }

        // Fonction utilitaire locale pour alphanum ASCII
        bool is_ascii_alnum(char ch) {
            return ((ch >= '0' && ch <= '9') || (ch >= 'A' && ch <= 'Z') || (ch >= 'a' && ch <= 'z'));
        }

        // Chercher la fin du marqueur (emphase/code), avec règles spéciales pour underscores (", ", "__", "___")
        if (found_marker == "_" || found_marker == "__" || found_marker == "___") {
            int len = found_marker.length;
            // Vérification des bordures pour l'ouverture
            bool open_left_ok = (next == 0) || !is_ascii_alnum(text[next - 1]);
            bool open_right_ok = (next + len < text.length) && is_ascii_alnum(text[next + len]);
            if (!(open_left_ok && open_right_ok)) {
                // Marqueur non valide (au milieu d'un mot) -> traiter comme texte
                var copy = new Gee.HashSet<TextFormatting>();
                copy.add_all(active_formats);
                segments.add(new TextSegment(text.substring(next, len), copy));
                i = next + len;
                continue;
            }
            // Rechercher une fermeture valide
            int close = text.index_of(found_marker, next + len);
            while (close != -1) {
                bool before_close_ok = (close - 1 >= 0) && is_ascii_alnum(text[close - 1]);
                bool after_close_ok = (close + len >= text.length) || !is_ascii_alnum(text[close + len]);
                if (before_close_ok && after_close_ok) break;
                close = text.index_of(found_marker, close + len);
            }
            if (close == -1) {
                // Pas de fermeture valide -> traiter le marqueur d'ouverture comme texte
                var copy = new Gee.HashSet<TextFormatting>();
                copy.add_all(active_formats);
                segments.add(new TextSegment(text.substring(next, len), copy));
                i = next + len;
                continue;
            }

            // Appliquer le format et extraire le contenu
            var new_formats = new Gee.HashSet<TextFormatting>();
            new_formats.add_all(active_formats);
            // "___" = BOLD + ITALIC, "__" = BOLD, "_" = ITALIC
            if (len == 3) {
                new_formats.add(TextFormatting.BOLD);
                new_formats.add(TextFormatting.ITALIC);
            } else if (len == 2) {
                new_formats.add(TextFormatting.BOLD);
            } else {
                new_formats.add(TextFormatting.ITALIC);
            }

            string content_between = text.substring(next + len, close - next - len);

            // Analyse récursive du contenu pour gérer les emphases imbriquées
            var sub = parse_inline_recursive_with_links(content_between, new_formats);
            foreach (var s in sub) {
                // Propager le type de délimiteur (underscores) si non défini par des sous-marqueurs
                if (s.formats.contains(TextFormatting.BOLD) && (s.bold_marker == null || s.bold_marker.length == 0))
                    s.bold_marker = "__";
                if (s.formats.contains(TextFormatting.ITALIC) && (s.italic_marker == null || s.italic_marker.length == 0))
                    s.italic_marker = "_";
                segments.add(s);
            }
            i = close + len;
            continue;
        } else {
            // Marqueurs autres que underscore: comportement existant
            int close = text.index_of(found_marker, next + found_marker.length);
            if (close == -1) {
                // Pas de fin de marqueur, considérer le reste comme texte brut
                var copy = new Gee.HashSet<TextFormatting>();
                copy.add_all(active_formats);
                segments.add(new TextSegment(text.substring(next), copy));         // inclut le marqueur de début
                break;
            }

            // Le texte entre les marqueurs avec le format appliqué
            var new_formats = new Gee.HashSet<TextFormatting>();
            new_formats.add_all(active_formats);

            // IMPORTANT: Détecter correctement le format
            switch (found_marker) {
            case "***":
                new_formats.add(TextFormatting.BOLD);
                new_formats.add(TextFormatting.ITALIC);
                break;
            case "**":
                new_formats.add(TextFormatting.BOLD);
                break;
            case "*":
                new_formats.add(TextFormatting.ITALIC);
                break;
            case "~~":
                new_formats.add(TextFormatting.STRIKETHROUGH);
                break;
            case "`":
                new_formats.add(TextFormatting.CODE);
                break;
            }

            string content_between = text.substring(next + found_marker.length, close - next - found_marker.length);

            if (found_marker == "`") {
                // Code inline: pas d'analyse récursive à l'intérieur
                var seg_code = new TextSegment(content_between, new_formats);
                segments.add(seg_code);
            } else {
                // Analyse récursive pour supporter les emphases imbriquées (***, **, *, ~~)
                var sub = parse_inline_recursive_with_links(content_between, new_formats);
                if (sub.size == 0) {
                    // texte vide entre marqueurs -> insérer segment vide avec les formats
                    var empty_seg = new TextSegment("", new_formats);
                    segments.add(empty_seg);
                } else {
                    foreach (var s in sub) {
                        if (s.formats.contains(TextFormatting.BOLD) && (s.bold_marker == null || s.bold_marker.length == 0))
                            s.bold_marker = "**";
                        if (s.formats.contains(TextFormatting.ITALIC) && (s.italic_marker == null || s.italic_marker.length == 0))
                            s.italic_marker = "*";
                        segments.add(s);
                    }
                }
            }
            i = close + found_marker.length;
            continue;
        }
    }
    return segments;
}
}
}
