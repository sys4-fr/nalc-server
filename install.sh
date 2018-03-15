#!/bin/bash

verif() {
	 if [[ $? -gt 0 ]]; then
		  echo "Erreur ! Arrêt du script."
		  exit 1
	 fi
}

# Affichage de l'aide si demandé en paramètres
if [[ $1 = "--help" ]]; then
	 echo "Usage : ./install.sh [options]"
	 echo ""
	 echo "Options :"
	 echo "--help : Cette aide"
	 echo "--git-user <utilisateur@serveur> : Utilisateur git"
	 exit 0
fi

# Récupération de l'utilisateur du dépot git
if [[ $1 = "--git-user" ]] && [[ -n $2 ]]; then
	 USER=$2\:
else
	 USER="https://sys4.fr/gogs/"
fi

# On clone le dépot du moteur du jeux Minetest à la racine
git clone $USER"NotreAmiLeCube/minetest.git"
verif

# On clone le dépot du sous-jeux minetest_game à la racine
git clone $USER"NotreAmiLeCube/minetest_game.git"
verif

# On clone les mods de nalc à la racine
git clone $USER"NotreAmiLeCube/nalc-server-mods.git"
verif

# On initialise les sous-modules du dépot des mods
cd nalc-server-mods
git submodule update --init --recursive

# On créé les liens symboliques nécessaires
cd ..
ln -s $(pwd)/minetest_game minetest/games/minetest_game
while [ -r mod ]
do
	 ln -s $(pwd)/nalc-server-mods/$mod minetest/mods/$mod
done <<< $(ls nalc-server-mods)

# TODO Lien symbolique minetest.conf

# Création du répertoire de la map
mkdir -p minetest/world/nalc
# TODO Lien symbolique world.mt
#ln -s ($pwd)/world.mt minetest/world/nalc/world.mt

# Compilation de Minetest
cd minetest
cmake . -DRUN_IN_PLACE=true -DENABLE_GETTEXT=true
make -j33

echo "Installation terminé. Bravo !"
