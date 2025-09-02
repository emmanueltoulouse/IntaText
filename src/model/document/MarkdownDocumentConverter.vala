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
                // Ajouter l'item au niveau courant
                stack.get(stack.size - 1).items.add(new PivotListItem() { text = item_text });
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
                stack.get(stack.size - 1).items.add(new PivotListItem() { text = item_text });
                i++;
            }
            pivot.children.add(root);
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
    return parse_inline_recursive_with_links(text, new Gee.HashSet<TextFormatting>());
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
        string[] markers = { "**", "*", "~~", "`", "__", "[", "!" };
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
                    string target = text.substring(p + 2, q - (p + 2));
                    if (is_img) {
                        // Image => pas de segment texte; cela devrait idéalement être un nœud bloc, mais si inline, on garde alt comme texte
                        var copy = new Gee.HashSet<TextFormatting>();
                        copy.add_all(active_formats);
                        var seg = new TextSegment(label, copy);
                        // Pas de link_href pour image
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
            // Si la structure n'est pas complète, traiter comme texte brut
        }

        // Chercher la fin du marqueur (emphase/code)
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
        case "**": new_formats.add(TextFormatting.BOLD); break;
        case "*": new_formats.add(TextFormatting.ITALIC); break;
        case "~~": new_formats.add(TextFormatting.STRIKETHROUGH); break;
        case "`": new_formats.add(TextFormatting.CODE); break;
        case "__": new_formats.add(TextFormatting.UNDERLINE); break;
        }

        // CORRECTION IMPORTANTE: Ajouter directement un segment avec le texte entre les marqueurs
        // au lieu de faire une récursion qui peut garder les marqueurs
        string content_between = text.substring(next + found_marker.length, close - next - found_marker.length);
        segments.add(new TextSegment(content_between, new_formats));

        // Avancer après le marqueur de fin
    i = close + found_marker.length;
    }
    return segments;
}
}
}
