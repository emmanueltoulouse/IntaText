#!/bin/bash
#
# Lanceur principal pour les tests d'indentation IntaText
# Permet de choisir le type de test à exécuter
#

set -e

# Couleurs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Répertoires
TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$TESTS_DIR")"

echo -e "${BLUE}=========================================="
echo -e "  TESTS D'INDENTATION - INTATEXT"
echo -e "==========================================${NC}"
echo ""

# Vérification de la compilation
if [ ! -f "$PROJECT_DIR/build/IntaText" ]; then
    echo -e "${RED}❌ IntaText n'est pas compilé${NC}"
    echo "Voulez-vous compiler maintenant ? (y/N)"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}🔨 Compilation en cours...${NC}"
        cd "$PROJECT_DIR"
        meson compile -C build
        echo -e "${GREEN}✅ Compilation terminée${NC}"
        echo ""
    else
        echo "Veuillez compiler IntaText avant de lancer les tests:"
        echo "  cd $PROJECT_DIR && meson compile -C build"
        exit 1
    fi
fi

echo "Choisissez le type de test à exécuter:"
echo ""
echo "1) Tests d'intégration Python (recommandé)"
echo "2) Tests manuels Bash"
echo "3) Tests unitaires existants"
echo "4) Tous les tests"
echo "5) Tests rapides (échantillons seulement)"
echo ""
echo -n "Votre choix (1-5): "
read -r choice

case $choice in
    1)
        echo -e "${BLUE}🐍 Lancement des tests d'intégration Python${NC}"
        echo ""
        cd "$TESTS_DIR"
        python3 integration/indentation_test_suite.py --verbose
        ;;
    2)
        echo -e "${BLUE}📝 Lancement des tests manuels Bash${NC}"
        echo ""
        cd "$TESTS_DIR"
        manual/indent_test_processor.sh
        ;;
    3)
        echo -e "${BLUE}🧪 Lancement des tests unitaires existants${NC}"
        echo ""
        cd "$PROJECT_DIR"
        meson test -C build --suite indentation
        ;;
    4)
        echo -e "${BLUE}🚀 Lancement de tous les tests${NC}"
        echo ""

        echo -e "${YELLOW}--- Tests unitaires ---${NC}"
        cd "$PROJECT_DIR"
        meson test -C build --suite indentation || true

        echo -e "${YELLOW}--- Tests d'intégration Python ---${NC}"
        cd "$TESTS_DIR"
        python3 integration/indentation_test_suite.py || true

        echo -e "${YELLOW}--- Tests manuels Bash ---${NC}"
        manual/indent_test_processor.sh || true
        ;;
    5)
        echo -e "${BLUE}⚡ Tests rapides sur les échantillons${NC}"
        echo ""
        cd "$TESTS_DIR"
        python3 integration/indentation_test_suite.py --samples-only
        ;;
    *)
        echo -e "${RED}❌ Choix invalide${NC}"
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}✅ Tests d'indentation terminés${NC}"
echo ""

# Proposer de voir les résultats détaillés
if [ -d "/tmp" ]; then
    temp_files=$(find /tmp -name "*intatext_indent_*" -type d 2>/dev/null | head -1)
    if [ -n "$temp_files" ]; then
        echo "Fichiers de résultats disponibles dans: $temp_files"
        echo "Voulez-vous voir les détails ? (y/N)"
        read -r show_details
        if [[ "$show_details" =~ ^[Yy]$ ]]; then
            echo ""
            echo -e "${BLUE}📊 Résultats détaillés:${NC}"
            if [ -f "$temp_files/indent_test_report.json" ]; then
                cat "$temp_files/indent_test_report.json" | python3 -m json.tool
            fi
            if [ -f "$temp_files/results.log" ]; then
                echo ""
                echo -e "${BLUE}📝 Log des résultats:${NC}"
                cat "$temp_files/results.log"
            fi
        fi
    fi
fi
