# ROADMAP 🗺️

Ce fichier vise à expliquer comment le projet de la Global Game Jam 2026 va être mise en place et comment il va être gérer.

## Langage / Framework 

Le projet va être développer avec le langage [LUA](https://www.lua.org/) en utilisant le framework [LÖVE2D](https://love2d.org/)

### Installation

```sh
# Linux LÖVE2D
sudo apt update
sudo apt install love
```

```sh
#Linux LUA 5.4
sudo apt install lua5.4
```

🪟 WINDOWS

Va sur https://love2d.org
Télécharge la version Windows (64-bit)
Lance l’installateur .exe
Installe normalement
Ajouter aux variables d'environnement le dossier LOVE

🔹 Installer Lua seul (optionnel)
https://www.lua.org/download.html
Télécharge Lua 5.4.x Windows
Extrais et ajoute Lua au PATH

## Gestion de projet

Pour la gestion de ce projet nous allons utiliser principalement les méthodes agiles. En quelques mots, le principe va être de fonctionner de façon incrémental, c'est-à-dire qu'on va développer une fonctionnalité qui a de la valeur et potentiellement la tester pour ensuite l'ajouter au projet final.

### Jira 

C'est l'outil de gestion de projet que nous allons utiliser, Jira va être utile pour visualiser l'avancement de notre projet. Nous allons pouvoir créer des tickets dans lesquels on va se donner une deadline, savoir le niveau de difficulté, la force du ticket...

Jira nous permettras de visualiser avec des graphiques à quel point le projet avance bien ou non.

NB : Jira est peut-être un outil trop puissant pour ce qu'on va en faire mais c'est pas grave car c'est cela qu'on utilise en Master

### Git

Pour gérer les versionnement on va utiliser git et pour le mettre en lien avec la gestion de projet on va fonctionner de cette manière :

- Pour une fonctionnalité/ticket $\rightarrow$ une branche nommée NUMTICKET_NOMFONCTIONNALITE
- A la fin du développement d'une fonctionnalité $\rightarrow$ tester localement et si possible demander à une autre personne de tester sur une machine la même ou une autre, pour avoir une autre vision de test
- Lorsqu'on veut mettre ajouter la fonctionnalité au projet $\rightarrow$ faire une Pull Request / Merge Request sur Github ⚠️ **CELA DOIT ÊTRE UNE PERSONNE DIFFÉRENTE QUI DOIT ACCEPTER LA PR/MR** ⚠️

Pour chaque $\delta$ de temps ($\delta$ à déterminer), nous ferons une revue de sprint où tous ensemble ou en petit groupe nous expliquerons ce qui a été developper, ce qui n'a pas pu être développer et les raisons, se déterminer un/des objectif(s) sur un sprint
