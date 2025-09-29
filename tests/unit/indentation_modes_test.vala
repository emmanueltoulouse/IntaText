/*
 * Tests unitaires pour les modes d'indentation d'IntaText
 * Teste: NONE, SPACES, MARGIN_TAGS, RTF_FORMAT et leurs comportements
 */

using GLib;
using Gtk;
using IntaText;

void test_indentation_mode_none() {
    Test.message("Testing IndentationMode.NONE");

    var app = new Gtk.Application("com.test.indentation", ApplicationFlags.FLAGS_NONE);
    app.activate.connect(() => {
        var editor = new WysiwygEditor();
        editor.set_indentation_mode(IndentationMode.NONE);

        // Vérifier que le mode est correctement défini
        var current_mode = editor.get_indentation_mode();
        assert_true(current_mode == IndentationMode.NONE);

        // Tester qu'aucune indentation n'est appliquée
        var buffer = editor.get_buffer() as Gtk.TextBuffer;
        buffer.set_text("Test paragraph\nSecond line", -1);

        Gtk.TextIter start, end;
        buffer.get_bounds(out start, out end);

        // Essayer d'indenter - ne devrait rien faire
        editor.increase_indent();

        string text_after = buffer.get_text(start, end, false);
        assert_true(text_after == "Test paragraph\nSecond line");

        Test.message("✅ IndentationMode.NONE validated");
    });

    app.run();
}

void test_indentation_mode_spaces() {
    Test.message("Testing IndentationMode.SPACES");

    var app = new Gtk.Application("com.test.indentation", ApplicationFlags.FLAGS_NONE);
    app.activate.connect(() => {
        var editor = new WysiwygEditor();
        editor.set_indentation_mode(IndentationMode.SPACES);

        // Vérifier que le mode est correctement défini
        var current_mode = editor.get_indentation_mode();
        assert_true(current_mode == IndentationMode.SPACES);

        var buffer = editor.get_buffer() as Gtk.TextBuffer;
        buffer.set_text("Test paragraph", -1);

        // Positionner le curseur au début
        Gtk.TextIter start;
        buffer.get_start_iter(out start);
        buffer.place_cursor(start);

        // Indenter avec des espaces
        editor.increase_indent();

        Gtk.TextIter iter_start, iter_end;
        buffer.get_bounds(out iter_start, out iter_end);
        string text_after = buffer.get_text(iter_start, iter_end, false);

        // Devrait commencer par 4 espaces
        assert_true(text_after.has_prefix("    "));
        assert_true(text_after.contains("Test paragraph"));

        Test.message("✅ IndentationMode.SPACES validated");
    });

    app.run();
}

void test_indentation_mode_margin_tags() {
    Test.message("Testing IndentationMode.MARGIN_TAGS");

    var app = new Gtk.Application("com.test.indentation", ApplicationFlags.FLAGS_NONE);
    app.activate.connect(() => {
        var editor = new WysiwygEditor();
        editor.set_indentation_mode(IndentationMode.MARGIN_TAGS);

        // Vérifier que le mode est correctement défini
        var current_mode = editor.get_indentation_mode();
        assert_true(current_mode == IndentationMode.MARGIN_TAGS);

        var buffer = editor.get_buffer() as Gtk.TextBuffer;
        buffer.set_text("Test paragraph", -1);

        // Positionner le curseur
        Gtk.TextIter start;
        buffer.get_start_iter(out start);
        buffer.place_cursor(start);

        // Indenter avec des tags de marge
        editor.increase_indent();

        // Vérifier qu'un tag d'indentation a été créé
        var tag_table = buffer.get_tag_table();
        var indent_tag = tag_table.lookup("indent-level-1");
        assert_nonnull(indent_tag);

        // Vérifier que le tag est appliqué au texte
        Gtk.TextIter iter_start, iter_end;
        buffer.get_bounds(out iter_start, out iter_end);
        assert_true(iter_start.has_tag(indent_tag));

        Test.message("✅ IndentationMode.MARGIN_TAGS validated");
    });

    app.run();
}

void test_indentation_mode_rtf_format() {
    Test.message("Testing IndentationMode.RTF_FORMAT");

    var app = new Gtk.Application("com.test.indentation", ApplicationFlags.FLAGS_NONE);
    app.activate.connect(() => {
        var editor = new WysiwygEditor();
        editor.set_indentation_mode(IndentationMode.RTF_FORMAT);

        // Vérifier que le mode est correctement défini
        var current_mode = editor.get_indentation_mode();
        assert_true(current_mode == IndentationMode.RTF_FORMAT);

        var buffer = editor.get_buffer() as Gtk.TextBuffer;
        buffer.set_text("Test paragraph", -1);

        // Positionner le curseur
        Gtk.TextIter start;
        buffer.get_start_iter(out start);
        buffer.place_cursor(start);

        // Indenter en mode RTF (utilise les tags comme MARGIN_TAGS)
        editor.increase_indent();

        // Vérifier qu'un tag d'indentation a été créé
        var tag_table = buffer.get_tag_table();
        var indent_tag = tag_table.lookup("indent-level-1");
        assert_nonnull(indent_tag);

        Test.message("✅ IndentationMode.RTF_FORMAT validated");
    });

    app.run();
}

