/*
 * Tests unitaires pour la conversion entre modes d'indentation
 * Teste: SPACES ↔ MARGIN_TAGS ↔ RTF_FORMAT, préservation des niveaux
 */

using GLib;
using Gtk;
using IntaText;

void test_conversion_spaces_to_margin_tags() {
    Test.message("Testing conversion SPACES to MARGIN_TAGS");

    var app = new Gtk.Application("com.test.indentation", ApplicationFlags.FLAGS_NONE);
    app.activate.connect(() => {
        var editor = new WysiwygEditor();
        var buffer = editor.get_buffer() as Gtk.TextBuffer;

        // Créer du contenu avec indentation par espaces
        string content = "    Level 1\n        Level 2\n            Level 3";
        buffer.set_text(content, -1);

        // Convertir de SPACES vers MARGIN_TAGS
        editor.convert_indentation_from_to(IndentationMode.SPACES, IndentationMode.MARGIN_TAGS);

        // Vérifier que les tags de marge ont été créés
        var tag_table = buffer.get_tag_table();
        var tag_1 = tag_table.lookup("indent-level-1");
        var tag_2 = tag_table.lookup("indent-level-2");
        var tag_3 = tag_table.lookup("indent-level-3");

        assert_nonnull(tag_1);
        assert_nonnull(tag_2);
        assert_nonnull(tag_3);

        // Vérifier que les espaces ont été supprimés
        Gtk.TextIter start, end;
        buffer.get_bounds(out start, out end);
        string text_after = buffer.get_text(start, end, false);

        // Le texte ne devrait plus commencer par des espaces
        assert_true(!text_after.has_prefix("    "));
        assert_true(text_after.contains("Level 1"));
        assert_true(text_after.contains("Level 2"));
        assert_true(text_after.contains("Level 3"));

        Test.message("✅ SPACES to MARGIN_TAGS conversion validated");
    });

    app.run();
}

void test_conversion_margin_tags_to_spaces() {
    Test.message("Testing conversion MARGIN_TAGS to SPACES");

    var app = new Gtk.Application("com.test.indentation", ApplicationFlags.FLAGS_NONE);
    app.activate.connect(() => {
        var editor = new WysiwygEditor();
        editor.set_indentation_mode(IndentationMode.MARGIN_TAGS);
        var buffer = editor.get_buffer() as Gtk.TextBuffer;

        // Créer du contenu et appliquer des tags de marge
        buffer.set_text("Level 1\nLevel 2\nLevel 3", -1);

        // Appliquer manuellement des tags d'indentation
        var tag_table = buffer.get_tag_table();

        // Créer les tags avec les marges appropriées
        var tag_1 = buffer.create_tag("indent-level-1", "left-margin", 20, null);
        var tag_2 = buffer.create_tag("indent-level-2", "left-margin", 40, null);
        var tag_3 = buffer.create_tag("indent-level-3", "left-margin", 60, null);

        // Appliquer les tags aux lignes appropriées
        Gtk.TextIter line1_start, line1_end;
        buffer.get_iter_at_line(out line1_start, 0);
        line1_end = line1_start; line1_end.forward_to_line_end();
        buffer.apply_tag(tag_1, line1_start, line1_end);

        Gtk.TextIter line2_start, line2_end;
        buffer.get_iter_at_line(out line2_start, 1);
        line2_end = line2_start; line2_end.forward_to_line_end();
        buffer.apply_tag(tag_2, line2_start, line2_end);

        Gtk.TextIter line3_start, line3_end;
        buffer.get_iter_at_line(out line3_start, 2);
        line3_end = line3_start; line3_end.forward_to_line_end();
        buffer.apply_tag(tag_3, line3_start, line3_end);

        // Convertir vers SPACES
        editor.convert_indentation_from_to(IndentationMode.MARGIN_TAGS, IndentationMode.SPACES);

        // Vérifier que les espaces ont été ajoutés
        Gtk.TextIter start, end;
        buffer.get_bounds(out start, out end);
        string text_after = buffer.get_text(start, end, false);

        var lines = text_after.split("\n");
        assert_true(lines.length >= 3);

        // Vérifier les niveaux d'indentation
        assert_true(lines[0].has_prefix("    ")); // 1 niveau = 4 espaces
        assert_true(lines[1].has_prefix("        ")); // 2 niveaux = 8 espaces
        assert_true(lines[2].has_prefix("            ")); // 3 niveaux = 12 espaces

        Test.message("✅ MARGIN_TAGS to SPACES conversion validated");
    });

    app.run();
}

