# Test Complet des Fonctionnalités IntaText

Ce document démontre l'ensemble des fonctionnalités supportées par IntaText.

## 1. Titres et Hiérarchie

# Titre de niveau 1
## Titre de niveau 2
### Titre de niveau 3
#### Titre de niveau 4
##### Titre de niveau 5
###### Titre de niveau 6

## 2. Enrichissements de Texte

Voici un paragraphe avec **du texte en gras**, *du texte en italique*, ***du texte en gras et italique***, <u>du texte souligné</u>, et ~~du texte barré~~.

On peut aussi combiner : **_texte gras et italique_** ou ***encore comme ça***.

### 2.1 Code

Du `code inline` dans une phrase, et un bloc de code :

```python
def hello_world():
    print("Hello, World!")
    return True
```

```javascript
function greet(name) {
    console.log(`Bonjour ${name}!`);
}
```

## 3. Citations

> Ceci est une citation simple.
> Elle peut s'étendre sur plusieurs lignes.

> Une autre citation avec **du texte en gras** et *en italique*.

## 4. Listes

### 4.1 Liste non ordonnée

- Premier élément
- Deuxième élément
  - Sous-élément 1
  - Sous-élément 2
- Troisième élément avec **gras** et *italique*

* Alternative avec astérisque
* Autre élément

### 4.2 Liste ordonnée

1. Premier élément
2. Deuxième élément
3. Troisième élément
   1. Sous-élément numéroté
   2. Autre sous-élément
4. Quatrième élément

### 4.3 Liste de tâches

- [ ] Tâche non complétée
- [x] Tâche complétée
- [ ] Autre tâche à faire
- [x] Encore une tâche faite

## 5. Liens

### 5.1 Liens externes

