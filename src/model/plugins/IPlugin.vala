/*
 * IPlugin.vala
 * Interface de base pour tous les plugins d'IntaText
 * Cette interface définit les méthodes communes que tous les plugins doivent implémenter
 */

namespace IntaText.Plugins {

    /**
     * Type de plugin
     */
    public enum PluginType {
        FORMAT,     // Plugins de format (import/export)
        LANGUAGE,   // Plugins de langage (grammaire, syntaxe)
        UI          // Plugins d'interface utilisateur
    }

    /**
     * Métadonnées d'un plugin
     */
    public struct PluginMetadata {
        public string id;
        public string name;
        public string description;
        public string version;
        public string author;
        public PluginType type;
        public string[] dependencies;
        public bool enabled;
    }

    /**
     * Interface de base pour tous les plugins
     */
    public interface IPlugin : Object {

        /**
         * Métadonnées du plugin
         */
        public abstract PluginMetadata metadata { get; }

        /**
         * Initialise le plugin
         * @param app_controller Le contrôleur principal de l'application
         * @return true si l'initialisation s'est bien passée
         */
        public abstract bool initialize (ApplicationController app_controller);

        /**
         * Active le plugin
         */
        public abstract void activate ();

        /**
         * Désactive le plugin
         */
        public abstract void deactivate ();

        /**
         * Nettoie les ressources du plugin avant sa suppression
         */
        public abstract void cleanup ();

        /**
         * Vérifie si le plugin est compatible avec la version actuelle d'IntaText
         * @param app_version Version de l'application
         * @return true si compatible
         */
        public virtual bool is_compatible (string app_version) {
            return true; // Par défaut, tous les plugins sont compatibles
        }

        /**
         * Obtient les paramètres de configuration du plugin
         * @return Un dictionnaire des paramètres
         */
        public virtual HashTable<string, Variant>? get_settings () {
            return null;
        }

        /**
         * Applique les paramètres de configuration au plugin
         * @param settings Dictionnaire des paramètres
         */
        public virtual void apply_settings (HashTable<string, Variant> settings) {
            // Implémentation par défaut vide
        }
    }
}
