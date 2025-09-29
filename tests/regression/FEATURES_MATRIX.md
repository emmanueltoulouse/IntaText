# Liste Complète des Fonctionnalités IntaText - Tests de Non-Régression

## 🎯 Vue d'ensemble

Cette liste répertorie toutes les fonctionnalités d'IntaText et leurs imbrications possibles pour créer une suite complète de tests de non-régression.

## 📝 1. Formatage de Texte de Base

### 1.1 Formatage Simple
- **Gras** (`**texte**` ou `__texte__`)
- **Italique** (`*texte*` ou `_texte_`)
- **Souligné** (`<u>texte</u>`)
- **Barré** (`~~texte~~`)
- **Code inline** (`` `code` ``)

### 1.2 Formatage Combiné
- **Gras + Italique** (`***texte***` ou `**_texte_**`)
- **Gras + Souligné** (`**<u>texte</u>**`)
- **Italique + Souligné** (`*<u>texte</u>*`)
- **Gras + Italique + Souligné** (`***<u>texte</u>***`)
- **Tous formats combinés** (`***<u>~~code~~</u>***`)

### 1.3 Échappement de Caractères
- Astérisques échappés (`\*`)
- Underscores échappés (`\_`)
- Tildes échappés (`\~`)
- Backticks échappés (`` \` ``)

## 📰 2. Titres et Structure

### 2.1 Titres ATX
- **H1** (`# Titre`)
- **H2** (`## Titre`)
- **H3** (`### Titre`)
- **H4** (`#### Titre`)
- **H5** (`##### Titre`)
- **H6** (`###### Titre`)

### 2.2 Titres Setext
- **H1 Setext** (ligne + `=======`)
- **H2 Setext** (ligne + `-------`)

### 2.3 Titres avec Formatage
- **H1 avec gras** (`# **Titre gras**`)
- **H2 avec italique** (`## *Titre italique*`)
- **H3 avec souligné** (`### <u>Titre souligné</u>`)
- **Titre avec formatage combiné** (`# ***<u>Titre complet</u>***`)

## 📋 3. Listes

### 3.1 Listes à Puces
- Puces simples (`-`, `*`, `+`)
- Listes imbriquées (2-3 niveaux)
- Mélanges de symboles

### 3.2 Listes Numérotées
- Numérotation simple (`1.`, `2.`, etc.)
- Listes imbriquées avec numéros
- Continuation de numérotation

### 3.3 Listes de Tâches
- Tâches non cochées (`- [ ]`)
- Tâches cochées (`- [x]`)
- Tâches imbriquées

### 3.4 Listes avec Formatage
- **Éléments en gras** (`- **élément**`)
- **Éléments en italique** (`- *élément*`)
- **Éléments avec liens** (`- [lien](url)`)
- **Éléments avec code** (`- \`code\``)
- **Formatage combiné dans listes**

## 💬 4. Citations

### 4.1 Citations Simples
- Citation sur une ligne (`> texte`)
- Citations multi-lignes

### 4.2 Citations Imbriquées
- Niveau 1 (`>`)
- Niveau 2 (`>>`)
- Niveaux multiples

### 4.3 Citations avec Formatage
- **Citations avec gras** (`> **texte**`)
- **Citations avec italique** (`> *texte*`)
- **Citations avec listes** (`> - élément`)
- **Citations avec code** (`> \`code\``)

## 💻 5. Code

### 5.1 Code Inline
- Code simple (`` `code` ``)
- Code avec backticks internes (``` ``code avec `tick` `` ```)
- Code dans formatage (`**code `var`**`)

### 5.2 Blocs de Code
- Blocs sans langage (``````text``````)
- Blocs avec langage (```vala, ```python, etc.)
- Code avec indentation (4 espaces)

### 5.3 Code avec Formatage
- Code dans **gras** : `**\`code\`**`
- Code dans *italique* : `*\`code\`*`
- Code dans listes : `- \`code\``
- Code dans tableaux

## 📊 6. Tableaux

### 6.1 Tableaux Simples
- 2-3 colonnes
- Avec/sans en-têtes
- Alignement (gauche, centre, droite)

### 6.2 Tableaux avec Formatage
- **Cellules en gras** : `| **cellule** |`
- **Cellules en italique** : `| *cellule* |`
- **Cellules avec liens** : `| [lien](url) |`
- **Cellules avec code** : `| \`code\` |`

### 6.3 Tableaux Complexes
- Formatage combiné dans cellules
- Listes dans tableaux
- Images dans tableaux

## 🔗 7. Liens et Images

### 7.1 Liens
- **Liens simples** : `[texte](url)`
- **Liens avec titre** : `[texte](url "titre")`
- **Liens de référence** : `[texte][ref]`
- **Liens automatiques** : `<url>`

### 7.2 Images
- **Images simples** : `![alt](url)`
- **Images avec titre** : `![alt](url "titre")`
- **Images de référence** : `![alt][ref]`

### 7.3 Liens et Images avec Formatage
- **Liens en gras** : `**[lien](url)**`
- **Liens en italique** : `*[lien](url)*`
- **Liens dans listes** : `- [lien](url)`
- **Liens dans tableaux**
- **Images dans listes**

## 🎨 8. Formatage Avancé

### 8.1 Couleurs
- **Couleur de texte** : `<span style="color:red">texte</span>`
- **Couleur de fond** : `<span style="background-color:yellow">texte</span>`
- **Couleurs combinées** : styles multiples

### 8.2 Police et Taille
- **Famille de police** : `<span style="font-family:Arial">texte</span>`
- **Taille de police** : `<span style="font-size:16pt">texte</span>`
- **Styles combinés**

### 8.3 Formatage HTML
- Balises `<span>` avec styles
- Balises `<div>` pour blocs
- Combinaisons HTML + Markdown

## 📐 9. Indentation et Espacement

### 9.1 Indentation Simple
- Paragraphes indentés
- Listes indentées
- Code indenté

### 9.2 Espacement Vertical
- Lignes vides simples
- Lignes vides multiples
- Séparateurs (`---`, `***`, `___`)

### 9.3 Indentation avec Formatage
- **Texte formaté indenté**
- **Listes formatées indentées**
- **Combinaisons complexes**

## 🔌 10. Fonctionnalités Plugins

### 10.1 Plugins UI
- Boutons de barre d'outils
- Éléments de menu
- Widgets de sidebar
- Composants de statut

### 10.2 Plugins de Format
- Import/Export de formats
- Conversion de documents
- Préprocesseurs de texte

### 10.3 Plugins Linguistiques
- Correction orthographique
- Vérification grammaticale
- Traduction
- Autocomplétion

## 🎯 11. Cas Limites et Edge Cases

### 11.1 Caractères Spéciaux
- **Caractères Unicode** : accents, emojis
- **Caractères de contrôle**
- **Espaces non-sécables**

### 11.2 Combinaisons Extrêmes
- **Maximum d'imbrications**
- **Formatage dans tous contextes**
- **Mélanges de syntaxes**

### 11.3 Erreurs et Récupération
- **Markdown malformé**
- **Tags HTML non fermés**
- **Références non résolues**

## 📁 12. Opérations sur Documents

### 12.1 Opérations de Base
- Créer nouveau document
- Ouvrir document existant
- Sauvegarder (Ctrl+S)
- Sauvegarder sous (Ctrl+Shift+S)

### 12.2 Import/Export
- Import depuis différents formats
- Export vers différents formats
- Conversion entre formats

### 12.3 Opérations Multiples
- Plusieurs documents ouverts
- Synchronisation entre vues
- Undo/Redo avancés

## ⌨️ 13. Interface Utilisateur

### 13.1 Éditeur WYSIWYG
- Formatage en temps réel
- Synchronisation avec Markdown
- Prévisualisation

### 13.2 Raccourcis Clavier
- Formatage (Ctrl+B, Ctrl+I, etc.)
- Navigation (Ctrl+F, Ctrl+G)
- Documents (Ctrl+N, Ctrl+O, etc.)

### 13.3 Interface Graphique
- Barres d'outils
- Menus contextuels
- Panneaux latéraux
- Barre de statut

---

## 🧪 Matrice de Tests d'Imbrication

### Formatage × Structure
| Base | H1 | H2 | H3 | Liste | Citation | Table | Lien |
|------|----|----|----| ------|----------|-------|------|
| **Gras** | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| **Italique** | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| **Souligné** | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| **Code** | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| **Combiné** | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |

### Imbrications × Contextes
- **Dans paragraphes** : Tous formatages
- **Dans titres** : Tous formatages sauf H4-H6
- **Dans listes** : Tous formatages + sous-listes
- **Dans citations** : Tous formatages + listes
- **Dans tableaux** : Tous formatages + liens/images
- **Dans code** : Préservation literal
- **Dans liens** : Formatage du texte du lien

---

Cette liste servira de base pour créer les tests de non-régression automatisés qui vérifieront chaque fonctionnalité et ses imbrications possibles.
