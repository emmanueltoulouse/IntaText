# Markdown — Fichier de test complet des balises

Ce fichier vise à couvrir un maximum de cas Markdown pour vérifier l’ouverture, le rendu WYSIWYG et la sauvegarde via les convertisseurs.

---

## 1. Titres

# Titre H1 (ATX)

## Titre H2 (ATX)

### Titre H3 (ATX)

# Titre H1 (Setext)

## Titre H2 (Setext)

---

## 2. Paragraphes et lignes

Paragraphe simple avec texte courant. Deux espaces à la fin pour forcer un saut de ligne
Nouvelle ligne via deux espaces.

Ligne suivante sans double espace — pas de saut de ligne forcé.

---

## 3. Emphase et combinaisons

- Italique avec astérisques: *italique*
- Italique avec underscores: _italique_
- Gras avec astérisques: **gras**
- Gras avec underscores: __gras__
- Gras + italique: ***gras+italique*** et ___gras+italique___
- Barré: ~~barré~~
- Souligné (HTML): <u>souligné</u>
- Combinaisons imbriquées: **gras et **___italique___** imbriqué** et <u>souligné avec </u><u>**gras**</u>
- Caractères échappés: \*pas italique\*, \_pas italique\_, \~pas barré\~, \`pas code\`
- Souligné avec contenu riche: <u>texte </u><u>*italique*</u><u> et </u><u>**gras**</u>

Cas sensibles aux underscores non intentionnels: snake_case, do_not_emphasize_underscores, version_1_2_3.

---

## 4. Code

Texte avec `code inline`, y compris des backticks littéraux: ``code avec `backtick` interne``.

Bloc de code (fences) sans langage:

```
ligne 1
ligne 2

```

Bloc de code Vala:

```vala
public class Hello : Object {
    public static int main (string[] args) {
        stdout.printf ("Hello, world!\n");
        return 0;
    }
}

```

---

## 5. Liens et images

- Lien simple: [Exemple](https://example.com)
- Lien avec titre: [Moteur de recherche](https://www.duckduckgo.com "DuckDuckGo")
- URL nue (peut s’auto-lier selon le parseur): https://example.org/path?q=1
- Lien de référence: [Ref vers site][site-ref].

- Image simple: Logo
- Image distante: PNG distant
- Image cliquable: [![Badge](https://img.shields.io/badge/test-ok-brightgreen.svg)](https://example.com)

[site-ref]: https://example.com "Exemple (référence)"

---

## 6. Listes

Liste à puces (mix symboles):

- Élément A
- Élément B
- Sous-élément B.1
- Sous-élément B.2
   - Sous-élément B.2.a
- Élément C
- Élément D

Liste ordonnée:

1. Premier
2. Deuxième
3. Troisième
   1. 3.1 nested
   2. 3.2 nested

Liste de tâches (si supportée):

- [ ] Tâche non cochée
- [x] Tâche cochée

---

## 7. Citations

> Ceci est une citation sur une ligne.
> 
> Deuxième ligne de citation avec **gras**, *italique*, et <u>souligné</u>.
> 
> - Élément de liste dans une citation
> - Deuxième élément

---

## 8. Règles horizontales

---
***
___

---

## 9. Tableaux (GitHub Flavored Markdown)

| Colonne A | Colonne B | Colonne C |
|:---------:|----------:|:----------|
| centré    | aligné dr | aligné g. |
| a         |        10 | foo       |
| b         |       200 | bar       |

---

## 10. Blocs HTML et inline HTML

<div class="note">
  <p>Bloc HTML: vérifier rendu/ignorance selon le parseur.</p>
</div>

Paragraphe avec inline HTML: <span style="color:red;">rouge</span> et <u>souligné</u>.

---

## 11. Cas limites

- Emphase collée à la ponctuation: (*italique*), **gras**!, ~~barré~~?
- Astérisques multiples: ****texte**** (comportement dépend du parseur)
- Parenthèses et liens: [texte entre (parenthèses)](https://example.com/test(1))
- Caractères non latin: Français, Español, 中文, عربى.
- Emoji: :sparkles: :rocket: (texte brut si non supporté)
- Math inline (doit rester texte brut): $E = mc^2$ et $x^2 + y^2$.

---

Fin du fichier.

