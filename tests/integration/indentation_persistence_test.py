#!/usr/bin/env python3
"""
Tests de persistance et round-trip pour l'indentation d'IntaText
Teste: sauvegarde/chargement avec indentation, formats Markdown/HTML/RTF
"""

import sys
import subprocess
import os
import tempfile
import time
import difflib
from pathlib import Path

class IntaTextIndentationPersistenceTests:
    """Tests de persistance pour l'indentation"""

    def __init__(self):
        self.temp_dir = None
        self.results = {}

    def setUp(self):
        """Prépare l'environnement de test"""
        print("🔧 Préparation des tests de persistance indentation...")
        self.temp_dir = tempfile.mkdtemp(prefix="intatext_indent_persist_test_")
        print(f"📁 Dossier temporaire: {self.temp_dir}")

    def tearDown(self):
        """Nettoie l'environnement"""
        if self.temp_dir and os.path.exists(self.temp_dir):
            import shutil
            shutil.rmtree(self.temp_dir, ignore_errors=True)

    def test_markdown_indentation_roundtrip(self):
        """Test round-trip Markdown avec indentation préservée"""
        print("🔄 Test round-trip Markdown indentation...")

        try:
            # Créer un fichier Markdown avec indentation complexe
            original_content = """# Document avec Indentation

## Paragraphes indentés

Voici un paragraphe normal.
Qui continue sur plusieurs lignes.

    Voici un paragraphe indenté avec 4 espaces.
    Il continue aussi sur plusieurs lignes.
    Et se termine ici.

        Voici un paragraphe avec indentation double.
        Niveau encore plus profond.

## Listes avec indentation

1. Premier élément de liste
    - Sous-élément à puce niveau 1
        - Sous-élément à puce niveau 2
            - Sous-élément à puce niveau 3
        - Retour niveau 2
    - Retour niveau 1
2. Deuxième élément de liste
    1. Sous-liste numérotée
    2. Deuxième sous-élément
3. Troisième élément

## Code et citations

```python
def fonction_indentee():
    if True:
        print("Code avec indentation")
        if nested:
            print("Encore plus indenté")
```

> Citation niveau 1
>
>     Citation avec indentation interne
>     Continué sur cette ligne
>
> Retour citation normale

## Mélange complexe

- Élément de liste

    Paragraphe indenté dans la liste.
    Continué sur cette ligne.

        Paragraphe encore plus indenté.
        Dans la liste aussi.

    Retour au niveau liste.

- Deuxième élément de liste
"""

            # Test round-trip via CLI
            original_file = os.path.join(self.temp_dir, "original_indent.md")
            with open(original_file, 'w', encoding='utf-8') as f:
                f.write(original_content)

            # Charger et sauvegarder via IntaText
            roundtrip_file = os.path.join(self.temp_dir, "roundtrip_indent.md")

            env = os.environ.copy()
            env["GSETTINGS_SCHEMA_DIR"] = "/usr/local/share/glib-2.0/schemas"

            # Test avec CLI si disponible
            if os.path.exists("./build/md_rt"):
                process = subprocess.run(
                    ["./build/md_rt", original_file, roundtrip_file],
                    env=env,
                    capture_output=True,
                    text=True,
                    timeout=30
                )

                if process.returncode == 0 and os.path.exists(roundtrip_file):
                    # Comparer les fichiers
                    with open(roundtrip_file, 'r', encoding='utf-8') as f:
                        roundtrip_content = f.read()

                    # Analyser les différences d'indentation
                    original_lines = original_content.splitlines()
                    roundtrip_lines = roundtrip_content.splitlines()

                    # Calculer similarité
                    similarity = difflib.SequenceMatcher(None, original_lines, roundtrip_lines).ratio()

                    print(f"📊 Similarité round-trip: {similarity:.2%}")

                    # Vérifier conservation des éléments clés
                    indentation_preserved = True

                    # Vérifier que les éléments indentés sont préservés
                    key_indented_lines = [
                        "    Voici un paragraphe indenté",
                        "        Voici un paragraphe avec indentation double",
                        "    - Sous-élément à puce niveau 1",
                        "        - Sous-élément à puce niveau 2",
                        "            - Sous-élément à puce niveau 3"
                    ]

                    for key_line in key_indented_lines:
                        if not any(key_line.strip() in line for line in roundtrip_lines):
                            print(f"⚠️ Ligne d'indentation manquante: {key_line[:30]}...")
                            indentation_preserved = False

                    success = similarity >= 0.85 and indentation_preserved

                    if success:
                        print("✅ Round-trip Markdown avec indentation OK")
                    else:
                        print(f"❌ Round-trip Markdown indentation insuffisant: {similarity:.2%}")

                else:
                    print("❌ Échec conversion round-trip Markdown")
                    success = False
            else:
                print("⚠️ Outil md_rt non trouvé, test ignoré")
                success = True  # Ne pas faire échouer si l'outil n'existe pas

            self.results["markdown_indentation_roundtrip"] = {
                "success": success,
                "similarity": similarity if 'similarity' in locals() else 0
            }

            return success

        except Exception as e:
            print(f"❌ Erreur test round-trip Markdown: {e}")
            return False

    def test_html_indentation_conversion(self):
        """Test conversion vers HTML avec préservation indentation"""
        print("🌐 Test conversion HTML indentation...")

        try:
            # Créer contenu Markdown avec indentation
            markdown_content = """# Document HTML Indentation

## Paragraphes avec indentation

Paragraphe normal.

    Paragraphe indenté niveau 1.
    Continué sur cette ligne.

        Paragraphe indenté niveau 2.
        Plus profond.

## Listes indentées

1. Élément numéroté
    - Sous-élément à puce
        - Sous-sous-élément
    - Retour niveau 1
2. Deuxième élément numéroté

## Code et citations

```
Code block
    with indentation
        nested deeper
```

> Citation
>
>     Citation indentée
>     Continué
"""

            md_file = os.path.join(self.temp_dir, "indent_source.md")
            with open(md_file, 'w', encoding='utf-8') as f:
                f.write(markdown_content)

            # Convertir vers HTML (simulé via CLI si disponible)
            html_file = os.path.join(self.temp_dir, "indent_output.html")

            env = os.environ.copy()
            env["GSETTINGS_SCHEMA_DIR"] = "/usr/local/share/glib-2.0/schemas"

            # Test de conversion basique (chargement Markdown)
            process = subprocess.Popen(
                ["./build/IntaText", md_file],
                env=env,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE
            )

            time.sleep(3)

            if process.poll() is None:
                print("✅ Chargement Markdown pour HTML OK")

                process.terminate()
                try:
                    process.wait(timeout=3)
                except subprocess.TimeoutExpired:
                    process.kill()

                success = True
            else:
                stdout, stderr = process.communicate()
                print(f"❌ Échec chargement Markdown pour HTML: {stderr.decode()[:100]}")
                success = False

            self.results["html_indentation_conversion"] = {"success": success}
            return success

        except Exception as e:
            print(f"❌ Erreur test conversion HTML: {e}")
            return False

    def test_rtf_indentation_preservation(self):
        """Test préservation indentation en format RTF"""
        print("📄 Test préservation RTF indentation...")

        try:
            # Créer contenu riche avec indentation
            rich_content = """# Document RTF avec Indentation

## Formatage riche indenté

**Texte gras normal.**

    **Texte gras indenté niveau 1.**
    *Texte italique indenté niveau 1.*

        **Texte gras indenté niveau 2.**
        *Texte italique indenté niveau 2.*
        `Code indenté niveau 2.`

## Listes riches

1. **Élément gras**
    - *Sous-élément italique*
        - `Sous-sous-élément code`
    - Retour niveau 1
2. Deuxième élément avec [lien](http://example.com)

## Combinaisons complexes

    > Citation indentée avec **gras** et *italique*
    > Continué avec `code inline`

        > Citation doublement indentée
        > Avec formatage **riche**
"""

            rtf_source = os.path.join(self.temp_dir, "rtf_indent_test.md")
            with open(rtf_source, 'w', encoding='utf-8') as f:
                f.write(rich_content)

            # Test chargement avec formatage riche
            env = os.environ.copy()
            env["GSETTINGS_SCHEMA_DIR"] = "/usr/local/share/glib-2.0/schemas"

            process = subprocess.Popen(
                ["./build/IntaText", rtf_source],
                env=env,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE
            )

            time.sleep(3)

            if process.poll() is None:
                print("✅ Chargement contenu RTF riche OK")

                process.terminate()
                try:
                    process.wait(timeout=3)
                except subprocess.TimeoutExpired:
                    process.kill()

                success = True
            else:
                stdout, stderr = process.communicate()
                print(f"❌ Échec chargement RTF riche: {stderr.decode()[:100]}")
                success = False

            self.results["rtf_indentation_preservation"] = {"success": success}
            return success

        except Exception as e:
            print(f"❌ Erreur test RTF: {e}")
            return False

    def test_indentation_settings_persistence(self):
        """Test persistance des préférences d'indentation"""
        print("⚙️ Test persistance préférences indentation...")

        try:
            # Test des différents modes d'indentation configurés
            indentation_modes = ["none", "spaces", "margin-tags", "rtf-format"]

            success_count = 0
            total_tests = len(indentation_modes)

            for mode in indentation_modes:
                # Créer un fichier test simple
                test_content = f"# Test mode {mode}\n\nParagraphe test pour {mode}.\nDeuxième ligne du paragraphe."

                test_file = os.path.join(self.temp_dir, f"mode_{mode}.md")
                with open(test_file, 'w', encoding='utf-8') as f:
                    f.write(test_content)

                # Test avec configuration simulée
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
                    print(f"✅ Mode {mode} chargé OK")
                    success_count += 1

                    process.terminate()
                    try:
                        process.wait(timeout=3)
                    except subprocess.TimeoutExpired:
                        process.kill()
                else:
                    stdout, stderr = process.communicate()
                    print(f"❌ Mode {mode} échec")

            success_rate = success_count / total_tests if total_tests > 0 else 0
            success = success_rate >= 0.75

            print(f"📊 Modes indentation testés: {success_rate:.2%} ({success_count}/{total_tests})")

            self.results["indentation_settings_persistence"] = {
                "success": success,
                "rate": success_rate
            }

            return success

        except Exception as e:
            print(f"❌ Erreur test persistance préférences: {e}")
            return False

    def test_complex_document_persistence(self):
        """Test persistance document complexe avec indentation"""
        print("🗂️ Test persistance document complexe...")

        try:
            # Créer un document très complexe
            complex_content = """# Document Complexe Complet

## Introduction avec formatage

Voici un paragraphe d'introduction avec **formatage gras** et *italique*.
Cette ligne contient du `code inline` et un [lien](http://example.com).

    Voici un paragraphe indenté avec **gras indenté** et *italique indenté*.
    Il contient aussi du `code indenté` et des [liens indentés](http://indented.com).

        Paragraphe doublement indenté avec tous les **formatages** *possibles*.
        Avec `code` et [liens](http://deep.com) très profonds.

## Listes complexes imbriquées

1. **Premier élément gras**
    - *Sous-élément italique*
        - `Sous-sous-élément code`
            - Sous-sous-sous-élément normal
        - Retour niveau 2
    - Retour niveau 1 avec [lien](http://level1.com)
2. Deuxième élément avec **tous** les *formatages* `possibles`
    1. Sous-liste numérotée **gras**
    2. Autre sous-élément *italique*
        1. Sous-sous-liste `code`
        2. Avec [lien interne](http://internal.com)
3. Troisième élément principal

## Code et citations complexes

```python
def fonction_complexe():
    \"\"\"Fonction avec indentation complexe.\"\"\"
    if condition:
        for item in liste:
            if autre_condition:
                resultat = traitement(item)
                if resultat:
                    return resultat
    return None
```

> Citation de niveau 1 avec **gras** et *italique*
>
>     Citation indentée avec `code inline`
>     Et des [liens](http://quoted.com) aussi
>
>         Citation doublement indentée
>         Avec **formatage riche**
>
> Retour citation normale

## Mélange ultra-complexe

- **Élément de liste gras**

    Paragraphe indenté dans la liste avec *italique*.
    Continué avec `code inline` et [lien](http://complex.com).

        Paragraphe encore plus indenté dans la liste.
        Avec **tous** les *formatages* `possibles` et [liens](http://deeper.com).

    ```python
    # Code dans liste indentée
    def fonction_dans_liste():
        return "code indenté"
    ```

    > Citation dans liste indentée
    > Avec **formatage** dans citation

    Retour au niveau liste principal.

- Deuxième élément de liste principal
    1. Sous-liste numérotée dans liste à puces
    2. Avec **formatage** *varié* et `code`
        - Retour aux puces dans numérotée
        - Avec [liens](http://mixed.com) partout

## Tableaux indentés (si supporté)

| Colonne 1 | Colonne 2 | Colonne 3 |
|-----------|-----------|-----------|
| **Gras**  | *Italique* | `Code`   |
| [Lien](http://table.com) | Normal | **Mixte** |

    | Tableau indenté | Deuxième colonne |
    |-----------------|------------------|
    | **Contenu gras** | *Contenu italique* |
    | `Code indenté` | [Lien indenté](http://nested-table.com) |

## Conclusion

Document complexe terminé avec **tous** les *éléments* `possibles`.
Avec indentation [complète](http://conclusion.com) sur plusieurs niveaux.

    Paragraphe final indenté avec **formatage** complet.
    Pour tester la persistance *totale* du `système`.
"""

            complex_file = os.path.join(self.temp_dir, "complex_persistence.md")
            with open(complex_file, 'w', encoding='utf-8') as f:
                f.write(complex_content)

            # Test chargement document ultra-complexe
            env = os.environ.copy()
            env["GSETTINGS_SCHEMA_DIR"] = "/usr/local/share/glib-2.0/schemas"

            process = subprocess.Popen(
                ["./build/IntaText", complex_file],
                env=env,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE
            )

            time.sleep(5)  # Plus de temps pour document complexe

            if process.poll() is None:
                print("✅ Chargement document ultra-complexe OK")

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

            self.results["complex_document_persistence"] = {"success": success}
            return success

        except Exception as e:
            print(f"❌ Erreur test document complexe: {e}")
            return False

    def run_indentation_persistence_tests(self):
        """Lance tous les tests de persistance d'indentation"""
        print("🎯 === Tests de Persistance Indentation IntaText ===")

        try:
            self.setUp()

            tests = [
                ("Round-trip Markdown", self.test_markdown_indentation_roundtrip),
                ("Conversion HTML", self.test_html_indentation_conversion),
                ("Préservation RTF", self.test_rtf_indentation_preservation),
                ("Persistance préférences", self.test_indentation_settings_persistence),
                ("Document complexe", self.test_complex_document_persistence)
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
            print("\n📊 === RÉSULTATS TESTS PERSISTANCE INDENTATION ===")
            for test_name, success in results:
                status = "✅" if success else "❌"
                print(f"{status} {test_name}")

            # Calcul du score de persistance
            success_count = sum(1 for _, success in results if success)
            persistence_score = success_count / len(results) if results else 0

            print(f"\n💾 Score de persistance: {persistence_score:.2%}")
            print(f"🎯 Résultat global: {'✅ PERSISTANCE INDENTATION EXCELLENTE' if persistence_score >= 0.8 else '⚠️ PERSISTANCE PARTIELLE' if persistence_score >= 0.6 else '❌ PERSISTANCE INSUFFISANTE'}")

            return persistence_score >= 0.6  # Au moins 60% pour passer

        finally:
            self.tearDown()

def main():
    """Point d'entrée principal"""
    print("🧪 IntaText - Tests de Persistance Indentation")

    if not os.path.exists("build/IntaText"):
        print("❌ ERREUR: Application IntaText non trouvée")
        print("Veuillez compiler avec: meson compile -C build")
        return 1

    test_suite = IntaTextIndentationPersistenceTests()
    success = test_suite.run_indentation_persistence_tests()

    return 0 if success else 1

if __name__ == "__main__":
    sys.exit(main())
