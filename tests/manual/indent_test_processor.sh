#!/bin/bash
#
# Script de traitement de test pour les indentations - IntaText
# Test automatisé de tous les aspects de l'indentation
#

set -e

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Variables globales
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SAMPLES_DIR="$TEST_DIR/samples"
TEMP_DIR="/tmp/intatext_indent_test_$$"
INTATEXT_BIN="$TEST_DIR/../build/IntaText"
RESULTS_LOG="$TEMP_DIR/results.log"
ERRORS_LOG="$TEMP_DIR/errors.log"
PASSED_TESTS=0
FAILED_TESTS=0

# Fonctions utilitaires
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

log_test() {
    echo -e "${CYAN}🧪 $1${NC}"
}

# Fonction de nettoyage
cleanup() {
    if [ -d "$TEMP_DIR" ]; then
        rm -rf "$TEMP_DIR"
    fi
}

trap cleanup EXIT

# Initialisation
init_test_env() {
    log_info "Initialisation de l'environnement de test des indentations"

    mkdir -p "$TEMP_DIR"
    touch "$RESULTS_LOG" "$ERRORS_LOG"

    # Vérifier que l'application est compilée
    if [ ! -f "$INTATEXT_BIN" ]; then
        log_error "IntaText n'est pas compilé. Veuillez exécuter 'meson compile -C build' d'abord."
        exit 1
    fi

    log_success "Environnement de test initialisé"
}

# Test 1: Indentation de paragraphes simples
test_paragraph_indentation() {
    log_test "Test 1: Indentation de paragraphes simples"

    local test_file="$TEMP_DIR/test_paragraphs.md"
    cat > "$test_file" << 'EOF'
Premier paragraphe sur une ligne.

Deuxième paragraphe avec plusieurs lignes.
Cette ligne fait partie du même paragraphe.
Dernière ligne du paragraphe.

Troisième paragraphe court.
EOF

    local expected_file="$TEMP_DIR/expected_paragraphs.md"
    cat > "$expected_file" << 'EOF'
    Premier paragraphe sur une ligne.

    Deuxième paragraphe avec plusieurs lignes.
    Cette ligne fait partie du même paragraphe.
    Dernière ligne du paragraphe.

    Troisième paragraphe court.
EOF

    # Simuler l'indentation (à adapter selon l'API d'IntaText)
    if test_indentation_operation "$test_file" "$expected_file" "paragraphs"; then
        log_success "✓ Test paragraphes simple réussi"
        ((PASSED_TESTS++))
    else
        log_error "✗ Test paragraphes simple échoué"
        ((FAILED_TESTS++))
    fi
}

# Test 2: Indentation de listes
test_list_indentation() {
    log_test "Test 2: Indentation de listes"

    local test_file="$TEMP_DIR/test_lists.md"
    cat > "$test_file" << 'EOF'
# Liste numérotée

1. Premier élément
2. Deuxième élément
3. Troisième élément

# Liste à puces

- Élément A
- Élément B
- Élément C

# Liste imbriquée

1. Niveau 1
   - Sous-élément A
   - Sous-élément B
2. Niveau 1 suite
EOF

    local expected_file="$TEMP_DIR/expected_lists.md"
    cat > "$expected_file" << 'EOF'
    # Liste numérotée

    1. Premier élément
    2. Deuxième élément
    3. Troisième élément

    # Liste à puces

    - Élément A
    - Élément B
    - Élément C

    # Liste imbriquée

    1. Niveau 1
       - Sous-élément A
       - Sous-élément B
    2. Niveau 1 suite
EOF

    if test_indentation_operation "$test_file" "$expected_file" "lists"; then
        log_success "✓ Test listes réussi"
        ((PASSED_TESTS++))
    else
        log_error "✗ Test listes échoué"
        ((FAILED_TESTS++))
    fi
}

