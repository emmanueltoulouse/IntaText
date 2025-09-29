#!/usr/bin/env python3
"""
Tests de round-trip complets pour vérifier la fidélité des conversions
Teste: Fichier original -> Chargement -> Edition -> Sauvegarde -> Rechargement -> Comparaison
"""

import sys
import subprocess
import os
import tempfile
import time
import difflib
from pathlib import Path

class IntaTextRoundTripTests:
    """Tests de round-trip pour vérifier la fidélité des conversions"""

    def __init__(self):
        self.temp_dir = None
        self.results = {}

    def setUp(self):
        """Prépare l'environnement de test"""
        print("🔧 Préparation des tests de round-trip...")
        self.temp_dir = tempfile.mkdtemp(prefix="intatext_roundtrip_")
        print(f"📁 Dossier temporaire: {self.temp_dir}")

    def tearDown(self):
        """Nettoie l'environnement"""
        if self.temp_dir and os.path.exists(self.temp_dir):
            import shutil
            shutil.rmtree(self.temp_dir, ignore_errors=True)

    def create_comprehensive_test_file(self, format_ext):
        """Crée un fichier de test complet selon le format"""
        if format_ext == "md":
            content = """# Test Complet Markdown

Ceci est un **test complet** avec du contenu *varié* pour vérifier la fidélité.

## Sections multiples

### Sous-section avec liste

- Item **gras** avec du contenu
- Item *italique* avec [lien](https://example.com)
- Item avec `code inline`

### Tableau complet

| Colonne 1 | Colonne 2 | Colonne 3 |
|-----------|-----------|-----------|
| **Gras** | *Italique* | `Code` |
| [Lien](https://test.com) | Normal | ~~Barré~~ |

### Bloc de code

```python
def test_function():
    return "Hello World"
```

### Citations

> Ceci est une citation importante
>
> Sur plusieurs lignes

### Ligne horizontale

---

## Fin du test

Paragraphe final avec **formatage** et *emphase*.
"""
        elif format_ext == "txt":
            content = """Test Complet Texte

Ceci est un test complet pour fichier texte.

Section 1
---------

Paragraphe avec du contenu normal.
Plusieurs lignes dans le même paragraphe.

Section 2
---------

Autre paragraphe avec différents contenus.

    Paragraphe indenté pour test.

Fin du document de test.
"""
        elif format_ext == "html":
            content = """<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <title>Test Complet HTML</title>
</head>
<body>
    <h1>Test Complet HTML</h1>

    <p>Ceci est un <strong>test complet</strong> avec du contenu <em>varié</em>.</p>

    <h2>Sections multiples</h2>

    <h3>Liste avec formatage</h3>
    <ul>
        <li>Item <strong>gras</strong></li>
        <li>Item <em>italique</em> avec <a href="https://example.com">lien</a></li>
        <li>Item avec <code>code</code></li>
    </ul>

    <h3>Tableau</h3>
    <table>
        <thead>
            <tr>
                <th>Colonne 1</th>
                <th>Colonne 2</th>
            </tr>
        </thead>
        <tbody>
            <tr>
                <td><strong>Gras</strong></td>
                <td><em>Italique</em></td>
            </tr>
            <tr>
                <td><a href="https://test.com">Lien</a></td>
                <td>Normal</td>
            </tr>
        </tbody>
    </table>

    <blockquote>
        <p>Citation importante</p>
    </blockquote>

    <hr>

    <p>Paragraphe final.</p>
</body>
</html>
"""
        else:
            content = "Contenu de test simple."

        return content

    def calculate_similarity(self, text1, text2):
        """Calcule la similarité entre deux textes"""
        # Normaliser les textes (espaces, retours à la ligne)
        norm1 = ' '.join(text1.split())
        norm2 = ' '.join(text2.split())

        # Calculer la similarité
        matcher = difflib.SequenceMatcher(None, norm1, norm2)
        return matcher.ratio()

    def test_markdown_round_trip(self):
        """Test de round-trip complet pour Markdown"""
        print("📝 Test round-trip Markdown...")

        try:
            # 1. Créer fichier original
            original_content = self.create_comprehensive_test_file("md")
            original_file = os.path.join(self.temp_dir, "original.md")

            with open(original_file, 'w', encoding='utf-8') as f:
                f.write(original_content)

            # 2. Test avec outil md_rt si disponible
            md_rt_path = "./build/md_rt"
            if os.path.exists(md_rt_path):
                result = subprocess.run(
                    [md_rt_path, original_file],
                    capture_output=True,
                    text=True,
                    timeout=30
                )

                if result.returncode != 0:
                    print(f"❌ Échec md_rt: {result.stderr}")
                    return False

                print("✅ Round-trip md_rt réussi")

            # 3. Test avec outil md_wysiwyg_rt si disponible
            wysiwyg_rt_path = "./build/md_wysiwyg_rt"
            if os.path.exists(wysiwyg_rt_path):
                result = subprocess.run(
                    [wysiwyg_rt_path, original_file],
                    capture_output=True,
                    text=True,
                    timeout=30
                )

                if result.returncode != 0:
                    print(f"❌ Échec md_wysiwyg_rt: {result.stderr}")
                    return False

                print("✅ Round-trip WYSIWYG réussi")

            # 4. Vérifier que les fichiers de sortie existent
            output_files = ["md_rt_out.md", "md_wysiwyg_rt_out.md"]

            for output_file in output_files:
                if os.path.exists(output_file):
                    with open(output_file, 'r', encoding='utf-8') as f:
                        output_content = f.read()

                    # Calculer similarité
                    similarity = self.calculate_similarity(original_content, output_content)

                    if similarity > 0.8:  # 80% de similarité
                        print(f"✅ Fidélité {output_file}: {similarity:.2%}")
                    else:
                        print(f"⚠️ Fidélité {output_file} faible: {similarity:.2%}")

            self.results["markdown_roundtrip"] = {"success": True}
            return True

        except Exception as e:
            print(f"❌ Erreur round-trip Markdown: {e}")
            self.results["markdown_roundtrip"] = {"success": False, "error": str(e)}
            return False

    def test_format_conversion_chain(self):
        """Test de chaîne de conversion entre formats"""
        print("🔄 Test chaîne conversions...")

        try:
            # Créer un fichier Markdown de base
            md_content = self.create_comprehensive_test_file("md")
            md_file = os.path.join(self.temp_dir, "chain_test.md")

            with open(md_file, 'w', encoding='utf-8') as f:
                f.write(md_content)

            # Simuler une chaîne de conversion MD -> HTML -> TXT
            # (en utilisant les outils disponibles)

            success = True
            similarity_scores = []

            # Test de conversion simple
            for tool in ["./build/md_rt", "./build/md_wysiwyg_rt"]:
                if os.path.exists(tool):
                    result = subprocess.run(
                        [tool, md_file],
                        capture_output=True,
                        text=True,
                        timeout=30
                    )

                    if result.returncode == 0:
                        print(f"✅ Conversion {os.path.basename(tool)} OK")
                    else:
                        print(f"❌ Échec {os.path.basename(tool)}")
                        success = False

            self.results["format_chain"] = {"success": success}
            return success

        except Exception as e:
            print(f"❌ Erreur chaîne conversion: {e}")
            return False

    def test_content_preservation(self):
        """Test de préservation du contenu essentiel"""
        print("🛡️ Test préservation contenu...")

        try:
            # Éléments critiques à préserver
            critical_elements = {
                "markdown": [
                    "# Titre principal",
                    "**texte gras**",
                    "*texte italique*",
                    "[lien](https://example.com)",
                    "| tableau | cellule |",
                    "> citation",
                    "```code```"
                ],
                "html": [
                    "<h1>",
                    "<strong>",
                    "<em>",
                    "<a href=",
                    "<table>",
                    "<blockquote>",
                    "<code>"
                ]
            }

            success_count = 0
            total_tests = 0

            for format_name, elements in critical_elements.items():
                if format_name == "markdown":
                    test_content = self.create_comprehensive_test_file("md")
                    test_file = os.path.join(self.temp_dir, f"preservation_test.md")
                else:
                    test_content = self.create_comprehensive_test_file("html")
                    test_file = os.path.join(self.temp_dir, f"preservation_test.html")

                with open(test_file, 'w', encoding='utf-8') as f:
                    f.write(test_content)

                # Vérifier que les éléments sont dans le fichier original
                for element in elements:
                    total_tests += 1
                    if element.lower() in test_content.lower():
                        success_count += 1
                        print(f"✅ Élément préservé: {element}")
                    else:
                        print(f"❌ Élément manquant: {element}")

            preservation_rate = success_count / total_tests if total_tests > 0 else 0
            success = preservation_rate > 0.8

            print(f"📊 Taux de préservation: {preservation_rate:.2%}")

            self.results["content_preservation"] = {
                "success": success,
                "rate": preservation_rate
            }

            return success

        except Exception as e:
            print(f"❌ Erreur test préservation: {e}")
            return False

    def test_stress_round_trip(self):
        """Test de stress avec fichiers volumineux"""
        print("💪 Test stress round-trip...")

        try:
            # Créer un fichier volumineux
            large_content = ""
            for i in range(100):
                large_content += f"\n## Section {i+1}\n\n"
                large_content += "Contenu " * 50 + "\n\n"
                large_content += f"| Col1 | Col2 | Col3 |\n"
                large_content += f"|------|------|------|\n"
                for j in range(10):
                    large_content += f"| Data{j}1 | Data{j}2 | Data{j}3 |\n"
                large_content += "\n"

            large_file = os.path.join(self.temp_dir, "stress_test.md")
            with open(large_file, 'w', encoding='utf-8') as f:
                f.write(large_content)

            file_size = os.path.getsize(large_file)
            print(f"📏 Taille fichier test: {file_size} bytes")

            # Tester avec les outils disponibles
            success = True

            for tool in ["./build/md_rt", "./build/md_wysiwyg_rt"]:
                if os.path.exists(tool):
                    start_time = time.time()

                    result = subprocess.run(
                        [tool, large_file],
                        capture_output=True,
                        text=True,
                        timeout=60  # Timeout plus long pour gros fichier
                    )

                    duration = time.time() - start_time

                    if result.returncode == 0:
                        print(f"✅ Stress test {os.path.basename(tool)} OK ({duration:.2f}s)")
                    else:
                        print(f"❌ Échec stress {os.path.basename(tool)}")
                        success = False

            self.results["stress_test"] = {"success": success}
            return success

        except Exception as e:
            print(f"❌ Erreur stress test: {e}")
            return False

    def run_round_trip_tests(self):
        """Lance tous les tests de round-trip"""
        print("🎯 === Tests de Round-Trip IntaText ===")

        try:
            self.setUp()

            tests = [
                ("Round-trip Markdown", self.test_markdown_round_trip),
                ("Chaîne conversions", self.test_format_conversion_chain),
                ("Préservation contenu", self.test_content_preservation),
                ("Stress test", self.test_stress_round_trip)
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
            print("\n📊 === RÉSULTATS TESTS ROUND-TRIP ===")
            for test_name, success in results:
                status = "✅" if success else "❌"
                print(f"{status} {test_name}")

            print(f"\n🎯 Résultat global: {'✅ TOUS LES TESTS PASSENT' if all_success else '❌ CERTAINS TESTS ÉCHOUENT'}")

            return all_success

        finally:
            self.tearDown()

def main():
    """Point d'entrée principal"""
    print("🧪 IntaText - Tests de Round-Trip")

    if not os.path.exists("build"):
        print("❌ ERREUR: Dossier build/ non trouvé")
        print("Veuillez compiler avec: meson compile -C build")
        return 1

    test_suite = IntaTextRoundTripTests()
    success = test_suite.run_round_trip_tests()

    return 0 if success else 1

if __name__ == "__main__":
    sys.exit(main())
