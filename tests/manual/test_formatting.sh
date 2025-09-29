#!/bin/bash

# Script de test pour vérifier le formatage Markdown dans IntaText
echo "Test du formatage Markdown dans IntaText"

# Attendre que l'application soit lancée
sleep 2

# Insérer du texte avec formatage Markdown via xdotool
# **Texte en gras**
# *Texte en italique*
# ~~Texte barré~~

echo "Insertion de texte formaté..."
xdotool type "**Ceci est du texte en gras**"
xdotool key Return
xdotool type "*Ceci est du texte en italique*"
xdotool key Return
xdotool type "~~Ceci est du texte barré~~"
xdotool key Return
xdotool type "Texte normal pour comparaison"

echo "Test terminé. Vérifiez visuellement le formatage dans l'application."
