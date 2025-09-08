using Json;
using Gee;

namespace IntaText.Document {

// Enum pour le formatage du texte
public enum TextFormatting {
    BOLD,
    ITALIC,
    UNDERLINE,
    STRIKETHROUGH,
    CODE;

    // Méthode pour parser une chaîne en enum
    public static TextFormatting parse(string s) throws Error {
        switch (s.up()){
        case "BOLD": return BOLD;
        case "ITALIC": return ITALIC;
        case "UNDERLINE": return UNDERLINE;
        case "STRIKETHROUGH": return STRIKETHROUGH;
        case "CODE": return CODE;
        default: throw new Error(Quark.from_string("PivotFormatError"), 0,
            "Invalid TextFormatting string: %s".printf(s));
        }
    }
}

// Spécifier GLib.Object pour éviter l'ambiguïté
public abstract class PivotNode : GLib.Object {
public abstract string to_markdown();
public abstract string to_html();
public abstract Json.Object to_json();

// Factory method pour la désérialisation
public static PivotNode from_json(Json.Object node) throws Error {
    if (!node.has_member("type")){
        throw new Error(Quark.from_string("PivotFormatError"), 0, "Missing 'type' field in JSON node");
    }
    string type = node.get_string_member("type");

    switch (type){
    case "Paragraph":
        return PivotParagraph.from_json(node);
    case "Heading":
        return PivotHeading.from_json(node);
    case "List":
        return PivotList.from_json(node);
    case "ListItem":
        return PivotListItem.from_json(node);
    case "CodeBlock":
        return PivotCodeBlock.from_json(node);
    case "Quote":
        return PivotQuote.from_json(node);
    case "Image":
        return PivotImage.from_json(node);
    case "Link":
        return PivotLink.from_json(node);
    case "Table":
        return PivotTable.from_json(node);
    case "Rule":
        return PivotRule.from_json(node);
    // Ajoutez d'autres types ici si nécessaire
    default:
        throw new Error(Quark.from_string("PivotFormatError"), 1, "Unknown node type: %s", type);
    }
}
}

// Spécifier GLib.Object
public class PivotDocument : PivotNode {
public Gee.List<PivotNode> children = new Gee.ArrayList<PivotNode>();
public string source_path { get; set; default = ""; }
public string source_format { get; set; default = "txt"; }
public string? meta_font_family = null;
public int? meta_font_size = null;
public string? meta_font_color = null;

// Propriété virtuelle pour compatibilité avec le code existant
public string content {
    owned get {
        return this.to_markdown();
    }
    set {
    children.clear();
        if (value != null && value != ""){
            children.add(new PivotParagraph() {
                        text = value
                    });
        }
    }
}

public PivotDocument(){
}

public override string to_markdown(){
    StringBuilder builder = new StringBuilder();
    foreach (var child in children){
        builder.append(child.to_markdown());
        builder.append("\n\n");
    }
    return builder.str;
}

public override string to_html(){
    StringBuilder builder = new StringBuilder();
    builder.append("<html><body>\n");
    foreach (var child in children){
        builder.append(child.to_html());
        builder.append("\n");
    }
    builder.append("</body></html>");
    return builder.str;
}

public override Json.Object to_json(){
    var obj = new Json.Object();
    obj.set_string_member("source_path", source_path ?? "");
    obj.set_string_member("source_format", source_format ?? "txt");
    if (meta_font_family != null) obj.set_string_member("meta_font_family", meta_font_family);
    if (meta_font_size != null) obj.set_int_member("meta_font_size", meta_font_size ?? 0);
    if (meta_font_color != null) obj.set_string_member("meta_font_color", meta_font_color);

    var children_array = new Json.Array();
    foreach (var child in children){
        children_array.add_object_element(child.to_json());
    }
    obj.set_array_member("children", children_array);
    return obj;
}

public string serialize(){
    var root_obj = this.to_json();
    var generator = new Json.Generator();
    // Utiliser le constructeur new Json.Node(Json.NodeType.OBJECT)
    var node = new Json.Node(Json.NodeType.OBJECT);
    node.set_object(root_obj);
    generator.set_root(node);
    generator.set_pretty(true);         // Pour un JSON lisible
    return generator.to_data(null);
}

public static PivotDocument deserialize(string content) throws Error {
    var parser = new Json.Parser();
    try {
        parser.load_from_data(content, -1);
        var root_node = parser.get_root();
        if (root_node == null || root_node.get_node_type() != Json.NodeType.OBJECT){
            throw new Error(Quark.from_string("PivotFormatError"), 2, "Invalid JSON root, expected object");
        }
        var root_obj = root_node.get_object();
        var pivot = new PivotDocument();

        // Désérialiser les métadonnées
        if (root_obj.has_member("source_path")) pivot.source_path = root_obj.get_string_member("source_path");
        if (root_obj.has_member("source_format")) pivot.source_format = root_obj.get_string_member("source_format");
        if (root_obj.has_member("meta_font_family")) pivot.meta_font_family =
                root_obj.get_string_member("meta_font_family");
        if (root_obj.has_member("meta_font_size")) pivot.meta_font_size =
                (int)root_obj.get_int_member("meta_font_size");
        if (root_obj.has_member("meta_font_color")) pivot.meta_font_color =
                root_obj.get_string_member("meta_font_color");

        // Désérialiser les enfants
        if (root_obj.has_member("children")){
            var children_array = root_obj.get_array_member("children");
            if (children_array != null){
                foreach (var element_node in children_array.get_elements()){
                    if (element_node.get_node_type() == Json.NodeType.OBJECT){
                        try {
                            var child_obj = element_node.get_object();
                            pivot.children.add(PivotNode.from_json(child_obj));
                        } catch (Error e) {
                            warning("Failed to deserialize child node: %s", e.message);
                            // Optionnel: ajouter un nœud d'erreur ou ignorer
                        }
                    }
                }
            }
        }
        return pivot;
    } catch (GLib.Error e) {
        throw new Error(Quark.from_string("PivotFormatError"), 3, "JSON parsing failed: %s", e.message);
    }
}
}

// Spécifier GLib.Object
public class PivotHeading : PivotNode {
public int level;
public string text;

public override string to_markdown(){
    // ATX headings par défaut; conversion Setext effectuée plus haut selon préférences
    int lvl = level.clamp(1, 6);
    string hashes = string.nfill(lvl, '#');
    return "%s %s".printf(hashes, text ?? "");
}

public override string to_html(){
    int lvl = level.clamp(1, 6);
    return "<h%d>%s</h%d>".printf(lvl, GLib.Markup.escape_text(text ?? ""), lvl);
}

public override Json.Object to_json(){
    var obj = new Json.Object();
    obj.set_string_member("type", "Heading");
    obj.set_int_member("level", level);
    obj.set_string_member("text", text ?? "");
    return obj;
}

public new static PivotHeading from_json(Json.Object node) throws Error {
    var heading = new PivotHeading();
    if (node.has_member("level")) heading.level = (int)node.get_int_member("level");
    if (node.has_member("text")) heading.text = node.get_string_member("text");
    return heading;
}
}

// Spécifier GLib.Object
public class TextSegment : GLib.Object {
public string text;
public Gee.HashSet<TextFormatting> formats;
// Optionnel: lien associé à ce segment (href). Null si non-lié.
public string? link_href;
// Préférence de délimiteur pour export (préserve le style d'origine)
public string? bold_marker;    // "**" ou "__"
public string? italic_marker;  // "*" ou "_"
// Couleurs inline facultatives
public string? fg_color;        // ex: "#ff0000" ou "red"
public string? bg_color;        // ex: "#ffff00"

public TextSegment(string text, Gee.HashSet<TextFormatting>? formats = null){
    this.text = text;
    this.formats = formats != null ? formats : new Gee.HashSet<TextFormatting>();
}

public bool has_format(TextFormatting fmt){
    return formats.contains(fmt);
}

public string to_markdown(){
    string result = text;
    if (has_format(TextFormatting.CODE)) result = "`" + result + "`";
    if (has_format(TextFormatting.STRIKETHROUGH)) result = "~~" + result + "~~";
    // Appliquer d'abord l'italique puis le gras pour avoir le gras à l'extérieur par défaut
    if (has_format(TextFormatting.ITALIC)) {
        string im = italic_marker != null && italic_marker != "" ? italic_marker : "*";
        result = im + result + im;
    }
    if (has_format(TextFormatting.BOLD)) {
        string bm = bold_marker != null && bold_marker != "" ? bold_marker : "**";
        result = bm + result + bm;
    }
    if (has_format(TextFormatting.UNDERLINE)) result = "<u>" + result + "</u>";       // Exporter souligné en HTML car non standard en MD
    // Appliquer les couleurs inline via <span style="...">
    if ((fg_color != null && fg_color.strip() != "") || (bg_color != null && bg_color.strip() != "")) {
        StringBuilder sb = new StringBuilder();
        sb.append("<span style=\"");
        bool first = true;
        if (fg_color != null && fg_color.strip() != "") {
            sb.append("color:"); sb.append(fg_color.strip()); sb.append(";"); first = false;
        }
        if (bg_color != null && bg_color.strip() != "") {
            sb.append("background-color:"); sb.append(bg_color.strip()); sb.append(";");
        }
        sb.append("\">");
        sb.append(result);
        sb.append("</span>");
        result = sb.str;
    }
    // Encapsuler dans un lien si présent
    if (link_href != null && link_href.strip() != "") {
        result = "[" + result + "](" + link_href + ")";
    }
    return result;
}

public Json.Object to_json(){
    var obj = new Json.Object();
    obj.set_string_member("text", text ?? "");
    var formats_array = new Json.Array();
    foreach (var format in formats){
        formats_array.add_string_element(format.to_string());
    }
    obj.set_array_member("formats", formats_array);
    if (link_href != null && link_href != "") obj.set_string_member("link", link_href);
    if (bold_marker != null && bold_marker != "") obj.set_string_member("bold_marker", bold_marker);
    if (italic_marker != null && italic_marker != "") obj.set_string_member("italic_marker", italic_marker);
    if (fg_color != null && fg_color != "") obj.set_string_member("fg_color", fg_color);
    if (bg_color != null && bg_color != "") obj.set_string_member("bg_color", bg_color);
    return obj;
}

public static TextSegment from_json(Json.Object node) throws Error {
    var segment = new TextSegment("");
    if (node.has_member("text")){
        segment.text = node.get_string_member("text");
    }
    if (node.has_member("formats")){
        var formats_array = node.get_array_member("formats");
        foreach (var format_node in formats_array.get_elements()){
            // Utiliser Json.NodeType.STRING_
            if (format_node.get_node_type() == Json.NodeType.VALUE){
                try {
                    // Utiliser la méthode parse ajoutée à l'enum
                    segment.formats.add(TextFormatting.parse(format_node.get_string()));
                } catch (Error e) {
                    warning("Failed to parse text formatting: %s", e.message);
                }
            }
        }
    }
    if (node.has_member("link")) segment.link_href = node.get_string_member("link");
    if (node.has_member("bold_marker")) segment.bold_marker = node.get_string_member("bold_marker");
    if (node.has_member("italic_marker")) segment.italic_marker = node.get_string_member("italic_marker");
    if (node.has_member("fg_color")) segment.fg_color = node.get_string_member("fg_color");
    if (node.has_member("bg_color")) segment.bg_color = node.get_string_member("bg_color");
    return segment;
}
}

// Modifier la classe PivotParagraph pour utiliser des segments
public class PivotParagraph : PivotNode {
// Au lieu d'un simple string, on a maintenant une liste de segments
public Gee.List<TextSegment> segments = new Gee.ArrayList<TextSegment>();

// Propriété virtuelle pour compatibilité avec le code existant
public string text {
    owned get {
        StringBuilder builder = new StringBuilder();
        foreach (var segment in segments){
            builder.append(segment.text);
        }
        return builder.str;
    }
    set {
        segments.clear();
        if (value != null){
            // Par défaut, ajoute le texte entier comme un segment normal
            segments.add(new TextSegment(value));
        }
    }
}

public override string to_markdown(){
    StringBuilder builder = new StringBuilder();
    foreach (var segment in segments){
        builder.append(segment.to_markdown());
    }
    return builder.str;
}

public override string to_html(){
    StringBuilder builder = new StringBuilder();
    builder.append("<p>");
    foreach (var segment in segments){
        string current_text = GLib.Markup.escape_text(segment.text);
        // Apply formats - order might matter for nesting, apply common ones first/last
        if (segment.has_format(TextFormatting.CODE)){
            current_text = "<code>" + current_text + "</code>";
        }
        if (segment.has_format(TextFormatting.STRIKETHROUGH)){
            current_text = "<s>" + current_text + "</s>";
        }
    // Ne pas injecter de <u> ici; le rendu HTML peut être géré ailleurs.
        if (segment.has_format(TextFormatting.BOLD)){
            current_text = "<strong>" + current_text + "</strong>";
        }
        if (segment.has_format(TextFormatting.ITALIC)){
            current_text = "<em>" + current_text + "</em>";
        }
        if ((segment.fg_color != null && segment.fg_color.strip() != "") || (segment.bg_color != null && segment.bg_color.strip() != "")) {
            StringBuilder sb = new StringBuilder();
            sb.append("<span style=\"");
            if (segment.fg_color != null && segment.fg_color.strip() != "") {
                sb.append("color:"); sb.append(GLib.Markup.escape_text(segment.fg_color.strip())); sb.append(";");
            }
            if (segment.bg_color != null && segment.bg_color.strip() != "") {
                sb.append("background-color:"); sb.append(GLib.Markup.escape_text(segment.bg_color.strip())); sb.append(";");
            }
            sb.append("\">");
            sb.append(current_text);
            sb.append("</span>");
            current_text = sb.str;
        }
        // If no specific format applied (or only NORMAL), just append escaped text
        builder.append(current_text);
    }
    builder.append("</p>");
    return builder.str;
}

public override Json.Object to_json(){
    var obj = new Json.Object();
    obj.set_string_member("type", "Paragraph");
    var segments_array = new Json.Array();
    foreach (var segment in segments){
        segments_array.add_object_element(segment.to_json());
    }
    obj.set_array_member("segments", segments_array);
    return obj;
}

// Ajouter 'new' pour masquer la méthode parente
public new static PivotParagraph from_json(Json.Object node) throws Error {
    var para = new PivotParagraph();
    if (node.has_member("segments")){
        var segments_array = node.get_array_member("segments");
        if (segments_array != null){
            foreach (var segment_node in segments_array.get_elements()){
                if (segment_node.get_node_type() == Json.NodeType.OBJECT){
                    try {
                        para.segments.add(TextSegment.from_json(segment_node.get_object()));
                    } catch (Error e) {
                        warning("Failed to deserialize text segment: %s", e.message);
                    }
                }
            }
        }
    }
    return para;
}
}

// Spécifier GLib.Object
public class PivotList : PivotNode {
public bool ordered;
public Gee.List<PivotListItem> items = new Gee.ArrayList<PivotListItem>();
public override string to_markdown(){
    string s = to_markdown_with_indent(0);
    // Retirer le dernier saut de ligne superflu si présent
    if (s.length > 0 && s.has_suffix("\n")) s = s.substring(0, s.length - 1);
    return s;
}

private string to_markdown_with_indent(int level){
    StringBuilder b = new StringBuilder();
    string indent = "";
    for (int i = 0; i < level * 3; i++) indent += " ";
    if (ordered) {
        int idx = 1;
        foreach (var item in items) {
            b.append("%s%d. %s\n".printf(indent, idx++, item.to_markdown()));
            if (item.children != null && item.children.items.size > 0) {
                b.append(item.children.to_markdown_with_indent(level + 1));
            }
        }
    } else {
        foreach (var item in items) {
            b.append("%s- %s\n".printf(indent, item.to_markdown()));
            if (item.children != null && item.children.items.size > 0) {
                b.append(item.children.to_markdown_with_indent(level + 1));
            }
        }
    }
    return b.str;
}
public override string to_html(){
    // Simple HTML list conversion
    StringBuilder builder = new StringBuilder();
    string tag = ordered ? "ol" : "ul";
    builder.append("<%s>\n".printf(tag));
    foreach (var item in items){
        builder.append(item.to_html());
        builder.append("\n");
    }
    builder.append("</%s>".printf(tag));
    return builder.str;
}

public override Json.Object to_json(){
    var obj = new Json.Object();
    obj.set_string_member("type", "List");
    obj.set_boolean_member("ordered", ordered);
    var items_array = new Json.Array();
    foreach (var item in items){
        items_array.add_object_element(item.to_json());
    }
    obj.set_array_member("items", items_array);
    return obj;
}

// Ajouter 'new' pour masquer la méthode parente
public new static PivotList from_json(Json.Object node) throws Error {
    var list = new PivotList();
    if (node.has_member("ordered")) list.ordered = node.get_boolean_member("ordered");
    if (node.has_member("items")){
        var items_array = node.get_array_member("items");
        if (items_array != null){
            foreach (var item_node in items_array.get_elements()){
                if (item_node.get_node_type() == Json.NodeType.OBJECT){
                    try {
                        // On suppose que PivotListItem a une méthode from_json
                        list.items.add(PivotListItem.from_json(item_node.get_object()));
                    } catch (Error e) {
                        warning("Failed to deserialize list item: %s", e.message);
                    }
                }
            }
        }
    }
    return list;
}
}

// Spécifier GLib.Object
public class PivotListItem : PivotNode {
public Gee.List<TextSegment> segments = new Gee.ArrayList<TextSegment>();
public PivotList? children; // liste imbriquée optionnelle

// Propriété de compatibilité: agrège/sépare segments en texte brut
public string text {
    owned get {
        StringBuilder b = new StringBuilder();
        foreach (var s in segments) b.append(s.text);
        return b.str;
    }
    set {
        segments.clear();
        segments.add(new TextSegment(value ?? ""));
    }
}

public override string to_markdown(){
    // Concaténer les segments inline avec format
    StringBuilder b = new StringBuilder();
    foreach (var s in segments) b.append(s.to_markdown());
    return b.str;
}
public override string to_html(){
    // HTML list item conversion with optional nested list
    StringBuilder b = new StringBuilder();
    b.append("<li>");
    // Rendu inline minimal similaire à PivotParagraph.to_html
    foreach (var segment in segments){
        string current_text = GLib.Markup.escape_text(segment.text);
        if (segment.has_format(TextFormatting.CODE)) current_text = "<code>" + current_text + "</code>";
        if (segment.has_format(TextFormatting.STRIKETHROUGH)) current_text = "<s>" + current_text + "</s>";
        if (segment.has_format(TextFormatting.BOLD)) current_text = "<strong>" + current_text + "</strong>";
        if (segment.has_format(TextFormatting.ITALIC)) current_text = "<em>" + current_text + "</em>";
        b.append(current_text);
    }
    if (children != null && children.items.size > 0) {
        b.append(children.to_html());
    }
    b.append("</li>");
    return b.str;
}

public override Json.Object to_json(){
    var obj = new Json.Object();
    obj.set_string_member("type", "ListItem");
    // Conserver text pour compat mais écrire aussi segments
    obj.set_string_member("text", text ?? "");
    var segments_array = new Json.Array();
    foreach (var s in segments) segments_array.add_object_element(s.to_json());
    obj.set_array_member("segments", segments_array);
    if (children != null){
        obj.set_object_member("children", children.to_json());
    }
    return obj;
}

// Ajouter 'new' pour masquer la méthode parente
public new static PivotListItem from_json(Json.Object node) throws Error {
    var item = new PivotListItem();
    if (node.has_member("segments")) {
        var arr = node.get_array_member("segments");
        if (arr != null) {
            foreach (var el in arr.get_elements()) {
                if (el.get_node_type() == Json.NodeType.OBJECT) {
                    try { item.segments.add(TextSegment.from_json(el.get_object())); }
                    catch (Error e) { warning("Failed to deserialize list item segment: %s", e.message); }
                }
            }
        }
    } else if (node.has_member("text")) {
        item.text = node.get_string_member("text");
    }
    if (node.has_member("children")) item.children = PivotList.from_json(node.get_object_member("children"));
    return item;
}
}

// Spécifier GLib.Object
public class PivotTable : PivotNode {
// Rendre 'rows' public pour l'instant pour corriger l'erreur d'accès
// Une meilleure solution serait un getter/setter ou une méthode dédiée
public Gee.List<Gee.List<string> > rows = new Gee.ArrayList<Gee.List<string> >();
public override string to_markdown(){
    if (rows.size == 0) return "";
    
    StringBuilder builder = new StringBuilder();
    
    // Première ligne - En-têtes
    if (rows.size > 0) {
        builder.append("| ");
        foreach (string cell in rows[0]) {
            builder.append(cell ?? "");
            builder.append(" | ");
        }
        builder.append("\n");
        
        // Ligne de séparation
        builder.append("|");
        foreach (string cell in rows[0]) {
            builder.append("---|");
        }
        builder.append("\n");
        
        // Lignes de données
        for (int i = 1; i < rows.size; i++) {
            builder.append("| ");
            foreach (string cell in rows[i]) {
                builder.append(cell ?? "");
                builder.append(" | ");
            }
            builder.append("\n");
        }
    }
    
    return builder.str;
}
public override string to_html(){
    // Simple HTML table conversion
    StringBuilder builder = new StringBuilder();
    builder.append("<table>\n");
    foreach (var row in rows){
        builder.append("  <tr>");
        foreach (var cell in row){
            builder.append("<td>");
            builder.append(cell ?? "");
            builder.append("</td>");
        }
        builder.append("</tr>\n");
    }
    builder.append("</table>");
    return builder.str;
}

public override Json.Object to_json(){
    var obj = new Json.Object();
    obj.set_string_member("type", "Table");
    var rows_array = new Json.Array();
    foreach (var row in rows){
        var row_array = new Json.Array();
        foreach (var cell in row){
            row_array.add_string_element(cell ?? "");
        }
        rows_array.add_array_element(row_array);
    }
    obj.set_array_member("rows", rows_array);
    return obj;
}

// Ajouter 'new' pour masquer la méthode parente
public new static PivotTable from_json(Json.Object node) throws Error {
    var table = new PivotTable();
    if (node.has_member("rows")){
        var rows_array = node.get_array_member("rows");
        foreach (var row_node in rows_array.get_elements()){
            if (row_node.get_node_type() == Json.NodeType.ARRAY){
                var row_list = new Gee.ArrayList<string>();
                var cells_array = row_node.get_array();
                foreach (var cell_node in cells_array.get_elements()){
                    if (cell_node.get_node_type() == Json.NodeType.VALUE){
                        row_list.add(cell_node.get_string());
                    }
                    else{
                        row_list.add("");         // Ajouter une chaîne vide si ce n'est pas une chaîne
                    }
                }
                table.rows.add(row_list);
            }
        }
    }
    return table;
}
}

// Spécifier GLib.Object
public class PivotCodeBlock : PivotNode {
public string language;
public string code;
public override string to_markdown(){
    // Simple markdown code block
    string lang = language ?? "";
    string code_content = code ?? "";
    return "```%s\n%s\n```".printf(lang, code_content);
}
public override string to_html(){
    // Simple HTML code block conversion
    string lang = language ?? "";
    string code_content = code ?? "";
    return "<pre><code class=\"language-%s\">%s</code></pre>".printf(lang, GLib.Markup.escape_text(code_content));
}

public override Json.Object to_json(){
    var obj = new Json.Object();
    obj.set_string_member("type", "CodeBlock");
    obj.set_string_member("language", language ?? "");
    obj.set_string_member("code", code ?? "");
    return obj;
}

// Ajouter 'new' pour masquer la méthode parente
public new static PivotCodeBlock from_json(Json.Object node) throws Error {
    var block = new PivotCodeBlock();
    if (node.has_member("language")) block.language = node.get_string_member("language");
    if (node.has_member("code")) block.code = node.get_string_member("code");
    return block;
}
}

// Spécifier GLib.Object
public class PivotQuote : PivotNode {
public string text;
public override string to_markdown(){
    // Simple markdown blockquote
    return text != null ? "> " + text.replace("\n", "\n> ") : "";
}
public override string to_html(){
    // Simple HTML blockquote conversion
    return "<blockquote>" + (text ?? "") + "</blockquote>";
}

public override Json.Object to_json(){
    var obj = new Json.Object();
    obj.set_string_member("type", "Quote");
    obj.set_string_member("text", text ?? "");         // Simplifié, pourrait être des segments
    return obj;
}

// Ajouter 'new' pour masquer la méthode parente
public new static PivotQuote from_json(Json.Object node) throws Error {
    var quote = new PivotQuote();
    if (node.has_member("text")) quote.text = node.get_string_member("text");
    return quote;
}
}

// Spécifier GLib.Object
public class PivotImage : PivotNode {
public string src;
public string alt;
public override string to_markdown(){
    // Simple markdown image syntax
    return "![" + (alt ?? "") + "](" + (src ?? "") + ")";
}
public override string to_html(){
    // Simple HTML image tag conversion
    return "<img src=\"" + (src ?? "") + "\" alt=\"" + (alt ?? "") + "\" />";
}

public override Json.Object to_json(){
    var obj = new Json.Object();
    obj.set_string_member("type", "Image");
    obj.set_string_member("src", src ?? "");
    obj.set_string_member("alt", alt ?? "");
    return obj;
}

// Ajouter 'new' pour masquer la méthode parente
public new static PivotImage from_json(Json.Object node) throws Error {
    var img = new PivotImage();
    if (node.has_member("src")) img.src = node.get_string_member("src");
    if (node.has_member("alt")) img.alt = node.get_string_member("alt");
    return img;
}
}

// Spécifier GLib.Object
public class PivotLink : PivotNode {
public string href;
public string text;
public override string to_markdown(){
    // Simple markdown link syntax
    return "[" + (text ?? "") + "](" + (href ?? "") + ")";
}
public override string to_html(){
    // Simple HTML link tag conversion
    return "<a href=\"" + (href ?? "") + "\">" + (text ?? "") + "</a>";
}

public override Json.Object to_json(){
    var obj = new Json.Object();
    obj.set_string_member("type", "Link");
    obj.set_string_member("href", href ?? "");
    obj.set_string_member("text", text ?? "");         // Simplifié, pourrait être des segments
    return obj;
}

// Ajouter 'new' pour masquer la méthode parente
public new static PivotLink from_json(Json.Object node) throws Error {
    var link = new PivotLink();
    if (node.has_member("href")) link.href = node.get_string_member("href");
    if (node.has_member("text")) link.text = node.get_string_member("text");
    return link;
}
}

// La méthode save_style_to_pivot n'appartient pas à ce namespace
// Elle devrait être dans EditorView ou une classe similaire
/*
  * private void save_style_to_pivot(PivotDocument? current_document,
  *                               string? font_family,
  *                               int? font_size,
  *                               string? font_color) {
  *  if (current_document != null) {
  *      current_document.meta_font_family = font_family;
  *      current_document.meta_font_size = font_size;
  *      current_document.meta_font_color = font_color;
  *  }
  * }
  */

// Spécifier GLib.Object
public class PivotRule : PivotNode {
public override string to_markdown(){
    return "---";
}

public override string to_html(){
    return "<hr>";
}

public override Json.Object to_json(){
    var obj = new Json.Object();
    obj.set_string_member("type", "Rule");
    return obj;
}

// Ajouter 'new' pour masquer la méthode parente
public new static PivotRule from_json(Json.Object node) throws Error {
    return new PivotRule();
}
}
}
