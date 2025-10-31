using GLib;
using IntaText;
using IntaText.Plugins;

public class HelloWorldPlugin : Object, IPlugin {
    private PluginMetadata metadata_value;
    private ApplicationController? controller;

    public PluginMetadata metadata {
        get { return metadata_value; }
    }

    public HelloWorldPlugin () {
        metadata_value = PluginMetadata () {
            id = "hello-world",
            name = "Hello World",
            description = "Plugin d'exemple qui affiche un message dans la console",
            version = "1.0.0",
            author = "IntaText",
            type = PluginType.UI,
            dependencies = {},
            enabled = true
        };
    }

    public bool initialize (ApplicationController app_controller) {
        controller = app_controller;
        print ("[HelloWorldPlugin] Initialisation\n");
        return true;
    }

    public void activate () {
        print ("[HelloWorldPlugin] Activation\n");
        print ("Hello World depuis IntaText !\n");
    }

    public void deactivate () {
        print ("[HelloWorldPlugin] Désactivation\n");
    }

    public void cleanup () {
        print ("[HelloWorldPlugin] Nettoyage\n");
        controller = null;
    }
}

[CCode (cname = "plugin_init")]
public Type plugin_init () {
    return typeof (HelloWorldPlugin);
}
