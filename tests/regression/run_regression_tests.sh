#!/bin/bash
# Script de Tests de Non-Régression - IntaText
# =============================================

set -e

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Configuration par défaut
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BUILD_DIR="$PROJECT_ROOT/build"
TESTS_DIR="$PROJECT_ROOT/tests"
REGRESSION_DIR="$TESTS_DIR/regression"

# Paramètres par défaut
VERBOSE=false
CREATE_BASELINE=false
UPDATE_BASELINE=false
FILTER=""
CATEGORIES=""
TIMEOUT=30
INTATEXT_PATH="$BUILD_DIR/IntaText"
PYTHON_TESTER="$REGRESSION_DIR/non_regression_tester.py"
ENABLE_UI_TESTS=true
UI_ONLY=false

# Fonction d'aide
show_help() {
    echo -e "${WHITE}Tests de Non-Régression - IntaText${NC}"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help              Afficher cette aide"
    echo "  -v, --verbose           Mode verbeux"
    echo "  -f, --filter PATTERN    Filtrer les tests (nom ou ID)"
    echo "  -c, --category CAT      Catégorie de tests (peut être répété)"
    echo "  -t, --timeout SEC       Timeout pour les tests (défaut: 30s)"
    echo "  -b, --build             Compiler avant les tests"
    echo "  -B, --create-baseline   Créer les baselines manquantes"
    echo "  -U, --update-baseline   Mettre à jour les baselines"
    echo "  -p, --path PATH         Chemin vers l'exécutable IntaText"
    echo "  --quick                 Tests rapides (priorité 1 seulement)"
    echo "  --full                  Tests complets (toutes priorités)"
    echo "  --critical              Tests critiques seulement"
    echo "  --no-ui                 Désactiver les tests d'interface utilisateur"
    echo "  --ui-only               Exécuter uniquement les tests d'interface utilisateur"
    echo ""
    echo "Catégories disponibles:"
    echo "  formatage_base, formatage_combiné, titres, listes, citations,"
    echo "  code, tableaux, liens, images, imbrication, cas_limites,"
    echo "  plugins, document, ui_wysiwyg, ui_wysiwyg_imbrication"
    echo ""
    echo "Exemples:"
    echo "  $0 --build --quick"
    echo "  $0 --filter bold --verbose"
    echo "  $0 --category formatage_base --category listes"
    echo "  $0 --create-baseline --category formatage_base"
    echo "  $0 --ui-only --verbose"
    echo "  $0 --no-ui --quick"
}

# Fonction de log
log() {
    local color="$1"
    local message="$2"
    echo -e "${color}${message}${NC}"
}

log_info() {
    log "$BLUE" "ℹ️  $1"
}

log_success() {
    log "$GREEN" "✅ $1"
}

log_warning() {
    log "$YELLOW" "⚠️  $1"
}

log_error() {
    log "$RED" "❌ $1"
}

log_header() {
    echo
    log "$WHITE" "=================================================="
    log "$WHITE" "  $1"
    log "$WHITE" "=================================================="
    echo
}

# Vérification des prérequis
check_prerequisites() {
    log_info "Vérification des prérequis..."

    # Vérifier Python 3
    if ! command -v python3 &> /dev/null; then
        log_error "Python 3 non trouvé"
        exit 1
    fi

    # Vérifier que le script Python existe
    if [ ! -f "$PYTHON_TESTER" ]; then
        log_error "Script de test non trouvé: $PYTHON_TESTER"
        exit 1
    fi

    # Vérifier les permissions
    if [ ! -x "$PYTHON_TESTER" ]; then
        chmod +x "$PYTHON_TESTER"
    fi

    # Vérifier les dépendances UI si les tests UI sont activés
    if [ "$ENABLE_UI_TESTS" = true ] && [ "$UI_ONLY" = false ]; then
        log_info "Vérification des dépendances d'accessibilité..."
        if ! python3 -c "import gi; gi.require_version('Atspi', '2.0')" 2>/dev/null; then
            log_warning "Bibliothèques d'accessibilité non disponibles - tests UI désactivés"
            ENABLE_UI_TESTS=false
        fi
    fi

    log_success "Prérequis OK"
}

