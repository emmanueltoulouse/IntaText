/*
 * PluginMetadataReader.vala
 * Lecteur de métadonnées des plugins depuis les fichiers .plugin
 */

namespace IntaText.Plugins {

    /**
     * Lecteur et validateur de métadonnées de plugins
     */
    public class PluginMetadataReader : Object {

        /**
         * Lit les métadonnées d'un plugin depuis un fichier .plugin
         * @param plugin_file Chemin vers le fichier .plugin
         * @return Métadonnées ou null en cas d'erreur
         */
        public static PluginMetadata? read_metadata (string plugin_file) {
            try {
                var key_file = new KeyFile ();
                key_file.load_from_file (plugin_file, KeyFileFlags.NONE);

                var metadata = PluginMetadata ();

                // Sections requises
                if (!key_file.has_group ("Plugin")) {
                    warning ("Fichier plugin %s: section [Plugin] manquante", plugin_file);
                    return null;
                }

                // Champs obligatoires
                metadata.id = key_file.get_string ("Plugin", "Id");
                metadata.name = key_file.get_string ("Plugin", "Name");
                metadata.version = key_file.get_string ("Plugin", "Version");
                metadata.author = key_file.get_string ("Plugin", "Author");

                var type_str = key_file.get_string ("Plugin", "Type");
                metadata.type = parse_plugin_type (type_str);

                // Champs optionnels
                metadata.description = key_file.has_key ("Plugin", "Description")
                    ? key_file.get_string ("Plugin", "Description")
                    : "";

                metadata.enabled = key_file.has_key ("Plugin", "Enabled")
                    ? key_file.get_boolean ("Plugin", "Enabled")
                    : true;

                // Dépendances
                if (key_file.has_key ("Plugin", "Dependencies")) {
                    metadata.dependencies = key_file.get_string_list ("Plugin", "Dependencies");
                } else {
                    metadata.dependencies = {};
                }

                // Validation
                if (!validate_metadata (metadata)) {
                    return null;
                }

                return metadata;

            } catch (Error e) {
                warning ("Erreur lors de la lecture des métadonnées %s: %s", plugin_file, e.message);
                return null;
            }
        }

        /**
         * Écrit les métadonnées d'un plugin dans un fichier .plugin
         */
        public static bool write_metadata (PluginMetadata metadata, string plugin_file) {
            try {
                var key_file = new KeyFile ();

                key_file.set_string ("Plugin", "Id", metadata.id);
                key_file.set_string ("Plugin", "Name", metadata.name);
                key_file.set_string ("Plugin", "Version", metadata.version);
                key_file.set_string ("Plugin", "Author", metadata.author);
                key_file.set_string ("Plugin", "Type", plugin_type_to_string (metadata.type));

                if (metadata.description.length > 0) {
                    key_file.set_string ("Plugin", "Description", metadata.description);
                }

                key_file.set_boolean ("Plugin", "Enabled", metadata.enabled);

                if (metadata.dependencies.length > 0) {
                    key_file.set_string_list ("Plugin", "Dependencies", metadata.dependencies);
                }

                // Sauvegarder
                key_file.save_to_file (plugin_file);
                return true;

            } catch (Error e) {
                warning ("Erreur lors de l'écriture des métadonnées %s: %s", plugin_file, e.message);
                return false;
            }
        }

        /**
         * Crée un fichier .plugin exemple
         */
        public static bool create_template (string plugin_file, string plugin_name, PluginType type) {
            var metadata = PluginMetadata ();
            metadata.id = plugin_name.down ().replace (" ", "_");
            metadata.name = plugin_name;
            metadata.version = "1.0.0";
            metadata.author = "Plugin Author";
            metadata.type = type;
            metadata.description = "Description du plugin " + plugin_name;
            metadata.enabled = true;
            metadata.dependencies = {};

            return write_metadata (metadata, plugin_file);
        }

        // Méthodes utilitaires privées

        private static PluginType parse_plugin_type (string type_str) {
            switch (type_str.up ()) {
                case "FORMAT":
                    return PluginType.FORMAT;
                case "LANGUAGE":
                    return PluginType.LANGUAGE;
                case "UI":
                    return PluginType.UI;
                default:
                    warning ("Type de plugin inconnu: %s", type_str);
                    return PluginType.UI; // Par défaut
            }
        }

        private static string plugin_type_to_string (PluginType type) {
            switch (type) {
                case PluginType.FORMAT:
                    return "Format";
                case PluginType.LANGUAGE:
                    return "Language";
                case PluginType.UI:
                    return "UI";
                default:
                    return "UI";
            }
        }

        private static bool validate_metadata (PluginMetadata metadata) {
            // Validation des champs requis
            if (metadata.id.length == 0) {
                warning ("Métadonnées plugin: ID manquant");
                return false;
            }

            if (metadata.name.length == 0) {
                warning ("Métadonnées plugin: Nom manquant");
                return false;
            }

            if (metadata.version.length == 0) {
                warning ("Métadonnées plugin: Version manquante");
                return false;
            }

            if (metadata.author.length == 0) {
                warning ("Métadonnées plugin: Auteur manquant");
                return false;
            }

            // Validation du format de version (simple)
            if (!Regex.match_simple ("^\\d+\\.\\d+\\.\\d+$", metadata.version)) {
                warning ("Métadonnées plugin: Format de version invalide: %s", metadata.version);
                return false;
            }

            // Validation de l'ID (caractères autorisés)
            if (!Regex.match_simple ("^[a-zA-Z][a-zA-Z0-9_-]*$", metadata.id)) {
                warning ("Métadonnées plugin: ID invalide: %s", metadata.id);
                return false;
            }

            return true;
        }

        /**
         * Compare deux versions (format semver simplifié)
         * @return < 0 si version1 < version2, 0 si égales, > 0 si version1 > version2
         */
        public static int compare_versions (string version1, string version2) {
            var parts1 = version1.split (".");
            var parts2 = version2.split (".");

            for (int i = 0; i < int.max (parts1.length, parts2.length); i++) {
                int v1 = (i < parts1.length) ? int.parse (parts1[i]) : 0;
                int v2 = (i < parts2.length) ? int.parse (parts2[i]) : 0;

                if (v1 != v2) {
                    return v1 - v2;
                }
            }

            return 0;
        }

        /**
         * Vérifie la compatibilité d'un plugin avec une version d'application
         */
        public static bool is_version_compatible (string plugin_version, string app_version, string min_app_version = "0.1.0") {
            // Le plugin doit être compatible avec la version actuelle de l'app
            // et l'app doit respecter la version minimale requise par le plugin

            return compare_versions (app_version, min_app_version) >= 0;
        }
    }
}
