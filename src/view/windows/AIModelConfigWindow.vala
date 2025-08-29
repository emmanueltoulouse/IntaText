using Adw;
using Gtk;

namespace IntaText.AI {
    public class AIModelConfigWindow : Adw.PreferencesWindow {
        private AIModelController controller;

        public AIModelConfigWindow(AIModelController controller) {
            Object(title: _("Configuration IA"), width_request: 600, height_request: 400);
            this.controller = controller;

            // Create a PreferencesPage to hold the groups
            var page = new Adw.PreferencesPage();

            // Groupe Ollama
            var ollama_group = new Adw.PreferencesGroup();
            ollama_group.set_title("Ollama");
            // (Ici tu ajouteras plus tard les widgets de configuration Ollama)
            page.add(ollama_group);

            // Groupe Llama.cpp
            var llama_group = new Adw.PreferencesGroup();
            llama_group.set_title("Llama.cpp");
            // (Ici tu ajouteras plus tard les widgets de configuration Llama.cpp)
            page.add(llama_group);

            // Add the page to the window
            this.add(page);
        }
    }
}