# Construction du projet
build_project() {
    log_header "CONSTRUCTION DU PROJET"

    cd "$PROJECT_ROOT"

    # Vérifier les dépendances
    log_info "Vérification des dépendances..."
    if ! command -v valac &> /dev/null; then
        log_error "valac (compilateur Vala) non trouvé"
        exit 1
    fi

    if ! command -v meson &> /dev/null; then
        log_error "meson non trouvé"
        exit 1
    fi

    # Configuration si nécessaire
    if [ ! -d "$BUILD_DIR" ]; then
        log_info "Configuration du projet avec Meson..."
        meson setup build
    fi

    # Compilation
    log_info "Compilation avec Ninja..."
    ninja -C build

    # Vérifier que l'exécutable existe
    if [ ! -f "$INTATEXT_PATH" ]; then
        log_error "Exécutable non trouvé après compilation: $INTATEXT_PATH"
        exit 1
    fi

    log_success "Compilation réussie"
}

# Préparation de l'environnement de test
prepare_test_environment() {
    log_info "Préparation de l'environnement de test..."

    # Créer les répertoires de test
    mkdir -p "$REGRESSION_DIR"
    mkdir -p "$REGRESSION_DIR/baselines"
    mkdir -p "$REGRESSION_DIR/reports"

    # Copier les fichiers de configuration si nécessaire
    if [ ! -f "$REGRESSION_DIR/config.py" ]; then
        log_warning "Fichier de configuration manquant"
    fi

    # Vérifier l'espace disque
    local available_space=$(df "$TESTS_DIR" | awk 'NR==2 {print $4}')
    if [ "$available_space" -lt 100000 ]; then  # 100MB
        log_warning "Espace disque faible pour les tests"
    fi

    log_success "Environnement de test prêt"
}

# Exécution des tests
run_tests() {
    log_header "EXÉCUTION DES TESTS DE NON-RÉGRESSION"

    # Construire la commande Python
    local cmd="python3 '$PYTHON_TESTER'"

    # Ajouter les options
    if [ "$UI_ONLY" = true ]; then
        cmd="$cmd --ui-only"
    elif [ "$ENABLE_UI_TESTS" = false ]; then
        cmd="$cmd --no-ui"
    fi

    if [ "$VERBOSE" = true ]; then
        cmd="$cmd --verbose"
    fi

    if [ "$CREATE_BASELINE" = true ]; then
        cmd="$cmd --create-baseline"
    fi

    if [ "$UPDATE_BASELINE" = true ]; then
        cmd="$cmd --update-baseline"
    fi

    if [ -n "$FILTER" ]; then
        cmd="$cmd --filter '$FILTER'"
    fi

    if [ -n "$CATEGORIES" ]; then
        for category in $CATEGORIES; do
            cmd="$cmd --category '$category'"
        done
    fi

    if [ -n "$TIMEOUT" ]; then
        cmd="$cmd --timeout $TIMEOUT"
    fi

    if [ -n "$INTATEXT_PATH" ]; then
        cmd="$cmd --intatext-path '$INTATEXT_PATH'"
    fi

    # Exécuter les tests
    log_info "Lancement des tests..."
    echo "Commande: $cmd"
    echo

    eval "$cmd"
    local exit_code=$?

    # Traiter le code de sortie
    case $exit_code in
        0)
            log_success "Tous les tests ont réussi !"
            ;;
        1)
            log_warning "Certains tests non-critiques ont échoué"
            ;;
        2)
            log_error "Des tests critiques ont échoué !"
            ;;
        *)
            log_error "Erreur d'exécution des tests"
            ;;
    esac

    return $exit_code
}

