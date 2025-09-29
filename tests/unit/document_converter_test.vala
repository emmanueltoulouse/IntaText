namespace IntaText.Tests {
    /**
     * Tests unitaires pour DocumentConverterManager et les convertisseurs
     */
    class DocumentConverterTest {

        private DocumentConverterManager manager;
        private string test_dir;

        public void setUp() {
            manager = DocumentConverterManager.get_instance();
            test_dir = DirUtils.make_tmp("intatext_converter_test_XXXXXX");
        }

        public void tearDown() {
            if (test_dir != null && FileUtils.test(test_dir, FileTest.EXISTS)) {
                // Nettoyer le dossier temporaire
                try {
                    var dir = File.new_for_path(test_dir);
                    var enumerator = dir.enumerate_children("*", FileQueryInfoFlags.NONE);
                    FileInfo info;
                    while ((info = enumerator.next_file()) != null) {
                        var file = dir.get_child(info.get_name());
                        file.delete();
                    }
                    dir.delete();
                } catch (Error e) {
                    warning("Impossible de nettoyer le dossier de test: %s", e.message);
                }
            }
        }

        public static void test_markdown_round_trip() {
            var test = new DocumentConverterTest();
            test.setUp();

            try {
                string markdown_content = """# Test Markdown

Ceci est un **paragraphe** avec du *texte formaté*.

## Liste

- Item 1
- Item 2
- Item 3

## Tableau

| Colonne 1 | Colonne 2 |
|-----------|-----------|
| Données A | Données B |

[Lien vers test](https://example.com)
""";

                // Test de round-trip : MD -> Pivot -> MD
                string test_file = Path.build_filename(test.test_dir, "test.md");
                FileUtils.set_contents(test_file, markdown_content);

                // Charger le fichier
                var pivot_doc = test.manager.open_file_as_pivot(test_file);
                assert(pivot_doc != null);
                assert(pivot_doc.source_format == "md");
                assert(pivot_doc.source_path == test_file);

                // Sauvegarder dans un nouveau fichier
                string output_file = Path.build_filename(test.test_dir, "output.md");
                string saved_path = test.manager.save_pivot_to_file(pivot_doc, output_file);
                assert(saved_path == output_file);

                // Vérifier que le fichier existe et contient des données
                assert(FileUtils.test(output_file, FileTest.EXISTS));

                string saved_content;
                FileUtils.get_contents(output_file, out saved_content);
                assert(saved_content != null);
                assert(saved_content.length > 0);

                // Vérifier que les éléments principaux sont préservés
                assert(saved_content.contains("# Test Markdown"));
                assert(saved_content.contains("**paragraphe**"));
                assert(saved_content.contains("*texte formaté*"));

                print("✅ Test Markdown round-trip réussi\n");

            } catch (Error e) {
                Test.fail_printf("Erreur test Markdown: %s", e.message);
            } finally {
                test.tearDown();
            }
        }

        public static void test_text_conversion() {
            var test = new DocumentConverterTest();
            test.setUp();

            try {
                string text_content = """Ceci est un simple fichier texte.

Avec plusieurs paragraphes.

Et des lignes multiples.
""";

                // Test de conversion TXT -> Pivot -> TXT
                string test_file = Path.build_filename(test.test_dir, "test.txt");
                FileUtils.set_contents(test_file, text_content);

                // Charger le fichier
                var pivot_doc = test.manager.open_file_as_pivot(test_file);
                assert(pivot_doc != null);
                assert(pivot_doc.source_format == "txt");

                // Sauvegarder
                string output_file = Path.build_filename(test.test_dir, "output.txt");
                test.manager.save_pivot_to_file(pivot_doc, output_file);

                // Vérifier le contenu
                string saved_content;
                FileUtils.get_contents(output_file, out saved_content);
                assert(saved_content.contains("simple fichier texte"));
                assert(saved_content.contains("plusieurs paragraphes"));

                print("✅ Test conversion TXT réussi\n");

            } catch (Error e) {
                Test.fail_printf("Erreur test TXT: %s", e.message);
            } finally {
                test.tearDown();
            }
        }

        public static void test_html_conversion() {
            var test = new DocumentConverterTest();
            test.setUp();

            try {
                string html_content = """<!DOCTYPE html>
<html>
<head>
    <title>Test HTML</title>
</head>
<body>
    <h1>Titre principal</h1>
    <p>Paragraphe avec <strong>gras</strong> et <em>italique</em>.</p>
    <ul>
        <li>Liste item 1</li>
        <li>Liste item 2</li>
    </ul>
</body>
</html>
""";

                // Test de conversion HTML -> Pivot -> HTML
                string test_file = Path.build_filename(test.test_dir, "test.html");
                FileUtils.set_contents(test_file, html_content);

                // Charger le fichier
                var pivot_doc = test.manager.open_file_as_pivot(test_file);
                assert(pivot_doc != null);
                assert(pivot_doc.source_format == "html");

                // Sauvegarder
                string output_file = Path.build_filename(test.test_dir, "output.html");
                test.manager.save_pivot_to_file(pivot_doc, output_file);

                // Vérifier que le fichier existe
                assert(FileUtils.test(output_file, FileTest.EXISTS));

                string saved_content;
                FileUtils.get_contents(output_file, out saved_content);
                assert(saved_content.length > 0);

                print("✅ Test conversion HTML réussi\n");

            } catch (Error e) {
                Test.fail_printf("Erreur test HTML: %s", e.message);
            } finally {
                test.tearDown();
            }
        }

        public static void test_format_detection() {
            var test = new DocumentConverterTest();
            test.setUp();

            try {
                // Test de détection automatique des formats
                var formats = new string[] { "txt", "md", "html", "htm" };

                foreach (string format in formats) {
                    string content = "Contenu de test pour " + format;
                    string test_file = Path.build_filename(test.test_dir, "test." + format);
                    FileUtils.set_contents(test_file, content);

                    var pivot_doc = test.manager.open_file_as_pivot(test_file);
                    assert(pivot_doc != null);

                    // Vérifier la détection du format
                    if (format == "htm") {
                        assert(pivot_doc.source_format == "html"); // htm -> html
                    } else {
                        assert(pivot_doc.source_format == format);
                    }
                }

                print("✅ Test détection formats réussi\n");

            } catch (Error e) {
                Test.fail_printf("Erreur test détection: %s", e.message);
            } finally {
                test.tearDown();
            }
        }

        public static void test_error_handling() {
            var test = new DocumentConverterTest();
            test.setUp();

            try {
                // Test avec fichier inexistant
                try {
                    string non_existent = Path.build_filename(test.test_dir, "inexistant.md");
                    test.manager.open_file_as_pivot(non_existent);
                    Test.fail_printf("Devrait échouer sur fichier inexistant");
                } catch (Error e) {
                    // C'est attendu
                    print("✅ Gestion d'erreur fichier inexistant OK\n");
                }

                // Test avec fichier vide
                string empty_file = Path.build_filename(test.test_dir, "vide.md");
                FileUtils.set_contents(empty_file, "");

                var pivot_doc = test.manager.open_file_as_pivot(empty_file);
                assert(pivot_doc != null); // Doit créer un document vide valide

                print("✅ Test gestion fichier vide réussi\n");

            } catch (Error e) {
                Test.fail_printf("Erreur test gestion d'erreurs: %s", e.message);
            } finally {
                test.tearDown();
            }
        }
    }

    /**
     * Point d'entrée des tests de convertisseurs
     */
    public static void register_converter_tests() {
        Test.add_func("/converter/markdown_round_trip",
                     DocumentConverterTest.test_markdown_round_trip);
        Test.add_func("/converter/text_conversion",
                     DocumentConverterTest.test_text_conversion);
        Test.add_func("/converter/html_conversion",
                     DocumentConverterTest.test_html_conversion);
        Test.add_func("/converter/format_detection",
                     DocumentConverterTest.test_format_detection);
        Test.add_func("/converter/error_handling",
                     DocumentConverterTest.test_error_handling);
    }
}
