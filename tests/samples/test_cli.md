# Test d'ouverture en ligne de commande

Ce fichier est utilisé pour tester la fonctionnalité d'ouverture de fichiers directement depuis la ligne de commande dans IntaText.

## Fonctionnalité implémentée

- L'application utilise maintenant `ApplicationFlags.HANDLES_OPEN`
- La méthode `open()` est implémentée pour traiter les fichiers passés en paramètre
- Le premier fichier spécifié est ouvert automatiquement

## Test

Pour tester cette fonctionnalité :

```bash
./build/IntaText test_cli.md
```

L'application devrait se lancer et ouvrir ce fichier automatiquement.
