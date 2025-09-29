# Tests IntaText

Ce dossier contient tous les tests automatisés pour IntaText.

## Structure

- **unit/** : Tests unitaires Vala (GLib.Test)
- **integration/** : Tests d'intégration entre composants
- **ui/** : Tests UI automatisés avec AT-SPI/Dogtail
- **regression/** : Suites de tests de non-régression
- **samples/** : Fichiers de test Markdown et échantillons
- **manual/** : Scripts de tests manuels (.sh)
- **experimental/** : Code expérimental et prototypes (.vala)

## Exécution

```bash
# Tests unitaires seulement
meson test -C build

# Tests complets (unitaires + UI + régression)
./tests/run_tests.sh

# Tests UI seulement
python3 tests/ui/all_ui_tests.py

# Tests de régression
python3 tests/regression/smoke_tests.py
```

## Dépendances

### Tests UI (AT-SPI)
```bash
sudo apt install python3-dogtail at-spi2-core accerciser
```

### Tests unitaires
Les tests unitaires utilisent GLib.Test intégré à Vala/GLib.

## Ajout de nouveaux tests

1. **Test unitaire** : Créer un fichier `.vala` dans `unit/`
2. **Test UI** : Créer un fichier `.py` dans `ui/`
3. **Test de régression** : Ajouter le scénario dans `regression/`

Voir les exemples existants pour la structure attendue.