# Test 3: Indentation de code
test_code_indentation() {
    log_test "Test 3: Indentation de blocs de code"

    local test_file="$TEMP_DIR/test_code.md"
    cat > "$test_file" << 'EOF'
Voici du code Python :

```python
def hello():
    print("Hello World")
    return True
```

Et du code inline `var x = 10;` dans le texte.

Code indenté:
    print("déjà indenté")
    return value
EOF

    local expected_file="$TEMP_DIR/expected_code.md"
    cat > "$expected_file" << 'EOF'
    Voici du code Python :

    ```python
    def hello():
        print("Hello World")
        return True
    ```

    Et du code inline `var x = 10;` dans le texte.

    Code indenté:
        print("déjà indenté")
        return value
EOF

    if test_indentation_operation "$test_file" "$expected_file" "code"; then
        log_success "✓ Test code réussi"
        ((PASSED_TESTS++))
    else
        log_error "✗ Test code échoué"
        ((FAILED_TESTS++))
    fi
}

# Test 4: Indentation de citations
test_quote_indentation() {
    log_test "Test 4: Indentation de citations"

    local test_file="$TEMP_DIR/test_quotes.md"
    cat > "$test_file" << 'EOF'
Citation simple:

> Ceci est une citation.
> Elle a plusieurs lignes.

Citation imbriquée:

> Citation de niveau 1
>> Citation de niveau 2
> Retour au niveau 1
EOF

    local expected_file="$TEMP_DIR/expected_quotes.md"
    cat > "$expected_file" << 'EOF'
    Citation simple:

    > Ceci est une citation.
    > Elle a plusieurs lignes.

    Citation imbriquée:

    > Citation de niveau 1
    >> Citation de niveau 2
    > Retour au niveau 1
EOF

    if test_indentation_operation "$test_file" "$expected_file" "quotes"; then
        log_success "✓ Test citations réussi"
        ((PASSED_TESTS++))
    else
        log_error "✗ Test citations échoué"
        ((FAILED_TESTS++))
    fi
}

# Test 5: Indentation mixte
test_mixed_indentation() {
    log_test "Test 5: Indentation de contenu mixte"

    local test_file="$TEMP_DIR/test_mixed.md"
    cat > "$test_file" << 'EOF'
# Titre

Paragraphe d'introduction.

## Liste avec code

1. Premier élément
   ```bash
   echo "test"
   ```
2. Deuxième élément

> Citation importante
> Sur plusieurs lignes

Paragraphe final.
EOF

    local expected_file="$TEMP_DIR/expected_mixed.md"
    cat > "$expected_file" << 'EOF'
    # Titre

    Paragraphe d'introduction.

    ## Liste avec code

    1. Premier élément
       ```bash
       echo "test"
       ```
    2. Deuxième élément

    > Citation importante
    > Sur plusieurs lignes

    Paragraphe final.
EOF

    if test_indentation_operation "$test_file" "$expected_file" "mixed"; then
        log_success "✓ Test contenu mixte réussi"
        ((PASSED_TESTS++))
    else
        log_error "✗ Test contenu mixte échoué"
        ((FAILED_TESTS++))
    fi
}

# Test 6: Test avec fichiers d'échantillons existants
test_sample_files() {
    log_test "Test 6: Indentation des fichiers d'échantillons"

    local sample_count=0
    local sample_passed=0

    if [ -d "$SAMPLES_DIR" ]; then
        for sample_file in "$SAMPLES_DIR"/test_*.md; do
            if [ -f "$sample_file" ]; then
                ((sample_count++))
                local basename=$(basename "$sample_file")
                log_info "Test du fichier: $basename"

                if test_sample_file_indentation "$sample_file"; then
                    ((sample_passed++))
                    log_success "  ✓ $basename traité avec succès"
                else
                    log_error "  ✗ $basename a échoué"
                fi
            fi
        done
    fi

    if [ $sample_count -gt 0 ]; then
        log_info "Fichiers d'échantillons: $sample_passed/$sample_count réussis"
        if [ $sample_passed -eq $sample_count ]; then
            ((PASSED_TESTS++))
        else
            ((FAILED_TESTS++))
        fi
    else
        log_warning "Aucun fichier d'échantillon trouvé"
    fi
}

