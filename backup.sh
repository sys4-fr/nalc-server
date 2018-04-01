#!/bin/bash

bak=/home/minetest/nalc-server-0.4/backup
if [[ ! -d $bak ]]; then
	 mkdir $bak
fi

bak_tmp=/var/tmp/nalc-0.4_dump
if [[ ! -d $bak_tmp ]]; then
	 mkdir $bak_tmp
fi

rm -r /home/minetest/nalc-server-0.4/minetest/worlds/nalc/rollback.sqlite
tar -I pbzip2 -cvf $bak/world.tar.bz2 /home/minetest/nalc-server-0.4/minetest/worlds/nalc

pg_dump nalc-0.4 > $bak_tmp/nalc-0.4.sql
pg_dump players-nalc-0.4 > $bak_tmp/players-nalc-0.4.sql

if [[ -e $bak/dump_sql.tar.bz2 ]]; then
	 cd $bak
	 tar -jxvf dump_sql.tar.bz2
	 cd ..
fi

rdiff-backup --no-file-statistics $bak_tmp $bak

cd $bak
tar -I pbzip2 -cvf dump_sql.tar.bz2 --remove-files *.sql
cd ..

rm -rf $bak_tmp
