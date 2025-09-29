#!/usr/bin/env python3
"""
Test UI rapide pour vérifier les améliorations d'accessibilité
"""

import sys
import time

try:
    import gi
    gi.require_version('Atspi', '2.0')
    from gi.repository import Atspi

    # Import de notre framework UI
    from ui_accessibility_tests import AccessibilityTester

except ImportError as e:
    print(f"❌ Erreur d'import: {e}")
    sys.exit(1)

def main():
    print("🧪 Test UI rapide - Améliorations d'accessibilité")
    print("=" * 50)

    # Initialiser Atspi
    Atspi.init()
    time.sleep(2)

    # Créer le testeur d'accessibilité
    app_path = "/home/emmanuel/Bureau/Projects/IntaText/build/IntaText"
    tester = AccessibilityTester(app_path)

    # Test 1: Trouver la zone de texte WYSIWYG
    print("🔍 Test 1: Recherche de la zone de texte WYSIWYG...")
    text_area = tester.find_text_area()

    if text_area:
        name = text_area.get_name() or "(sans nom)"
        role = text_area.get_role_name()
        print(f"✅ Zone de texte trouvée: {name} [{role}]")

        # Test 2: Essayer de définir du texte
        print("📝 Test 2: Tentative d'insertion de texte...")
        test_text = "Test d'accessibilité"
        success = tester.set_text(text_area, test_text)

        if success:
            print("✅ Texte inséré avec succès")

            # Vérifier que le texte a été inséré
            current_text = tester.get_text(text_area)
            if test_text in current_text:
                print(f"✅ Texte vérifié: '{current_text}'")
            else:
                print(f"⚠️  Texte différent: '{current_text}'")
        else:
            print("❌ Échec de l'insertion de texte")

        # Test 3: Trouver les boutons de formatage
        print("🔘 Test 3: Recherche des boutons de formatage...")

        bold_button = tester.find_button("Bouton Gras")
        if bold_button:
            print("✅ Bouton Gras trouvé")
        else:
            print("❌ Bouton Gras non trouvé")

        italic_button = tester.find_button("Bouton Italique")
        if italic_button:
            print("✅ Bouton Italique trouvé")
        else:
            print("❌ Bouton Italique non trouvé")

    else:
        print("❌ Zone de texte WYSIWYG non trouvée")
        print("💡 Vérifiez que IntaText est lancé et visible")
        return 1

    print("\n" + "=" * 50)
    print("✅ Test rapide terminé")
    return 0

if __name__ == "__main__":
    sys.exit(main())
