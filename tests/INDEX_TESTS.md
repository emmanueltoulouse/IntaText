# Tests IntaText - Index Complet

Ce répertoire contient tous les systèmes de tests pour IntaText, l'éditeur Markdown WYSIWYG.

## 🗂️ Structure des Tests

```
tests/
├── 📊 regression/              # Tests de non-régression (NOUVEAU)
│   ├── README.md              # Documentation complète
│   ├── FEATURES_MATRIX.md     # Matrice des 80+ fonctionnalités
│   ├── SYSTÈME_COMPLET.md     # Vue d'ensemble du système
│   ├── non_regression_tester.py # Moteur principal (800+ lignes)
│   ├── run_regression_tests.sh  # Script d'exécution
│   ├── config.py              # Configuration
│   ├── baselines/             # Résultats de référence
│   └── reports/               # Rapports d'exécution
│
├── 🧪 unit/                   # Tests unitaires
│   └── (à développer)
│
├── 🔗 integration/            # Tests d'intégration
│   └── (à développer)
│
├── 🖱️ ui/                     # Tests d'interface utilisateur
│   └── (à développer)
│
├── ✋ manual/                 # Tests manuels
│   └── (existants)
│
├── 📝 samples/                # Échantillons de test
│   └── (existants)
│
├── 🔧 experimental/           # Tests expérimentaux
│   └── (existants)
│
└── 📄 run_tests.sh           # Script principal d'exécution
```

## 🎯 Types de Tests Disponibles

### 🚨 Tests de Non-Régression (Opérationnels)
**Status**: ✅ **Complet et fonctionnel**
**Objectif**: Garantir la stabilité de toutes les fonctionnalités
**Couverture**: 61 tests, 13 catégories, 80+ fonctionnalités

```bash
# Tests critiques rapides (< 30s)
./regression/run_regression_tests.sh --critical

# Tests d'une fonctionnalité spécifique
./regression/run_regression_tests.sh --filter "bold" --verbose

# Tests complets pour release
./regression/run_regression_tests.sh --full --build
```

**Fonctionnalités testées**:
- ✅ Formatage de base (gras, italique, souligné, barré, code)
- ✅ Formatages combinés (`***gras+italique***`)
- ✅ Titres H1-H6 (ATX et Setext)
- ✅ Listes (puces, numérotées, tâches)
- ✅ Citations (simples, imbriquées)
- ✅ Code (inline, blocs, langages)
- ✅ Tableaux (simples, alignés, formatés)
- ✅ Liens et images
- ✅ Styles avancés (couleurs, polices)
- ✅ Imbrications complexes (gras dans titres, formatage dans listes)
- ✅ Cas limites (Unicode, emojis, malformé)
- ✅ Opérations documents (round-trip MD↔WYSIWYG)
- ✅ Système de plugins

### 🔧 Tests d'Indentation (Existants)
**Status**: ✅ Opérationnels
**Objectif**: Validation des règles d'indentation

```bash
# Tests d'indentation existants
./run_indent_tests.sh
```

### 🧪 Tests Unitaires (À Développer)
**Status**: 🚧 Prochaine étape
**Objectif**: Tester les composants individuels

**Composants à tester**:
- Classes de modèles (`ApplicationModel`, `EditorModel`)
- Convertisseurs de documents (`MarkdownDocumentConverter`, `HtmlDocumentConverter`)
- Gestionnaires (`ConfigManager`, `BookmarksManager`, `HistoryManager`)
- Utilitaires et helpers

### 🔗 Tests d'Intégration (À Développer)
**Status**: 🚧 Planifiés
**Objectif**: Tester les interactions entre composants

**Scénarios à tester**:
- Pipeline complet de conversion MD ↔ WYSIWYG
- Intégration plugins ↔ application
- Sauvegarde/chargement de documents
- Synchronisation modèle ↔ vue

### 🖱️ Tests UI (À Développer)
**Status**: 🚧 Futurs
**Objectif**: Tester l'interface utilisateur

**Interactions à tester**:
- Clics de boutons de formatage
- Raccourcis clavier
- Drag & drop de fichiers
- Workflows utilisateur complets

## 🎖️ Priorités d'Exécution

### 1. 🚨 Tests Critiques (Quotidiens)
```bash
# Avant chaque commit
./regression/run_regression_tests.sh --critical --quick

# Vérification rapide
./run_indent_tests.sh
```

### 2. 📊 Tests Complets (Releases)
```bash
# Tests de non-régression complets
./regression/run_regression_tests.sh --full --build

# Tous les tests existants
./run_tests.sh
```

### 3. 🔍 Tests Ciblés (Développement)
```bash
# Tests d'une fonctionnalité spécifique
./regression/run_regression_tests.sh --filter "formatage" --verbose

# Tests d'une catégorie
./regression/run_regression_tests.sh --category listes --category titres
```