# Génération du rapport
generate_report() {
    log_info "Génération du rapport de test..."

    local report_dir="$REGRESSION_DIR/reports"
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local report_file="$report_dir/regression_report_$timestamp.html"

    # Créer un rapport HTML simple si disponible
    if [ -f "$REGRESSION_DIR/regression_report.json" ]; then
        cat > "$report_file" << EOF
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Rapport de Tests de Non-Régression - IntaText</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background: #f0f0f0; padding: 10px; border-radius: 5px; }
        .success { color: green; }
        .warning { color: orange; }
        .error { color: red; }
        .category { margin: 10px 0; padding: 10px; border: 1px solid #ddd; }
        pre { background: #f5f5f5; padding: 10px; overflow-x: auto; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Rapport de Tests de Non-Régression - IntaText</h1>
        <p>Généré le: $(date)</p>
    </div>

    <h2>Résumé</h2>
    <p>Voir le fichier JSON pour les détails complets.</p>

    <h2>Fichiers de rapport</h2>
    <ul>
        <li><a href="regression_report.json">Rapport JSON détaillé</a></li>
    </ul>
</body>
</html>
EOF
        log_success "Rapport HTML généré: $report_file"
    fi
}

# Nettoyage
cleanup() {
    log_info "Nettoyage des fichiers temporaires..."

    # Supprimer les fichiers temporaires
    find /tmp -name "intatext_regression_*" -type d -mtime +1 -exec rm -rf {} \; 2>/dev/null || true

    log_success "Nettoyage terminé"
}

# Traitement des arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -f|--filter)
            FILTER="$2"
            shift 2
            ;;
        -c|--category)
            CATEGORIES="$CATEGORIES $2"
            shift 2
            ;;
        -t|--timeout)
            TIMEOUT="$2"
            shift 2
            ;;
        -b|--build)
            BUILD=true
            shift
            ;;
        -B|--create-baseline)
            CREATE_BASELINE=true
            shift
            ;;
        -U|--update-baseline)
            UPDATE_BASELINE=true
            shift
            ;;
        -p|--path)
            INTATEXT_PATH="$2"
            shift 2
            ;;
        --quick)
            CATEGORIES="formatage_base titres listes code document"
            shift
            ;;
        --full)
            # Toutes les catégories (défaut)
            shift
            ;;
        --critical)
            CATEGORIES="formatage_base formatage_combiné titres listes code document imbrication cas_limites"
            shift
            ;;
        --no-ui)
            ENABLE_UI_TESTS=false
            shift
            ;;
        --ui-only)
            UI_ONLY=true
            shift
            ;;
        *)
            log_error "Option inconnue: $1"
            show_help
            exit 1
            ;;
    esac
done

# Fonction principale
main() {
    log_header "TESTS DE NON-RÉGRESSION - INTATEXT"

    # Vérifications initiales
    check_prerequisites

    # Construction si demandée
    if [ "$BUILD" = true ]; then
        build_project
    fi

    # Préparation
    prepare_test_environment

    # Exécution des tests
    local test_exit_code=0
    if run_tests; then
        log_success "Tests terminés avec succès"
    else
        test_exit_code=$?
        log_warning "Tests terminés avec des problèmes"
    fi

    # Génération du rapport
    generate_report

    # Nettoyage
    cleanup

    # Affichage du résumé final
    echo
    log_header "RÉSUMÉ FINAL"

    case $test_exit_code in
        0)
            log_success "✅ Tous les tests de non-régression ont réussi"
            log_success "L'application est stable et prête pour la release"
            ;;
        1)
            log_warning "⚠️  Quelques tests non-critiques ont échoué"
            log_warning "Vérifiez les détails mais la release peut continuer"
            ;;
        2)
            log_error "🚨 Des tests critiques ont échoué"
            log_error "La release doit être bloquée jusqu'à résolution"
            ;;
    esac

    echo
    log_info "Logs détaillés disponibles dans: $REGRESSION_DIR/reports/"

    exit $test_exit_code
}

# Piège pour le nettoyage en cas d'interruption
trap cleanup EXIT

# Exécution
main "$@"
