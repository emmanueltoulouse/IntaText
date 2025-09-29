# Test d'indentation - Blocs de code et citations

## Code avec syntaxe

Voici du code Python:

```python
def calculate_sum(a, b):
    """Calcule la somme de deux nombres."""
    result = a + b
    return result

class TestClass:
    def __init__(self):
        self.value = 42

    def get_value(self):
        return self.value
```

## Code avec différents langages

JavaScript:
```javascript
function factorial(n) {
    if (n <= 1) return 1;
    return n * factorial(n - 1);
}

const result = factorial(5);
console.log(result);
```

Bash:
```bash
#!/bin/bash
for file in *.txt; do
    echo "Processing: $file"
    wc -l "$file"
done
```

## Code indenté pré-formaté

    Ce bloc est déjà indenté avec 4 espaces
    Chaque ligne commence par des espaces
    Il devrait être préservé lors de l'indentation

## Citations simples

> Ceci est une citation simple.
> Elle s'étend sur plusieurs lignes.
> Chaque ligne commence par >.

## Citations imbriquées

> Citation de niveau 1
> Qui continue sur cette ligne
>> Citation de niveau 2
>> Avec plusieurs lignes aussi
> Retour au niveau 1

## Citations avec formatage

> Cette citation contient du **texte en gras**.
> Elle a aussi de l'*italique* et du `code`.
>
> > Citation imbriquée avec formatage
> > Et du [lien](http://example.com)

## Code inline dans le texte

Ce paragraphe contient du `code inline` au milieu.
Voici une variable `var x = 10;` et une fonction `print("hello")`.
Le code inline ne doit pas affecter l'indentation du paragraphe.

## Mélange code et citations

Voici du code:
```python
def hello():
    print("Hello")
```

Et une citation:
> Le code ci-dessus affiche "Hello"
> C'est un exemple simple

Paragraphe final normal.