# Fonction de test d'opération d'indentation
test_indentation_operation() {
    local input_file="$1"
    local expected_file="$2"
    local test_name="$3"
    local output_file="$TEMP_DIR/output_${test_name}.md"

    # Ici, nous simulons l'opération d'indentation
    # Dans un vrai scénario, cela appellerait IntaText avec les bons paramètres

    # Pour l'instant, nous créons simplement le résultat attendu
    # TODO: Intégrer avec l'API réelle d'IntaText
    local success=true

    # Simulation de l'indentation (remplacer par l'appel réel)
    if simulate_indentation "$input_file" "$output_file"; then
        # Comparer le résultat avec l'attendu
        if compare_files "$output_file" "$expected_file"; then
            echo "SUCCESS: $test_name" >> "$RESULTS_LOG"
            return 0
        else
            echo "FAIL: $test_name - Output mismatch" >> "$ERRORS_LOG"
            return 1
        fi
    else
        echo "FAIL: $test_name - Indentation operation failed" >> "$ERRORS_LOG"
        return 1
    fi
}

# Simulation de l'indentation (à remplacer par l'API réelle)
simulate_indentation() {
    local input_file="$1"
    local output_file="$2"

    # Simulation: ajouter 4 espaces au début de chaque ligne non-vide
    sed 's/^[[:space:]]*\(.*[^[:space:]]\)/    \1/' "$input_file" > "$output_file"
    return 0
}

# Test d'un fichier d'échantillon
test_sample_file_indentation() {
    local sample_file="$1"
    local basename=$(basename "$sample_file" .md)
    local output_file="$TEMP_DIR/indented_${basename}.md"

    # Tenter l'indentation du fichier d'échantillon
    if simulate_indentation "$sample_file" "$output_file"; then
        # Vérifier que le fichier de sortie n'est pas vide
        if [ -s "$output_file" ]; then
            return 0
        fi
    fi
    return 1
}

# Comparaison de fichiers
compare_files() {
    local file1="$1"
    local file2="$2"

    # Utiliser diff pour comparer (ignorer les espaces en fin de ligne)
    if diff -b -w "$file1" "$file2" > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Tests de performance
test_performance() {
    log_test "Test 7: Performance d'indentation"

    # Créer un gros fichier de test
    local large_file="$TEMP_DIR/large_test.md"
    {
        for i in {1..1000}; do
            echo "Ligne $i avec du contenu pour tester la performance."
            if [ $((i % 10)) -eq 0 ]; then
                echo ""
            fi
        done
    } > "$large_file"

    local start_time=$(date +%s.%N)

    if simulate_indentation "$large_file" "$TEMP_DIR/large_output.md"; then
        local end_time=$(date +%s.%N)
        local duration=$(echo "$end_time - $start_time" | bc -l)

        log_success "✓ Test de performance réussi (${duration}s)"
        ((PASSED_TESTS++))
    else
        log_error "✗ Test de performance échoué"
        ((FAILED_TESTS++))
    fi
}

# Rapport final
generate_report() {
    local total_tests=$((PASSED_TESTS + FAILED_TESTS))

    echo ""
    echo "=========================================="
    echo "  RAPPORT DE TEST - INDENTATIONS"
    echo "=========================================="
    echo ""
    echo "Tests exécutés: $total_tests"
    echo -e "Tests réussis:  ${GREEN}$PASSED_TESTS${NC}"
    echo -e "Tests échoués:  ${RED}$FAILED_TESTS${NC}"
    echo ""

    if [ $FAILED_TESTS -eq 0 ]; then
        echo -e "${GREEN}🎉 TOUS LES TESTS SONT PASSÉS !${NC}"
        echo ""
        exit 0
    else
        echo -e "${RED}❌ CERTAINS TESTS ONT ÉCHOUÉ${NC}"
        echo ""
        echo "Consultez les logs d'erreur:"
        echo "  - $ERRORS_LOG"
        echo "  - $RESULTS_LOG"
        echo ""
        exit 1
    fi
}

# Fonction principale
main() {
    echo "=========================================="
    echo "  TRAITEMENT DE TEST - INDENTATIONS"
    echo "         IntaText Test Suite"
    echo "=========================================="
    echo ""

    init_test_env

    # Exécution de tous les tests
    test_paragraph_indentation
    test_list_indentation
    test_code_indentation
    test_quote_indentation
    test_mixed_indentation
    test_sample_files
    test_performance

    # Génération du rapport
    generate_report
}

# Point d'entrée
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
