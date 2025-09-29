# Test d'indentation - Contenu complexe et cas limites

## Tableaux

| Colonne 1 | Colonne 2 | Colonne 3 |
|-----------|-----------|-----------|
| Valeur A  | Valeur B  | Valeur C  |
| Data 1    | Data 2    | Data 3    |
| Test X    | Test Y    | Test Z    |

## Liens et images

Voici un [lien simple](http://example.com) dans le texte.

![Image de test](test.png "Description de l'image")

Lien avec référence: [Google][1]

[1]: https://google.com "Moteur de recherche"

## Lignes horizontales

Première section

---

Deuxième section

***

Troisième section

## Texte avec échappement

Voici du texte avec \*astérisques échappés\*.
Et des \`backticks échappés\`.
Aussi des \_underscores échappés\_.

## Formules mathématiques (si supportées)

Formule inline: $E = mc^2$

Formule en bloc:
$$
\sum_{i=1}^{n} x_i = x_1 + x_2 + \ldots + x_n
$$

## Mélange complexe

1. **Élément de liste important**

   Paragraphe dans la liste avec du contenu étendu.
   Ce paragraphe fait partie de l'élément de liste.

   ```python
   # Code dans la liste
   def list_function():
       return "dans une liste"
   ```

   > Citation dans la liste
   > Avec plusieurs lignes

   - Sous-liste dans l'élément
   - Autre sous-élément

2. **Deuxième élément principal**

   | Table | Dans  | Liste |
   |-------|-------|-------|
   | A     | B     | C     |

   Paragraphe final de l'élément.

## Caractères Unicode et emojis

Ce paragraphe contient des caractères spéciaux: ñáéíóú.
Il a aussi des emojis: 🎉 ✨ 🚀 💡 🔧 ⚡ 🎯 🌟 📝 ✅
Et des symboles: ©®™€£¥§¶†‡•…‰‹›«»„"‚'

## Espaces et tabulations mixtes

    Ce bloc a des espaces au début
	Et cette ligne a une tabulation
    Retour aux espaces
	Nouvelle tabulation

## Lignes vides multiples



Après plusieurs lignes vides.


Et encore des lignes vides.

## Fin du test

Paragraphe final pour terminer le test d'indentation.
Il confirme que tous les éléments ont été traités correctement.