void test_multiple_indentation_levels() {
    Test.message("Testing multiple indentation levels");

    var app = new Gtk.Application("com.test.indentation", ApplicationFlags.FLAGS_NONE);
    app.activate.connect(() => {
        var editor = new WysiwygEditor();
        editor.set_indentation_mode(IndentationMode.MARGIN_TAGS);

        var buffer = editor.get_buffer() as Gtk.TextBuffer;
        buffer.set_text("Test paragraph", -1);

        // Positionner le curseur
        Gtk.TextIter start;
        buffer.get_start_iter(out start);
        buffer.place_cursor(start);

        // Indenter plusieurs fois
        editor.increase_indent(); // Niveau 1
        editor.increase_indent(); // Niveau 2
        editor.increase_indent(); // Niveau 3

        // Vérifier les niveaux d'indentation
        var tag_table = buffer.get_tag_table();

        // Niveau 3 devrait être le plus élevé appliqué
        var indent_tag_3 = tag_table.lookup("indent-level-3");
        assert_nonnull(indent_tag_3);

        Gtk.TextIter iter_start, iter_end;
        buffer.get_bounds(out iter_start, out iter_end);
        assert_true(iter_start.has_tag(indent_tag_3));

        // Diminuer l'indentation
        editor.decrease_indent(); // Retour au niveau 2

        var indent_tag_2 = tag_table.lookup("indent-level-2");
        assert_nonnull(indent_tag_2);
        assert_true(iter_start.has_tag(indent_tag_2));

        Test.message("✅ Multiple indentation levels validated");
    });

    app.run();
}

void test_indentation_limit() {
    Test.message("Testing indentation level limits");

    var app = new Gtk.Application("com.test.indentation", ApplicationFlags.FLAGS_NONE);
    app.activate.connect(() => {
        var editor = new WysiwygEditor();
        editor.set_indentation_mode(IndentationMode.MARGIN_TAGS);

        var buffer = editor.get_buffer() as Gtk.TextBuffer;
        buffer.set_text("Test paragraph", -1);

        // Positionner le curseur
        Gtk.TextIter start;
        buffer.get_start_iter(out start);
        buffer.place_cursor(start);

        // Indenter au-delà de la limite (devrait s'arrêter à 10)
        for (int i = 0; i < 15; i++) {
            editor.increase_indent();
        }

        // Vérifier qu'on ne dépasse pas le niveau 10
        var tag_table = buffer.get_tag_table();
        var indent_tag_10 = tag_table.lookup("indent-level-10");
        var indent_tag_11 = tag_table.lookup("indent-level-11");

        assert_nonnull(indent_tag_10);
        assert_null(indent_tag_11); // Ne devrait pas exister

        Test.message("✅ Indentation level limits validated");
    });

    app.run();
}

void test_spaces_mode_decrease() {
    Test.message("Testing spaces mode decrease indentation");

    var app = new Gtk.Application("com.test.indentation", ApplicationFlags.FLAGS_NONE);
    app.activate.connect(() => {
        var editor = new WysiwygEditor();
        editor.set_indentation_mode(IndentationMode.SPACES);

        var buffer = editor.get_buffer() as Gtk.TextBuffer;
        // Texte pré-indenté avec des espaces
        buffer.set_text("        Test paragraph", -1);

        // Positionner le curseur au début
        Gtk.TextIter start;
        buffer.get_start_iter(out start);
        buffer.place_cursor(start);

        // Diminuer l'indentation
        editor.decrease_indent();

        Gtk.TextIter iter_start, iter_end;
        buffer.get_bounds(out iter_start, out iter_end);
        string text_after = buffer.get_text(iter_start, iter_end, false);

        // Devrait avoir retiré 4 espaces
        assert_true(text_after == "    Test paragraph");

        Test.message("✅ Spaces mode decrease indentation validated");
    });

    app.run();
}

int main(string[] args) {
    Test.init(ref args);
    Gtk.init();

    // Tests des modes d'indentation
    Test.add_func("/indentation/mode_none", test_indentation_mode_none);
    Test.add_func("/indentation/mode_spaces", test_indentation_mode_spaces);
    Test.add_func("/indentation/mode_margin_tags", test_indentation_mode_margin_tags);
    Test.add_func("/indentation/mode_rtf_format", test_indentation_mode_rtf_format);

    // Tests des niveaux et limites
    Test.add_func("/indentation/multiple_levels", test_multiple_indentation_levels);
    Test.add_func("/indentation/level_limits", test_indentation_limit);
    Test.add_func("/indentation/spaces_decrease", test_spaces_mode_decrease);

    return Test.run();
}
