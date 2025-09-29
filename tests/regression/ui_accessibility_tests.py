#!/usr/bin/env python3
"""
Tests UI WYSIWYG via Accessibilité - IntaText
Tests de l'interface utilisateur en utilisant les API d'accessibilité
"""

import time
import subprocess
import signal
import os
import tempfile
from pathlib import Path
from typing import Dict, List, Optional, Tuple, Any
from dataclasses import dataclass
import threading
import queue

try:
    import gi
    gi.require_version('Atspi', '2.0')
    gi.require_version('Gtk', '4.0')
    from gi.repository import Atspi, GLib, Gtk
    ACCESSIBILITY_AVAILABLE = True
except ImportError:
    ACCESSIBILITY_AVAILABLE = False

@dataclass
class UITestResult:
    """Résultat d'un test UI"""
    test_id: str
    success: bool
    error_message: Optional[str] = None
    execution_time: float = 0.0
    screenshot_path: Optional[str] = None
    ui_state: Optional[Dict] = None

class AccessibilityTester:
    """Testeur d'interface via accessibilité"""

    def __init__(self, app_path: str):
        self.app_path = Path(app_path)
        self.app_process = None
        self.app_node = None
        self.timeout = 30
        self.results: List[UITestResult] = []

        if not ACCESSIBILITY_AVAILABLE:
            raise ImportError("Les bibliothèques d'accessibilité ne sont pas disponibles")

        # Initialiser l'accessibilité
        Atspi.init()

    def start_application(self) -> bool:
        """Lance l'application IntaText"""
        try:
            # Variables d'environnement pour l'accessibilité
            env = os.environ.copy()
            env.update({
                'GTK_MODULES': 'gail:atk-bridge',
                'GSETTINGS_SCHEMA_DIR': '/usr/local/share/glib-2.0/schemas',
                'NO_AT_BRIDGE': '0',
                'DISPLAY': ':0'
            })

            # Lancer l'application
            self.app_process = subprocess.Popen(
                [str(self.app_path)],
                env=env,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE
            )

            # Attendre que l'application soit accessible
            return self._wait_for_application()

        except Exception as e:
            print(f"Erreur lors du lancement: {e}")
            return False

    def _wait_for_application(self) -> bool:
        """Attend que l'application soit accessible"""
        timeout = time.time() + self.timeout

        while time.time() < timeout:
            try:
                # Chercher l'application par nom
                desktop = Atspi.get_desktop(0)

                for i in range(desktop.get_child_count()):
                    app = desktop.get_child_at_index(i)
                    if app and 'IntaText' in app.get_name():
                        self.app_node = app
                        time.sleep(1)  # Laisser l'UI se stabiliser
                        return True

            except Exception:
                pass

            time.sleep(0.5)

        return False

    def stop_application(self):
        """Arrête l'application"""
        if self.app_process:
            try:
                self.app_process.terminate()
                self.app_process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                self.app_process.kill()
            finally:
                self.app_process = None

        self.app_node = None

    def find_element(self, role: Atspi.Role, name: str = None, recursive: bool = True) -> Optional[Any]:
        """Trouve un élément par rôle et nom"""
        if not self.app_node:
            return None

        def search_node(node, depth=0):
            if depth > 10:  # Éviter la récursion infinie
                return None

            try:
                if node.get_role() == role:
                    if name is None or name in node.get_name():
                        return node

                if recursive:
                    for i in range(node.get_child_count()):
                        child = node.get_child_at_index(i)
                        if child:
                            result = search_node(child, depth + 1)
                            if result:
                                return result
            except Exception:
                pass

            return None

        return search_node(self.app_node)

    def find_button(self, name: str) -> Optional[Any]:
        """Trouve un bouton par nom"""
        return self.find_element(Atspi.Role.PUSH_BUTTON, name)

    def find_text_area(self) -> Optional[Any]:
        """Trouve la zone de texte principale WYSIWYG"""
        try:
            desktop = Atspi.get_desktop(0)

            for i in range(desktop.get_child_count()):
                app = desktop.get_child_at_index(i)
                if app and 'IntaText' in (app.get_name() or ''):
                    # Recherche spécifique de "Zone d'édition WYSIWYG"
                    text_widget = self._search_wysiwyg_text_widget(app)
                    if text_widget:
                        return text_widget

            # Fallback : chercher par rôle
            for role in [Atspi.Role.TEXT, Atspi.Role.DOCUMENT_TEXT, Atspi.Role.TERMINAL]:
                element = self.find_element(role)
                if element:
                    return element
            return None

        except Exception as e:
            print(f"Erreur lors de la recherche de zone de texte: {e}")
            return None

    def _search_wysiwyg_text_widget(self, element):
        """Recherche récursive de la zone d'édition WYSIWYG"""
        try:
            if not element:
                return None

            # Vérifier si c'est l'élément que nous cherchons
            name = element.get_name() or ""
            role = element.get_role_name()

            if ("Zone d'édition WYSIWYG" in name or
                ("WYSIWYG" in name and "text" in role.lower())):
                return element

            # Rechercher dans les enfants
            for i in range(element.get_child_count()):
                child = element.get_child_at_index(i)
                if child:
                    result = self._search_wysiwyg_text_widget(child)
                    if result:
                        return result

            return None

        except Exception as e:
            return None

    def click_element(self, element) -> bool:
        """Clique sur un élément"""
        try:
            if element and hasattr(element, 'do_action'):
                # Essayer l'action "click" ou "activate"
                for i in range(element.get_n_actions()):
                    action_name = element.get_action_name(i)
                    if action_name in ['click', 'activate', 'press']:
                        return element.do_action(i)
            return False
        except Exception:
            return False

    def set_text(self, element, text: str) -> bool:
        """Définit le texte d'un élément"""
        try:
            if not element:
                return False

            # Essayer différentes méthodes pour définir le texte

            # Méthode 1: Interface Text
            try:
                if hasattr(element, 'get_text_iface'):
                    text_iface = element.get_text_iface()
                    if text_iface:
                        # Effacer le texte existant
                        char_count = text_iface.get_character_count()
                        if char_count > 0:
                            text_iface.delete_text(0, char_count)
                        # Insérer le nouveau texte
                        return text_iface.insert_text(0, text, len(text))
            except:
                pass

            # Méthode 2: Interface EditableText
            try:
                editable_iface = element.get_editable_text_iface()
                if editable_iface:
                    # Effacer le texte existant
                    editable_iface.delete_text(0, -1)
                    # Insérer le nouveau texte
                    editable_iface.insert_text(0, text, len(text))
                    return True
            except:
                pass

            # Méthode 3: Simuler la saisie clavier (si les autres échouent)
            try:
                # Donner le focus à l'élément
                for i in range(element.get_n_actions()):
                    action_name = element.get_action_name(i)
                    if action_name in ['grab_focus', 'focus']:
                        element.do_action(i)
                        break

                # Sélectionner tout (Ctrl+A) et taper le nouveau texte
                # Note: Ceci nécessiterait une simulation clavier plus avancée
                # Pour l'instant, on retourne False pour indiquer l'échec
                return False

            except:
                pass

            return False

        except Exception as e:
            print(f"Erreur lors de la définition du texte: {e}")
            return False

    def get_text(self, element) -> str:
        """Récupère le texte d'un élément"""
        try:
            if element and hasattr(element, 'get_text_iface'):
                text_iface = element.get_text_iface()
                if text_iface:
                    return text_iface.get_text(0, -1)
            return ""
        except Exception:
            return ""

    def select_text(self, element, start: int, end: int) -> bool:
        """Sélectionne du texte"""
        try:
            if element and hasattr(element, 'get_text_iface'):
                text_iface = element.get_text_iface()
                if text_iface:
                    return text_iface.set_selection(0, start, end)
            return False
        except Exception:
            return False

