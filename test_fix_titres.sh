#!/bin/bash

echo "Test de vérification de la correction de duplication des titres"
echo "================================================================"

# Fichier de test simple
cat > test_simple_titres.md << 'EOF'
# Premier titre H1

Paragraphe sous H1.

## Titre H2

Paragraphe sous H2.

### Titre H3

Paragraphe sous H3.
EOF

echo "Fichier de test créé : test_simple_titres.md"
echo "Contenu :"
cat test_simple_titres.md

echo ""
echo "Pour tester la correction :"
echo "1. Ouvrez IntaText"
echo "2. Ouvrez le fichier test_simple_titres.md"
echo "3. Passez en mode WYSIWYG si nécessaire"
echo "4. Sauvegardez le fichier"
echo "5. Vérifiez que les titres ne sont pas dupliqués dans le fichier sauvé"

echo ""
echo "La correction empêche maintenant flush_paragraph_block() de traiter"
echo "le contenu déjà marqué comme titre (avec les tags tag_heading1/2/3)"
echo "comme des paragraphes, évitant ainsi la duplication."
