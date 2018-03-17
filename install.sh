#!/bin/bash

verif() {
	 if [[ $? -gt 0 ]]; then
		  echo "Erreur ! Arrêt du script."
		  exit 1
	 fi
}

error() {
	 echo "ERREUR : paramètres invalides !" >&2
	 echo "utilisez l'option -h pour en savoir plus" >&2
	 exit 1
}

usage() {
	 echo "Usage : ./install.sh [options]"
	 echo "--help ou -h : Afficher l'aide"
	 echo "--ssh : Authentification par ssh"
	 echo "--https : Authentification publique anonyme"
}

install() {
	 if [[ $1 == "ssh" ]]; then
		  read -p "Please enter <username>@<host> : " ident
		  ident=$ident\:
	 else
		  ident="https://sys4.fr/gogs/"
	 fi
	 
	 # On clone le dépot du moteur du jeux Minetest à la racine
	 git clone $ident"NotreAmiLeCube/minetest.git"
	 verif

	 # On clone le dépot du sous-jeux minetest_game à la racine
	 git clone $ident"NotreAmiLeCube/minetest_game.git"
	 verif

	 # On clone les mods de nalc à la racine
	 git clone $ident"NotreAmiLeCube/nalc-server-mods.git"
	 verif

	 # On initialise les sous-modules du dépot des mods
	 cd nalc-server-mods
	 git submodule update --init --recursive

	 # On créé les liens symboliques nécessaires
	 cd ..
	 ln -s $(pwd)/minetest_game minetest/games/minetest_game
	 while read -r mod
	 do
		  ln -s $(pwd)/nalc-server-mods/$mod minetest/mods/$mod
	 done <<< $(ls nalc-server-mods)

	 # TODO Lien symbolique minetest.conf

	 # Création du répertoire de la map
	 mkdir -p minetest/worlds/nalc
	 
	 # Compilation de Minetest
	 cd minetest
	 cmake . -DRUN_IN_PLACE=true -DENABLE_GETTEXT=true
	 make -j33

	 verif
	 cd ..

	 echo "Installation terminé."
	 echo "Mise à jour des mods..."
	 exec ./upgrade.sh --mods-link
}

sshinstall() {
	 if [[ -z `pidof ssh-agent` ]]; then
		  echo "Exécutez les commandes suivantes :"
		  echo "$ eval \`ssh-agent -s\`"
		  echo "$ ssh-add <chemin vers votre clé privé>"
		  echo "Relancez de nouveau le script : ./install.sh --ssh"
		  exit 0
	 fi
	 
	 install "ssh"
}

# Pas de paramètre
[[ $# -lt 1 ]] && error

# -o : Options courtes
# -l : options longues
options=$(getopt -o h -l help,https,ssh -- "$@")

# éclatement de $options en $1, $2...
set -- $options

while true; do
	 case "$1" in
		  --ssh) sshinstall
					#shift 2;;
					exit 0;;
		  --https) install
					  #shift;;
					  exit 0;;
		  -h|--help) usage
						 exit 0;;
		  --)
				shift
				break;;
		  *) error
			  shift;;
	 esac
done
