#!/bin/bash

# Script de test pour l'architecture des plugins d'IntaText

set -e

echo "=== Test de l'architecture des plugins IntaText ==="
echo

# Vérifier que l'application est compilée
if [ ! -f "./build/IntaText" ]; then
    echo "❌ L'application n'est pas compilée. Compilation en cours..."
    meson compile -C build
fi

echo "✅ Application compilée"

# Créer les répertoires de plugins si nécessaire
mkdir -p ~/.local/share/intatext/plugins
mkdir -p ~/.local/lib/intatext/plugins

echo "✅ Répertoires de plugins créés"

# Tester la compilation du plugin d'exemple
echo "🔧 Test de compilation du plugin d'exemple..."

cd examples/plugins/hello-world

# Créer un build temporaire pour le plugin
if [ ! -d "build" ]; then
    meson setup build --prefix=$HOME/.local
fi

# Compiler le plugin
meson compile -C build

echo "✅ Plugin d'exemple compilé"

# Copier les fichiers du plugin
cp build/libhello-world-plugin.so ~/.local/lib/intatext/plugins/
cp hello-world.plugin ~/.local/share/intatext/plugins/

echo "✅ Plugin installé localement"

cd ../../..

# Lancer l'application avec debug pour voir les plugins
echo "🚀 Lancement d'IntaText avec debug des plugins..."

G_MESSAGES_DEBUG=all GSETTINGS_SCHEMA_DIR=/usr/local/share/glib-2.0/schemas ./build/IntaText

echo "=== Test terminé ==="
