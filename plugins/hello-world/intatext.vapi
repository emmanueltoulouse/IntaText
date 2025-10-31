namespace IntaText {
    [CCode (cheader_filename = "IntaText.h")]
    public class ApplicationController : GLib.Object {
    }
}

namespace IntaText.Plugins {
    [CCode (cname = "IntaTextPluginsPluginType", cprefix = "INTA_TEXT_PLUGINS_PLUGIN_TYPE_", has_type_id = false, cheader_filename = "IntaText.h")]
    public enum PluginType {
        FORMAT,
        LANGUAGE,
        UI
    }

    [CCode (cname = "IntaTextPluginsPluginMetadata", destroy_function = "", has_type_id = false, cheader_filename = "IntaText.h")]
    public struct PluginMetadata {
        public string id;
        public string name;
        public string description;
        public string version;
        public string author;
        public PluginType type;
        [CCode (array_length_cname = "dependencies_length1", array_length_type = "gint")]
        public string[] dependencies;
        public bool enabled;
    }

    [CCode (cname = "IntaTextPluginsIPlugin", type_cname = "IntaTextPluginsIPluginIface", cheader_filename = "IntaText.h")]
    public interface IPlugin : GLib.Object {
        [CCode (cname = "inta_text_plugins_iplugin_get_metadata")]
        public abstract PluginMetadata get_metadata ();

        [CCode (cname = "inta_text_plugins_iplugin_initialize")]
        public abstract bool initialize (IntaText.ApplicationController app_controller);

        [CCode (cname = "inta_text_plugins_iplugin_activate")]
        public abstract void activate ();

        [CCode (cname = "inta_text_plugins_iplugin_deactivate")]
        public abstract void deactivate ();

        [CCode (cname = "inta_text_plugins_iplugin_cleanup")]
        public abstract void cleanup ();

        [CCode (cname = "inta_text_plugins_iplugin_is_compatible")]
        public virtual bool is_compatible (string app_version) {
            return true;
        }

        [CCode (cname = "inta_text_plugins_iplugin_get_settings")]
        public virtual GLib.HashTable<string, GLib.Variant>? get_settings () {
            return null;
        }

        [CCode (cname = "inta_text_plugins_iplugin_apply_settings")]
        public virtual void apply_settings (GLib.HashTable<string, GLib.Variant> settings) {
        }
    }
}
