#!/bin/bash

# Script de test simple pour le formatage Markdown
echo "Test du formatage Markdown..."

# Attendre un peu que l'application soit prête
sleep 3

# Se concentrer sur la fenêtre de l'application
xdotool search --name "IntaText" windowactivate

# Attendre que la fenêtre soit active
sleep 1

# Taper du texte avec formatage
echo "Saisie du texte formaté..."
xdotool type "**Texte en gras**"
xdotool key Return
xdotool type "*Texte en italique*"
xdotool key Return
xdotool type "~~Texte barré~~"
xdotool key Return
xdotool type "Texte normal"

echo "Test terminé. Vérifiez les logs de l'application."
