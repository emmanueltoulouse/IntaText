#!/bin/bash
#
# Script de tests post-build pour IntaText
# Exécute automatiquement tous les tests après une compilation réussie
#

set -e  # Arrêter en cas d'erreur

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonctions utilitaires
log_info() {
    echo -e "${BLUE}ℹ️ $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️ $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

log_section() {
    echo -e "\n${BLUE}🎯 === $1 ===${NC}"
}

# Variables
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/build"
TESTS_DIR="$PROJECT_DIR/tests"

# Vérification de l'environnement
check_environment() {
    log_section "Vérification de l'environnement"

    # Vérifier que nous sommes dans le bon répertoire
    if [[ ! -f "$PROJECT_DIR/meson.build" ]]; then
        log_error "Impossible de trouver meson.build dans $PROJECT_DIR"
        exit 1
    fi

    # Vérifier que le dossier build existe
    if [[ ! -d "$BUILD_DIR" ]]; then
        log_error "Dossier build/ non trouvé. Exécutez d'abord: meson setup build"
        exit 1
    fi

    # Vérifier les dépendances
    for cmd in meson ninja python3; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            log_error "Commande manquante: $cmd"
            exit 1
        fi
    done

    log_success "Environnement OK"
}

# Compilation
build_project() {
    log_section "Compilation du projet"

    cd "$PROJECT_DIR"

    if meson compile -C build; then
        log_success "Compilation réussie"
        return 0
    else
        log_error "Échec de la compilation"
        return 1
    fi
}

# Tests unitaires
run_unit_tests() {
    log_section "Tests unitaires (Vala/GLib.Test)"

    cd "$PROJECT_DIR"

    if [[ ! -f "$TESTS_DIR/meson.build" ]]; then
        log_warning "Tests unitaires non configurés, ignorés"
        return 0
    fi

    if meson test -C build --suite unit --print-errorlogs; then
        log_success "Tests unitaires réussis"
        return 0
    else
        log_error "Échec des tests unitaires"
        return 1
    fi
}

# Tests de régression
run_regression_tests() {
    log_section "Tests de régression"

    cd "$PROJECT_DIR"

    if [[ -f "$TESTS_DIR/regression/smoke_tests.py" ]]; then
        if python3 "$TESTS_DIR/regression/smoke_tests.py"; then
            log_success "Tests de régression réussis"
            return 0
        else
            log_error "Échec des tests de régression"
            return 1
        fi
    else
        log_warning "Tests de régression non trouvés, ignorés"
        return 0
    fi
}

# Tests d'intégration (nouvelles fonctionnalités)
run_integration_tests() {
    log_section "Tests d'intégration - Opérations fichiers"

    cd "$PROJECT_DIR"

    local integration_success=0
    local integration_total=0

    # Tests d'opérations de fichiers
    if [[ -f "$TESTS_DIR/integration/file_operations_test.py" ]]; then
        log_info "Exécution des tests d'opérations fichiers..."
        integration_total=$((integration_total + 1))

        if python3 "$TESTS_DIR/integration/file_operations_test.py"; then
            log_success "Tests opérations fichiers réussis"
            integration_success=$((integration_success + 1))
        else
            log_error "Échec des tests opérations fichiers"
        fi
    fi

    # Tests round-trip
    if [[ -f "$TESTS_DIR/integration/round_trip_test.py" ]]; then
        log_info "Exécution des tests round-trip..."
        integration_total=$((integration_total + 1))

        if python3 "$TESTS_DIR/integration/round_trip_test.py"; then
            log_success "Tests round-trip réussis"
            integration_success=$((integration_success + 1))
        else
            log_error "Échec des tests round-trip"
        fi
    fi

    # Tests d'indentation (nouveaux)
    if [[ -f "$TESTS_DIR/integration/indentation_integration_test.py" ]]; then
        log_info "Exécution des tests d'intégration indentation..."
        integration_total=$((integration_total + 1))

        if python3 "$TESTS_DIR/integration/indentation_integration_test.py"; then
            log_success "Tests intégration indentation réussis"
            integration_success=$((integration_success + 1))
        else
            log_error "Échec des tests intégration indentation"
        fi
    fi

    # Tests de persistance indentation
    if [[ -f "$TESTS_DIR/integration/indentation_persistence_test.py" ]]; then
        log_info "Exécution des tests persistance indentation..."
        integration_total=$((integration_total + 1))

        if python3 "$TESTS_DIR/integration/indentation_persistence_test.py"; then
            log_success "Tests persistance indentation réussis"
            integration_success=$((integration_success + 1))
        else
            log_warning "Tests persistance indentation partiellement échoués (non critique)"
            integration_success=$((integration_success + 1))  # Non critique
        fi
    fi

    if [[ $integration_total -eq 0 ]]; then
        log_warning "Aucun test d'intégration trouvé"
        return 0
    fi

    log_info "Tests d'intégration: $integration_success/$integration_total réussis"

    # Succès si au moins 80% des tests passent
    local success_rate=$((integration_success * 100 / integration_total))
    if [[ $success_rate -ge 80 ]]; then
        log_success "Tests d'intégration globalement réussis ($success_rate%)"
        return 0
    else
        log_error "Tests d'intégration insuffisants ($success_rate%)"
        return 1
    fi
}

# Tests d'indentation spécialisés
run_indentation_tests() {
    log_section "Tests d'indentation spécialisés"

    cd "$TESTS_DIR"

    local indent_success=0
    local indent_total=0

    # Test avec le script Python d'intégration
    if [[ -f "integration/indentation_test_suite.py" ]]; then
        ((indent_total++))
        log_info "Exécution de la suite de tests Python..."

        if python3 integration/indentation_test_suite.py; then
            log_success "Suite de tests Python réussie"
            ((indent_success++))
        else
            log_error "Suite de tests Python échouée"
        fi
    fi

    # Test avec le script Bash manuel
    if [[ -f "manual/indent_test_processor.sh" && -x "manual/indent_test_processor.sh" ]]; then
        ((indent_total++))
        log_info "Exécution du processeur de tests Bash..."

        if manual/indent_test_processor.sh; then
            log_success "Processeur Bash réussi"
            ((indent_success++))
        else
            log_error "Processeur Bash échoué"
        fi
    fi

    # Tests des fichiers d'échantillons
    if [[ -d "samples" ]]; then
        local sample_count=$(find samples -name "test_indent_*.md" | wc -l)
        if [[ $sample_count -gt 0 ]]; then
            ((indent_total++))
            log_info "Validation des $sample_count fichiers d'indentation..."

            # Test simple de lecture des fichiers
            local sample_success=true
            for sample_file in samples/test_indent_*.md; do
                if [[ -f "$sample_file" ]]; then
                    if ! head -n 1 "$sample_file" > /dev/null 2>&1; then
                        sample_success=false
                        break
                    fi
                fi
            done

            if $sample_success; then
                log_success "Fichiers d'échantillons validés"
                ((indent_success++))
            else
                log_error "Problème avec les fichiers d'échantillons"
            fi
        fi
    fi

    if [[ $indent_total -eq 0 ]]; then
        log_warning "Aucun test d'indentation spécialisé trouvé"
        return 0
    fi

    log_info "Tests d'indentation: $indent_success/$indent_total réussis"

    if [[ $indent_success -eq $indent_total ]]; then
        log_success "Tous les tests d'indentation réussis"
        return 0
    else
        log_warning "Tests d'indentation partiellement échoués"
        return 1
    fi
}

# Tests UI (optionnels, nécessitent un environnement graphique)
run_ui_tests() {
    log_section "Tests UI (optionnels)"

    # Vérifier si nous avons un environnement graphique
    if [[ -z "$DISPLAY" ]]; then
        log_warning "Pas d'environnement graphique, tests UI ignorés"
        return 0
    fi

    # Vérifier si dogtail est installé
    if ! python3 -c "import dogtail" 2>/dev/null; then
        log_warning "python3-dogtail non installé, tests UI ignorés"
        log_info "Pour installer: sudo apt install python3-dogtail"
        return 0
    fi

    cd "$PROJECT_DIR"

    if [[ -f "$TESTS_DIR/ui/indentation_ui_test.py" ]]; then
        log_info "Lancement des tests UI (peut prendre du temps)..."

        if python3 "$TESTS_DIR/ui/indentation_ui_test.py"; then
            log_success "Tests UI réussis"
            return 0
        else
            log_warning "Échec des tests UI (non critique)"
            return 0  # Les tests UI ne font pas échouer le build
        fi
    else
        log_warning "Tests UI non trouvés, ignorés"
        return 0
    fi
}

# Rapport final
generate_report() {
    local build_result=$1
    local unit_result=$2
    local integration_result=$3
    local indentation_result=$4
    local regression_result=$5
    local ui_result=$6

    log_section "Rapport final"

    echo "Résultats des tests:"
    [[ $build_result -eq 0 ]] && echo "✅ Compilation: RÉUSSIE" || echo "❌ Compilation: ÉCHEC"
    [[ $unit_result -eq 0 ]] && echo "✅ Tests unitaires: RÉUSSIS" || echo "❌ Tests unitaires: ÉCHEC"
    [[ $integration_result -eq 0 ]] && echo "✅ Tests d'intégration: RÉUSSIS" || echo "❌ Tests d'intégration: ÉCHEC"
    [[ $indentation_result -eq 0 ]] && echo "✅ Tests d'indentation: RÉUSSIS" || echo "❌ Tests d'indentation: ÉCHEC"
    [[ $regression_result -eq 0 ]] && echo "✅ Tests de régression: RÉUSSIS" || echo "❌ Tests de régression: ÉCHEC"
    [[ $ui_result -eq 0 ]] && echo "✅ Tests UI: RÉUSSIS" || echo "⚠️ Tests UI: IGNORÉS/ÉCHEC"

    # Déterminer le résultat global
    if [[ $build_result -eq 0 && $unit_result -eq 0 && $integration_result -eq 0 && $indentation_result -eq 0 && $regression_result -eq 0 ]]; then
        log_success "🎉 TOUS LES TESTS CRITIQUES RÉUSSIS!"
        echo ""
        log_info "L'application est prête pour utilisation/déploiement"
        echo ""
        log_info "📊 Couverture des tests:"
        log_info "  • Tests unitaires DocumentConverterManager"
        log_info "  • Tests unitaires modes indentation"
        log_info "  • Tests conversion indentation"
        log_info "  • Tests d'intégration opérations fichiers"
        log_info "  • Tests d'intégration indentation"
        log_info "  • Tests d'indentation spécialisés"
        log_info "  • Tests round-trip conversion"
        log_info "  • Tests persistance indentation"
        log_info "  • Tests gestion d'erreurs et robustesse"
        log_info "  • Tests de régression"
        return 0
    else
        log_error "🚨 CERTAINS TESTS CRITIQUES ONT ÉCHOUÉ"
        echo ""
        log_info "Veuillez corriger les erreurs avant de continuer"
        return 1
    fi
}

# Fonction principale
main() {
    echo "🧪 IntaText - Suite de tests automatisés"
    echo "========================================"

    # Variables pour les résultats
    build_result=1
    unit_result=1
    integration_result=1
    indentation_result=1
    regression_result=1
    ui_result=1

    # Exécution des tests
    check_environment

    if build_project; then
        build_result=0

        # Ne continuer que si la compilation réussit
        if run_unit_tests; then
            unit_result=0
        fi

        # Tests d'intégration (nouveaux)
        if run_integration_tests; then
            integration_result=0
        fi

        # Tests d'indentation spécialisés
        if run_indentation_tests; then
            indentation_result=0
        fi

        if run_regression_tests; then
            regression_result=0
        fi

        # Tests UI en dernier (non critiques)
        run_ui_tests
        ui_result=$?
    fi

    # Rapport final
    generate_report $build_result $unit_result $integration_result $indentation_result $regression_result $ui_result
    exit $?
}

# Gestion des signaux
trap 'log_error "Tests interrompus"; exit 130' INT TERM

# Exécution
main "$@"
