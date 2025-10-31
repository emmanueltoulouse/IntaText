namespace IntaText {
    public class ApplicationController : GLib.Object {
    }
}

namespace IntaText.Plugins {
    public enum PluginType {
        FORMAT,
        LANGUAGE,
        UI
    }

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

    public interface IPlugin : GLib.Object {
        public abstract PluginMetadata get_metadata ();
        public abstract bool initialize (ApplicationController app_controller);
        public abstract void activate ();
        public abstract void deactivate ();
        public abstract void cleanup ();
    }
}
