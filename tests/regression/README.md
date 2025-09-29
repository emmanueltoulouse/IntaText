# Tests de Non-Régression - IntaText

Ce système de tests de non-régression assure la stabilité de toutes les fonctionnalités d'IntaText, y compris leurs imbrications complexes.

## 🎯 Objectifs

- **Validation complète** : Tester toutes les fonctionnalités et leurs combinaisons
- **Détection de régressions** : Identifier immédiatement les régressions
- **Qualité continue** : Maintenir un haut niveau de qualité du code
- **Documentation vivante** : Les tests servent de documentation des fonctionnalités

## 📊 Matrice de Fonctionnalités

Le système teste **80+ fonctionnalités** organisées en **13 catégories** :

### Formatage de Base (Priorité 1 - Critique)
- **Gras** : `**texte**`, `__texte__`
- **Italique** : `*texte*`, `_texte_`
- **Souligné** : `<u>texte</u>`
- **Barré** : `~~texte~~`
- **Code inline** : `` `code` ``
- **Combinaisons** : `***gras+italique***`

### Éléments Structurels (Priorité 1-2)
- **Titres** : `# H1` à `###### H6`, Setext
- **Listes** : À puces (`-`, `*`), numérotées, tâches (`- [ ]`)
- **Citations** : `> citation`, imbriquées
- **Code** : Blocs fencés (````), indentés
- **Tableaux** : Simples, avec alignement

### Fonctionnalités Avancées (Priorité 2-3)
- **Liens** : `[texte](url)`, références
- **Images** : `![alt](src)`
- **Styles** : Couleurs, polices, CSS
- **Plugins** : UI, formats, langages

### Imbrications Complexes (Priorité 2 - Critique)
- Gras dans titres : `# Titre **gras**`
- Formatage dans listes : `- **élément** gras`
- Listes dans citations : `> - élément`
- Tout dans tableaux : `| **gras** | *italique* |`

## 🚀 Utilisation

### Exécution Rapide
```bash
# Tests critiques seulement (recommandé pour CI)
./run_regression_tests.sh --critical --build

# Tests rapides (fonctionnalités de base)
./run_regression_tests.sh --quick --build
```

### Exécution Complète
```bash
# Tous les tests avec compilation
./run_regression_tests.sh --build --full

# Mode verbeux pour débogage
./run_regression_tests.sh --verbose --build
```

### Filtrage et Catégories
```bash
# Tests spécifiques
./run_regression_tests.sh --filter "bold" --verbose

# Catégories spécifiques
./run_regression_tests.sh --category formatage_base --category listes

# Plusieurs catégories
./run_regression_tests.sh -c formatage_base -c titres -c code
```

### Gestion des Baselines
```bash
# Créer les baselines manquantes (première fois)
./run_regression_tests.sh --create-baseline --category formatage_base

# Mettre à jour les baselines existantes (après changements validés)
./run_regression_tests.sh --update-baseline --category formatage_base
```

## 📁 Structure

```
tests/regression/
├── README.md                    # Cette documentation
├── FEATURES_MATRIX.md          # Matrice complète des fonctionnalités
├── config.py                  # Configuration du système
├── non_regression_tester.py   # Système principal de tests
├── run_regression_tests.sh    # Script d'exécution
├── baselines/                 # Résultats de référence
│   ├── format_bold_asterisk.md
│   ├── heading_h1_atx.md
│   └── ...
└── reports/                   # Rapports d'exécution
    ├── regression_report_20241201_143000.html
    └── regression_report.json
```

## 🏷️ Catégories de Tests

| Catégorie | Priorité | Description | Tests |
|-----------|----------|-------------|-------|
| `formatage_base` | 1 | Formatage de base | 9 |
| `formatage_combiné` | 1 | Formatages combinés | 2 |
| `titres` | 1 | Titres H1-H6 | 5 |
| `titres_formatage` | 2 | Titres avec formatage | 3 |
| `listes` | 1 | Listes et tâches | 5 |
| `listes_formatage` | 2 | Listes avec formatage | 2 |
| `citations` | 2 | Citations simples/imbriquées | 3 |
| `citations_formatage` | 3 | Citations avec formatage | 2 |
| `code` | 1 | Blocs et inline code | 4 |
| `tableaux` | 2 | Tableaux | 2 |
| `tableaux_formatage` | 3 | Tableaux avec formatage | 1 |
| `liens` | 2 | Liens et références | 3 |
| `liens_formatage` | 3 | Liens avec formatage | 1 |
| `images` | 2 | Images | 1 |
| `formatage_avancé` | 3 | Styles CSS avancés | 4 |
| `imbrication` | 2 | Imbrications complexes | 5 |
| `cas_limites` | 2 | Edge cases | 6 |
| `plugins` | 3 | Fonctionnalités plugins | 2 |
| `document` | 1 | Opérations documents | 3 |

**Total : 62 tests individuels + combinaisons**

