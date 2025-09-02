using Gee;
using IntaText.Document;

public class MdRoundTrip : Object {
    public static int main(string[] args) {
        if (args.length < 2) {
            stdout.printf("Usage: md_rt <input.md> [output.md]\n");
            return 1;
        }
        string in_path = args[1];
        string out_path = args.length >= 3 ? args[2] : null;
        try {
            string content;
            FileUtils.get_contents(in_path, out content);
            var conv = new MarkdownDocumentConverter();
            var pivot = conv.to_pivot(content, in_path);
            string out_md = conv.from_pivot(pivot);
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
