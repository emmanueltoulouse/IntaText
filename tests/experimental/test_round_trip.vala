#!/usr/bin/env vala

// Test simple pour vérifier les enrichissements de tableaux
using IntaText.Document;

void main() {
    print("Test des enrichissements de tableaux\n");
    print("=====================================\n");

    // Test basique
    string markdown_content = """
# Test tableau avec enrichissements

| Colonne 1 | Colonne 2 |
|-----------|-----------|
| **Gras** | <span style="color:red">Rouge</span> |
| [Lien](http://test.com) | ![Image](test.png) |
""";

    print("Markdown original :\n%s\n", markdown_content);

    try {
        var converter = new MarkdownDocumentConverter();
        var pivot_doc = converter.to_pivot(markdown_content, "");

        print("Conversion en PivotDocument réussie\n");

        var back_to_markdown = pivot_doc.to_markdown();
        print("\nMarkdown reconverti :\n%s\n", back_to_markdown);

        // Vérifier la présence d'éléments enrichis
        if (back_to_markdown.contains("**Gras**")) {
            print("✓ Formatage gras préservé\n");
        }

        if (back_to_markdown.contains("style=\"color:red\"")) {
            print("✓ Couleur préservée\n");
        }

        if (back_to_markdown.contains("[Lien](http://test.com)")) {
            print("✓ Lien préservé\n");
        }

        if (back_to_markdown.contains("![Image](test.png)")) {
            print("✓ Image préservée\n");
        }

    } catch (Error e) {
        print("Erreur : %s\n", e.message);
    }
}
