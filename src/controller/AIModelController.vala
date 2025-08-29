namespace IntaText.AI {

    // Define AIModelManager if it does not exist elsewhere
    public class AIModelManager : Object {
        // Add properties and methods as needed
        public AIModelManager() {
        }
    }

    public class AIModelController : Object {
        public AIModelManager model_manager { get; private set; }

        public AIModelController() {
            model_manager = new AIModelManager();
        }

        public void open_config_window(Gtk.Window? parent = null) {
            var win = new AIModelConfigWindow(this);
            if (parent != null)
                win.set_transient_for(parent);
            win.present();
        }
    }
}
