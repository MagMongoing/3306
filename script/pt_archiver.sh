#!/bin/bash

S_SOCKET=/tmp/mysql3341.sock
S_USER=root
S_HOST=localhost
S_PASS=admin
S_DB=dba
S_TABLE=dba
SOURCE="A=utf8mb4,h=$S_HOST,S=$S_SOCKET,u=$S_USER,p=$S_PASS,D=$S_DB,t=$S_TABLE"
#SOURCE="h=$S_HOST,S=$S_SOCKET,u=$S_USER,p=$S_PASS,D=$S_DB,t=$S_TABLE"
# dest
D_SOCKET=/tmp/mysql3341.sock
D_USER=root
D_HOST=localhost
D_PASS=admin
D_DB=dba
D_TABLE=dba_archive
DEST="A=utf8mb4,h=$D_HOST,S=$D_SOCKET,u=$D_USER,p=$D_PASS,D=$D_DB,t=$D_TABLE"
#DEST="h=$D_HOST,S=$D_SOCKET,u=$D_USER,p=$D_PASS,D=$D_DB,t=$D_TABLE"
# slave
SLAVE_USER=root
SLAVE_PORT=3342
SLAVE_PASS=admin
SLAVE_HOST1=localhost

S1="h=localhost,P=3341,S=/tmp/mysql3342.sock,p=admin"

# pt-archiver
LIMIT=300
PROGRESS=20000

WHERE_SQL='update_time>"2019-06-22 00:00:00"'
echo $WHERE_SQL
DRY=""  # --dry-run
CHARSET="--no-check-charset"  #"--charset=utf8"  # --no-check-charset/--charset=
DELETE="--no-delete"    # --no-delete

/usr/bin/pt-archiver --source $SOURCE --dest $DEST  --where "$WHERE_SQL" --check-slave-lag $S1  $CHARSET --bulk-insert  $DELETE --commit-each --limit=$LIMIT --progress=$PROGRESS  --statistics --why-quit $DRY>> $S_TABLE.sql
      if [ $? -eq 0  ]
          then echo " $S_TABLE $WHERE_SQL is OK\n"
       else echo "$S_TABLE $WHERE_SQL  Failed"
     fi
     sleep 2
