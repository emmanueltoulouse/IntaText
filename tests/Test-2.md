# Markdown — Fichier de test complet des balises

# Ce fichier vise à couvrir un maximum de cas Markdown pour vérifier l’ouverture, le rendu WYSIWYG et la sauvegarde via les convertisseurs.

1. Titres

Ce fichier vise à couvrir un maximum de cas Markdown pour vérifier l’ouverture, le rendu WYSIWYG et la sauvegarde via les convertisseurs.

---

1. Titres

## 1. Titres


Titre H1 (ATX)

# Titre H1 (ATX)


Titre H2 (ATX)

## Titre H2 (ATX)


Titre H3 (ATX)

### Titre H3 (ATX)


Titre H1 (Setext)

# Titre H1 (Setext)


Titre H2 (Setext)

## Titre H2 (Setext)

1. Paragraphes et lignes


---

2. Paragraphes et lignes

## 2. Paragraphes et lignes

1. Emphase et combinaisons


Paragraphe simple avec texte courant. Deux espaces à la fin pour forcer un saut de ligne  
Nouvelle ligne via deux espaces.

Ligne suivante sans double espace — pas de saut de ligne forcé.

---

3. Emphase et combinaisons

## 3. Emphase et combinaisons

1. Italique avec astérisques: *italique*
2. Italique avec astérisques: *italique*
3. Italique avec underscores: _italique_
4. Gras avec astérisques: **gras**
5. Gras avec underscores: __gras__
6. Gras + italique: ***gras+italique*** et **_gras+italique_**
7. Barré: ~~barré~~
8. Souligné (HTML): <u>souligné</u>
9. Combinaisons imbriquées: **gras et _italique_ imbriqué** et <u>souligné avec **gras**</u>
10. Caractères échappés: \*pas italique\*, \_pas italique\_, \~pas barré\~, \`pas code\`
11. Souligné avec contenu riche: <u>texte <em>italique</em> et <strong>gras</strong></u>
12. Code

Cas sensibles aux underscores non intentionnels: snake_case, do_not_emphasize_underscores, version_1_2_3.

---

4. Code

## 4. Code

```
ligne 1
ligne 2

Bloc de code Vala:

[vala]
public class Hello : Object {
    public static int main (string[] args) {
        stdout.printf ("Hello, world!\n");
        return 0;
    }
}

---

5. Liens et images
```

1. Liens et images

`ligne 1
ligne 2

`Bloc de code Vala:

`[vala]
public class Hello : Object {
    public static int main (string[] args) {
        stdout.printf ("Hello, world!\n");
        return 0;
    }
}

`---

5. Liens et images

## 5. Liens et images

1. Lien simple: [Exemple](https://example.com)
2. Lien simple: [Exemple](https://example.com)
3. Lien avec titre: [Moteur de recherche](https://www.duckduckgo.com "DuckDuckGo")
4. URL nue (peut s’auto-lier selon le parseur): https://example.org/path?q=1
5. Lien de référence: [Ref vers site][site-ref].
6. Image simple: ![Logo](images/logo.png "Titre de l’image")
7. Image simple: ![Logo](images/logo.png "Titre de l’image")
8. Image distante: ![PNG distant](https://via.placeholder.com/100x50.png)
9. Image cliquable: [![Badge](https://img.shields.io/badge/test-ok-brightgreen.svg)](https://example.com)
10. Listes

[site-ref]: https://example.com "Exemple (référence)"

---

6. Listes

## 6. Listes

1. Élément A
2. Élément A
3. Élément B
4. Sous-élément B.1
5. Sous-élément B.2
6. Sous-élément B.2.a
7. Élément C
8. Élément D
9. Premier
10. Premier
11. Deuxième
12. Troisième
13. 3.1 nested
14. 3.2 nested
15. [ ] Tâche non cochée
16. [ ] Tâche non cochée
17. [x] Tâche cochée
18. Citations


Liste à puces (mix symboles):

• Élément A
• Élément B
• Sous-élément B.1
• Sous-élément B.2
• Sous-élément B.2.a
• Élément C
• Élément D

Liste ordonnée:

1. Premier
2. Deuxième
3. Troisième
4. 3.1 nested
5. 3.2 nested

Liste de tâches (si supportée):

• [ ] Tâche non cochée
• [x] Tâche cochée

---

7. Citations

## 7. Citations

> 
> 8. Règles horizontales

---

8. Règles horizontales

## 8. Règles horizontales

1. Tableaux (GitHub Flavored Markdown)


---
***
___

---

9. Tableaux (GitHub Flavored Markdown)

## 9. Tableaux (GitHub Flavored Markdown)

1. Blocs HTML et inline HTML


| Colonne A | Colonne B | Colonne C |
|:---------:|----------:|:----------|
| centré    | aligné dr | aligné g. |
| a         |        10 | foo       |
| b         |       200 | bar       |

---

10. Blocs HTML et inline HTML

## 10. Blocs HTML et inline HTML

1. Cas limites


<div class="note">
  <p>Bloc HTML: vérifier rendu/ignorance selon le parseur.</p>
</div>

Paragraphe avec inline HTML: <span style="color: red;">rouge</span> et __souligné__.

---

11. Cas limites

## 11. Cas limites

- Emphase collée à la ponctuation: (*italique*), **gras**!, ~~barré~~?
- Emphase collée à la ponctuation: (*italique*), **gras**!, ~~barré~~?
- Astérisques multiples: ****texte**** (comportement dépend du parseur)
- Parenthèses et liens: [texte entre (parenthèses)](https://example.com/test(1))
- Caractères non latin: Français, Español, 中文, عربى.
- Emoji: :sparkles: :rocket: (texte brut si non supporté)
- Math inline (doit rester texte brut): $E = mc^2$ et $x^2 + y^2$.

---

Fin du fichier.



