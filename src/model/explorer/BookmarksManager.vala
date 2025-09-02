public class BookmarksManager : Object {
private static BookmarksManager? instance = null;

// Favoris propres à l'application (persistés dans ~/.config/intatext/bookmarks.txt)
private Gee.List<File> user_bookmarks;

// Favoris système (Nautilus/GTK bookmarks) chargés depuis ~/.config/gtk-3.0/bookmarks ou gtk-4.0/bookmarks
private Gee.List<File> gtk_bookmarks;

private File bookmarks_file;

public signal void bookmarks_changed();

public static BookmarksManager get_instance() {
    if (instance == null) {
        instance = new BookmarksManager();
    }
    return instance;
}

private BookmarksManager() {
    user_bookmarks = new Gee.ArrayList<File>();
    gtk_bookmarks = new Gee.ArrayList<File>();

    // Localisation du fichier de favoris
    string config_dir = Environment.get_user_config_dir();
    string app_config_dir = Path.build_filename(config_dir, "intatext");

    try {
        File dir = File.new_for_path(app_config_dir);
        if (!dir.query_exists()) {
            dir.make_directory_with_parents();
        }

        bookmarks_file = File.new_for_path(Path.build_filename(app_config_dir, "bookmarks.txt"));
        load_bookmarks();
    } catch (Error e) {
        warning(_("Erreur lors de l'initialisation des favoris: %s"), e.message);
    }
}

public Gee.List<File> get_bookmarks() {
    // Fusionne les favoris GTK (Nautilus) et ceux de l'application, en évitant les doublons
    var merged = new Gee.ArrayList<File>();
    var seen = new Gee.HashSet<string>();

    foreach (var f in gtk_bookmarks) {
        string key = file_key(f);
        if (!seen.contains(key)) {
            merged.add(f);
            seen.add(key);
        }
    }

    foreach (var f in user_bookmarks) {
        string key = file_key(f);
        if (!seen.contains(key)) {
            merged.add(f);
            seen.add(key);
        }
    }

    return merged;
}

public bool add_bookmark(File file) {
    // Vérifier si le favori existe déjà
    if (is_bookmarked(file)) {
        return false;
    }

    user_bookmarks.add(file);
    save_bookmarks();
    bookmarks_changed();
    return true;
}

public bool remove_bookmark(File file) {
    bool removed = false;

    for (int i = 0; i < user_bookmarks.size; i++) {
        if (files_equal(user_bookmarks[i], file)) {
            user_bookmarks.remove_at(i);
            removed = true;
            break;
        }
    }

    if (removed) {
        save_bookmarks();
        bookmarks_changed();
    }

    return removed;
}

public bool is_bookmarked(File file) {
    foreach (var bookmark in gtk_bookmarks) {
        if (files_equal(bookmark, file)) return true;
    }
    foreach (var bookmark in user_bookmarks) {
        if (files_equal(bookmark, file)) return true;
    }
    return false;
}

private void load_bookmarks() {
    // Recharge les deux sources: GTK (Nautilus) + favoris de l'app
    load_gtk_bookmarks();
    load_user_bookmarks();
}

private void save_bookmarks() {
    try {
        var dos = new DataOutputStream(
            bookmarks_file.replace(null, false, FileCreateFlags.NONE)
            );

        foreach (var bookmark in user_bookmarks) {
            // Persiste sous forme d'URI pour supporter les favoris distants (smb, sftp, ...)
            string uri = bookmark.get_uri();
            if (uri != null && uri != "") {
                dos.put_string(uri + "\n");
            } else {
                // Fallback: chemin local
                var path = bookmark.get_path();
                if (path != null) dos.put_string(path + "\n");
            }
        }
    } catch (Error e) {
        warning(_("Erreur lors de l'enregistrement des favoris: %s"), e.message);
    }
}

public void refresh_bookmarks(bool emit_signal = true) {
    load_bookmarks();
    if (emit_signal) bookmarks_changed();
}

// --- Implémentation ---

private void load_user_bookmarks() {
    user_bookmarks.clear();

    if (!bookmarks_file.query_exists()) {
        return;
    }

    try {
        var dis = new DataInputStream(bookmarks_file.read());
        string? line;
        while ((line = dis.read_line()) != null) {
            line = line.strip();
            if (line == null || line == "") continue;

            File? f = parse_bookmark_line(line);
            if (f != null) user_bookmarks.add(f);
        }
    } catch (Error e) {
        warning(_("Erreur lors du chargement des favoris (app): %s"), e.message);
    }
}

private void load_gtk_bookmarks() {
    gtk_bookmarks.clear();

    // Cherche en priorité GTK 4, puis GTK 3
    string config_dir = Environment.get_user_config_dir();
    var gtk4 = File.new_for_path(Path.build_filename(config_dir, "gtk-4.0", "bookmarks"));
    var gtk3 = File.new_for_path(Path.build_filename(config_dir, "gtk-3.0", "bookmarks"));

    // Charge les deux si présents (évite de manquer des entrées)
    load_gtk_bookmarks_from_file(gtk4);
    load_gtk_bookmarks_from_file(gtk3);
}

private void load_gtk_bookmarks_from_file(File file) {
    if (!file.query_exists()) return;

    try {
        var dis = new DataInputStream(file.read());
        string? line;
        var seen = new Gee.HashSet<string>();
        foreach (var existing in gtk_bookmarks) seen.add(file_key(existing));

        while ((line = dis.read_line()) != null) {
            line = line.strip();
            if (line == null || line == "") continue;

            // Format GTK: URI [espace] LabelOptionnel
            string uri = extract_uri_from_gtk_line(line);
            File? f = null;
            if (uri != "") {
                try { f = File.new_for_uri(uri); } catch (Error e) { f = null; }
            }
            if (f != null) {
                string key = file_key(f);
                if (!seen.contains(key)) {
                    gtk_bookmarks.add(f);
                    seen.add(key);
                }
            }
        }
    } catch (Error e) {
        warning(_("Erreur lors du chargement des favoris Nautilus: %s"), e.message);
    }
}

private static string extract_uri_from_gtk_line(string line) {
    // Prend le premier token avant l'espace (l'URI ne contient pas d'espaces, ils sont encodés)
    int idx = line.index_of_char(' ');
    if (idx > 0) {
        return line.substring(0, idx);
    }
    return line;
}

private static File? parse_bookmark_line(string line) {
    // Accepte URI complets (xx://) et chemins locaux
    if (line.index_of("://") > 0) {
        try { return File.new_for_uri(line); } catch (Error e) { return null; }
    }
    return File.new_for_path(line);
}

private static string file_key(File f) {
    var uri = f.get_uri();
    if (uri != null && uri != "") return uri;
    var path = f.get_path();
    return path != null ? path : "";
}

private static bool files_equal(File a, File b) {
    // Compare via URI si possible, sinon via chemin
    var au = a.get_uri();
    var bu = b.get_uri();
    if (au != null && bu != null) return au == bu;
    var ap = a.get_path();
    var bp = b.get_path();
    if (ap != null && bp != null) return ap == bp;
    // Fallback: GIO equality (peut impliquer I/O selon backend)
    try { return a.equal(b); } catch (Error e) { return false; }
}

}
