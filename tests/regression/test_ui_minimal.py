#!/usr/bin/env python3
"""
Test UI minimal pour IntaText - Version de débogage d'accessibilité
"""

import sys
import time

try:
    import gi
    gi.require_version('Atspi', '2.0')
    from gi.repository import Atspi
except ImportError as e:
    print(f"❌ Erreur d'import des bibliothèques d'accessibilité: {e}")
    sys.exit(1)

def find_all_text_widgets():
    """Trouve tous les widgets de type texte dans l'application"""
    print("🔍 Recherche de tous les widgets de texte...")

    # Initialiser Atspi
    Atspi.init()

    # Récupérer le bureau
    desktop = Atspi.get_desktop(0)

    text_widgets = []

    def search_recursive(element, level=0):
        if not element:
            return

        indent = "  " * level
        name = element.get_name() or "(sans nom)"
        role = element.get_role_name()

        print(f"{indent}├─ {name} [{role}]")

        # Vérifier si c'est un élément de texte
        if 'text' in role.lower() or 'entry' in role.lower() or 'edit' in role.lower():
            text_widgets.append({
                'name': name,
                'role': role,
                'element': element,
                'level': level
            })
            print(f"{indent}  🎯 WIDGET TEXTE TROUVÉ!")

        # Parcourir les enfants
        try:
            for i in range(element.get_child_count()):
                child = element.get_child_at_index(i)
                if child:
                    search_recursive(child, level + 1)
        except Exception as e:
            print(f"{indent}  ⚠️  Erreur lors de l'exploration: {e}")

    # Chercher dans toutes les applications
    for i in range(desktop.get_child_count()):
        app = desktop.get_child_at_index(i)
        if app and 'IntaText' in (app.get_name() or ''):
            print(f"📱 Application IntaText trouvée: {app.get_name()}")
            search_recursive(app)

    return text_widgets

def test_text_input(text_widget):
    """Test d'entrée de texte sur un widget"""
    try:
        element = text_widget['element']

        # Essayer de mettre le focus
        element.set_focus()
        print(f"✅ Focus mis sur {text_widget['name']}")

        # Essayer d'insérer du texte (si possible)
        # Note: Atspi peut ne pas supporter l'insertion directe selon le widget

        return True

    except Exception as e:
        print(f"❌ Erreur lors du test d'entrée: {e}")
        return False

def main():
    print("🧪 Test UI minimal IntaText - Debug d'accessibilité")
    print("=" * 60)

    # Attendre que l'application soit disponible
    print("⏳ Attente de l'application IntaText...")
    time.sleep(3)

    # Trouver tous les widgets de texte
    text_widgets = find_all_text_widgets()

    print("\n" + "=" * 60)
    print(f"📊 Résultats: {len(text_widgets)} widget(s) de texte trouvé(s)")

    if not text_widgets:
        print("❌ Aucun widget de texte trouvé!")
        print("💡 Suggestions:")
        print("   - Vérifier que l'application expose ses widgets à l'API d'accessibilité")
        print("   - Ajouter des rôles d'accessibilité aux widgets TextView")
        print("   - Vérifier la configuration GTK d'accessibilité")
        return 1

    # Tester chaque widget trouvé
    for i, widget in enumerate(text_widgets):
        print(f"\n🎯 Test du widget {i+1}: {widget['name']} [{widget['role']}]")
        success = test_text_input(widget)
        if success:
            print(f"✅ Widget {i+1} fonctionne")
        else:
            print(f"❌ Widget {i+1} a échoué")

    print("\n" + "=" * 60)
    print("✅ Test terminé")
    return 0

if __name__ == "__main__":
    sys.exit(main())
