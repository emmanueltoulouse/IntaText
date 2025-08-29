/* CommunicationView.vala
 *
 * Copyright 2023
 */

using Gtk;

namespace IntaText {
    /**
     * Vue pour la zone de communication de l'application
     */
    public class CommunicationView : Gtk.Box {
        private ApplicationController controller;
        private Notebook notebook;
        private ChatView chat_view;
        private TerminalView terminal_view;

        public CommunicationView(ApplicationController controller) {
            Object(orientation: Orientation.VERTICAL, spacing: 6);

            this.controller = controller;

            // Ajout d'un encadrement pour la visibilité
            var frame = new Frame(null);
            frame.set_margin_start(6);
            frame.set_margin_end(6);
            frame.set_margin_top(6);
            frame.set_margin_bottom(6);

            // Panneau interne pour le contenu de la zone de communication
            var content_box = new Box(Orientation.VERTICAL, 6);

            // Chargement du CSS personnalisé
            load_css();

            // Notebook pour les trois onglets de communication
            notebook = new Notebook();
            notebook.set_vexpand(true);

            // Onglet Chat IA avec notre nouveau widget de chat
            chat_view = new ChatView(controller);
            notebook.append_page(chat_view, new Label("Chat IA"));

            // Onglet Terminal avec notre nouveau widget de terminal
            terminal_view = new TerminalView(controller);
            notebook.append_page(terminal_view, new Label("Terminal"));

            // SUPPRESSION DU CODE REDONDANT DE L'ONGLET TERMINAL ICI

            // Onglet Macros
            var macro_box = new Box(Orientation.VERTICAL, 6);
            var macro_view = new TextView();
            macro_view.set_vexpand(true);

            var macro_scroll = new ScrolledWindow();
            macro_scroll.set_child(macro_view);
            macro_box.append(macro_scroll);

            var macro_actions_box = new Box(Orientation.HORIZONTAL, 6);
            macro_actions_box.append(new Button.with_label("Nouvelle macro"));
            macro_actions_box.append(new Button.with_label("Exécuter"));
            macro_actions_box.append(new Button.with_label("Enregistrer"));
            macro_box.append(macro_actions_box);

            notebook.append_page(macro_box, new Label("Macros"));

            // Connecter le signal de changement d'onglet avec gestion améliorée du focus
            notebook.switch_page.connect((page, page_num) => {
                print("Changement d'onglet vers %d\n", (int)page_num);

                // Retarder un peu la prise de focus pour s'assurer que l'onglet est bien activé
                Timeout.add(100, () => {
                    if (page_num == 0) { // Chat
                        print("Donner le focus à chat_view\n");
                        chat_view.grab_focus();
                    } else if (page_num == 1) { // Terminal
                        print("Donner le focus à terminal_view\n");
                        terminal_view.focus_entry();
                        // Vérifiez l'état de l'entrée
                        terminal_view.check_entry_state();
                    }
                    return Source.REMOVE;
                });
            });

            content_box.append(notebook);
            frame.set_child(content_box);
            this.append(frame);

            // Ajouter un bouton pour tester le terminal à tout moment
            var debug_button = new Button.with_label("Réinitialiser Terminal");
            debug_button.clicked.connect(() => {
                print("Tentative de réinitialisation du terminal\n");
                terminal_view.focus_entry();
                terminal_view.check_entry_state();
            });
            content_box.append(debug_button);

            // Écouter les nouveaux messages du modèle
            controller.subscribe_to_messages((message) => {
                // Ajouter le message à la vue de chat
                var chat_message = new ChatMessage(message, ChatMessage.SenderType.AI);
                chat_view.add_message(chat_message);
            });
        }

        /**
         * Charge le fichier CSS personnalisé pour les bulles et autres éléments d'interface
         */
        private void load_css() {
            var provider = new CssProvider();

            try {
                var display = Gdk.Display.get_default();
                var css_file = File.new_for_uri("resource:///com/cabineteto/IntaText/style.css");
                provider.load_from_file(css_file);

                Gtk.StyleContext.add_provider_for_display(display, provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
            } catch (Error e) {
                warning("Impossible de charger le CSS: %s", e.message);
            }
        }

        /**
         * Exécute une commande dans le terminal
         * Cette méthode n'est plus utilisée car nous utilisons maintenant TerminalView
         */
        private void execute_command(string command, TextView terminal_view) {
            // La méthode est conservée mais n'est plus utilisée
            // Vous pouvez la supprimer ou la déplacer dans la classe TerminalView
        }
    }
}
