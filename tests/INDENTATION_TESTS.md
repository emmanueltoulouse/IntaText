# Tests d'Indentation - IntaText

## Vue d'ensemble

Ce document décrit le système complet de tests d'indentation pour IntaText, permettant de valider toutes les fonctionnalités liées à l'indentation de texte dans l'éditeur.

## Structure des Tests

### 🎯 Types de Tests

1. **Tests Unitaires** (`tests/unit/`)
   - Tests des fonctions d'indentation de base
   - Validation des modes d'indentation
   - Tests de conversion d'indentation

2. **Tests d'Intégration** (`tests/integration/`)
   - Tests de bout en bout avec fichiers réels
   - Validation des opérations complexes
   - Tests de performance

3. **Tests Manuels** (`tests/manual/`)
   - Scripts bash pour tests interactifs
   - Validation visuelle des résultats
   - Tests de cas spécifiques

4. **Fichiers d'Échantillons** (`tests/samples/`)
   - Fichiers Markdown de test
   - Cas d'usage réels
   - Exemples complexes

## 🚀 Exécution des Tests

### Option 1: Script de Lancement Interactif
```bash
cd tests/
./run_indent_tests.sh
```

Menu interactif avec options:
1. Tests d'intégration Python (recommandé)
2. Tests manuels Bash
3. Tests unitaires existants
4. Tous les tests
5. Tests rapides (échantillons seulement)

### Option 2: Tests Intégrés
```bash
# Depuis la racine du projet
./tests/run_tests.sh
```
Inclut automatiquement les tests d'indentation dans la suite complète.

### Option 3: Tests Spécifiques

#### Tests Python (recommandé)
```bash
cd tests/
python3 integration/indentation_test_suite.py
```

Options disponibles:
```bash
python3 integration/indentation_test_suite.py --verbose
python3 integration/indentation_test_suite.py --indent-size 2
python3 integration/indentation_test_suite.py --use-tabs
```

#### Tests Bash
```bash
cd tests/
./manual/indent_test_processor.sh
```

#### Tests Unitaires Vala
```bash
# Depuis la racine
meson test -C build --suite indentation
```

## 📋 Tests Couverts

### 1. Tests de Paragraphes
- Indentation de paragraphes simples
- Paragraphes multi-lignes
- Préservation des espaces
- Gestion des lignes vides

### 2. Tests de Listes
- Listes numérotées
- Listes à puces
- Listes imbriquées
- Listes avec contenu mixte

### 3. Tests de Code
- Blocs de code fencés
- Code inline préservé
- Indentation du code existant
- Différents langages

### 4. Tests de Citations
- Citations simples
- Citations imbriquées
- Citations avec formatage
- Niveaux multiples

### 5. Tests de Contenu Mixte
- Combinaisons complexes
- Tableaux
- Images et liens
- Formules mathématiques

### 6. Tests de Cas Limites
- Fichiers vides
- Caractères Unicode/Emojis
- Espaces et tabulations mixtes
- Lignes très longues

### 7. Tests de Performance
- Gros fichiers (1000+ lignes)
- Mesure du temps d'exécution
- Tests de mémoire

## 📊 Fichiers d'Échantillons

Les fichiers de test se trouvent dans `tests/samples/`:

- `test_indent_paragraphs.md` - Tests de paragraphes complexes
- `test_indent_lists.md` - Tests de listes et structures
- `test_indent_code_quotes.md` - Tests de code et citations
- `test_indent_complex.md` - Tests de contenu complexe et cas limites

## 🔧 Configuration

### Variables d'Indentation
```python
test_config = {
    "indent_size": 4,        # Nombre d'espaces par niveau
    "use_tabs": False,       # Utiliser des tabulations
    "preserve_existing": False,  # Préserver l'indentation existante
    "indent_empty_lines": False  # Indenter les lignes vides
}
```

### Variables d'Environnement
```bash
export INTATEXT_TEST_VERBOSE=1    # Mode verbeux
export INTATEXT_TEST_TIMEOUT=30   # Timeout des tests
```

## 📈 Rapports et Logs

### Rapport JSON
Généré automatiquement dans `/tmp/intatext_indent_*/indent_test_report.json`:
```json
{
  "timestamp": 1673024400.0,
  "total_tests": 6,
  "passed_tests": 6,
  "failed_tests": 0,
  "success_rate": 100.0,
  "config": {...}
}
```

### Logs Détaillés
- `results.log` - Résumé des tests réussis
- `errors.log` - Détails des échecs
- Sortie couleur en temps réel

## 🐛 Dépannage

### Tests Python Échouent
```bash
# Vérifier les dépendances
python3 -c "import difflib, tempfile, json"

# Permissions
chmod +x tests/integration/indentation_test_suite.py
```

### Tests Bash Échouent
```bash
# Vérifier bc pour les calculs
sudo apt install bc

# Permissions
chmod +x tests/manual/indent_test_processor.sh
```

### Application Non Compilée
```bash
# Compiler IntaText
cd projet_root/
meson compile -C build
```

## 🎨 Personnalisation

### Ajouter de Nouveaux Tests
1. Créer un fichier d'échantillon dans `tests/samples/`
2. Ajouter le test dans `indentation_test_suite.py`
3. Mettre à jour la documentation

### Modifier la Configuration
Éditer `test_config` dans `indentation_test_suite.py` ou utiliser les arguments de ligne de commande.

### Intégration CI/CD
```yaml
# Exemple GitHub Actions
- name: Tests d'indentation
  run: |
    cd tests/
    python3 integration/indentation_test_suite.py --verbose
```

## 📞 Support

En cas de problème:
1. Vérifier que IntaText est compilé
2. Consulter les logs d'erreur
3. Exécuter avec `--verbose` pour plus de détails
4. Vérifier les permissions des scripts

## 🔄 Intégration Continue

Les tests d'indentation sont automatiquement inclus dans:
- `./tests/run_tests.sh` (suite complète)
- Tests unitaires Meson
- Validation avant commit (si configuré)

---

**Note**: Ces tests simulent actuellement le comportement d'indentation. Pour une intégration complète, il faut connecter les tests à l'API réelle d'IntaText.
