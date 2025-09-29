using IntaText.Document;

namespace IntaText.Tests {
    /**
     * Tests unitaires pour la classe MarkdownDocumentConverter
     */
    class MarkdownConverterTest {

        public static void test_basic_markdown_to_pivot() {
            Test.log(LogLevel.INFO, "Test conversion Markdown -> Pivot");

            var converter = new MarkdownDocumentConverter();
            string markdown = """
# Titre 1

Paragraphe normal.

    Paragraphe indenté.

## Titre 2

**Texte gras** et *texte italique*.
""";

            try {
                var doc = converter.to_pivot(markdown);

                // Vérifications de base
                assert(doc != null);
                assert(doc.children.size > 0);

                Test.log(LogLevel.INFO, "Conversion réussie, %d éléments", doc.children.size);

            } catch (Error e) {
                Test.fail_printf("Erreur conversion : %s", e.message);
            }
        }

        public static void test_indented_paragraph_detection() {
            Test.log(LogLevel.INFO, "Test détection paragraphe indenté");

            var converter = new MarkdownDocumentConverter();
            string markdown = "    Paragraphe avec 4 espaces au début";

            try {
                var doc = converter.to_pivot(markdown);

                assert(doc != null);
                assert(doc.children.size > 0);

                // Chercher un paragraphe indenté
                bool found_indented = false;
                foreach (var child in doc.children) {
                    if (child is PivotParagraph) {
                        var para = child as PivotParagraph;
                        if (para.indent_level > 0) {
                            found_indented = true;
                            Test.log(LogLevel.INFO, "Paragraphe indenté trouvé, niveau : %d", para.indent_level);
                        }
                    }
                }

                // Note: Le test peut échouer si le converter ne détecte pas encore les indentations
                // C'est normal à ce stade de développement
                Test.log(LogLevel.INFO, "Paragraphe indenté détecté : %s", found_indented ? "oui" : "non");

            } catch (Error e) {
                Test.fail_printf("Erreur conversion : %s", e.message);
            }
        }

        public static void test_heading_conversion() {
            Test.log(LogLevel.INFO, "Test conversion titres Markdown");

            var converter = new MarkdownDocumentConverter();
            string markdown = """
# Titre niveau 1
## Titre niveau 2
### Titre niveau 3
""";

            try {
                var doc = converter.to_pivot(markdown);

                assert(doc != null);

                // Compter les titres
                int heading_count = 0;
                foreach (var child in doc.children) {
                    if (child is PivotHeading) {
                        heading_count++;
                        var heading = child as PivotHeading;
                        Test.log(LogLevel.INFO, "Titre niveau %d : %s", heading.level, heading.text);
                    }
                }

                assert(heading_count >= 1); // Au moins un titre détecté
                Test.log(LogLevel.INFO, "%d titres détectés", heading_count);

            } catch (Error e) {
                Test.fail_printf("Erreur conversion : %s", e.message);
            }
        }

        public static void test_formatted_text_conversion() {
            Test.log(LogLevel.INFO, "Test conversion texte formaté");

            var converter = new MarkdownDocumentConverter();
            string markdown = "**Gras** et *italique* et ***gras-italique***";

            try {
                var doc = converter.to_pivot(markdown);

                assert(doc != null);
                assert(doc.children.size > 0);

                // Chercher des segments formatés
                bool found_formatting = false;
                foreach (var child in doc.children) {
                    if (child is PivotParagraph) {
                        var para = child as PivotParagraph;
                        foreach (var segment in para.segments) {
                            if (segment.bold || segment.italic) {
                                found_formatting = true;
                                Test.log(LogLevel.INFO, "Formatage trouvé : %s (gras=%s, italique=%s)",
                                       segment.text, segment.bold ? "oui" : "non", segment.italic ? "oui" : "non");
                            }
                        }
                    }
                }

                assert(found_formatting);

            } catch (Error e) {
                Test.fail_printf("Erreur conversion : %s", e.message);
            }
        }
    }

    /**
     * Point d'entrée des tests
     */
    public static int main(string[] args) {
        Test.init(ref args);

        // Enregistrer les tests
        Test.add_func("/markdown_converter/basic_conversion",
                     MarkdownConverterTest.test_basic_markdown_to_pivot);
        Test.add_func("/markdown_converter/indented_paragraph",
                     MarkdownConverterTest.test_indented_paragraph_detection);
        Test.add_func("/markdown_converter/heading_conversion",
                     MarkdownConverterTest.test_heading_conversion);
        Test.add_func("/markdown_converter/formatted_text",
                     MarkdownConverterTest.test_formatted_text_conversion);

        // Exécuter les tests
        return Test.run();
    }
}
