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

        // Exécuter les tests
        return Test.run();
    }
}