## 📊 Métriques de Qualité

### Tests de Non-Régression
- **61 tests** automatisés
- **100% des fonctionnalités** principales couvertes
- **3 niveaux de priorité** (Critique/Important/Normal)
- **Rapports détaillés** JSON + Console

### Codes de Sortie Standards
- **0**: ✅ Tous tests réussis
- **1**: ⚠️ Tests non-critiques échoués
- **2**: 🚨 Tests critiques échoués

## 🚀 Intégration CI/CD

### Pre-commit Hook
```bash
#!/bin/bash
cd "$(git rev-parse --show-toplevel)"

# Tests rapides critiques
./tests/regression/run_regression_tests.sh --critical
REGRESSION_EXIT=$?

# Tests d'indentation
./tests/run_indent_tests.sh
INDENT_EXIT=$?

# Sortie combinée
if [ $REGRESSION_EXIT -eq 2 ] || [ $INDENT_EXIT -ne 0 ]; then
    echo "❌ Tests critiques échoués - commit bloqué"
    exit 1
elif [ $REGRESSION_EXIT -eq 1 ]; then
    echo "⚠️ Tests non-critiques échoués - review recommandée"
    exit 0
else
    echo "✅ Tous les tests réussis"
    exit 0
fi
```

### Pipeline GitHub Actions
```yaml
name: Tests IntaText

on: [push, pull_request]

jobs:
  test-critical:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Install dependencies
        run: |
          sudo apt-get update
          sudo apt-get install valac meson ninja-build
      - name: Run critical tests
        run: ./tests/regression/run_regression_tests.sh --build --critical
      - name: Upload reports
        uses: actions/upload-artifact@v3
        if: always()
        with:
          name: test-reports
          path: tests/regression/reports/

  test-full:
    runs-on: ubuntu-latest
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v3
      - name: Install dependencies
        run: |
          sudo apt-get update
          sudo apt-get install valac meson ninja-build
      - name: Run full regression tests
        run: ./tests/regression/run_regression_tests.sh --build --full
      - name: Run indentation tests
        run: ./tests/run_indent_tests.sh
```

## 📈 Évolution des Tests

### ✅ Complété
- **Tests de non-régression** : Système complet opérationnel
- **Tests d'indentation** : Validations existantes
- **Documentation** : Complète et détaillée

### 🚧 En Cours / Planifié
1. **Tests unitaires** : Classes et fonctions individuelles
2. **Tests d'intégration** : Interactions entre composants
3. **Tests de performance** : Benchmarks et optimisations
4. **Tests UI** : Interface utilisateur et interactions

### 🔮 Futurs
- **Tests de charge** : Gros documents et performances
- **Tests de compatibilité** : Différentes versions/environnements
- **Tests de sécurité** : Validation des entrées utilisateur
- **Tests d'accessibilité** : Support des technologies d'assistance

## 🤝 Guide de Contribution

### Ajouter des Tests de Non-Régression
1. Identifier la fonctionnalité dans `regression/FEATURES_MATRIX.md`
2. Ajouter le test dans `regression/non_regression_tester.py`
3. Définir catégorie et priorité appropriées
4. Créer la baseline avec `--create-baseline`
5. Valider manuellement et commiter

### Développer d'Autres Types de Tests
1. Créer le répertoire approprié (`unit/`, `integration/`, etc.)
2. Suivre les patterns établis pour la structure
3. Intégrer dans `run_tests.sh` principal
4. Documenter dans ce fichier index
5. Ajouter aux pipelines CI/CD

## 📞 Support et Documentation

### Documentation Détaillée
- **Tests de non-régression** : `regression/README.md` (3,200 mots)
- **Matrice des fonctionnalités** : `regression/FEATURES_MATRIX.md`
- **Vue d'ensemble** : `regression/SYSTÈME_COMPLET.md`

### Aide Rapide
```bash
# Aide des tests de non-régression
./regression/run_regression_tests.sh --help

# Aide du script principal
./run_tests.sh --help
```

### Contact
- **Issues** : Utiliser le système d'issues du projet GitHub
- **Questions** : Consulter la documentation ou ouvrir une issue
- **Contributions** : Suivre le guide ci-dessus

---

## 🎯 Résumé Exécutif

**IntaText dispose maintenant d'un système de tests robuste et évolutif** :

✅ **Tests de non-régression** : 61 tests automatisés couvrant 80+ fonctionnalités
✅ **Tests d'indentation** : Validation des règles de formatage
🚧 **Tests unitaires/intégration** : Planifiés pour les prochaines itérations
✅ **Intégration CI/CD** : Prêt pour déploiement automatique
✅ **Documentation complète** : Guides détaillés pour tous les aspects

Le système garantit la **qualité continue** d'IntaText et permet un **développement en confiance** avec détection automatique des régressions.

**🚀 Prêt pour la production et l'évolution continue !**
