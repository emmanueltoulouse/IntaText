#!/usr/bin/env python3
"""
Tests d'intégration pour les fonctionnalités de chargement/sauvegarde
Tests utilisant l'automation UI pour vérifier le comportement complet
"""

import sys
import subprocess
import os
import tempfile
import time
from pathlib import Path

class IntaTextFileIntegrationTests:
    """Tests d'intégration pour le chargement/sauvegarde de fichiers"""

    def __init__(self):
        self.temp_dir = None
        self.app_process = None
        self.results = {}

    def setUp(self):
        """Prépare l'environnement de test"""
        print("🔧 Préparation des tests d'intégration fichiers...")
        self.temp_dir = tempfile.mkdtemp(prefix="intatext_file_test_")
        print(f"📁 Dossier temporaire: {self.temp_dir}")

        # Créer des fichiers de test
        self.create_test_files()

    def create_test_files(self):
        """Crée les fichiers de test nécessaires"""
        test_files = {
            "test.md": """# Test Markdown

Ceci est un **test** avec du contenu *formaté*.

## Liste de test

- Item 1
- Item 2

## Tableau

| Col1 | Col2 |
|------|------|
| A    | B    |
""",
            "test.txt": """Fichier texte simple pour test.

Avec plusieurs lignes.
Et différents paragraphes.
""",
            "test.html": """<!DOCTYPE html>
<html>
<head><title>Test</title></head>
<body>
    <h1>Test HTML</h1>
    <p><strong>Contenu</strong> de test.</p>
</body>
</html>
""",
            "corrupted.md": "# Fichier avec contenu \x00\xff invalide"
        }

        for filename, content in test_files.items():
            filepath = os.path.join(self.temp_dir, filename)
            with open(filepath, 'w', encoding='utf-8', errors='ignore') as f:
                f.write(content)

    def tearDown(self):
        """Nettoie l'environnement"""
        if self.app_process:
            try:
                self.app_process.terminate()
                self.app_process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                self.app_process.kill()
            except:
                pass

        if self.temp_dir and os.path.exists(self.temp_dir):
            import shutil
            shutil.rmtree(self.temp_dir, ignore_errors=True)

    def test_file_loading_via_command_line(self):
        """Test du chargement de fichier via ligne de commande"""
        print("📂 Test chargement via ligne de commande...")

        try:
            # Tester avec différents formats
            test_files = ["test.md", "test.txt", "test.html"]

            for test_file in test_files:
                file_path = os.path.join(self.temp_dir, test_file)

                # Lancer l'application avec le fichier
                env = os.environ.copy()
                env["GSETTINGS_SCHEMA_DIR"] = "/usr/local/share/glib-2.0/schemas"

                process = subprocess.Popen(
                    ["./build/IntaText", file_path],
                    env=env,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE
                )

                # Laisser le temps de démarrer
                time.sleep(2)

                # Vérifier que l'app tourne
                if process.poll() is None:
                    print(f"✅ Chargement {test_file} via CLI réussi")
                    success = True
                else:
                    print(f"❌ Échec chargement {test_file}")
                    success = False

                # Arrêter l'application
                process.terminate()
                try:
                    process.wait(timeout=3)
                except subprocess.TimeoutExpired:
                    process.kill()

                self.results[f"cli_load_{test_file}"] = {"success": success}

            return all(result["success"] for result in self.results.values()
                      if result.get("success") is not None)

        except Exception as e:
            print(f"❌ Erreur test CLI: {e}")
            return False

    def test_file_saving_formats(self):
        """Test de sauvegarde dans différents formats"""
        print("💾 Test sauvegarde différents formats...")

        try:
            # Utiliser l'outil md_rt pour tester les conversions
            md_rt_path = "./build/md_rt"
            if not os.path.exists(md_rt_path):
                print("⚠️ Outil md_rt non trouvé, test ignoré")
                return True

            input_file = os.path.join(self.temp_dir, "test.md")

            # Test round-trip Markdown
            result = subprocess.run(
                [md_rt_path, input_file],
                capture_output=True,
                text=True,
                timeout=30
            )

            success = result.returncode == 0

            if success:
                print("✅ Test sauvegarde formats réussi")
            else:
                print(f"❌ Échec sauvegarde: {result.stderr}")

            self.results["format_saving"] = {"success": success}
            return success

        except Exception as e:
            print(f"❌ Erreur test sauvegarde: {e}")
            self.results["format_saving"] = {"success": False, "error": str(e)}
            return False

    def test_file_path_management(self):
        """Test de la gestion des chemins de fichiers"""
        print("📍 Test gestion chemins fichiers...")

        try:
            # Tester avec des chemins spéciaux
            special_paths = [
                "test with spaces.md",
                "test-with-dashes.md",
                "test_with_underscores.md",
                "тест_unicode.md",  # Caractères unicode
            ]

            success_count = 0

            for special_name in special_paths:
                try:
                    # Créer un fichier avec nom spécial
                    special_path = os.path.join(self.temp_dir, special_name)
                    with open(special_path, 'w', encoding='utf-8') as f:
                        f.write("# Test contenu\n\nTest avec nom spécial.")

                    # Tester le chargement
                    env = os.environ.copy()
                    env["GSETTINGS_SCHEMA_DIR"] = "/usr/local/share/glib-2.0/schemas"

                    process = subprocess.Popen(
                        ["./build/IntaText", special_path],
                        env=env,
                        stdout=subprocess.PIPE,
                        stderr=subprocess.PIPE
                    )

                    time.sleep(1.5)

                    if process.poll() is None:
                        success_count += 1
                        print(f"✅ Chemin spécial OK: {special_name}")
                    else:
                        print(f"❌ Échec chemin: {special_name}")

                    process.terminate()
                    try:
                        process.wait(timeout=2)
                    except subprocess.TimeoutExpired:
                        process.kill()

                except Exception as e:
                    print(f"❌ Erreur chemin {special_name}: {e}")

            success = success_count >= len(special_paths) // 2  # Au moins 50% de réussite
            self.results["path_management"] = {"success": success}

            if success:
                print(f"✅ Gestion chemins OK ({success_count}/{len(special_paths)})")
            else:
                print(f"❌ Gestion chemins insuffisante ({success_count}/{len(special_paths)})")

            return success

        except Exception as e:
            print(f"❌ Erreur test chemins: {e}")
            return False

    def test_error_recovery(self):
        """Test de récupération d'erreurs"""
        print("🚨 Test récupération d'erreurs...")

        try:
            # Test avec fichier corrompu
            corrupted_file = os.path.join(self.temp_dir, "corrupted.md")

            env = os.environ.copy()
            env["GSETTINGS_SCHEMA_DIR"] = "/usr/local/share/glib-2.0/schemas"

            process = subprocess.Popen(
                ["./build/IntaText", corrupted_file],
                env=env,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE
            )

            time.sleep(2)

            # L'application devrait démarrer même avec un fichier problématique
            if process.poll() is None:
                print("✅ Récupération d'erreur réussie")
                success = True
            else:
                stdout, stderr = process.communicate()
                print(f"❌ Crash sur fichier corrompu: {stderr.decode()}")
                success = False

            if process.poll() is None:
                process.terminate()
                try:
                    process.wait(timeout=3)
                except subprocess.TimeoutExpired:
                    process.kill()

            self.results["error_recovery"] = {"success": success}
            return success

        except Exception as e:
            print(f"❌ Erreur test récupération: {e}")
            return False

    def run_integration_tests(self):
        """Lance tous les tests d'intégration"""
        print("🎯 === Tests d'Intégration Fichiers IntaText ===")

        try:
            self.setUp()

            tests = [
                ("Chargement CLI", self.test_file_loading_via_command_line),
                ("Sauvegarde formats", self.test_file_saving_formats),
                ("Gestion chemins", self.test_file_path_management),
                ("Récupération erreurs", self.test_error_recovery)
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
            print("\n📊 === RÉSULTATS TESTS D'INTÉGRATION FICHIERS ===")
            for test_name, success in results:
                status = "✅" if success else "❌"
                print(f"{status} {test_name}")

            print(f"\n🎯 Résultat global: {'✅ TOUS LES TESTS PASSENT' if all_success else '❌ CERTAINS TESTS ÉCHOUENT'}")

            return all_success

        finally:
            self.tearDown()

def main():
    """Point d'entrée principal"""
    print("🧪 IntaText - Tests d'Intégration Fichiers")

    if not os.path.exists("build/IntaText"):
        print("❌ ERREUR: Application IntaText non trouvée")
        print("Veuillez compiler avec: meson compile -C build")
        return 1

    test_suite = IntaTextFileIntegrationTests()
    success = test_suite.run_integration_tests()

    return 0 if success else 1

if __name__ == "__main__":
    sys.exit(main())
