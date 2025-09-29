#!/usr/bin/env python3
"""
Tests spécialisés pour la gestion d'erreurs et cas limites
Teste: fichiers corrompus, permissions, limites système, récupération d'erreurs
"""

import sys
import subprocess
import os
import tempfile
import time
import stat
from pathlib import Path

class IntaTextErrorHandlingTests:
    """Tests pour la gestion d'erreurs et robustesse"""

    def __init__(self):
        self.temp_dir = None
        self.results = {}

    def setUp(self):
        """Prépare l'environnement de test"""
        print("🔧 Préparation des tests de gestion d'erreurs...")
        self.temp_dir = tempfile.mkdtemp(prefix="intatext_error_test_")
        print(f"📁 Dossier temporaire: {self.temp_dir}")

    def tearDown(self):
        """Nettoie l'environnement"""
        if self.temp_dir and os.path.exists(self.temp_dir):
            # Restaurer les permissions avant suppression
            try:
                for root, dirs, files in os.walk(self.temp_dir):
                    for d in dirs:
                        os.chmod(os.path.join(root, d), 0o755)
                    for f in files:
                        os.chmod(os.path.join(root, f), 0o644)
            except:
                pass

            import shutil
            shutil.rmtree(self.temp_dir, ignore_errors=True)

    def test_corrupted_files(self):
        """Test avec fichiers corrompus ou invalides"""
        print("🗂️ Test fichiers corrompus...")

        try:
            corrupted_files = {
                "binary.md": b"\x00\x01\x02\x03\xFF\xFE\xFD\xFC",  # Données binaires
                "incomplete.md": "# Titre\n\n**gras non fermé",  # Markdown invalide
                "huge_line.md": "# " + "x" * 100000,  # Ligne très longue
                "encoding.md": "# Titre\nContenu avec émoticôns 🚀 et caractères spéciaux àéîôù",
                "mixed_encoding.md": "# Titre\n" + "\x80\x81\x82",  # Encodage mixte
                "empty.md": "",  # Fichier vide
                "only_spaces.md": "   \n\n   \t  \n",  # Seulement espaces
            }

            success_count = 0
            total_tests = len(corrupted_files)

            for filename, content in corrupted_files.items():
                file_path = os.path.join(self.temp_dir, filename)

                # Créer le fichier corrompu
                mode = 'wb' if isinstance(content, bytes) else 'w'
                encoding = None if isinstance(content, bytes) else 'utf-8'

                try:
                    with open(file_path, mode, encoding=encoding, errors='ignore') as f:
                        f.write(content)
                except:
                    # Si on ne peut même pas créer le fichier, l'ignorer
                    continue

                # Tester le chargement avec IntaText
                env = os.environ.copy()
                env["GSETTINGS_SCHEMA_DIR"] = "/usr/local/share/glib-2.0/schemas"

                try:
                    process = subprocess.Popen(
                        ["./build/IntaText", file_path],
                        env=env,
                        stdout=subprocess.PIPE,
                        stderr=subprocess.PIPE
                    )

                    time.sleep(2)  # Laisser le temps de démarrer/planter

                    if process.poll() is None:
                        # L'application tourne encore = récupération réussie
                        print(f"✅ Récupération OK: {filename}")
                        success_count += 1

                        process.terminate()
                        try:
                            process.wait(timeout=3)
                        except subprocess.TimeoutExpired:
                            process.kill()
                    else:
                        # L'application s'est arrêtée
                        stdout, stderr = process.communicate()
                        print(f"❌ Crash sur: {filename}")
                        if stderr:
                            print(f"   Erreur: {stderr.decode()[:100]}...")

                except Exception as e:
                    print(f"❌ Erreur test {filename}: {e}")

            success_rate = success_count / total_tests if total_tests > 0 else 0
            success = success_rate >= 0.7  # 70% de réussite acceptable

            print(f"📊 Taux de récupération: {success_rate:.2%} ({success_count}/{total_tests})")

            self.results["corrupted_files"] = {
                "success": success,
                "rate": success_rate
            }

            return success

        except Exception as e:
            print(f"❌ Erreur test fichiers corrompus: {e}")
            return False

    def test_permission_errors(self):
        """Test avec problèmes de permissions"""
        print("🔒 Test erreurs de permissions...")

        try:
            # Créer des fichiers avec différents problèmes de permissions
            test_files = {
                "readonly.md": "# Fichier lecture seule",
                "noread.md": "# Fichier sans lecture",
                "protected.md": "# Fichier protégé"
            }

            success_count = 0
            total_tests = 0

            for filename, content in test_files.items():
                file_path = os.path.join(self.temp_dir, filename)

                # Créer le fichier
                with open(file_path, 'w', encoding='utf-8') as f:
                    f.write(content)

                # Modifier les permissions selon le test
                if filename == "readonly.md":
                    os.chmod(file_path, stat.S_IRUSR)  # Lecture seule
                elif filename == "noread.md":
                    os.chmod(file_path, stat.S_IWUSR)  # Écriture seule (pas de lecture)
                elif filename == "protected.md":
                    os.chmod(file_path, 0o000)  # Aucune permission

                total_tests += 1

                # Tester le chargement
                env = os.environ.copy()
                env["GSETTINGS_SCHEMA_DIR"] = "/usr/local/share/glib-2.0/schemas"

                try:
                    process = subprocess.Popen(
                        ["./build/IntaText", file_path],
                        env=env,
                        stdout=subprocess.PIPE,
                        stderr=subprocess.PIPE
                    )

                    time.sleep(2)

                    if process.poll() is None:
                        # L'application gère l'erreur de permission
                        print(f"✅ Gestion permission OK: {filename}")
                        success_count += 1

                        process.terminate()
                        try:
                            process.wait(timeout=3)
                        except subprocess.TimeoutExpired:
                            process.kill()
                    else:
                        stdout, stderr = process.communicate()
                        # Acceptable si l'erreur est gérée proprement
                        if "permission" in stderr.decode().lower() or "access" in stderr.decode().lower():
                            print(f"✅ Erreur permission gérée: {filename}")
                            success_count += 1
                        else:
                            print(f"❌ Crash inattendu: {filename}")

                except Exception as e:
                    print(f"❌ Erreur test permission {filename}: {e}")

                # Restaurer les permissions pour le nettoyage
                try:
                    os.chmod(file_path, 0o644)
                except:
                    pass

            success_rate = success_count / total_tests if total_tests > 0 else 0
            success = success_rate >= 0.6  # 60% acceptable pour permissions

            print(f"📊 Gestion permissions: {success_rate:.2%}")

            self.results["permission_errors"] = {
                "success": success,
                "rate": success_rate
            }

            return success

        except Exception as e:
            print(f"❌ Erreur test permissions: {e}")
            return False

    def test_resource_limits(self):
        """Test avec limites de ressources"""
        print("💾 Test limites ressources...")

        try:
            success_count = 0
            total_tests = 0

            # Test 1: Fichier très volumineux
            try:
                huge_content = "# Fichier énorme\n\n" + "Contenu répété. " * 100000
                huge_file = os.path.join(self.temp_dir, "huge.md")

                with open(huge_file, 'w', encoding='utf-8') as f:
                    f.write(huge_content)

                file_size = os.path.getsize(huge_file)
                print(f"📏 Fichier test: {file_size / (1024*1024):.1f} MB")

                total_tests += 1

                # Tester avec timeout plus long
                env = os.environ.copy()
                env["GSETTINGS_SCHEMA_DIR"] = "/usr/local/share/glib-2.0/schemas"

                process = subprocess.Popen(
                    ["./build/IntaText", huge_file],
                    env=env,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE
                )

                time.sleep(5)  # Plus de temps pour gros fichier

                if process.poll() is None:
                    print("✅ Gestion gros fichier OK")
                    success_count += 1

                    process.terminate()
                    try:
                        process.wait(timeout=5)
                    except subprocess.TimeoutExpired:
                        process.kill()
                else:
                    stdout, stderr = process.communicate()
                    if "memory" in stderr.decode().lower() or "size" in stderr.decode().lower():
                        print("✅ Limite mémoire gérée proprement")
                        success_count += 1
                    else:
                        print("❌ Échec gros fichier")

            except Exception as e:
                print(f"⚠️ Test gros fichier ignoré: {e}")

            # Test 2: Nombreux fichiers simultanés
            try:
                total_tests += 1

                # Créer plusieurs petits fichiers
                multi_files = []
                for i in range(5):
                    small_file = os.path.join(self.temp_dir, f"multi_{i}.md")
                    with open(small_file, 'w') as f:
                        f.write(f"# Fichier {i}\nContenu {i}")
                    multi_files.append(small_file)

                # Tenter d'ouvrir plusieurs fichiers
                env = os.environ.copy()
                env["GSETTINGS_SCHEMA_DIR"] = "/usr/local/share/glib-2.0/schemas"

                process = subprocess.Popen(
                    ["./build/IntaText"] + multi_files[:3],  # 3 fichiers max
                    env=env,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE
                )

                time.sleep(3)

                if process.poll() is None:
                    print("✅ Gestion multi-fichiers OK")
                    success_count += 1

                    process.terminate()
                    try:
                        process.wait(timeout=3)
                    except subprocess.TimeoutExpired:
                        process.kill()
                else:
                    print("❌ Échec multi-fichiers")

            except Exception as e:
                print(f"⚠️ Test multi-fichiers ignoré: {e}")

            success_rate = success_count / total_tests if total_tests > 0 else 1.0
            success = success_rate >= 0.5  # 50% acceptable pour limites

            print(f"📊 Gestion limites: {success_rate:.2%}")

            self.results["resource_limits"] = {
                "success": success,
                "rate": success_rate
            }

            return success

        except Exception as e:
            print(f"❌ Erreur test limites: {e}")
            return False

    def test_recovery_scenarios(self):
        """Test de scénarios de récupération"""
        print("🔄 Test scénarios récupération...")

        try:
            success_count = 0
            total_tests = 0

            # Scénario 1: Redémarrage après crash simulé
            try:
                total_tests += 1

                test_file = os.path.join(self.temp_dir, "recovery.md")
                with open(test_file, 'w') as f:
                    f.write("# Test récupération\nContenu pour test.")

                env = os.environ.copy()
                env["GSETTINGS_SCHEMA_DIR"] = "/usr/local/share/glib-2.0/schemas"

                # Premier démarrage
                process1 = subprocess.Popen(
                    ["./build/IntaText", test_file],
                    env=env,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE
                )

                time.sleep(1)

                if process1.poll() is None:
                    # Tuer brutalement (simuler crash)
                    process1.kill()
                    process1.wait()

                    # Redémarrage immédiat
                    process2 = subprocess.Popen(
                        ["./build/IntaText", test_file],
                        env=env,
                        stdout=subprocess.PIPE,
                        stderr=subprocess.PIPE
                    )

                    time.sleep(2)

                    if process2.poll() is None:
                        print("✅ Récupération après crash OK")
                        success_count += 1

                        process2.terminate()
                        try:
                            process2.wait(timeout=3)
                        except subprocess.TimeoutExpired:
                            process2.kill()
                    else:
                        print("❌ Échec récupération crash")
                else:
                    print("❌ Démarrage initial échoué")

            except Exception as e:
                print(f"⚠️ Test récupération crash ignoré: {e}")

            # Scénario 2: Résilience aux interruptions
            try:
                total_tests += 1

                test_file = os.path.join(self.temp_dir, "interrupt.md")
                with open(test_file, 'w') as f:
                    f.write("# Test interruption\nContenu test.")

                # Démarrage avec interruption rapide
                process = subprocess.Popen(
                    ["./build/IntaText", test_file],
                    env=env,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE
                )

                time.sleep(0.5)  # Interruption très rapide
                process.terminate()

                try:
                    stdout, stderr = process.communicate(timeout=3)

                    # Pas de core dump ou erreur grave
                    if process.returncode in [0, -15, -2]:  # Terminaison propre
                        print("✅ Interruption gérée proprement")
                        success_count += 1
                    else:
                        print(f"❌ Interruption mal gérée: {process.returncode}")

                except subprocess.TimeoutExpired:
                    process.kill()
                    print("❌ Blocage sur interruption")

            except Exception as e:
                print(f"⚠️ Test interruption ignoré: {e}")

            success_rate = success_count / total_tests if total_tests > 0 else 1.0
            success = success_rate >= 0.5

            print(f"📊 Scénarios récupération: {success_rate:.2%}")

            self.results["recovery_scenarios"] = {
                "success": success,
                "rate": success_rate
            }

            return success

        except Exception as e:
            print(f"❌ Erreur test récupération: {e}")
            return False

    def run_error_handling_tests(self):
        """Lance tous les tests de gestion d'erreurs"""
        print("🎯 === Tests de Gestion d'Erreurs IntaText ===")

        try:
            self.setUp()

            tests = [
                ("Fichiers corrompus", self.test_corrupted_files),
                ("Erreurs permissions", self.test_permission_errors),
                ("Limites ressources", self.test_resource_limits),
                ("Scénarios récupération", self.test_recovery_scenarios)
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
            print("\n📊 === RÉSULTATS TESTS GESTION D'ERREURS ===")
            for test_name, success in results:
                status = "✅" if success else "❌"
                print(f"{status} {test_name}")

            # Calcul du score de robustesse
            success_count = sum(1 for _, success in results if success)
            robustness_score = success_count / len(results) if results else 0

            print(f"\n🛡️ Score de robustesse: {robustness_score:.2%}")
            print(f"🎯 Résultat global: {'✅ APPLICATION ROBUSTE' if robustness_score >= 0.75 else '⚠️ ROBUSTESSE LIMITÉE' if robustness_score >= 0.5 else '❌ ROBUSTESSE INSUFFISANTE'}")

            return robustness_score >= 0.5  # Au moins 50% pour passer

        finally:
            self.tearDown()

def main():
    """Point d'entrée principal"""
    print("🧪 IntaText - Tests de Gestion d'Erreurs")

    if not os.path.exists("build/IntaText"):
        print("❌ ERREUR: Application IntaText non trouvée")
        print("Veuillez compiler avec: meson compile -C build")
        return 1

    test_suite = IntaTextErrorHandlingTests()
    success = test_suite.run_error_handling_tests()

    return 0 if success else 1

if __name__ == "__main__":
    sys.exit(main())
