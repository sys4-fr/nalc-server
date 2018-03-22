#!/bin/bash

# Fonctions
strip() {
    echo $1 | cut -d \' -f 2
}

verif() {
    if [[ $? -gt 0 ]]; then
		  echo "Erreur ! Arrêt du script."
		  exit 1
    fi
}

error() {
    echo "ERREUR : Vérifiez vos paramètres !" >&2
    echo "Utilisez l'option -h pour en savoir plus" >&2
    exit 1
}

usage() {
    echo "Usage: ./install.sh [options] [--] <arg>"
    echo "Options :"
    echo "--help | -h : Affiche l'aide."
    echo "--verbose | -v : Be verbose !"
    echo "--ssh <user@host>: Identifiants ssh."
    echo "--url <URL>: URL distante personnalisée."
    echo -e "\tSi l'option --ssh est passée en option, il s'agira du chemin distant."
    echo "Commandes :"
    echo -e "\tinit : Installation par défaut. Suivez les instructions..."
    echo -e "\t\tSi une installation précédente est détectée alors le script s'arrête."
    echo -e "\tupgrade : Met à jour le serveur tout en sauvegardant la version précédente au cas où."
    echo -e "\tclean_install : /!\ Permet de faire une installation qui supprime toute installation précédente (Perte de la map et des paramètres définitif...)."
    echo -e "\tuninstall : /!\ Permet de supprimer l'installation courante (Perte de données...)."
    exit 0
}

ssh() {
    ssh=$(strip $1)
    echo "Installation avec identifiants ssh : $ssh"
}

url() {
	 url=$(strip $1)
}

makeopt() {
	 makeopt=$(strip $1)
}

full() {
    if [[ -n $URL ]]; then
		  echo "Full install... with "$URL
    else
		  echo "ERREUR: Vous devez choisir l'option --ssh ou --https avec cette commande !"
		  usage
    fi
}

clean() {
    echo "clean install..."
}

install_minetest() {
	 if [[ -z $makeopt ]]; then
		  local makeopt=1
	 fi
	 
	 if [[ -d minetest ]]; then
		  echo "Installation précédente de Minetest détecté."
		  read -p "Mettre à jour ? (y,n,clean,cancel) : " continue
		  if [[ $continue == "clean" ]]; then
				echo "Attention ! Cela va supprimer définitivement toutes les données."
				read -p "Êtes-vous certains de vouloir continuer ? (y or n) : " continue
				if [[ $continue == "y" ]]; then
					 rm -rf minetest
					 echo "Répertoire minetest supprimé."
				else
					 echo "Installation annulée. Fin"
					 exit 0
				fi
		  elif [[ $continue == "y" ]]; then
				cd minetest
				git pull
				verif
				cd ..
		  elif [[ $continue == "cancel" ]]; then
				echo "Installation annulée. Fin"
				exit 0
		  fi
	 fi

	 if [[ ! -d minetest ]]; then
		  git clone $URL/minetest.git
		  verif
	 fi

	 echo "Minetest va être recompilé..."
	 sleep 3
	 cd minetest
	 cmake . -DRUN_IN_PLACE=true -DGETTEXT=true
	 make -j$makeopt
	 echo "Installation de Minetest terminé."
	 cd ..
}

install_minetest_game() {
	 if [[ -d minetest_game ]]; then
		  echo "Installation précédente du jeux Minetest détecté."
		  read -p "Mettre à jour ? (y,n,clean,cancel) " continue
		  if [[ $continue == "y" ]]; then
				cd minetest_game
				git pull
				verif
				cd ..
				echo "Mise à jour du jeux Minetest depuis dépôt distant terminé."
		  elif [[ $continue == "clean" ]]; then
				echo "/!\ Cette action va effacer les données du répertoire minetest_game"
				read -p "Êtes-vous sûr de vouloir continuer ? (y or n) " continue
				if [[ $continue == "y" ]]; then
					 rm -rf minetest_game
					 echo "Jeux Minetest supprimé."
				else
					 echo "Mise à jour annulée. Terminé."
					 exit 0
				fi
		  elif [[ $continue == "cancel" ]]; then
				echo "Mise à jour annulée. Terminé."
				exit 0
		  fi
	 fi

	 if [[ ! -d minetest_game ]]; then
		  git clone $URL/minetest_game.git
		  verif
		  echo "Clonage de minetest_game terminé."
	 fi

	 if [[ ! -a minetest/games/minetest_game ]]; then
		  ln -s $(pwd)/minetest_game minetest/games/minetest_game
		  echo "Lien symbolique minetest/games/minetest_game vers $(pwd)/minetest_game créé."
	 fi

	 echo "Installation/Mise à jour du jeux Minetest terminé."
}

