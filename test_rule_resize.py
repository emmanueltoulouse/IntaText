#!/usr/bin/env python3
"""
Test manuel pour vérifier le redimensionnement des traits de séparation
"""

import gi
gi.require_version('Gtk', '4.0')
gi.require_version('Atspi', '2.0')
from gi.repository import Gtk, Atspi, GLib
import time
import subprocess
import sys

def test_horizontal_rule_resize():
    """Test le redimensionnement des traits horizontaux"""
    print("🧪 Test de redimensionnement des traits de séparation")

    # Démarrer l'application
    print("📱 Démarrage de l'application...")
    process = subprocess.Popen(
        ['./build/IntaText'],
        cwd='/home/emmanuel/Bureau/Projects/IntaText',
        env={'GSETTINGS_SCHEMA_DIR': '/usr/local/share/glib-2.0/schemas'}
    )

    # Attendre que l'application démarre
    time.sleep(3)

    try:
        # Initialiser Atspi
        Atspi.init()

        # Trouver l'application
        desktop = Atspi.get_desktop(0)
        app = None

        for i in range(desktop.get_child_count()):
            child = desktop.get_child_at_index(i)
            if child and "IntaText" in child.get_name():
                app = child
                break

        if not app:
            print("❌ Application IntaText non trouvée")
            return False

        print(f"✅ Application trouvée: {app.get_name()}")

        # Trouver la zone d'édition WYSIWYG
        text_area = None
        def find_text_area(obj, depth=0):
            nonlocal text_area
            if depth > 10:  # Limite de profondeur
                return

            try:
                role = obj.get_role()
                name = obj.get_name() or ""

                if role == Atspi.Role.TEXT and "WYSIWYG" in name:
                    text_area = obj
                    return

                # Parcourir les enfants
                for i in range(obj.get_child_count()):
                    child = obj.get_child_at_index(i)
                    if child:
                        find_text_area(child, depth + 1)
                        if text_area:
                            return
            except Exception as e:
                pass

        find_text_area(app)

        if not text_area:
            print("❌ Zone d'édition WYSIWYG non trouvée")
            return False

        print(f"✅ Zone d'édition trouvée: {text_area.get_name()}")

        # Insérer du texte de test avec trait de séparation
        test_text = """Test de redimensionnement des traits

Voici un trait de séparation qui devrait s'adapter à la largeur de la fenêtre :

---

Le trait ci-dessus devrait se redimensionner automatiquement."""

        # Simuler la saisie de texte
        try:
            text_iface = text_area.get_text_iface()
            if text_iface:
                text_iface.set_text_contents(test_text)
                print("✅ Texte inséré avec succès")
            else:
                print("❌ Interface de texte non disponible")
                return False
        except Exception as e:
            print(f"❌ Erreur lors de l'insertion de texte: {e}")
            return False

        # Attendre un moment pour que le rendu se fasse
        time.sleep(2)

        # Obtenir la taille actuelle de la fenêtre
        window = None
        def find_window(obj):
            nonlocal window
            try:
                if obj.get_role() == Atspi.Role.WINDOW and "IntaText" in obj.get_name():
                    window = obj
                    return
                for i in range(obj.get_child_count()):
                    child = obj.get_child_at_index(i)
                    if child:
                        find_window(child)
                        if window:
                            return
            except:
                pass

        find_window(app)

        if window:
            print("✅ Fenêtre principale trouvée")
            print("📏 Test de redimensionnement en cours...")

            # Simuler le redimensionnement de la fenêtre
            # Note: Avec Wayland/GTK4, il peut être difficile de redimensionner programmatiquement
            print("ℹ️ Veuillez redimensionner manuellement la fenêtre pour tester le redimensionnement des traits")
            print("⏱️ Attente de 10 secondes pour permettre le test manuel...")
            time.sleep(10)

        else:
            print("❌ Fenêtre principale non trouvée")
            return False

        print("✅ Test terminé")
        return True

    except Exception as e:
        print(f"❌ Erreur durant le test: {e}")
        return False

    finally:
        # Fermer l'application
        try:
            process.terminate()
            process.wait(timeout=5)
        except:
            process.kill()

if __name__ == "__main__":
    success = test_horizontal_rule_resize()
    sys.exit(0 if success else 1)
