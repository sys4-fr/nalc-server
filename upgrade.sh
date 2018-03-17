#!/bin/bash

verif() {
	 if [[ $? -gt 0 ]]; then
		  echo "Erreur ! Arrêt du script."
		  exit 1
	 fi
}

# Affichage de l'aide si demandé en paramètres
if [[ $1 = "--help" ]]; then
	 echo "Usage : ./upgrade.sh [options]"
	 echo ""
	 echo "Options :"
	 echo "--help : Cette aide"
	 echo "--mods-link : Met à jour les liens symboliques des mods seulement"
	 exit 0
fi

# Mise à jour de tous les liens symboliques des mods
if [[ $1 == "--mods-link" ]]; then
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

	 # Lien symbolique world.mt
	 if [[ ! -a minetest/worlds/nalc/world.mt ]]; then
		  ln -s $(pwd)/world.mt minetest/worlds/nalc/world.mt
	 fi
fi

echo "Mise à jour terminé."
exit 0