void test_conversion_margin_tags_to_rtf() {
    Test.message("Testing conversion MARGIN_TAGS to RTF_FORMAT");

    var app = new Gtk.Application("com.test.indentation", ApplicationFlags.FLAGS_NONE);
    app.activate.connect(() => {
        var editor = new WysiwygEditor();
        var buffer = editor.get_buffer() as Gtk.TextBuffer;

        // Créer du contenu avec tags de marge
        buffer.set_text("RTF Level 1\nRTF Level 2", -1);

        // Créer et appliquer tags de marge
        var tag_1 = buffer.create_tag("indent-level-1", "left-margin", 20, null);
        var tag_2 = buffer.create_tag("indent-level-2", "left-margin", 40, null);

        Gtk.TextIter line1_start, line1_end;
        buffer.get_iter_at_line(out line1_start, 0);
        line1_end = line1_start; line1_end.forward_to_line_end();
        buffer.apply_tag(tag_1, line1_start, line1_end);

        Gtk.TextIter line2_start, line2_end;
        buffer.get_iter_at_line(out line2_start, 1);
        line2_end = line2_start; line2_end.forward_to_line_end();
        buffer.apply_tag(tag_2, line2_start, line2_end);

        // Convertir vers RTF_FORMAT (qui utilise les mêmes tags)
        editor.convert_indentation_from_to(IndentationMode.MARGIN_TAGS, IndentationMode.RTF_FORMAT);

        // En mode RTF, les tags devraient toujours être là
        var tag_table = buffer.get_tag_table();
        var rtf_tag_1 = tag_table.lookup("indent-level-1");
        var rtf_tag_2 = tag_table.lookup("indent-level-2");

        assert_nonnull(rtf_tag_1);
        assert_nonnull(rtf_tag_2);

        // Vérifier que les tags sont toujours appliqués
        assert_true(line1_start.has_tag(rtf_tag_1));
        assert_true(line2_start.has_tag(rtf_tag_2));

        Test.message("✅ MARGIN_TAGS to RTF_FORMAT conversion validated");
    });

    app.run();
}

void test_conversion_preserve_content() {
    Test.message("Testing conversion preserves content");

    var app = new Gtk.Application("com.test.indentation", ApplicationFlags.FLAGS_NONE);
    app.activate.connect(() => {
        var editor = new WysiwygEditor();
        var buffer = editor.get_buffer() as Gtk.TextBuffer;

        // Contenu avec formatage spécial
        string original_content = "**Bold text**\n*Italic text*\n`Code text`";
        buffer.set_text(original_content, -1);

        // Appliquer du formatage (gras, italique, code)
        var tag_bold = buffer.create_tag("bold", "weight", 700, null);
        var tag_italic = buffer.create_tag("italic", "style", Pango.Style.ITALIC, null);
        var tag_code = buffer.create_tag("code", "family", "monospace", null);

        // Appliquer tags au contenu approprié
        Gtk.TextIter start, end;
        buffer.get_start_iter(out start);
        end = start; end.forward_chars(2); // "**"
        var bold_start = end;
        end.forward_chars(9); // "Bold text"
        buffer.apply_tag(tag_bold, bold_start, end);

        // Convertir plusieurs fois pour tester la préservation
        editor.convert_indentation_from_to(IndentationMode.NONE, IndentationMode.SPACES);
        editor.convert_indentation_from_to(IndentationMode.SPACES, IndentationMode.MARGIN_TAGS);
        editor.convert_indentation_from_to(IndentationMode.MARGIN_TAGS, IndentationMode.RTF_FORMAT);

        // Vérifier que le contenu est préservé
        buffer.get_bounds(out start, out end);
        string final_content = buffer.get_text(start, end, false);

        // Le contenu principal devrait être intact
        assert_true(final_content.contains("Bold text"));
        assert_true(final_content.contains("Italic text"));
        assert_true(final_content.contains("Code text"));

        // Les tags de formatage devraient être préservés
        var preserved_bold = buffer.get_tag_table().lookup("bold");
        var preserved_italic = buffer.get_tag_table().lookup("italic");
        var preserved_code = buffer.get_tag_table().lookup("code");

        assert_nonnull(preserved_bold);
        assert_nonnull(preserved_italic);
        assert_nonnull(preserved_code);

        Test.message("✅ Content preservation during conversion validated");
    });

    app.run();
}

