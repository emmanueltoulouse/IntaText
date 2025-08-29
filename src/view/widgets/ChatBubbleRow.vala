using Gtk;

namespace IntaText {
    /**
     * Widget représentant une bulle de message dans l'interface de chat
     */
    public class ChatBubbleRow : Gtk.Box {
        private Label content_label;
        private Label time_label;
        private ChatMessage message;

        /**
         * Crée une nouvelle bulle de message
         */
        public ChatBubbleRow(ChatMessage message) {
            Object(orientation: Orientation.VERTICAL, spacing: 3);
            this.message = message;

            // Configuration en fonction du type d'émetteur
            bool is_user = (message.sender == ChatMessage.SenderType.USER);

            // Configuration visuelle de la boîte
            this.margin_start = is_user ? 50 : 12;
            this.margin_end = is_user ? 12 : 50;
            this.margin_top = 6;
            this.margin_bottom = 6;
            this.halign = is_user ? Align.END : Align.START;

            // Ajouter les classes CSS pour styliser
            this.add_css_class("chat-bubble");
            this.add_css_class(is_user ? "user-bubble" : "ai-bubble");

            // Conteneur pour le contenu avec un style de bulle
            var bubble_box = new Box(Orientation.VERTICAL, 3);
            bubble_box.add_css_class("bubble-content");

            // Créer le libellé pour le contenu du message
            content_label = new Label(message.content);
            content_label.wrap = true;
            content_label.wrap_mode = Pango.WrapMode.WORD_CHAR;
            content_label.xalign = 0;
            content_label.max_width_chars = 40;
            content_label.add_css_class("bubble-text");

            // Créer le libellé pour l'horodatage
            time_label = new Label(message.get_formatted_time());
            time_label.add_css_class("bubble-time");
            time_label.set_halign(is_user ? Align.END : Align.START);

            // Ajouter les libellés au conteneur de bulle
            bubble_box.append(content_label);
            bubble_box.append(time_label);

            // Ajouter la bulle à la boîte principale
            this.append(bubble_box);
        }
    }
}
