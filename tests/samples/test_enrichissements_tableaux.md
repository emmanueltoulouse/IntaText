# Test des enrichissements dans les tableaux

## Tableau avec enrichissements complets

| Texte simple | **Gras** | *Italique* | ~~Barré~~ |
|--------------|----------|------------|-----------|
| Couleur rouge | <span style="color:red">Rouge</span> | <span style="background-color:yellow">Fond jaune</span> | `code` |
| Lien externe | [GitHub](https://github.com) | **[Lien gras](https://example.com)** | *[Lien italique](https://test.com)* |
| Image | ![alt text](path/to/image.png) | ![Test](https://example.com/img.jpg) | `![Code image](test.png)` |
| Mixte | **<span style="color:blue">Bleu gras</span>** | *[Lien rouge italique](https://red.com)* | ~~[Lien barré](https://crossed.com)~~ |

## Instructions de test

1. Ouvrez ce fichier dans IntaText
2. Passez en mode WYSIWYG
3. Cliquez dans chaque cellule pour vérifier qu'elle est éditable
4. Essayez de modifier le texte dans les cellules
5. Vérifiez que les enrichissements (couleurs, liens, images) sont préservés
6. Testez le passage entre mode Markdown et WYSIWYG

## Test de création de tableau

Créez un nouveau tableau avec des enrichissements :
- Utilisez les boutons de formatage
- Ajoutez des liens avec Ctrl+L
- Ajoutez des couleurs
- Testez la conversion Markdown ↔ WYSIWYG
