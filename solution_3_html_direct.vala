// Solution 3 : Préservation directe du HTML dans TextSegment
// Modification de la classe TextSegment pour supporter le HTML natif

// Dans PivotDocument.vala, améliorer TextSegment :
public class TextSegment : Object {
    public string text { get; set; default = ""; }
    public string? html_content { get; set; default = null; } // NOUVEAU
    public Gee.Set<TextFormatting> formatting { get; set; }
    public string? fg_color { get; set; default = null; }
    public string? bg_color { get; set; default = null; }
    public string? link_href { get; set; default = null; }
    
    // Méthode améliorée de export markdown
    public string to_markdown() {
        if (html_content != null && html_content != "") {
            // Utiliser directement le contenu HTML stocké
            return html_content;
        }
        // Sinon utiliser la logique actuelle...
        return generate_markdown_from_formatting();
    }
}

// Dans WysiwygEditor, lors de l'extraction :
private void extract_segments_with_html_preservation(TextIter start, TextIter end) {
    // Au lieu d'essayer de reconstruire les couleurs depuis les tags,
    // extraire directement le HTML du buffer et le stocker
    
    string buffer_text = buffer.get_text(start, end, false);
    if (contains_html_formatting(buffer_text)) {
        // Le texte contient du formatage HTML, le préserver tel quel
        var seg = new TextSegment();
        seg.text = extract_plain_text(buffer_text);
        seg.html_content = buffer_text; // Préservation directe
        return seg;
    } else {
        // Texte simple, utiliser la logique normale
        return create_simple_segment(buffer_text);
    }
}
