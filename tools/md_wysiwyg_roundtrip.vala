using Gee;
using Gtk;
using IntaText.Document;

// Outil CLI: Markdown -> Pivot -> WYSIWYG (TextBuffer tags) -> Pivot -> Markdown
// Usage: md_wysiwyg_rt <input.md> [output.md]
public class MdWysiwygRoundTrip : Object {
    public static int main(string[] args) {
        if (args.length < 2) {
            stdout.printf("Usage: md_wysiwyg_rt <input.md> [output.md]\n");
            return 1;
        }
        string in_path = args[1];
        string? out_path = args.length >= 3 ? args[2] : null;
        try {
            string content;
            FileUtils.get_contents(in_path, out content);
            // 1) md -> pivot
            var conv = new MarkdownDocumentConverter();
            var pivot1 = conv.to_pivot(content, in_path);

            // 2) pivot -> WYSIWYG buffer -> pivot
            // Init GTK pour permettre la création de TextBuffer/TextView
            Gtk.init();
            var editor = new IntaText.WysiwygEditor();
            editor.load_pivot_document(pivot1);
            // Forcer la récupération depuis le buffer rendu
            var pivot2 = editor.get_pivot_document();

            // 3) pivot -> md
            string out_md = conv.from_pivot(pivot2);
            if (out_path != null) {
                FileUtils.set_contents(out_path, out_md);
            } else {
                stdout.printf("%s", out_md);
            }
            return 0;
        } catch (Error e) {
            stderr.printf("Error: %s\n", e.message);
            return 2;
        }
    }
}
