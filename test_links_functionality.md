# Test des fonctionnalités de liens

Ce fichier permet de tester les nouvelles interactions avec les liens HTTP dans l'éditeur WYSIWYG.

## Liens à tester :

Voici quelques liens pour tester les nouvelles fonctionnalités :

- **Lien simple** : https://www.google.com
- **Autre lien** : https://github.com 
- **Lien avec texte** : [Mozilla Developer Network](https://developer.mozilla.org)
- **Lien FTP** : ftp://example.com/files
- **Email** : mailto:contact@example.com

## Fonctionnalités implémentées :

### 1. Curseur en forme de main au survol ✨
- Survolez les liens ci-dessus avec votre souris
- Le curseur devrait se transformer en main (pointer)
- Quand vous quittez le lien, le curseur redevient normal (texte)

### 2. Ouverture avec Ctrl+Click 🚀
- Maintenez `Ctrl` enfoncé et cliquez sur un lien
- Le lien devrait s'ouvrir dans votre navigateur par défaut
- Un message de debug s'affichera dans le terminal

### 3. Détection intelligente des URLs
- Les liens HTTP, HTTPS, FTP et mailto sont reconnus
- La fonctionnalité fonctionne même avec des liens formatés en Markdown

---

**Instructions de test :**
1. Passez en mode WYSIWYG
2. Survolez les liens pour voir le curseur changer
3. Utilisez Ctrl+Click pour ouvrir les liens
4. Vérifiez que les messages s'affichent dans le terminal