class WYSIWYGUITester:
    """Testeur spécialisé pour l'interface WYSIWYG d'IntaText"""

    def __init__(self, app_path: str):
        self.accessibility = AccessibilityTester(app_path)
        self.temp_dir = Path(tempfile.mkdtemp(prefix="intatext_ui_tests_"))

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        self.cleanup()

    def cleanup(self):
        """Nettoyage"""
        self.accessibility.stop_application()
        if self.temp_dir.exists():
            import shutil
            shutil.rmtree(self.temp_dir)

    def setup_test_environment(self) -> bool:
        """Prépare l'environnement de test"""
        return self.accessibility.start_application()

    def test_bold_formatting(self) -> UITestResult:
        """Test du formatage gras via l'interface"""
        start_time = time.time()

        try:
            # Trouver la zone de texte
            text_area = self.accessibility.find_text_area()
            if not text_area:
                return UITestResult(
                    test_id="ui_bold_formatting",
                    success=False,
                    error_message="Zone de texte non trouvée",
                    execution_time=time.time() - start_time
                )

            # Saisir du texte
            test_text = "Texte pour test gras"
            if not self.accessibility.set_text(text_area, test_text):
                return UITestResult(
                    test_id="ui_bold_formatting",
                    success=False,
                    error_message="Impossible de saisir le texte",
                    execution_time=time.time() - start_time
                )

            # Sélectionner le mot "test"
            text_content = self.accessibility.get_text(text_area)
            start_pos = text_content.find("test")
            if start_pos == -1:
                return UITestResult(
                    test_id="ui_bold_formatting",
                    success=False,
                    error_message="Texte de test non trouvé",
                    execution_time=time.time() - start_time
                )

            end_pos = start_pos + 4
            self.accessibility.select_text(text_area, start_pos, end_pos)

            # Trouver et cliquer le bouton gras
            bold_button = self.accessibility.find_button("Gras") or \
                         self.accessibility.find_button("Bold") or \
                         self.accessibility.find_button("B")

            if not bold_button:
                return UITestResult(
                    test_id="ui_bold_formatting",
                    success=False,
                    error_message="Bouton gras non trouvé",
                    execution_time=time.time() - start_time
                )

            if not self.accessibility.click_element(bold_button):
                return UITestResult(
                    test_id="ui_bold_formatting",
                    success=False,
                    error_message="Impossible de cliquer le bouton gras",
                    execution_time=time.time() - start_time
                )

            # Attendre la mise à jour
            time.sleep(0.5)

            # Vérifier le résultat (dépend de l'implémentation d'IntaText)
            # On peut vérifier si le texte contient maintenant du formatage
            updated_text = self.accessibility.get_text(text_area)

            success = "**test**" in updated_text or "<b>test</b>" in updated_text

            return UITestResult(
                test_id="ui_bold_formatting",
                success=success,
                error_message=None if success else "Formatage gras non appliqué",
                execution_time=time.time() - start_time,
                ui_state={"text_content": updated_text}
            )

        except Exception as e:
            return UITestResult(
                test_id="ui_bold_formatting",
                success=False,
                error_message=f"Erreur durant le test: {str(e)}",
                execution_time=time.time() - start_time
            )

    def test_italic_formatting(self) -> UITestResult:
        """Test du formatage italique via l'interface"""
        start_time = time.time()

        try:
            text_area = self.accessibility.find_text_area()
            if not text_area:
                return UITestResult(
                    test_id="ui_italic_formatting",
                    success=False,
                    error_message="Zone de texte non trouvée"
                )

            # Saisir et sélectionner du texte
            test_text = "Texte pour test italique"
            self.accessibility.set_text(text_area, test_text)

            text_content = self.accessibility.get_text(text_area)
            start_pos = text_content.find("test")
            if start_pos != -1:
                self.accessibility.select_text(text_area, start_pos, start_pos + 4)

            # Trouver et cliquer le bouton italique
            italic_button = self.accessibility.find_button("Italique") or \
                           self.accessibility.find_button("Italic") or \
                           self.accessibility.find_button("I")

            if not italic_button or not self.accessibility.click_element(italic_button):
                return UITestResult(
                    test_id="ui_italic_formatting",
                    success=False,
                    error_message="Impossible d'appliquer l'italique"
                )

            time.sleep(0.5)
            updated_text = self.accessibility.get_text(text_area)
            success = "*test*" in updated_text or "<i>test</i>" in updated_text

            return UITestResult(
                test_id="ui_italic_formatting",
                success=success,
                error_message=None if success else "Formatage italique non appliqué",
                execution_time=time.time() - start_time
            )

        except Exception as e:
            return UITestResult(
                test_id="ui_italic_formatting",
                success=False,
                error_message=str(e),
                execution_time=time.time() - start_time
            )

    def test_heading_formatting(self) -> UITestResult:
        """Test du formatage de titre via l'interface"""
        start_time = time.time()

        try:
            text_area = self.accessibility.find_text_area()
            if not text_area:
                return UITestResult(
                    test_id="ui_heading_formatting",
                    success=False,
                    error_message="Zone de texte non trouvée"
                )

            # Saisir un titre
            test_text = "Mon Titre de Test"
            self.accessibility.set_text(text_area, test_text)

            # Sélectionner tout le texte
            text_content = self.accessibility.get_text(text_area)
            self.accessibility.select_text(text_area, 0, len(text_content))

            # Chercher le bouton ou menu de titre
            heading_button = self.accessibility.find_button("Titre") or \
                           self.accessibility.find_button("Heading") or \
                           self.accessibility.find_button("H1")

            if not heading_button or not self.accessibility.click_element(heading_button):
                return UITestResult(
                    test_id="ui_heading_formatting",
                    success=False,
                    error_message="Impossible d'appliquer le formatage de titre"
                )

            time.sleep(0.5)
            updated_text = self.accessibility.get_text(text_area)
            success = "# Mon Titre" in updated_text or "<h1>" in updated_text

            return UITestResult(
                test_id="ui_heading_formatting",
                success=success,
                error_message=None if success else "Formatage de titre non appliqué",
                execution_time=time.time() - start_time
            )

        except Exception as e:
            return UITestResult(
                test_id="ui_heading_formatting",
                success=False,
                error_message=str(e),
                execution_time=time.time() - start_time
            )

    def test_list_formatting(self) -> UITestResult:
        """Test du formatage de liste via l'interface"""
        start_time = time.time()

        try:
            text_area = self.accessibility.find_text_area()
            if not text_area:
                return UITestResult(
                    test_id="ui_list_formatting",
                    success=False,
                    error_message="Zone de texte non trouvée"
                )

            # Saisir des éléments de liste
            test_text = "Premier élément\nDeuxième élément\nTroisième élément"
            self.accessibility.set_text(text_area, test_text)

            # Sélectionner tout
            text_content = self.accessibility.get_text(text_area)
            self.accessibility.select_text(text_area, 0, len(text_content))

            # Chercher le bouton de liste
            list_button = self.accessibility.find_button("Liste") or \
                         self.accessibility.find_button("List") or \
                         self.accessibility.find_button("Puces")

            if not list_button or not self.accessibility.click_element(list_button):
                return UITestResult(
                    test_id="ui_list_formatting",
                    success=False,
                    error_message="Impossible d'appliquer le formatage de liste"
                )

            time.sleep(0.5)
            updated_text = self.accessibility.get_text(text_area)
            success = "- Premier" in updated_text or "* Premier" in updated_text or "<li>" in updated_text

            return UITestResult(
                test_id="ui_list_formatting",
                success=success,
                error_message=None if success else "Formatage de liste non appliqué",
                execution_time=time.time() - start_time
            )

        except Exception as e:
            return UITestResult(
                test_id="ui_list_formatting",
                success=False,
                error_message=str(e),
                execution_time=time.time() - start_time
            )

    def test_combined_formatting(self) -> UITestResult:
        """Test de formatages combinés via l'interface"""
        start_time = time.time()

        try:
            text_area = self.accessibility.find_text_area()
            if not text_area:
                return UITestResult(
                    test_id="ui_combined_formatting",
                    success=False,
                    error_message="Zone de texte non trouvée"
                )

            # Saisir du texte
            test_text = "Texte pour test combiné"
            self.accessibility.set_text(text_area, test_text)

            # Sélectionner "test"
            text_content = self.accessibility.get_text(text_area)
            start_pos = text_content.find("test")
            if start_pos != -1:
                self.accessibility.select_text(text_area, start_pos, start_pos + 4)

                # Appliquer gras
                bold_button = self.accessibility.find_button("Gras") or self.accessibility.find_button("B")
                if bold_button:
                    self.accessibility.click_element(bold_button)
                    time.sleep(0.3)

                # Appliquer italique (maintenir la sélection)
                italic_button = self.accessibility.find_button("Italique") or self.accessibility.find_button("I")
                if italic_button:
                    self.accessibility.click_element(italic_button)
                    time.sleep(0.3)

            updated_text = self.accessibility.get_text(text_area)
            success = ("***test***" in updated_text or
                      ("<b>" in updated_text and "<i>" in updated_text) or
                      ("**" in updated_text and "*" in updated_text))

            return UITestResult(
                test_id="ui_combined_formatting",
                success=success,
                error_message=None if success else "Formatage combiné non appliqué",
                execution_time=time.time() - start_time
            )

        except Exception as e:
            return UITestResult(
                test_id="ui_combined_formatting",
                success=False,
                error_message=str(e),
                execution_time=time.time() - start_time
            )

    def test_wysiwyg_markdown_toggle(self) -> UITestResult:
        """Test de la bascule WYSIWYG ↔ Markdown"""
        start_time = time.time()

        try:
            # Saisir du texte avec formatage
            text_area = self.accessibility.find_text_area()
            if not text_area:
                return UITestResult(
                    test_id="ui_wysiwyg_markdown_toggle",
                    success=False,
                    error_message="Zone de texte non trouvée"
                )

            # Créer du contenu formaté
            test_text = "Titre de test"
            self.accessibility.set_text(text_area, test_text)

            # Formater en titre
            self.accessibility.select_text(text_area, 0, len(test_text))
            heading_button = self.accessibility.find_button("Titre") or self.accessibility.find_button("H1")
            if heading_button:
                self.accessibility.click_element(heading_button)
                time.sleep(0.5)

            # Chercher le bouton de bascule mode
            toggle_button = self.accessibility.find_button("Markdown") or \
                          self.accessibility.find_button("Source") or \
                          self.accessibility.find_button("Mode")

            if not toggle_button:
                return UITestResult(
                    test_id="ui_wysiwyg_markdown_toggle",
                    success=False,
                    error_message="Bouton de bascule non trouvé"
                )

            # Basculer vers Markdown
            if not self.accessibility.click_element(toggle_button):
                return UITestResult(
                    test_id="ui_wysiwyg_markdown_toggle",
                    success=False,
                    error_message="Impossible de basculer vers Markdown"
                )

            time.sleep(0.5)

            # Vérifier le contenu Markdown
            markdown_text = self.accessibility.get_text(text_area)
            has_markdown = "# Titre" in markdown_text

            # Basculer retour vers WYSIWYG
            self.accessibility.click_element(toggle_button)
            time.sleep(0.5)

            wysiwyg_text = self.accessibility.get_text(text_area)
            back_to_wysiwyg = "Titre" in wysiwyg_text

            success = has_markdown and back_to_wysiwyg

            return UITestResult(
                test_id="ui_wysiwyg_markdown_toggle",
                success=success,
                error_message=None if success else "Bascule WYSIWYG ↔ Markdown échouée",
                execution_time=time.time() - start_time,
                ui_state={
                    "markdown_content": markdown_text,
                    "wysiwyg_content": wysiwyg_text
                }
            )

        except Exception as e:
            return UITestResult(
                test_id="ui_wysiwyg_markdown_toggle",
                success=False,
                error_message=str(e),
                execution_time=time.time() - start_time
            )

    def run_all_ui_tests(self) -> List[UITestResult]:
        """Exécute tous les tests UI"""
        if not self.setup_test_environment():
            return [UITestResult(
                test_id="ui_setup",
                success=False,
                error_message="Impossible de lancer l'application pour les tests UI"
            )]

        tests = [
            self.test_bold_formatting,
            self.test_italic_formatting,
            self.test_heading_formatting,
            self.test_list_formatting,
            self.test_combined_formatting,
            self.test_wysiwyg_markdown_toggle
        ]

        results = []
        for test_func in tests:
            try:
                result = test_func()
                results.append(result)
                time.sleep(1)  # Pause entre les tests
            except Exception as e:
                results.append(UITestResult(
                    test_id=test_func.__name__,
                    success=False,
                    error_message=f"Erreur lors de l'exécution: {str(e)}"
                ))

        return results