install_world() {
	 if [[ -d minetest/worlds/nalc ]]; then
		  echo "Une map est déjà présente. Que souhaitez-vous faire ?"
		  read -p "Choisissez parmi la liste ([1]Nouveau, [2]Utiliser) : " continuer
		  if [[ $continuer == 1 ]]; then
				if [[ -d minetest/worlds/nalc_old ]]; then
					 rm -rf minetest/worlds/nalc_old
				fi
				
				mv minetest/worlds/nalc minetest/worlds/nalc_old
		  fi
	 fi

	 if [[ ! -d minetest/worlds/nalc ]]; then
		  mkdir -p minetest/worlds/nalc
		  ln -s $(pwd)/world.mt minetest/worlds/nalc/world.mt
	 fi
}		

install_mods() {
	 if [[ -d nalc-server-mods ]]; then
		  echo "Le dossier de mods est déjà présent. Que souhaitez-vous faire ?"
		  read -p "Choisissez parmi la liste, ([1]update, [2]clean, [3]cancel, [4]Ne rien faire) : " continue
		  if [[ $continue == 1 ]]; then
				cd nalc-server-mods
				git pull
				verif
				git submodule update --remote --recursive
				verif
				cd ..
		  elif [[ $continue == 2 ]]; then
				rm -rf nalc-server-mods
		  elif [[ $continue == 3 ]]; then
				echo "Mise à jour des mods annulé. Terminé."
				exit 0
		  fi
	 fi

	 if [[ ! -d nalc-server-mods ]]; then
		  git clone $URL/nalc-server-mods.git
		  verif
		  cd nalc-server-mods
		  git submodule update --init --recursive
		  cd ..
	 fi

	 # Recréation des liens symboliques et du fichier world.mt (dans tous les cas)
	 rm minetest/mods/*

	 if [[ -a world.mt ]]; then
		  rm world.mt
	 fi

	 cp worldmt.conf world.mt

	 if [[ -d custom/mods ]]; then
		  ls custom/mods | while read -r mod; do
				if [[ -d custom/mods/$mod ]]; then
					 rm nalc-server-mods/$mod
					 ln -s $(pwd)/custom/mods/$mod nalc-server-mods/$mod
				fi
		  done
	 fi

	 ls nalc-server-mods | while read -r mod; do
		  if [[ -d nalc-server-mods/$mod ]]; then
				ln -s $(pwd)/nalc-server-mods/$mod minetest/mods/$mod

				if [[ -a nalc-server-mods/$mod/modpack.txt ]]; then
					 ls nalc-server-mods/$mod | while read -r submod; do
						  if [[ -d nalc-server-mods/$mod/$submod ]]; then
								echo "load_mod_$submod = true" >> world.mt
						  fi
					 done
				else
					 echo "load_mod_$mod = true" >> world.mt
				fi
		  fi
	 done

	 echo "Liens des mods créés dans minetest/mods/"
}

init() {
	 if [[ -n $ssh && -n $url ]]; then
		  URL=$ssh\:$url
	 elif [[ -n $url ]]; then
		  URL=$url
	 else
		  URL="https://github.com/sys4-fr"
	 fi

	 read -p "L'installation va démarrer. Continuer ? (y or n) : " continue
	 if [[ $continue == "y" ]]; then
		  install_minetest
		  install_minetest_game
		  install_mods
		  install_world
		  
		  echo "L'installation est terminé. Bravo !"
	 else
		  echo "Installation annulée. Fin."
	 fi
}

action() {
    local arg=$(strip $1)
    if [[ $arg == "init" ]]; then
		  init
    elif [[ $arg == "clean" ]]; then
		  clean
    else
		  error
    fi
    exit 0
}

# Pas de paramètre
#[[ $# -lt 1 ]] && error
# ou
[[ $# -lt 1 ]] && usage

# -o : Options courtes
# -l : options longues
OPT=$(getopt -o h,v,j: -l verbose,help,url:,ssh:,makeopt: -- "$@")

# éclatement de $options en $1, $2...
set -- $OPT

while true; do
    case "$1" in
	-v|--verbose)
	    # TODO
	    shift;;
	-h|--help)
	    usage;;
	--ssh)
	    ssh $2
	    shift 2;;
	--url)
	    url $2
	    shift 2;;
	-j|--makeopt)
		 makeopt $2
		 shift 2;;
	--) 
	    shift;;
	*)
	    action $1
	    shift;;
    esac
done

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
	 ln -s $(pwd)/custom/mods/nalc nalc-server-mods/nalc
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
