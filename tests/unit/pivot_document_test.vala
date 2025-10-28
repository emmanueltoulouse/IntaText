namespace IntaText.Tests {
    /**
     * Tests unitaires basiques pour valider l'infrastructure de test
     */
    class BasicTest {

        public static void test_glib_test_framework() {
            print("Test framework GLib.Test\n");

            // Test basique pour vérifier que le framework fonctionne
            assert(true);
            assert(1 + 1 == 2);
            assert("test".length == 4);
        }

        public static void test_gee_collections() {
            print("Test collections Gee\n");

            // Test des collections Gee utilisées dans IntaText
            var list = new Gee.ArrayList<string>();
            list.add("item1");
            list.add("item2");

            assert(list.size == 2);
            assert(list[0] == "item1");
            assert(list[1] == "item2");
        }

        public static void test_json_parsing() {
            print("Test parsing JSON\n");

            // Test basique de parsing JSON
            string json_string = """{"test": "value", "number": 42}""";

            try {
                var parser = new Json.Parser();
                parser.load_from_data(json_string);
                var root = parser.get_root().get_object();

                assert(root.get_string_member("test") == "value");
                assert(root.get_int_member("number") == 42);

            } catch (Error e) {
                Test.fail_printf("Erreur parsing JSON : %s", e.message);
            }
        }

        public static void test_string_operations() {
            print("Test opérations sur les chaînes\n");

            string text = "  Test avec espaces  ";
            string trimmed = text.strip();

            assert(trimmed == "Test avec espaces");
            assert(text.has_prefix("  Test"));
            assert(text.has_suffix("  "));
        }

        public static void test_pivot_table_json_persistence_sizes() {
            print("Test PivotTable JSON: persistance des tailles\n");

            // Construire une table 2x2 avec tailles personnalisées
            var table = new IntaText.Document.PivotTable();
            table.add_row_from_strings(new Gee.ArrayList<string>.wrap({"H1", "H2"}));
            table.add_row_from_strings(new Gee.ArrayList<string>.wrap({"A1", "A2"}));
            table.column_widths.add(120);
            table.column_widths.add(220);
            table.row_heights.add(30);
            table.row_heights.add(50);

            // Sérialiser en JSON
            var obj = table.to_json();
            var node = new Json.Node(Json.NodeType.OBJECT);
            node.set_object(obj);
            var gen = new Json.Generator();
            gen.set_root(node);
            string json_str = gen.to_data(null);

            // Désérialiser
            var parser = new Json.Parser();
            parser.load_from_data(json_str);
            var root = parser.get_root().get_object();
            IntaText.Document.PivotTable table2;
            try {
                table2 = IntaText.Document.PivotTable.from_json(root);
            } catch (Error e) {
                Test.fail_printf("Erreur désérialisation PivotTable: %s", e.message);
                return;
            }

            // Vérifications
            assert(table2.rows.size == 2);
            assert(table2.rows[0].size == 2);
            assert(table2.get_row_as_strings(0)[0] == "H1");
            assert(table2.get_row_as_strings(0)[1] == "H2");
            assert(table2.get_row_as_strings(1)[0] == "A1");
            assert(table2.get_row_as_strings(1)[1] == "A2");

            assert(table2.column_widths.size == 2);
            assert(table2.column_widths[0] == 120);
            assert(table2.column_widths[1] == 220);
            assert(table2.row_heights.size == 2);
            assert(table2.row_heights[0] == 30);
            assert(table2.row_heights[1] == 50);
        }

        public static void test_pivot_table_json_no_sizes() {
            print("Test PivotTable JSON: absence de tailles\n");

            // JSON minimal pour une table 1x1 sans tailles
            string json_string = """
                {
                  "type": "Table",
                  "rows": [[ {"type":"TableCell","segments":[{"type":"Text","content":"X"}]} ]]
                }
            """;

            try {
                var parser = new Json.Parser();
                parser.load_from_data(json_string);
                var root = parser.get_root().get_object();
                var table = IntaText.Document.PivotTable.from_json(root);
                assert(table.rows.size == 1);
                assert(table.rows[0].size == 1);
                assert(table.get_row_as_strings(0)[0] == "X");
                assert(table.column_widths.size == 0);
                assert(table.row_heights.size == 0);
            } catch (Error e) {
                Test.fail_printf("Erreur parsing/désérialisation: %s", e.message);
            }
        }
    }

    /**
     * Point d'entrée des tests
     */
    public static int main(string[] args) {
        Test.init(ref args);

        // Enregistrer les tests basiques
        Test.add_func("/basic/glib_test_framework",
                     BasicTest.test_glib_test_framework);
        Test.add_func("/basic/gee_collections",
                     BasicTest.test_gee_collections);
        Test.add_func("/basic/json_parsing",
                     BasicTest.test_json_parsing);
        Test.add_func("/basic/string_operations",
                     BasicTest.test_string_operations);
    Test.add_func("/pivot/pivot_table_json_persistence_sizes",
             BasicTest.test_pivot_table_json_persistence_sizes);
    Test.add_func("/pivot/pivot_table_json_no_sizes",
             BasicTest.test_pivot_table_json_no_sizes);

        // Exécuter les tests
        return Test.run();
    }
}
