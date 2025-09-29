#!/usr/bin/env python3
"""
Test automatisé des indentations - IntaText
Module de test complet pour valider les fonctionnalités d'indentation
"""

import os
import sys
import subprocess
import tempfile
import difflib
import time
import json
from pathlib import Path
from typing import List, Dict, Tuple, Optional

# Configuration des couleurs pour la sortie
class Colors:
    RED = '\033[0;31m'
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    BLUE = '\033[0;34m'
    CYAN = '\033[0;36m'
    MAGENTA = '\033[0;35m'
    WHITE = '\033[1;37m'
    NC = '\033[0m'  # No Color

class IndentationTester:
    """Classe principale pour les tests d'indentation"""

    def __init__(self, intatext_path: str = None):
        self.test_dir = Path(__file__).parent
        self.samples_dir = self.test_dir / "samples"
        self.temp_dir = Path(tempfile.mkdtemp(prefix="intatext_indent_"))
        self.results = []
        self.passed_tests = 0
        self.failed_tests = 0

        # Chemin vers l'exécutable IntaText
        if intatext_path:
            self.intatext_path = Path(intatext_path)
        else:
            self.intatext_path = self.test_dir.parent / "build" / "IntaText"

        # Configuration des tests
        self.test_config = {
            "indent_size": 4,
            "use_tabs": False,
            "preserve_existing": False,
            "indent_empty_lines": False
        }

    def log(self, message: str, color: str = Colors.NC):
        """Affiche un message avec couleur"""
        print(f"{color}{message}{Colors.NC}")

    def log_info(self, message: str):
        self.log(f"ℹ️  {message}", Colors.BLUE)

    def log_success(self, message: str):
        self.log(f"✅ {message}", Colors.GREEN)

    def log_warning(self, message: str):
        self.log(f"⚠️  {message}", Colors.YELLOW)

    def log_error(self, message: str):
        self.log(f"❌ {message}", Colors.RED)

    def log_test(self, message: str):
        self.log(f"🧪 {message}", Colors.CYAN)

    def create_test_file(self, content: str, filename: str) -> Path:
        """Crée un fichier de test temporaire"""
        test_file = self.temp_dir / filename
        test_file.write_text(content, encoding='utf-8')
        return test_file

    def simulate_indentation(self, input_file: Path, output_file: Path,
                           indent_level: int = 1) -> bool:
        """
        Simule l'opération d'indentation
        TODO: Remplacer par l'appel réel à IntaText API
        """
        try:
            with open(input_file, 'r', encoding='utf-8') as f:
                lines = f.readlines()

            indent_str = " " * (self.test_config["indent_size"] * indent_level)
            indented_lines = []

            for line in lines:
                # Ne pas indenter les lignes vides sauf si configuré
                if line.strip() == "" and not self.test_config["indent_empty_lines"]:
                    indented_lines.append(line)
                else:
                    # Ajouter l'indentation au début de la ligne
                    if line.strip():  # Ligne non vide
                        indented_lines.append(indent_str + line.lstrip())
                    else:
                        indented_lines.append(line)

            with open(output_file, 'w', encoding='utf-8') as f:
                f.writelines(indented_lines)

            return True

        except Exception as e:
            self.log_error(f"Erreur lors de l'indentation: {e}")
            return False

    def compare_files(self, file1: Path, file2: Path) -> Tuple[bool, str]:
        """Compare deux fichiers et retourne le résultat + diff"""
        try:
            with open(file1, 'r', encoding='utf-8') as f1:
                content1 = f1.readlines()
            with open(file2, 'r', encoding='utf-8') as f2:
                content2 = f2.readlines()

            if content1 == content2:
                return True, ""

            # Générer le diff
            diff = list(difflib.unified_diff(
                content1, content2,
                fromfile=str(file1),
                tofile=str(file2),
                lineterm=''
            ))

            return False, '\n'.join(diff)

        except Exception as e:
            return False, f"Erreur lors de la comparaison: {e}"

    def test_paragraph_indentation(self) -> bool:
        """Test d'indentation de paragraphes simples"""
        self.log_test("Test 1: Indentation de paragraphes simples")

        test_content = """Premier paragraphe sur une ligne.

Deuxième paragraphe avec plusieurs lignes.
Cette ligne fait partie du même paragraphe.
Dernière ligne du paragraphe.

Troisième paragraphe court."""

        expected_content = """    Premier paragraphe sur une ligne.

    Deuxième paragraphe avec plusieurs lignes.
    Cette ligne fait partie du même paragraphe.
    Dernière ligne du paragraphe.

    Troisième paragraphe court."""

        input_file = self.create_test_file(test_content, "test_paragraphs.md")
        output_file = self.temp_dir / "output_paragraphs.md"
        expected_file = self.create_test_file(expected_content, "expected_paragraphs.md")

        if self.simulate_indentation(input_file, output_file):
            is_equal, diff = self.compare_files(output_file, expected_file)
            if is_equal:
                self.log_success("✓ Test paragraphes réussi")
                self.passed_tests += 1
                return True
            else:
                self.log_error("✗ Test paragraphes échoué - différences trouvées")
                self.log_error(f"Diff:\n{diff}")
                self.failed_tests += 1
                return False
        else:
            self.log_error("✗ Test paragraphes échoué - erreur d'indentation")
            self.failed_tests += 1
            return False

    def test_list_indentation(self) -> bool:
        """Test d'indentation de listes"""
        self.log_test("Test 2: Indentation de listes")

        test_content = """# Liste numérotée

1. Premier élément
2. Deuxième élément
3. Troisième élément

# Liste à puces

- Élément A
- Élément B
- Élément C"""

        expected_content = """    # Liste numérotée

    1. Premier élément
    2. Deuxième élément
    3. Troisième élément

    # Liste à puces

    - Élément A
    - Élément B
    - Élément C"""

        input_file = self.create_test_file(test_content, "test_lists.md")
        output_file = self.temp_dir / "output_lists.md"
        expected_file = self.create_test_file(expected_content, "expected_lists.md")

        if self.simulate_indentation(input_file, output_file):
            is_equal, diff = self.compare_files(output_file, expected_file)
            if is_equal:
                self.log_success("✓ Test listes réussi")
                self.passed_tests += 1
                return True
            else:
                self.log_error("✗ Test listes échoué")
                self.failed_tests += 1
                return False
        else:
            self.log_error("✗ Test listes échoué - erreur d'indentation")
            self.failed_tests += 1
            return False

    def test_code_blocks(self) -> bool:
        """Test d'indentation de blocs de code"""
        self.log_test("Test 3: Indentation de blocs de code")

        test_content = """Voici du code Python :

```python
def hello():
    print("Hello World")
    return True
```

Code inline `var x = 10;` dans le texte."""

        expected_content = """    Voici du code Python :

    ```python
    def hello():
        print("Hello World")
        return True
    ```

    Code inline `var x = 10;` dans le texte."""

        input_file = self.create_test_file(test_content, "test_code.md")
        output_file = self.temp_dir / "output_code.md"
        expected_file = self.create_test_file(expected_content, "expected_code.md")

        if self.simulate_indentation(input_file, output_file):
            is_equal, diff = self.compare_files(output_file, expected_file)
            if is_equal:
                self.log_success("✓ Test code réussi")
                self.passed_tests += 1
                return True
            else:
                self.log_error("✗ Test code échoué")
                self.failed_tests += 1
                return False
        else:
            self.log_error("✗ Test code échoué - erreur d'indentation")
            self.failed_tests += 1
            return False

    def test_sample_files(self) -> bool:
        """Test d'indentation des fichiers d'échantillons"""
        self.log_test("Test 4: Indentation des fichiers d'échantillons")

        sample_files = list(self.samples_dir.glob("test_indent_*.md"))
        if not sample_files:
            # Essayer avec le chemin relatif
            sample_files = list(Path("samples").glob("test_indent_*.md"))

        if not sample_files:
            self.log_warning("Aucun fichier d'échantillon trouvé")
            return True

        success_count = 0
        total_count = len(sample_files)

        for sample_file in sample_files:
            self.log_info(f"Test du fichier: {sample_file.name}")

            output_file = self.temp_dir / f"output_{sample_file.name}"

            if self.simulate_indentation(sample_file, output_file):
                # Vérifier que le fichier de sortie n'est pas vide
                if output_file.stat().st_size > 0:
                    success_count += 1
                    self.log_success(f"  ✓ {sample_file.name} traité avec succès")
                else:
                    self.log_error(f"  ✗ {sample_file.name} - fichier de sortie vide")
            else:
                self.log_error(f"  ✗ {sample_file.name} - erreur de traitement")

        self.log_info(f"Fichiers d'échantillons: {success_count}/{total_count} réussis")

        if success_count == total_count:
            self.passed_tests += 1
            return True
        else:
            self.failed_tests += 1
            return False

    def test_performance(self) -> bool:
        """Test de performance d'indentation"""
        self.log_test("Test 5: Performance d'indentation")

        # Créer un gros fichier de test
        large_content = ""
        for i in range(1000):
            large_content += f"Ligne {i+1} avec du contenu pour tester la performance.\n"
            if (i + 1) % 10 == 0:
                large_content += "\n"

        input_file = self.create_test_file(large_content, "large_test.md")
        output_file = self.temp_dir / "large_output.md"

        start_time = time.time()

        if self.simulate_indentation(input_file, output_file):
            end_time = time.time()
            duration = end_time - start_time

            self.log_success(f"✓ Test de performance réussi ({duration:.3f}s)")
            self.passed_tests += 1
            return True
        else:
            self.log_error("✗ Test de performance échoué")
            self.failed_tests += 1
            return False

    def test_edge_cases(self) -> bool:
        """Test des cas limites"""
        self.log_test("Test 6: Cas limites")

        test_cases = [
            ("Fichier vide", ""),
            ("Une seule ligne", "Seule ligne de texte"),
            ("Lignes vides multiples", "\n\n\nContenu\n\n\n"),
            ("Espaces en fin de ligne", "Ligne avec espaces   \n"),
            ("Caractères Unicode", "Texte avec émojis 🎉 et accents àáâãä"),
        ]

        success_count = 0

        for test_name, content in test_cases:
            self.log_info(f"  Test: {test_name}")

            input_file = self.create_test_file(content, f"edge_case_{success_count}.md")
            output_file = self.temp_dir / f"edge_output_{success_count}.md"

            if self.simulate_indentation(input_file, output_file):
                success_count += 1
                self.log_success(f"    ✓ {test_name} réussi")
            else:
                self.log_error(f"    ✗ {test_name} échoué")

        if success_count == len(test_cases):
            self.log_success("✓ Tous les cas limites réussis")
            self.passed_tests += 1
            return True
        else:
            self.log_error(f"✗ Cas limites échoués ({success_count}/{len(test_cases)})")
            self.failed_tests += 1
            return False

    def generate_report(self):
        """Génère le rapport final"""
        total_tests = self.passed_tests + self.failed_tests

        print("\n" + "="*50)
        print("  RAPPORT DE TEST - INDENTATIONS")
        print("="*50)
        print()
        print(f"Tests exécutés: {total_tests}")
        self.log(f"Tests réussis:  {self.passed_tests}", Colors.GREEN)
        self.log(f"Tests échoués:  {self.failed_tests}", Colors.RED)
        print()

        # Sauvegarder le rapport JSON
        report_data = {
            "timestamp": time.time(),
            "total_tests": total_tests,
            "passed_tests": self.passed_tests,
            "failed_tests": self.failed_tests,
            "success_rate": (self.passed_tests / total_tests * 100) if total_tests > 0 else 0,
            "config": self.test_config
        }

        report_file = self.temp_dir / "indent_test_report.json"
        with open(report_file, 'w', encoding='utf-8') as f:
            json.dump(report_data, f, indent=2)

        print(f"Rapport JSON sauvegardé: {report_file}")

        if self.failed_tests == 0:
            self.log("🎉 TOUS LES TESTS SONT PASSÉS !", Colors.GREEN)
            return True
        else:
            self.log("❌ CERTAINS TESTS ONT ÉCHOUÉ", Colors.RED)
            return False

    def cleanup(self):
        """Nettoie les fichiers temporaires"""
        import shutil
        if self.temp_dir.exists():
            shutil.rmtree(self.temp_dir)

    def run_all_tests(self) -> bool:
        """Exécute tous les tests d'indentation"""
        self.log("="*50, Colors.WHITE)
        self.log("  TRAITEMENT DE TEST - INDENTATIONS", Colors.WHITE)
        self.log("         IntaText Test Suite", Colors.WHITE)
        self.log("="*50, Colors.WHITE)
        print()

        self.log_info("Initialisation de l'environnement de test")
        self.log_info(f"Répertoire temporaire: {self.temp_dir}")
        self.log_info(f"Configuration: {self.test_config}")
        print()

        try:
            # Exécution de tous les tests
            self.test_paragraph_indentation()
            self.test_list_indentation()
            self.test_code_blocks()
            self.test_sample_files()
            self.test_performance()
            self.test_edge_cases()

            # Génération du rapport
            success = self.generate_report()

            return success

        except KeyboardInterrupt:
            self.log_warning("Tests interrompus par l'utilisateur")
            return False
        except Exception as e:
            self.log_error(f"Erreur inattendue: {e}")
            return False
        finally:
            self.cleanup()

def main():
    """Fonction principale"""
    import argparse

    parser = argparse.ArgumentParser(description="Test d'indentation pour IntaText")
    parser.add_argument("--intatext-path", help="Chemin vers l'exécutable IntaText")
    parser.add_argument("--indent-size", type=int, default=4, help="Taille de l'indentation")
    parser.add_argument("--use-tabs", action="store_true", help="Utiliser des tabulations")
    parser.add_argument("--verbose", "-v", action="store_true", help="Mode verbeux")

    args = parser.parse_args()

    # Créer et configurer le testeur
    tester = IndentationTester(args.intatext_path)
    tester.test_config["indent_size"] = args.indent_size
    tester.test_config["use_tabs"] = args.use_tabs

    # Exécuter les tests
    success = tester.run_all_tests()

    # Code de sortie
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()
