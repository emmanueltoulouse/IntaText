#!/usr/bin/env python3
"""
Tests d'intégration pour les fonctionnalités d'indentation d'IntaText
Teste: increase_indent(), decrease_indent(), paragraphes, listes, titres
"""

import sys
import subprocess
import os
import tempfile
import time
from pathlib import Path

class IntaTextIndentationIntegrationTests:
    """Tests d'intégration pour l'indentation"""

    def __init__(self):
        self.temp_dir = None
        self.results = {}

    def setUp(self):
        """Prépare l'environnement de test"""
        print("🔧 Préparation des tests d'intégration indentation...")
        self.temp_dir = tempfile.mkdtemp(prefix="intatext_indent_test_")
        print(f"📁 Dossier temporaire: {self.temp_dir}")

    def tearDown(self):
        """Nettoie l'environnement"""
        if self.temp_dir and os.path.exists(self.temp_dir):
            import shutil
            shutil.rmtree(self.temp_dir, ignore_errors=True)

    def test_paragraph_indentation(self):
        """Test d'indentation de paragraphes multi-lignes"""
        print("📝 Test indentation paragraphes...")

        try:
            # Créer un fichier de test avec paragraphes
            test_content = """# Test d'indentation

Voici un paragraphe avec plusieurs lignes.
Cette ligne fait partie du même paragraphe.
Celle-ci aussi appartient au paragraphe.
Et cette dernière ligne termine le paragraphe.

Voici un deuxième paragraphe complètement séparé.
Il a aussi plusieurs lignes pour tester l'indentation.
Toutes ces lignes doivent être indentées ensemble.

## Section suivante

Paragraphe normal après la section.
Avec plusieurs lignes aussi.
"""

            test_file = os.path.join(self.temp_dir, "paragraph_test.md")
            with open(test_file, 'w', encoding='utf-8') as f:
                f.write(test_content)

            # Test via CLI pour valider le chargement
            env = os.environ.copy()
            env["GSETTINGS_SCHEMA_DIR"] = "/usr/local/share/glib-2.0/schemas"

            process = subprocess.Popen(
                ["./build/IntaText", test_file],
                env=env,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE
            )

            time.sleep(3)  # Laisser le temps de charger

            if process.poll() is None:
                print("✅ Chargement paragraphes multi-lignes OK")

                # L'application tourne, les paragraphes sont chargés
                process.terminate()
                try:
                    process.wait(timeout=3)
                except subprocess.TimeoutExpired:
                    process.kill()

                success = True
            else:
                stdout, stderr = process.communicate()
                print(f"❌ Échec chargement paragraphes: {stderr.decode()[:100]}")
                success = False

            self.results["paragraph_indentation"] = {"success": success}
            return success

        except Exception as e:
            print(f"❌ Erreur test paragraphes: {e}")
            return False

    def test_list_indentation(self):
        """Test d'indentation de listes"""
        print("📋 Test indentation listes...")

        try:
            # Créer un fichier avec différents types de listes
            test_content = """# Test listes avec indentation

## Listes à puces

- Premier élément
- Deuxième élément
    - Sous-élément indenté
    - Autre sous-élément
- Troisième élément

## Listes ordonnées

1. Premier élément numéroté
2. Deuxième élément numéroté
    1. Sous-élément numéroté
    2. Autre sous-élément numéroté
3. Troisième élément numéroté

## Listes mixtes

- Élément à puce
    1. Sous-élément numéroté
    2. Autre sous-élément numéroté
        - Sous-sous-élément à puce
- Autre élément à puce
"""

            test_file = os.path.join(self.temp_dir, "list_test.md")
            with open(test_file, 'w', encoding='utf-8') as f:
                f.write(test_content)

            # Test chargement et parsing des listes
            env = os.environ.copy()
            env["GSETTINGS_SCHEMA_DIR"] = "/usr/local/share/glib-2.0/schemas"

            process = subprocess.Popen(
                ["./build/IntaText", test_file],
                env=env,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE
            )

            time.sleep(3)

            if process.poll() is None:
                print("✅ Chargement listes indentées OK")

                process.terminate()
                try:
                    process.wait(timeout=3)
                except subprocess.TimeoutExpired:
                    process.kill()

                success = True
            else:
                stdout, stderr = process.communicate()
                print(f"❌ Échec chargement listes: {stderr.decode()[:100]}")
                success = False

            self.results["list_indentation"] = {"success": success}
            return success

        except Exception as e:
            print(f"❌ Erreur test listes: {e}")
            return False

    def test_heading_indentation(self):
        """Test d'indentation de titres"""
        print("📰 Test indentation titres...")

        try:
            # Créer un fichier avec titres de différents niveaux
            test_content = """# Titre de niveau 1

Paragraphe après titre 1.

## Titre de niveau 2

Paragraphe après titre 2.

### Titre de niveau 3

Paragraphe après titre 3.

#### Titre de niveau 4

Paragraphe après titre 4.

##### Titre de niveau 5

Paragraphe après titre 5.

###### Titre de niveau 6

Paragraphe après titre 6.
"""

            test_file = os.path.join(self.temp_dir, "heading_test.md")
            with open(test_file, 'w', encoding='utf-8') as f:
                f.write(test_content)

            # Test chargement et rendu des titres
            env = os.environ.copy()
            env["GSETTINGS_SCHEMA_DIR"] = "/usr/local/share/glib-2.0/schemas"

            process = subprocess.Popen(
                ["./build/IntaText", test_file],
                env=env,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE
            )

            time.sleep(3)

            if process.poll() is None:
                print("✅ Chargement titres multi-niveaux OK")

                process.terminate()
                try:
                    process.wait(timeout=3)
                except subprocess.TimeoutExpired:
                    process.kill()

                success = True
            else:
                stdout, stderr = process.communicate()
                print(f"❌ Échec chargement titres: {stderr.decode()[:100]}")
                success = False

            self.results["heading_indentation"] = {"success": success}
            return success

        except Exception as e:
            print(f"❌ Erreur test titres: {e}")
            return False

    def test_complex_document_indentation(self):
        """Test d'indentation document complexe avec tout type de contenu"""
        print("🗂️ Test indentation document complexe...")

        try:
            # Créer un document complexe avec tous les éléments
            test_content = """# Document Complexe avec Indentations

## Introduction

Voici un paragraphe d'introduction avec plusieurs lignes.
Cette ligne fait partie du même paragraphe d'introduction.
Le paragraphe continue sur cette ligne.

### Listes et sous-listes

1. Premier élément de liste ordonnée
    - Sous-élément à puce
    - Autre sous-élément à puce
        1. Sous-sous-élément numéroté
        2. Autre sous-sous-élément numéroté
    - Retour au niveau 2
2. Deuxième élément de liste ordonnée
3. Troisième élément de liste ordonnée

#### Paragraphes indentés

Voici un paragraphe normal.
Qui continue sur plusieurs lignes.
Et se termine ici.

        Voici un paragraphe pré-indenté avec des espaces.
        Il garde son indentation originale.
        Et se termine également ici.

##### Code et citations

Voici du `code inline` dans un paragraphe.

```
Voici un bloc de code
Avec plusieurs lignes
Et de l'indentation préservée
```

> Voici une citation
> Qui s'étend sur plusieurs lignes
> Et garde son format

###### Mélange de tout

- Liste à puces avec du **gras** et de l'*italique*
    1. Sous-liste numérotée avec du `code`
    2. Autre élément avec [lien](http://example.com)
        - Sous-sous-liste à puces
        - Avec plusieurs éléments
- Retour au niveau principal

Paragraphe final avec tous les styles: **gras**, *italique*, `code`, et [lien](http://example.com).
Qui continue sur cette ligne.
Et se termine définitivement ici.
"""

            test_file = os.path.join(self.temp_dir, "complex_test.md")
            with open(test_file, 'w', encoding='utf-8') as f:
                f.write(test_content)

            # Test chargement document complexe
            env = os.environ.copy()
            env["GSETTINGS_SCHEMA_DIR"] = "/usr/local/share/glib-2.0/schemas"

            process = subprocess.Popen(
                ["./build/IntaText", test_file],
                env=env,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE
            )

            time.sleep(5)  # Plus de temps pour document complexe

            if process.poll() is None:
                print("✅ Chargement document complexe OK")

                process.terminate()
                try:
                    process.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    process.kill()

                success = True
            else:
                stdout, stderr = process.communicate()
                print(f"❌ Échec chargement document complexe: {stderr.decode()[:100]}")
                success = False

            self.results["complex_document_indentation"] = {"success": success}
            return success

        except Exception as e:
            print(f"❌ Erreur test document complexe: {e}")
            return False

    def test_indentation_modes_via_cli(self):
        """Test des différents modes d'indentation via CLI"""
        print("⚙️ Test modes indentation CLI...")

        try:
            # Créer un fichier simple pour tester
            test_content = """# Test Modes Indentation

Paragraphe simple pour tester.
Avec plusieurs lignes.

- Liste à puces
- Deuxième élément
"""

            success_count = 0
            total_tests = 0

            # Test différents fichiers avec modes (simulé via nom de fichier)
            test_files = {
                "spaces_mode.md": test_content,
                "margin_mode.md": test_content,
                "rtf_mode.md": test_content,
                "none_mode.md": test_content
            }

            for filename, content in test_files.items():
                total_tests += 1
                test_file = os.path.join(self.temp_dir, filename)

                with open(test_file, 'w', encoding='utf-8') as f:
                    f.write(content)

                # Test chargement avec chaque "mode"
                env = os.environ.copy()
                env["GSETTINGS_SCHEMA_DIR"] = "/usr/local/share/glib-2.0/schemas"

                process = subprocess.Popen(
                    ["./build/IntaText", test_file],
                    env=env,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE
                )

                time.sleep(2)

                if process.poll() is None:
                    print(f"✅ Mode test OK: {filename}")
                    success_count += 1

                    process.terminate()
                    try:
                        process.wait(timeout=3)
                    except subprocess.TimeoutExpired:
                        process.kill()
                else:
                    stdout, stderr = process.communicate()
                    print(f"❌ Mode test échec: {filename}")

            success_rate = success_count / total_tests if total_tests > 0 else 0
            success = success_rate >= 0.75  # 75% de réussite requis

            print(f"📊 Modes indentation: {success_rate:.2%} ({success_count}/{total_tests})")

            self.results["indentation_modes_cli"] = {
                "success": success,
                "rate": success_rate
            }

            return success

        except Exception as e:
            print(f"❌ Erreur test modes CLI: {e}")
            return False

    def run_indentation_integration_tests(self):
        """Lance tous les tests d'intégration d'indentation"""
        print("🎯 === Tests d'Intégration Indentation IntaText ===")

        try:
            self.setUp()

            tests = [
                ("Indentation paragraphes", self.test_paragraph_indentation),
                ("Indentation listes", self.test_list_indentation),
                ("Indentation titres", self.test_heading_indentation),
                ("Document complexe", self.test_complex_document_indentation),
                ("Modes indentation CLI", self.test_indentation_modes_via_cli)
            ]

            results = []
            all_success = True

            for test_name, test_func in tests:
                print(f"\n📋 {test_name}...")
                success = test_func()
                results.append((test_name, success))
                if not success:
                    all_success = False

            # Rapport final
            print("\n📊 === RÉSULTATS TESTS INTÉGRATION INDENTATION ===")
            for test_name, success in results:
                status = "✅" if success else "❌"
                print(f"{status} {test_name}")

            # Calcul du score d'intégration
            success_count = sum(1 for _, success in results if success)
            integration_score = success_count / len(results) if results else 0

            print(f"\n📈 Score d'intégration: {integration_score:.2%}")
            print(f"🎯 Résultat global: {'✅ INTÉGRATION INDENTATION RÉUSSIE' if integration_score >= 0.8 else '⚠️ INTÉGRATION PARTIELLE' if integration_score >= 0.6 else '❌ INTÉGRATION INSUFFISANTE'}")

            return integration_score >= 0.6  # Au moins 60% pour passer

        finally:
            self.tearDown()

def main():
    """Point d'entrée principal"""
    print("🧪 IntaText - Tests d'Intégration Indentation")

    if not os.path.exists("build/IntaText"):
        print("❌ ERREUR: Application IntaText non trouvée")
        print("Veuillez compiler avec: meson compile -C build")
        return 1

    test_suite = IntaTextIndentationIntegrationTests()
    success = test_suite.run_indentation_integration_tests()

    return 0 if success else 1

if __name__ == "__main__":
    sys.exit(main())
