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
    echo "--makeopt | -j : Passer des options à make."
    echo "--ssh <user@host>: Identifiants ssh."
    echo "--url <URL>: URL distante personnalisée."
	 echo "--irrlicht | -i : Chemin personnalisé des sources irrlicht."
	 echo "--postgresql | -p : Si vous voulez que le serveur soit configuré avec postgresql"
    echo -e "\tSi l'option --ssh est passée en option, il s'agira du chemin distant."
    echo "Commandes :"
    echo -e "\t0.5 : Installation du serveur avec minetest-0.5.x. Suivez les instructions..."
    echo -e "\t0.4 : Installation du serveur avec minetest-0.4.x. Suivez les instructions..."
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

postgresql() {
	 echo "Les indications à fournir ci-après nécessite d'avoir configuré un serveur postgresql au préalable. (Ctrl-C) pour annuler."
	 read -p "Indiquez l'adresse de la base de données : " pg_url
	 read -p "Indiquez l'utilisateur de la BDD : " pg_user
	 read -p "Indiquez le mot de passe : " pg_password
	 read -p "Indiquez le nom de la BDD à utiliser : " pg_dbname

	 echo "gameid = minetest_game" > worldmt.conf
	 echo "backend = postgresql" >> worldmt.conf
	 echo "player_backend = postgresql" >> worldmt.conf
	 echo "pgsql_connection = host=$pg_url user=$pg_user password=$pg_password dbname=$pg_dbname" >> worldmt.conf
	 echo "pgsql_player_connection = host=$pg_url user=$pg_user password=$pg_password dbname=players-$pg_dbname" >> worldmt.conf
}

install_0.4() {
	 if [[ -d server-0.4 ]]; then
		  echo "Installation précédente détecté. Voulez-vous faire la mise à jour ?"
		  read -p "Votre choix ? (y, n, clean) " continuer
		  if [[ $continuer == "y" ]]; then
				cd server-0.4
				git pull
				verif
				git submodule update --remote --recursive
				verif
				cd ..
		  elif [[ $continuer == "clean" ]]; then
				rm -rf server-0.4
				git clone https://github.com/sys4-fr/server-nalc.git server-0.4
				verif
				cd server-0.4
				git submodule update --init --recursive
				verif
				cd ..
		  else
				echo "Mise à jour annulé."
		  fi
	 else
		  git clone https://github.com/sys4-fr/server-nalc.git server-0.4
		  verif
		  cd server-0.4
		  git submodule update --init --recursive
		  verif
		  cd ..
	 fi
}

install_minetest() {
	 if [[ -z $makeopt ]]; then
		  local makeopt=$(grep -c processor /proc/cpuinfo)
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
		  local branch="-b master"
		  if [[ $ver == "0.4" ]]; then
				branch="-b backport-0.4"
		  fi
		  git clone $branch $URL/minetest.git
		  verif
	 fi

	 echo "Minetest va être (re)compilé..."
	 sleep 3
	 cd minetest
	 cmake . -DBUILD_CLIENT=0 -DBUILD_SERVER=1 -DENABLE_SOUND=0 -DENABLE_SYSTEM_GMP=1 $irrlicht_src -DENABLE_LEVELDB=0 -DENABLE_REDIS=1 -DENABLE_POSTGRESQL=1 -DRUN_IN_PLACE=1 -DENABLE_GETTEXT=1 -DENABLE_FREETYPE=1 -DENABLE_LUAJIT=1 -DENABLE_CURL=1
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
		  local branch="-b master"
		  if [[ ! $ver == "0.4" ]]; then
				branch="-b backport-0.4"
		  fi
		  git clone $branch $URL/minetest_game.git
		  verif
		  echo "Clonage de minetest_game terminé."
	 fi

	 if [[ ! -L minetest/games/minetest_game ]]; then
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

				if [[ -n $pg_dbname ]]; then
					 dropdb $pg_dbname
					 verif
					 dropdb players-$pg_dbname
					 verif
					 createdb $pg_dbname
					 createdb players-$pg_dbname
				fi
		  fi
	 fi

	 if [[ ! -d minetest/worlds/nalc ]]; then
		  mkdir -p minetest/worlds/nalc
		  if [[ -n $pg_dbname ]]; then
				createdb $pg_dbname
				createdb players-$pg_dbname
		  fi

		  if [[ $ver == "0.4" ]]; then
				ln -s $(pwd)/server-0.4/worlds/minetestforfun/world.mt minetest/worlds/nalc/world.mt
		  else
				ln -s $(pwd)/world.mt minetest/worlds/nalc/world.mt
		  fi
	 fi
}		

