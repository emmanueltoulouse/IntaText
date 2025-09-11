/*
 * ILanguagePlugin.vala
 * Interface pour les plugins de langage (support des langues, grammaire, correction)
 */

namespace IntaText.Plugins {

    /**
     * Type de service linguistique
     */
    public enum LanguageService {
        SPELL_CHECK,        // Correction orthographique
        GRAMMAR_CHECK,      // Correction grammaticale
        TRANSLATION,        // Traduction
        AUTOCOMPLETE,       // Autocomplétion
        SYNTAX_HIGHLIGHT,   // Coloration syntaxique
        WORD_COUNT,         // Comptage de mots/caractères
        READABILITY         // Analyse de lisibilité
    }

    /**
     * Suggestion linguistique
     */
    public struct LanguageSuggestion {
        public int start_offset;
        public int end_offset;
        public string original_text;
        public string[] suggestions;
        public string error_type;
        public string description;
        public LanguageService service;
    }

    /**
     * Interface pour les plugins de langage
     * Permet d'étendre IntaText avec des services linguistiques
     */
    public interface ILanguagePlugin : IPlugin {

        /**
         * Codes de langue supportés (ISO 639-1)
         * @return Liste des codes de langue (ex: ["fr", "en", "es"])
         */
        public abstract string[] get_supported_languages ();

        /**
         * Services linguistiques fournis par ce plugin
         * @return Liste des services disponibles
         */
        public abstract LanguageService[] get_provided_services ();

        /**
         * Vérifie un texte et retourne les suggestions
         * @param text Texte à analyser
         * @param language_code Code de la langue
         * @param service Type de service demandé
         * @return Liste des suggestions
         */
        public abstract LanguageSuggestion[] analyze_text (string text, string language_code, LanguageService service);

        /**
         * Applique une suggestion au texte
         * @param text Texte original
         * @param suggestion Suggestion à appliquer
         * @return Texte corrigé
         */
        public abstract string apply_suggestion (string text, LanguageSuggestion suggestion);

        /**
         * Configure le service pour une langue
         * @param language_code Code de la langue
         * @param options Options de configuration
         */
        public virtual void configure_language (string language_code, HashTable<string, Variant> options) {
            // Implémentation par défaut vide
        }

        /**
         * Obtient les dictionnaires personnalisés disponibles
         * @param language_code Code de la langue
         * @return Liste des dictionnaires
         */
        public virtual string[] get_custom_dictionaries (string language_code) {
            return {};
        }

        /**
         * Ajoute un mot au dictionnaire personnel
         * @param word Mot à ajouter
         * @param language_code Code de la langue
         */
        public virtual void add_to_personal_dictionary (string word, string language_code) {
            // Implémentation par défaut vide
        }

        /**
         * Obtient les statistiques d'un texte
         * @param text Texte à analyser
         * @param language_code Code de la langue
         * @return Dictionnaire des statistiques
         */
        public virtual HashTable<string, Variant>? get_text_statistics (string text, string language_code) {
            return null;
        }

        /**
         * Traduit un texte
         * @param text Texte à traduire
         * @param source_lang Langue source
         * @param target_lang Langue cible
         * @return Texte traduit ou null si non supporté
         */
        public virtual string? translate_text (string text, string source_lang, string target_lang) {
            return null;
        }

        /**
         * Détecte automatiquement la langue d'un texte
         * @param text Texte à analyser
         * @return Code de langue détecté ou null
         */
        public virtual string? detect_language (string text) {
            return null;
        }
    }
}
