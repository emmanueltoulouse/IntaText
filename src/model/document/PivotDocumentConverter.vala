using IntaText.Document;
using Gee;

namespace IntaText.Document {
    public interface DocumentConverter : Object {
        public abstract PivotDocument to_pivot(string content, string path);
        public abstract string from_pivot(PivotDocument pivot);
    }
    
    public class PivotDocumentConverter : Object, DocumentConverter {
        public PivotDocument to_pivot(string content, string path) {
            // Désérialisation simple (exemple basique, à améliorer selon le format pivot réel)
            var pivot = new PivotDocument();
            try {
                // Utilise GLib.Variant ou JSON pour la sérialisation réelle si besoin
                pivot = PivotDocument.deserialize(content);
            } catch (Error e) {
                warning("Erreur de désérialisation Pivot: %s", e.message);
            }
            pivot.source_path = path;
            pivot.source_format = "pivot";
            return pivot;
        }
        public string from_pivot(PivotDocument pivot) {
            // Sérialisation simple (exemple basique, à améliorer selon le format pivot réel)
            return pivot.serialize();
        }
    }
}
