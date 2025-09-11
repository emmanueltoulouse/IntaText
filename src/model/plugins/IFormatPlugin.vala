/*
 * IFormatPlugin.vala
 * Interface pour les plugins de format (import/export de documents)
 */

using IntaText.Document;

namespace IntaText.Plugins {

    /**
     * Interface pour les plugins de format
     * Permet d'étendre IntaText avec de nouveaux formats de document
     */
    public interface IFormatPlugin : IPlugin {

        /**
         * Extensions de fichier supportées par ce plugin
         * @return Liste des extensions (ex: [".txt", ".rtf"])
         */
        public abstract string[] get_supported_extensions ();

        /**
         * Types MIME supportés
         * @return Liste des types MIME
         */
        public abstract string[] get_supported_mime_types ();

        /**
         * Nom du format pour l'interface utilisateur
         * @return Nom du format (ex: "Rich Text Format")
         */
        public abstract string get_format_name ();

        /**
         * Vérifie si le plugin peut importer depuis ce format
         * @return true si l'import est supporté
         */
        public abstract bool supports_import ();

        /**
         * Vérifie si le plugin peut exporter vers ce format
         * @return true si l'export est supporté
         */
        public abstract bool supports_export ();

        /**
         * Importe un document depuis un fichier
         * @param file_path Chemin vers le fichier à importer
         * @return Document PivotDocument ou null en cas d'erreur
         * @throws GLib.Error en cas d'erreur de lecture/parsing
         */
        public abstract PivotDocument? import_document (string file_path) throws GLib.Error;

        /**
         * Exporte un document vers un fichier
         * @param document Document à exporter
         * @param file_path Chemin de destination
         * @throws GLib.Error en cas d'erreur d'écriture
         */
        public abstract void export_document (PivotDocument document, string file_path) throws GLib.Error;

        /**
         * Obtient les options d'import spécifiques au format
         * @return Dictionnaire des options disponibles
         */
        public virtual HashTable<string, Variant>? get_import_options () {
            return null;
        }

        /**
         * Obtient les options d'export spécifiques au format
         * @return Dictionnaire des options disponibles
         */
        public virtual HashTable<string, Variant>? get_export_options () {
            return null;
        }

        /**
         * Prévisualise l'import d'un document (optionnel)
         * @param file_path Chemin vers le fichier
         * @return Aperçu textuel du contenu ou null
         */
        public virtual string? preview_import (string file_path) {
            return null;
        }

        /**
         * Valide un fichier avant import
         * @param file_path Chemin vers le fichier
         * @return true si le fichier est valide pour ce format
         */
        public virtual bool validate_file (string file_path) {
            return true;
        }
    }
}