install_mods() {
	 if [[ $ver == "0.4" ]]; then
		  local i=0
		  local md[1]="" # Mods to disable
		  for mod in "mysql_auth watershed mobs_old magicmithril obsidian eventobjects player_inactive random_messages irc irc_commands profilerdumper profnsched"; do
				i=$(( $i+1 ))
				md[$i]=$mod
		  done
		  
		  if [[ -d minetest/mods ]]; then
				rm -rf minetest/mods
				ln -s $(pwd)/server-0.4/mods minetest/mods
		  fi

		  if [[ -a world.mt ]]; then
				rm world.mt
		  fi
		  cp worldmt.conf world.mt

		  ls server-0.4/mods | while read -r mod; do
				if [[ -a server-0.4/mods/$mod/modpack.txt ]]; then
					 ls server-0.4/mods/$mod | while read -r submod; do
						  if [[ -d server-0.4/mods/$mod/$submod ]]; then
								local mod_enable="true"
								for (( modn=1; modn<$i; modn++ )); do
									 if [[ ${md[$modn]} == $submod ]]; then
										  mod_enable="false"
									 fi
								done
								echo "load_mod_$submod = $mod_enable" >> world.mt
						  fi
					 done
				else
					 local mod_enable="true"
					 for (( modn=1; modn<$i; modn++ )); do
						  if [[ ${md[$modn]} == $mod ]]; then
								mod_enable="false"
						  fi
					 done  
					 echo "load_mod_$mod = $mod_enable" >> world.mt
				fi
		  done
	 else
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
	 fi
}

post_install() {
	 if [[ ! -a minetest/minetest.conf ]]; then
		  if [[ $ver == "0.4" ]]; then
				cp server-0.4/minetest.conf minetest/minetest.conf
		  else
				cp minetest.conf minetest/minetest.conf
		  fi
		  
		  echo "Veuillez éditer le fichier $(pwd)/minetest/minetest.conf"
	 fi

	 if [[ ! -d logs ]]; then
		  mkdir logs
	 fi

	 if [[ $ver == "0.4" ]]; then
		  if [[ ! -a start.sh ]]; then
				cp server-0.4/other_things/scripts/Server-side/script/start-mff.sh ./start.sh
				echo "Veuiller éditer le fichier start.sh"
		  fi
	 fi

	 # skindb updater (à relancer à la main plusieurs fois pour l'instant)
	 if [[ -d nalc-server-mods/skinsdb/updater ]]; then
		  cd nalc-server-mods/skinsdb/updater
		  ./update_from_db.py
		  cd ../../..
	 fi
}

init() {
	 ver=$(strip $1)
	 
	 if [[ -n $ssh && -n $url ]]; then
		  URL=$ssh\:$url
	 elif [[ -n $url ]]; then
		  URL=$url
	 else
		  URL="https://github.com/sys4-fr"
	 fi

	 read -p "L'installation va démarrer. Continuer ? (y or n) : " continue
	 if [[ $continue == "y" ]]; then
		  if [[ $ver == "0.4" ]]; then
				install_0.4
		  fi
		  install_minetest
		  install_minetest_game
		  install_mods
		  install_world
		  post_install
		  echo "L'installation est terminé. Bravo !"
	 else
		  echo "Installation annulée. Fin."
	 fi
}

action() {
    local arg=$(strip $1)
    if [[ $arg == "0.5" ]]; then
		  init "0.5"
    elif [[ $arg == "0.4" ]]; then
		  init "0.4"
    else
		  error
    fi
    exit 0
}

irrlicht() {
	 local arg=$(strip $1)
	 if [[ -d $arg ]]; then
		  irrlicht_src="-DIRRLICHT_SOURCE_DIR=$arg"
	 fi
}

# Pas de paramètre
#[[ $# -lt 1 ]] && error
# ou
[[ $# -lt 1 ]] && usage

# -o : Options courtes
# -l : options longues
OPT=$(getopt -o h,p,j:,i: -l help,postgresql,url:,ssh:,makeopt:,irrlicht: -- "$@")

# éclatement de $options en $1, $2...
set -- $OPT

while true; do
    case "$1" in
	-h|--help)
	    usage;;
	-i|--irrlicht)
		 irrlicht $2
		 shift 2;;
	-p|--postgresql)
		 postgresql
		 shift;;
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
