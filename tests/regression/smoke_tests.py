#!/usr/bin/env python3
"""
Suite de tests de non-régression pour IntaText
Tests automatisés pour s'assurer qu'aucune fonctionnalité n'est cassée
"""

import sys
import subprocess
import os
import tempfile
import time
from pathlib import Path

class IntaTextRegressionTests:
    """Suite de tests de non-régression pour IntaText"""

    def __init__(self):
        self.temp_dir = None
        self.results = {}

    def setUp(self):
        """Prépare l'environnement de test"""
        print("🔧 Préparation des tests de régression...")
        self.temp_dir = tempfile.mkdtemp(prefix="intatext_regression_")
        print(f"📁 Dossier temporaire: {self.temp_dir}")

    def tearDown(self):
        """Nettoie l'environnement"""
        if self.temp_dir and os.path.exists(self.temp_dir):
            import shutil
            shutil.rmtree(self.temp_dir, ignore_errors=True)

    def test_build_success(self):
        """Test que l'application se compile sans erreur"""
        print("🔨 Test de compilation...")

        try:
            result = subprocess.run(
                ["meson", "compile", "-C", "build"],
                capture_output=True,
                text=True,
                timeout=120
            )

            success = result.returncode == 0
            self.results["build"] = {
                "success": success,
                "stdout": result.stdout,
                "stderr": result.stderr
            }

            if success:
                print("✅ Compilation réussie")
            else:
                print("❌ Échec de compilation")
                print(f"Erreur: {result.stderr}")

            return success

        except subprocess.TimeoutExpired:
            print("❌ Timeout de compilation")
            self.results["build"] = {"success": False, "error": "Timeout"}
            return False
        except Exception as e:
            print(f"❌ Erreur compilation: {e}")
            self.results["build"] = {"success": False, "error": str(e)}
            return False

    def test_unit_tests(self):
        """Test que tous les tests unitaires passent"""
        print("🧪 Exécution des tests unitaires...")

        try:
            result = subprocess.run(
                ["meson", "test", "-C", "build", "--suite", "unit"],
                capture_output=True,
                text=True,
                timeout=60
            )

            success = result.returncode == 0
            self.results["unit_tests"] = {
                "success": success,
                "stdout": result.stdout,
                "stderr": result.stderr
            }

            if success:
                print("✅ Tests unitaires réussis")
            else:
                print("❌ Échec des tests unitaires")
                print(f"Sortie: {result.stdout}")
                print(f"Erreur: {result.stderr}")

            return success

        except subprocess.TimeoutExpired:
            print("❌ Timeout des tests unitaires")
            self.results["unit_tests"] = {"success": False, "error": "Timeout"}
            return False
        except Exception as e:
            print(f"❌ Erreur tests unitaires: {e}")
            self.results["unit_tests"] = {"success": False, "error": str(e)}
            return False

    def test_app_starts(self):
        """Test que l'application démarre sans crash"""
        print("🚀 Test de démarrage de l'application...")

        app_path = "build/IntaText"
        if not os.path.exists(app_path):
            print(f"❌ Exécutable non trouvé: {app_path}")
            self.results["app_start"] = {"success": False, "error": "Exécutable manquant"}
            return False

        try:
            # Démarrer l'app et la tuer rapidement
            env = os.environ.copy()
            env["GSETTINGS_SCHEMA_DIR"] = "/usr/local/share/glib-2.0/schemas"

            process = subprocess.Popen(
                [app_path],
                env=env,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE
            )

            # Laisser démarrer
            time.sleep(3)

            # Tuer proprement
            process.terminate()

            try:
                stdout, stderr = process.communicate(timeout=5)
                returncode = process.returncode
            except subprocess.TimeoutExpired:
                process.kill()
                stdout, stderr = process.communicate()
                returncode = process.returncode

            # L'application a démarré si elle ne s'est pas crashée immédiatement
            success = returncode in [0, -15]  # 0 = sortie normale, -15 = SIGTERM

            self.results["app_start"] = {
                "success": success,
                "returncode": returncode,
                "stdout": stdout.decode() if stdout else "",
                "stderr": stderr.decode() if stderr else ""
            }

            if success:
                print("✅ Application démarre correctement")
            else:
                print(f"❌ Crash au démarrage (code: {returncode})")
                if stderr:
                    print(f"Erreur: {stderr.decode()}")

            return success

        except Exception as e:
            print(f"❌ Erreur test démarrage: {e}")
            self.results["app_start"] = {"success": False, "error": str(e)}
            return False

    def test_markdown_conversion(self):
        """Test basique de conversion Markdown"""
        print("📝 Test de conversion Markdown...")

        try:
            # Créer un fichier Markdown de test
            test_md = os.path.join(self.temp_dir, "test.md")
            with open(test_md, "w") as f:
                f.write("""# Titre de test

Paragraphe normal avec **texte gras** et *italique*.

    Paragraphe indenté

## Sous-titre

- Liste item 1
- Liste item 2
""")

            # Utiliser l'outil de conversion s'il existe
            converter_path = "build/md_rt"
            if os.path.exists(converter_path):
                result = subprocess.run(
                    [converter_path, test_md],
                    capture_output=True,
                    text=True,
                    timeout=30
                )

                success = result.returncode == 0
                self.results["markdown_conversion"] = {
                    "success": success,
                    "stdout": result.stdout,
                    "stderr": result.stderr
                }

                if success:
                    print("✅ Conversion Markdown réussie")
                else:
                    print("❌ Échec conversion Markdown")
                    print(f"Erreur: {result.stderr}")

                return success
            else:
                print("⚠️ Outil de conversion non trouvé, test ignoré")
                self.results["markdown_conversion"] = {"success": True, "skipped": True}
                return True

        except Exception as e:
            print(f"❌ Erreur test conversion: {e}")
            self.results["markdown_conversion"] = {"success": False, "error": str(e)}
            return False

    def run_smoke_tests(self):
        """Lance tous les tests rapides de non-régression"""
        print("🎯 === Tests de Non-Régression IntaText ===")

        try:
            self.setUp()

            tests = [
                ("Compilation", self.test_build_success),
                ("Tests unitaires", self.test_unit_tests),
                ("Démarrage app", self.test_app_starts),
                ("Conversion Markdown", self.test_markdown_conversion)
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
            print("\n📊 === RÉSULTATS DES TESTS DE RÉGRESSION ===")
            for test_name, success in results:
                status = "✅" if success else "❌"
                print(f"{status} {test_name}")

            print(f"\n🎯 Résultat global: {'✅ TOUS LES TESTS PASSENT' if all_success else '❌ CERTAINS TESTS ÉCHOUENT'}")

            if not all_success:
                print("\n🔍 Détails des échecs:")
                for test_name, success in results:
                    if not success and test_name.lower().replace(" ", "_") in self.results:
                        result = self.results[test_name.lower().replace(" ", "_")]
                        if "error" in result:
                            print(f"  {test_name}: {result['error']}")
                        elif "stderr" in result and result["stderr"]:
                            print(f"  {test_name}: {result['stderr'][:200]}...")

            return all_success

        finally:
            self.tearDown()

def main():
    """Point d'entrée principal"""
    print("🧪 IntaText - Tests de Non-Régression")

    if not os.path.exists("build"):
        print("❌ ERREUR: Dossier build/ non trouvé")
        print("Veuillez configurer avec: meson setup build")
        return 1

    test_suite = IntaTextRegressionTests()
    success = test_suite.run_smoke_tests()

    return 0 if success else 1

if __name__ == "__main__":
    sys.exit(main())