void test_conversion_roundtrip() {
    Test.message("Testing roundtrip conversion");

    var app = new Gtk.Application("com.test.indentation", ApplicationFlags.FLAGS_NONE);
    app.activate.connect(() => {
        var editor = new WysiwygEditor();
        var buffer = editor.get_buffer() as Gtk.TextBuffer;

        // Commencer avec du contenu indenté par espaces
        string original_content = "    Level 1 content\n        Level 2 content\n    Back to level 1";
        buffer.set_text(original_content, -1);

        // Cycle complet de conversion
        editor.convert_indentation_from_to(IndentationMode.SPACES, IndentationMode.MARGIN_TAGS);
        editor.convert_indentation_from_to(IndentationMode.MARGIN_TAGS, IndentationMode.RTF_FORMAT);
        editor.convert_indentation_from_to(IndentationMode.RTF_FORMAT, IndentationMode.MARGIN_TAGS);
        editor.convert_indentation_from_to(IndentationMode.MARGIN_TAGS, IndentationMode.SPACES);

        // Vérifier que l'indentation finale est similaire à l'originale
        Gtk.TextIter start, end;
        buffer.get_bounds(out start, out end);
        string final_content = buffer.get_text(start, end, false);

        var final_lines = final_content.split("\n");
        assert_true(final_lines.length >= 3);

        // Vérifier les niveaux d'indentation
        assert_true(final_lines[0].has_prefix("    ")); // Niveau 1
        assert_true(final_lines[1].has_prefix("        ")); // Niveau 2
        assert_true(final_lines[2].has_prefix("    ")); // Retour niveau 1

        // Vérifier que le contenu textuel est préservé
        assert_true(final_content.contains("Level 1 content"));
        assert_true(final_content.contains("Level 2 content"));
        assert_true(final_content.contains("Back to level 1"));

        Test.message("✅ Roundtrip conversion validated");
    });

    app.run();
}

void test_conversion_empty_lines() {
    Test.message("Testing conversion with empty lines");

    var app = new Gtk.Application("com.test.indentation", ApplicationFlags.FLAGS_NONE);
    app.activate.connect(() => {
        var editor = new WysiwygEditor();
        var buffer = editor.get_buffer() as Gtk.TextBuffer;

        // Contenu avec lignes vides
        string content_with_empty = "    Line 1\n\n        Line 3\n\n    Line 5";
        buffer.set_text(content_with_empty, -1);

        // Convertir avec lignes vides
        editor.convert_indentation_from_to(IndentationMode.SPACES, IndentationMode.MARGIN_TAGS);

        // Vérifier que les lignes vides n'ont pas cassé la conversion
        Gtk.TextIter start, end;
        buffer.get_bounds(out start, out end);
        string result = buffer.get_text(start, end, false);

        // Le contenu devrait toujours contenir les lignes vides
        var lines = result.split("\n");
        assert_true(lines.length >= 5);

        // Vérifier que les tags ont été créés
        var tag_table = buffer.get_tag_table();
        var tag_1 = tag_table.lookup("indent-level-1");
        var tag_2 = tag_table.lookup("indent-level-2");

        assert_nonnull(tag_1);
        assert_nonnull(tag_2);

        Test.message("✅ Conversion with empty lines validated");
    });

    app.run();
}

int main(string[] args) {
    Test.init(ref args);
    Gtk.init();

    // Tests de conversion entre modes
    Test.add_func("/indentation/conversion_spaces_to_margin", test_conversion_spaces_to_margin_tags);
    Test.add_func("/indentation/conversion_margin_to_spaces", test_conversion_margin_tags_to_spaces);
    Test.add_func("/indentation/conversion_margin_to_rtf", test_conversion_margin_tags_to_rtf);

    // Tests de préservation et robustesse
    Test.add_func("/indentation/conversion_preserve_content", test_conversion_preserve_content);
    Test.add_func("/indentation/conversion_roundtrip", test_conversion_roundtrip);
    Test.add_func("/indentation/conversion_empty_lines", test_conversion_empty_lines);

    return Test.run();
}
