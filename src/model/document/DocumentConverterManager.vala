using IntaText.Document;

/**
  * Gestionnaire central des convertisseurs de documents (phase 1).
  */
public class DocumentConverterManager : Object {
private static DocumentConverterManager? instance = null;
private IntaText.Document.DocumentConverter txt_converter;
private IntaText.Document.DocumentConverter md_converter;
private IntaText.Document.DocumentConverter html_converter;
private IntaText.Document.DocumentConverter pivot_converter;

private DocumentConverterManager() {
    txt_converter = new TextDocumentConverter();
    md_converter = new MarkdownDocumentConverter();
    html_converter = new HtmlDocumentConverter();
    pivot_converter = new PivotDocumentConverter();
}

public static DocumentConverterManager get_instance() {
    if (instance == null) {
        instance = new DocumentConverterManager();
    }
    return instance;
}

public PivotDocument open_file_as_pivot(string path) throws Error {
    string content = "";
    try {
        FileUtils.get_contents(path, out content);
    } catch (Error e) {
        throw new Error(Quark.from_string("INTATEXT_ERROR"), 1, "Impossible de lire le fichier: %s", e.message);
    }

    PivotDocument doc;

    if (path.has_suffix(".pivot")) {
        doc = pivot_converter.to_pivot(content, path);
    }
    else if (path.has_suffix(".md")) {
        doc = md_converter.to_pivot(content, path);
    }
    else if (path.has_suffix(".html") || path.has_suffix(".htm")) {
        doc = html_converter.to_pivot(content, path);
    }
    else {
        doc = txt_converter.to_pivot(content, path);
    }

    // Vérification supplémentaire pour garantir un document valide
    if (doc == null) {
        doc = new PivotDocument();
        doc.source_path = path;
        doc.content = content;
    }

    return doc;
}

public string save_pivot_to_file(PivotDocument pivot, string path) throws Error {
    if (path.has_suffix(".pivot")) {
        FileUtils.set_contents(path, pivot_converter.from_pivot(pivot));
        return path;
    }
    else if (path.has_suffix(".md")) {
        FileUtils.set_contents(path, md_converter.from_pivot(pivot));
        return path;
    }
    else if (path.has_suffix(".html") || path.has_suffix(".htm")) {
        FileUtils.set_contents(path, html_converter.from_pivot(pivot));
        return path;
    }
    else {
        FileUtils.set_contents(path, txt_converter.from_pivot(pivot));
        return path;
    }
}
}
