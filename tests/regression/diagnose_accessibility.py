#!/usr/bin/env python3
"""
Script de diagnostic d'accessibilité pour IntaText
Analyse l'arbre d'accessibilité de l'application
"""

import sys
import time

try:
    import gi
    gi.require_version('Atspi', '2.0')
    from gi.repository import Atspi
except ImportError as e:
    print(f"❌ Erreur d'import des bibliothèques d'accessibilité: {e}")
    print("Veuillez installer: sudo apt install python3-gi gir1.2-atspi-2.0")
    sys.exit(1)

def find_intatext_windows():
    """Trouve toutes les fenêtres IntaText"""
    windows = []
    desktop = Atspi.get_desktop(0)

    for i in range(desktop.get_child_count()):
        app = desktop.get_child_at_index(i)
        if app and 'IntaText' in (app.get_name() or ''):
            print(f"📱 Application trouvée: {app.get_name()}")
            for j in range(app.get_child_count()):
                window = app.get_child_at_index(j)
                if window:
                    windows.append(window)
                    print(f"   🪟 Fenêtre: {window.get_name()} (rôle: {window.get_role_name()})")

    return windows

def analyze_element(element, level=0, max_level=5):
    """Analyse récursivement un élément d'accessibilité"""
    if level > max_level or not element:
        return

    indent = "  " * level
    name = element.get_name() or "(sans nom)"
    role = element.get_role_name()

    # Informations sur l'élément
    info = f"{indent}├─ {name} [{role}]"

    # Ajouter des informations sur les éléments texte
    if 'text' in role.lower() or 'entry' in role.lower() or 'edit' in role.lower():
        try:
            if hasattr(element, 'get_text'):
                text_content = element.get_text(0, -1) if hasattr(element, 'get_text') else ""
                info += f" (texte: '{text_content[:50]}...')"
        except:
            pass
        info += " 🎯"  # Marquer les éléments texte potentiels

    print(info)

    # Analyser les enfants
    try:
        child_count = element.get_child_count()
        for i in range(min(child_count, 20)):  # Limiter à 20 enfants max
            child = element.get_child_at_index(i)
            if child:
                analyze_element(child, level + 1, max_level)
    except Exception as e:
        print(f"{indent}  ⚠️  Erreur lors de l'analyse des enfants: {e}")

def main():
    print("🔍 Diagnostic d'accessibilité IntaText")
    print("=" * 50)

    # Initialiser Atspi
    try:
        Atspi.init()
        print("✅ Atspi initialisé")
    except Exception as e:
        print(f"❌ Erreur d'initialisation Atspi: {e}")
        return 1

    # Attendre un peu
    print("⏳ Recherche des applications IntaText...")
    time.sleep(2)

    # Trouver les fenêtres IntaText
    windows = find_intatext_windows()

    if not windows:
        print("❌ Aucune fenêtre IntaText trouvée")
        print("💡 Assurez-vous que IntaText est lancé et visible")
        return 1

    print(f"\n🎯 Analyse de {len(windows)} fenêtre(s) IntaText:")
    print("-" * 50)

    for i, window in enumerate(windows):
        print(f"\n📋 Fenêtre {i+1}: {window.get_name()}")
        analyze_element(window, max_level=4)

    print("\n" + "=" * 50)
    print("✅ Diagnostic terminé")
    return 0

if __name__ == "__main__":
    sys.exit(main())
