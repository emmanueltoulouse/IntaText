# Test Tableaux - Support Complet

## Tableau avec liens, couleurs et images

| Type | Exemple | Résultat attendu |
|------|---------|------------------|
| **Lien** | [GitHub](https://github.com) | Lien cliquable |
| **Couleur** | <span style="color:red">Texte rouge</span> | Texte en rouge |
| **Couleur fond** | <span style="background-color:yellow">Surlignage</span> | Fond jaune |
| **Image** | ![Logo](https://via.placeholder.com/50) | Image intégrée |
| **Combiné** | [<span style="color:blue">**Lien bleu gras**</span>](https://example.com) | Lien bleu et gras |
| **Enrichi mixte** | *<span style="color:green">Italique vert</span>* et `code` | Formatage multiple |

## Tableau enrichi complet

| Formatage | Couleur | Lien | Image |
|-----------|---------|------|-------|
| **Gras** et *italique* | <span style="color:red; background-color:lightgray">Rouge sur gris</span> | [Documentation](https://docs.example.com) | ![Icon](https://via.placeholder.com/20) |
| `Code inline` | <span style="color:blue">Bleu</span> | [**Lien gras**](https://bold.example.com) | ![Small](https://via.placeholder.com/15) |
| ~~Barré~~ et <u>souligné</u> | <span style="color:green; font-weight:bold">Vert gras</span> | [*Lien italique*](https://italic.example.com) | ![Tiny](https://via.placeholder.com/10) |

## Instructions de test

1. **Liens** : Vérifier que les liens sont cliquables et s'ouvrent correctement
2. **Couleurs** : Observer les couleurs de texte et d'arrière-plan
3. **Images** : Confirmer l'affichage des images (même des placeholders)
4. **Combinaisons** : Tester que les formats se combinent bien (lien + couleur, etc.)
5. **Édition** : Modifier une cellule pour ajouter des éléments complexes
6. **Sauvegarde** : Vérifier que tous les éléments sont préservés lors de l'enregistrement

## Test de syntaxe markdown complexe

| Syntaxe | Rendu |
|---------|-------|
| `[Lien](http://example.com)` | [Lien](http://example.com) |
| `![Image](url)` | ![Test](https://via.placeholder.com/30) |
| `<span style="color:red">Rouge</span>` | <span style="color:red">Rouge</span> |
| `**[Gras lien](url)**` | **[Gras lien](https://example.com)** |
| `*![Italique image](url)*` | *![Ital](https://via.placeholder.com/25)* |