## 🎖️ Niveaux de Priorité

### Priorité 1 - Critique ⭐⭐⭐
- **Fonctionnalités essentielles** : Doivent fonctionner parfaitement
- **Impact** : Bloque la release si échec
- **Exemples** : Formatage de base, titres, listes, code, documents

### Priorité 2 - Important ⭐⭐
- **Fonctionnalités importantes** : Attendues par les utilisateurs
- **Impact** : Avertissement si échec, release possible avec justification
- **Exemples** : Tableaux, citations, imbrications, cas limites

### Priorité 3 - Normal ⭐
- **Fonctionnalités avancées** : Nice-to-have
- **Impact** : Information si échec, release normale
- **Exemples** : Styles avancés, plugins, formatages complexes

## 📊 Métriques de Qualité

### Seuils de Réussite
- **Excellent** : > 98% de réussite
- **Bon** : > 95% de réussite
- **Acceptable** : > 85% de réussite
- **Problématique** : > 70% de réussite
- **Critique** : ≤ 70% de réussite

### Codes de Sortie
- **0** : Tous les tests réussis ✅
- **1** : Tests non-critiques échoués ⚠️
- **2** : Tests critiques échoués 🚨

## 🔧 Configuration

### Variables d'Environnement
```bash
export INTATEXT_BUILD_DIR="/path/to/build"
export REGRESSION_TIMEOUT=60
export REGRESSION_VERBOSE=true
```

### Fichier de Configuration
Modifiez `config.py` pour personnaliser :
- Seuils de qualité
- Catégories et priorités
- Outils externes
- Patterns de validation

## 🏃‍♂️ Intégration CI/CD

### Vérification Pré-Commit
```bash
# Dans .git/hooks/pre-commit
#!/bin/bash
cd "$(git rev-parse --show-toplevel)"
./tests/regression/run_regression_tests.sh --critical --quick
```

### Pipeline CI
```yaml
# GitHub Actions / GitLab CI
test-regression:
  script:
    - ./tests/regression/run_regression_tests.sh --build --critical
  artifacts:
    reports:
      junit: tests/regression/reports/junit.xml
    paths:
      - tests/regression/reports/
```

## 🐛 Débogage

### Tests Échoués
```bash
# Mode verbeux pour voir les détails
./run_regression_tests.sh --verbose --filter "test_échoué"

# Comparer avec la baseline
diff tests/regression/baselines/test.md /tmp/intatext_regression_*/output.md
```

### Mise à Jour des Baselines
```bash
# Après validation manuelle des changements
./run_regression_tests.sh --update-baseline --category formatage_base
git add tests/regression/baselines/
git commit -m "Update regression baselines for formatting changes"
```

### Nouveaux Tests
1. Ajouter le test dans `non_regression_tester.py`
2. Définir la catégorie et priorité
3. Exécuter avec `--create-baseline`
4. Valider manuellement le résultat
5. Commiter la baseline

## 📈 Évolution des Tests

### Ajouter une Fonctionnalité
1. **Identifier** : Nouvelle fonctionnalité à tester
2. **Catégoriser** : Définir catégorie et priorité
3. **Implémenter** : Ajouter le test dans le code
4. **Valider** : Créer la baseline de référence
5. **Documenter** : Mettre à jour cette documentation

### Modifier une Fonctionnalité
1. **Tester** : Exécuter les tests existants
2. **Identifier** : Quels tests échouent légitimement
3. **Valider** : Vérifier manuellement les changements
4. **Mettre à jour** : Nouvelles baselines si nécessaire
5. **Versionner** : Commiter les changements

## 🤝 Contribution

### Bonnes Pratiques
- **Tests atomiques** : Un test = une fonctionnalité
- **Noms explicites** : Tests faciles à identifier
- **Documentation** : Décrire le comportement testé
- **Exemples représentatifs** : Cas d'usage réels

### Standards de Code
- **Python 3.6+** compatible
- **Type hints** pour la clarté
- **Docstrings** pour la documentation
- **Tests unitaires** pour le testeur lui-même

## 📞 Support

### Problèmes Courants

**Q : Les tests échouent après une mise à jour**
R : Vérifiez si c'est une régression ou un changement attendu. Utilisez `--verbose` pour plus de détails.

**Q : Comment ajouter un nouveau test ?**
R : Suivez la section "Ajouter une Fonctionnalité" ci-dessus.

**Q : Les baselines semblent incorrectes**
R : Supprimez-les et recréez avec `--create-baseline` après validation manuelle.

### Contact
- **Issues** : Utilisez le système d'issues du projet
- **Documentation** : Consultez `FEATURES_MATRIX.md` pour les détails
- **Code** : Voir `non_regression_tester.py` pour l'implémentation

---

**Note** : Ce système de tests est conçu pour évoluer avec IntaText. N'hésitez pas à l'adapter selon les besoins du projet !
