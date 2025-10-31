using GLib;

public class HelloWorldPlugin : Object {
    
    public bool initialize (Object? app_controller) {
        return true;
    }

    public void activate () {
        print ("Hello World depuis IntaText !\n");
    }

    public void deactivate () {
    }

    public void cleanup () {
    }
    
    public void get_metadata (out string id, out string name, out string description, 
                              out string version, out string author) {
        id = "hello-world";
        name = "Hello World";
        description = "Plugin d'exemple";
        version = "1.0.0";
        author = "IntaText";
    }
}

[CCode (cname = "plugin_init")]
public Type plugin_init () {
    return typeof (HelloWorldPlugin);
}
