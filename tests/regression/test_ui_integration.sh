#!/bin/bash
#
# Script de test d'intégration UI pour IntaText
# Lance l'application, exécute les tests UI d'accessibilité, puis nettoie
#

set -e

# Configuration
PROJECT_ROOT="/home/emmanuel/Bureau/Projects/IntaText"
INTATEXT_BIN="$PROJECT_ROOT/build/IntaText"
TEST_DIR="$PROJECT_ROOT/tests/regression"
LOG_FILE="/tmp/intatext_ui_test.log"

# Couleurs pour le log
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[UI-TEST]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[UI-TEST]${NC} ✅ $1"
}

log_warning() {
    echo -e "${YELLOW}[UI-TEST]${NC} ⚠️  $1"
}

log_error() {
    echo -e "${RED}[UI-TEST]${NC} ❌ $1"
}

cleanup() {
    log "Nettoyage..."

    # Fermer toutes les instances d'IntaText
    pkill -f IntaText || true

    # Attendre que les processus se ferment
    sleep 2

    # Supprimer le fichier de log temporaire
    rm -f "$LOG_FILE"

    log_success "Nettoyage terminé"
}

# Gestionnaire de signaux pour le nettoyage
trap cleanup EXIT INT TERM

main() {
    log "Démarrage des tests d'intégration UI..."

    # Vérifications préliminaires
    if [ ! -f "$INTATEXT_BIN" ]; then
        log_error "Exécutable IntaText non trouvé: $INTATEXT_BIN"
        log "Veuillez compiler l'application d'abord avec: meson compile -C build"
        exit 1
    fi

    if [ ! -f "$TEST_DIR/non_regression_tester.py" ]; then
        log_error "Testeur de régression non trouvé: $TEST_DIR/non_regression_tester.py"
        exit 1
    fi

    # Vérifier les dépendances d'accessibilité
    log "Vérification des dépendances d'accessibilité..."
    if ! python3 -c "import gi; gi.require_version('Atspi', '2.0'); from gi.repository import Atspi" 2>/dev/null; then
        log_error "Bibliothèques d'accessibilité non disponibles"
        log "Veuillez installer: sudo apt install python3-gi gir1.2-atspi-2.0"
        exit 1
    fi
    log_success "Dépendances d'accessibilité OK"

    # Nettoyer les instances existantes
    pkill -f IntaText || true
    sleep 1

    # Lancer IntaText en arrière-plan
    log "Lancement d'IntaText en arrière-plan..."
    cd "$PROJECT_ROOT"
    export GSETTINGS_SCHEMA_DIR=/usr/local/share/glib-2.0/schemas
    "$INTATEXT_BIN" > "$LOG_FILE" 2>&1 &
    INTATEXT_PID=$!

    # Attendre que l'application démarre
    log "Attente du démarrage de l'application..."
    sleep 5

    # Vérifier que l'application est toujours en cours d'exécution
    if ! kill -0 $INTATEXT_PID 2>/dev/null; then
        log_error "L'application IntaText a échoué au démarrage"
        cat "$LOG_FILE"
        exit 1
    fi
    log_success "IntaText démarré (PID: $INTATEXT_PID)"

    # Attendre un peu plus pour que l'interface soit complètement chargée
    log "Attente du chargement complet de l'interface..."
    sleep 3

    # Exécuter les tests UI
    log "Exécution des tests UI d'accessibilité..."
    cd "$TEST_DIR"

    if ./run_regression_tests.sh --ui-only --verbose; then
        log_success "Tests UI réussis !"
        exit_code=0
    else
        log_error "Échec des tests UI"
        exit_code=1
    fi

    # Afficher le log de l'application si les tests ont échoué
    if [ $exit_code -ne 0 ] && [ -f "$LOG_FILE" ]; then
        log "Log de l'application IntaText:"
        echo "----------------------------------------"
        cat "$LOG_FILE"
        echo "----------------------------------------"
    fi

    return $exit_code
}

# Point d'entrée
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    main "$@"
fi
