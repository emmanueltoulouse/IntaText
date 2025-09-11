#!/bin/bash

# Script de test pour les enrichissements de tableaux

echo "Test des enrichissements dans les tableaux d'IntaText"
echo "======================================================"

# Créer un fichier de test temporaire
TEST_FILE="/tmp/test_enrichissements_tableaux.md"

cat > "$TEST_FILE" << 'EOF'
# Test des enrichissements de tableaux

| Simple | Couleurs | Liens |
|--------|----------|-------|
| Texte normal | <span style="color:red">Rouge</span> | [Google](https://google.com) |
| **Gras** | <span style="color:blue">Bleu</span> | [Local](./test.md) |
| *Italique* | <span style="background-color:yellow">Jaune</span> | ![Image](test.png) |

| Combinaisons | Description |
|--------------|-------------|
| **<span style="color:green">Gras vert</span>** | Texte gras ET coloré |
| *[Lien italique](https://example.com)* | Lien avec style italique |
| `<span style="color:purple">Code coloré</span>` | Code avec couleur |
EOF

echo "Fichier de test créé : $TEST_FILE"
echo ""
echo "Contenu du fichier :"
echo "-------------------"
cat "$TEST_FILE"
echo ""
echo "Vous pouvez maintenant ouvrir ce fichier dans IntaText"
echo "pour vérifier que tous les enrichissements fonctionnent"
echo "correctement dans les tableaux."