- [Site officiel de IntaText](https://github.com/emmanueltoulouse/IntaText)
- [Documentation Vala](https://valadoc.org/)
- [GTK Documentation](https://www.gtk.org/)
- [GitHub](https://github.com)

### 5.2 Liens internes

- [Retour aux titres](#1-titres-et-hiérarchie)
- [Voir les tableaux](#8-tableaux)
- [Aller aux couleurs](#7-couleurs-et-styles)

Lien vers un autre fichier : [README principal](../../README.md)

## 6. Images et Icônes

### 6.1 Icône de l'application

![Icône IntaText](../../data/IntaText.png)

### 6.2 Images avec texte alternatif

![Logo IntaText](../../data/IntaText.png "Logo de l'application IntaText")

### 6.3 Icônes inline

Voici l'icône de l'application : ![icon](../../data/IntaText.png) dans le texte.

Plusieurs icônes : ![icon](../../data/IntaText.png) ![icon](../../data/IntaText.png) ![icon](../../data/IntaText.png)

## 7. Couleurs et Styles

### 7.1 Couleur de texte

Texte avec <span style="color:red;">couleur rouge</span>, <span style="color:blue;">couleur bleue</span>, <span style="color:green;">couleur verte</span>.

Couleurs hexadécimales : <span style="color:#FF6B6B;">rouge pâle</span>, <span style="color:#4ECDC4;">turquoise</span>, <span style="color:#FFE66D;">jaune</span>.

### 7.2 Couleur de fond

Texte avec <span style="background-color:yellow;">fond jaune</span>, <span style="background-color:lightblue;">fond bleu clair</span>, <span style="background-color:lightgreen;">fond vert clair</span>.

### 7.3 Combinaisons

<span style="color:white;background-color:darkblue;">Texte blanc sur fond bleu foncé</span>

<span style="color:darkred;background-color:lightyellow;">Texte rouge foncé sur fond jaune clair</span>

<span style="color:#ffffff;background-color:#e74c3c;">Texte blanc sur fond rouge</span>

## 8. Tableaux

### 8.1 Tableau simple

| Colonne 1 | Colonne 2 | Colonne 3 |
|-----------|-----------|-----------|
| Cellule A | Cellule B | Cellule C |
| Cellule D | Cellule E | Cellule F |

### 8.2 Tableau avec enrichissements

| Format | Exemple | Description |
|--------|---------|-------------|
| **Gras** | **Texte important** | Mise en évidence forte |
| *Italique* | *Texte accentué* | Mise en évidence légère |
| `Code` | `variable = 42` | Code informatique |
| ~~Barré~~ | ~~Texte obsolète~~ | Texte supprimé |

### 8.3 Tableau avec couleurs

| Type | Couleur texte | Couleur fond |
|------|---------------|--------------|
| Erreur | <span style="color:red;">Rouge</span> | <span style="background-color:#ffebee;">Rose pâle</span> |
| Succès | <span style="color:green;">Vert</span> | <span style="background-color:#e8f5e9;">Vert pâle</span> |
| Avertissement | <span style="color:orange;">Orange</span> | <span style="background-color:#fff3e0;">Orange pâle</span> |
| Info | <span style="color:blue;">Bleu</span> | <span style="background-color:#e3f2fd;">Bleu pâle</span> |

### 8.4 Tableau avec liens et icônes

| Nom | Lien | Icône |
|-----|------|-------|
| IntaText | [GitHub](https://github.com/emmanueltoulouse/IntaText) | ![icon](../../data/IntaText.png) |
| Documentation | [Voir docs](../../README.md) | ![icon](../../data/IntaText.png) |
| Site web | [Visiter](https://github.com) | ![icon](../../data/IntaText.png) |

### 8.5 Tableau complexe avec tout

| **Élément** | **Style** | **Exemple** | **Lien** |
|-------------|-----------|-------------|----------|
| Titre | **Gras** + <span style="color:blue;">Bleu</span> | **<span style="color:blue;">Mon Titre</span>** | [Voir](#1-titres-et-hiérarchie) |
| Code | `Monospace` + <span style="background-color:#f0f0f0;">Fond gris</span> | `let x = 10;` | [Documentation](https://github.com) |
| Citation | *Italique* + <span style="color:gray;">Gris</span> | *<span style="color:gray;">Une citation</span>* | ![icon](../../data/IntaText.png) |
| Alerte | **Gras** + <span style="color:red;background-color:yellow;">Rouge/Jaune</span> | **<span style="color:red;background-color:yellow;">ATTENTION</span>** | [Détails](#7-couleurs-et-styles) |

## 9. Traits Horizontaux

Voici un trait horizontal :

---

Un autre trait :

***

Et encore un :

___

## 10. Combinaisons Avancées

### 10.1 Liste avec enrichissements

- **Premier point en gras** avec du texte normal
- *Deuxième point en italique* et du `code`
- ~~Troisième point barré~~ et un [lien](https://github.com)
- Point avec <span style="color:red;">couleur rouge</span> et <span style="background-color:yellow;">fond jaune</span>
- Point avec icône ![icon](../../data/IntaText.png) et **gras**

### 10.2 Citation avec enrichissements

> **Citation importante** avec du texte en gras.
>
> *Texte en italique* dans la citation.
>
> Citation avec `du code` et un [lien](https://example.com).
>
> Citation avec <span style="color:blue;">couleur</span> et ![icône](../../data/IntaText.png).

### 10.3 Code avec description enrichie

Voici un exemple de **fonction Python** en *italique* :

```python
def process_data(data):
    """
    Fonction de traitement des données
    """
    result = []
    for item in data:
        result.append(item * 2)
    return result
```

## 11. Formatage de Police

### 11.1 Tailles de texte

Texte normal avec des variations de mise en forme.

**Texte en gras** et *texte en italique* de taille normale.

### 11.2 Familles de police

Texte avec différentes polices :
- Police par défaut
- `Police monospace pour le code`
- Police normale pour le contenu

## 12. Éléments Spéciaux

### 12.1 Caractères spéciaux

Voici quelques caractères spéciaux : © ® ™ € $ ¥ £ ¢ ± × ÷ ∞ ∑ √ ∫ ≈ ≠ ≤ ≥

Flèches : ← → ↑ ↓ ↔ ⇐ ⇒ ⇔

Symboles : ★ ☆ ♠ ♣ ♥ ♦ ♪ ♫ ☀ ☁ ☂ ☃

### 12.2 Émojis

😀 😃 😄 😁 😆 😅 🤣 😂 🙂 🙃 😉 😊 😇

👍 👎 👏 🙌 🤝 💪 🦾 🦿

❤️ 🧡 💛 💚 💙 💜 🖤 🤍 🤎

🎉 🎊 🎈 🎁 🏆 🥇 🥈 🥉

## 13. Test de Performance

### 13.1 Long paragraphe avec enrichissements

Ceci est un **très long paragraphe** avec *beaucoup d'enrichissements* différents pour tester les <span style="color:red;">performances</span> de l'application. Il contient du `code inline`, des ~~mots barrés~~, des <u>mots soulignés</u>, et des [liens multiples](https://example.com) vers différentes [ressources](https://github.com) [en ligne](https://google.com). On y trouve aussi des couleurs comme <span style="color:blue;">bleu</span>, <span style="color:green;">vert</span>, <span style="color:orange;">orange</span>, et des fonds colorés comme <span style="background-color:yellow;">jaune</span>, <span style="background-color:lightblue;">bleu clair</span>, <span style="background-color:lightgreen;">vert clair</span>. Le paragraphe peut également contenir des icônes ![icon](../../data/IntaText.png) et des combinaisons complexes comme **<span style="color:white;background-color:darkblue;">texte blanc sur fond bleu foncé en gras</span>**.

### 13.2 Liste longue

1. Premier élément avec **gras**, *italique*, `code`, [lien](https://example.com), et ![icon](../../data/IntaText.png)
2. Deuxième élément avec <span style="color:red;">rouge</span>, <span style="background-color:yellow;">fond jaune</span>, et ~~barré~~
3. Troisième élément avec ***gras et italique***, <u>souligné</u>, et `code`
4. Quatrième élément avec des combinaisons : **<span style="color:blue;">gras bleu</span>** et *<span style="background-color:lightgreen;">italique fond vert</span>*
5. Cinquième élément avec citation : > Citation dans liste
6. Sixième élément avec code block:
   ```
   code dans liste
   ```
7. Septième élément avec tout : **gras** *italique* `code` [lien](https://github.com) ![icon](../../data/IntaText.png) <span style="color:red;">rouge</span> <span style="background-color:yellow;">jaune</span> ~~barré~~ <u>souligné</u>

## 14. Références

### 14.1 Notes de bas de page (simulées)

Voici un texte avec une référence¹.

Un autre texte avec une autre référence².

¹ Première note de référence
² Deuxième note de référence

### 14.2 Liens de référence

[Lien vers Google][1]
[Lien vers GitHub][2]
[Lien vers Documentation][3]

[1]: https://google.com
[2]: https://github.com
[3]: https://github.com/emmanueltoulouse/IntaText

## 15. Blocs Imbriqués

### 15.1 Liste dans citation

> - Premier élément de liste
> - Deuxième élément de liste
> - Troisième élément de liste

### 15.2 Code dans liste

1. Premier point avec code :
   ```python
   def hello():
       print("Hello!")
   ```
2. Deuxième point avec code :
   ```javascript
   function test() {
       return true;
   }
   ```

### 15.3 Tableau dans liste

1. Premier élément

   | Col 1 | Col 2 |
   |-------|-------|
   | A     | B     |

2. Deuxième élément

---

## Conclusion

Ce document démontre **toutes les fonctionnalités** supportées par *IntaText* :

✅ Titres (6 niveaux)
✅ Enrichissements (gras, italique, souligné, barré, code)
✅ Couleurs (texte et fond)
✅ Listes (ordonnées, non ordonnées, tâches)
✅ Tableaux (simples et complexes)
✅ Liens (externes, internes)
✅ Images et icônes
✅ Citations
✅ Code (inline et blocs)
✅ Traits horizontaux
✅ Combinaisons avancées

![IntaText](../../data/IntaText.png)

**Merci d'utiliser IntaText !** 🎉

[Retour au début](#test-complet-des-fonctionnalités-intatext)
