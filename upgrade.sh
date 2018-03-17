#!/bin/bash

auth="https"

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
	 echo "Usage : ./upgrade.sh [options]"
	 echo "--help ou -h : Afficher l'aide"
	 echo "--ssh : Authentification par ssh"
	 echo "--https : Authentification publique anonyme"
	 echo "--mods-link : Met à jour les liens symboliques des mods et le fichier world.mt"
	 echo "--mods <mod|all> : Met à jour le(s) mod(s) depuis le dépôt distant"
	 echo "--minetest : Met à jour le moteur du jeux depuis le dépot distant"
}

modslink() {
	 # Suppression des liens
	 rm minetest/mods/*

	 # Supression du world.mt
	 if [[ -a world.mt ]]; then
		  rm world.mt
	 fi
	 # Création du fichier world.mt depuis sa conf
	 cp worldmt.conf world.mt
	 
	 # Création des liens
	 while read -r mod
	 do
		  if [[ -d nalc-server-mods/$mod ]]; then
				ln -s $(pwd)/nalc-server-mods/$mod minetest/mods/$mod
				
				# Ajout dans world.mt
				if [[ -a nalc-server-mods/$mod/modpack.txt ]]; then
					 while read -r submod
					 do
						  echo "load_mod_"$submod" = true" >> world.mt
					 done <<< $(ls nalc-server-mods/$mod)
				else
					 echo "load_mod_"$mod" = true" >> world.mt
				fi
		  fi
	 done <<< $(ls nalc-server-mods)

	 echo "Liens des mods créés dans minetest/mods/"
	 
	 # Lien symbolique world.mt
	 if [[ ! -a minetest/worlds/nalc/world.mt ]]; then
		  ln -s $(pwd)/world.mt minetest/worlds/nalc/world.mt
		  echo "Lien vers world.mt créé dans minetest/worlds/nalc/"
	 fi
}

modsupgrade() {
	 if [[ $auth == "ssh" ]]; then
		  read -p "Please enter <username>@<host> : " ident
		  ident=$ident\:
	 else
		  ident="https://sys4.fr/gogs/"
	 fi

	 mods=$(echo $1 | cut -f 2 -d \')
	 
	 if [[ $mods == "all" ]]; then

		  # On met à jour le dépot local des mods
		  cd nalc-server-mods
		  git pull
		  git submodule update --init --recursive
		  verif
		  cd ..
	 else
		  # Mise à jour du mod spécifié en ligne de commande
		  cd nalc-server-mods
		  git pull
		  git submodule update --init --recursive $1
		  verif
		  cd ..
	 fi

	 # Mise à jour des liens
	 modslink
}

minetestupgrade() {
	 cd minetest
	 git pull
	 verif
	 cmake . -DRUN_IN_PLACE=true -DENABLE_GETTEXT=true
	 make -j33
	 cd ..
}

sshauth() {
	 if [[ -z `pidof ssh-agent` ]]; then
		  echo "Exécutez les commandes suivantes :"
		  echo "$ eval \`ssh-agent -s\`"
		  echo "$ ssh-add <chemin vers votre clé privé>"
		  echo "Relancez de nouveau le script : ./upgrade.sh --ssh [options]"
		  exit 0
	 else
		  auth="ssh"
		  echo "Authentification ssh activé."
	 fi
}

httpauth() {
	 auth="https"
	 echo "Authentification https activé."
}

# Pas de paramètre
[[ $# -lt 1 ]] && error

# -o : Options courtes
# -l : Options longues
options=$(getopt -o h -l help,https,ssh,mods-link,minetest,mods: -- "$@")

# Éclatement de $options en $1, $2...
set -- $options

while true; do
	 case "$1" in
		  --ssh) sshauth
					shift;;
		  --https) httpsauth
					  shift;;
		  --mods-link) modslink
							shift;;
		  --mods) modsupgrade $2
					 shift 2;;
		  --minetest) minetestupgrade
						  shift;;
		  -h|--help) usage
						 exit 0;;
		  --)
				shift
				break;;
		  *) error
			  shift;;
	 esac
done

exit 0
