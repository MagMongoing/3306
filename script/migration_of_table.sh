#!/bin/bash


# source
#S_SOCKET=/tmp/mysql.sock
S_USER=archive
S_PORT=3306
S_HOST=$1
S_PASS=admin
S_DB=$2

# dist
#D_SOCKET=/tmp/mysql.sock
D_USER=archive
D_PORT=3306
D_HOST=$3
D_PASS=admin
D_DB=$4

# slave
SLAVE_USER=archive
SLAVE_PASS=admin
SLAVE="--slave-user=$SLAVE_USER --slave-password=$SLAVE_PASS"

# display error message and exit
error()
{
	echo "$1" 1>&2
	exit 1
}

# Check options before proceding
if [ ! -d "log" ];
   then mkdir log
fi

if [ ! -e /usr/bin/pt-archiver ];
	then error "pt-archiver is not installed"
fi

# pt-archiver
LIMIT=300
PROGRESS=2000000

#WHERE_SQL='create_time<"2019-10-26 01:00:00"'
WHERE_SQL=$5

#DRY=""  # --dry-run
#DELETE="--bulk-delete"    # --no-delete --bulk-delete
#DRY="--dry-run"
#DELETE="--no-delete"    # --no-delete --bulk-delete
#DRY="$8"
DRY="" #--no-check-columns
DELETE="--no-delete"    # --no-delete --bulk-delete
CHARSET="--charset=utf8"  #"--charset=utf8"  # --no-check-charset/--charset=

#for i in $(seq 15 127)
#do 
#t=$t" "user_coupon_$i
#done
t="op_1 op"
echo $t
for table in $t
do
S_TABLE=$table
D_TABLE=$table
SOURCE="A=utf8mb4,h=$S_HOST,P=$S_PORT,u=$S_USER,p=$S_PASS,D=$S_DB,t=$S_TABLE"
DEST="A=utf8mb4,h=$D_HOST,u=$D_USER,p=$D_PASS,D=$D_DB,t=$D_TABLE,P=$D_PORT"
mysqldump -uarchive -p$S_PASS -h$S_HOST --single-transaction --skip-add-drop-table --set-gtid-purged=off $S_DB -d --tables $S_TABLE|mysql -uarchive -p$D_PASS -h$D_HOST -D$D_DB
#LOG FILE
LOG=./log/$S_TABLE.sql
echo " "     >>$LOG
echo "source: $S_DB.$S_TABLE" >>$LOG
echo "DEST: $D_DB.$D_TABLE"   >>$LOG 
echo "WHERE: $WHERE_SQL "     >>$LOG
echo " "     >>$LOG
echo $WHERE_SQL
/usr/bin/pt-archiver --source $SOURCE --dest $DEST  --where "$WHERE_SQL" $SLAVE  $CHARSET --bulk-insert --no-delete --commit-each --limit=$LIMIT --progress=$PROGRESS --no-safe-auto-increment  --statistics --why-quit $DRY>>$LOG
      if [ $? -eq 0  ]
          then echo " $S_TABLE $WHERE_SQL is OK\n" >>$LOG
       else echo "$S_TABLE $WHERE_SQL  Failed"     >>$LOG
     fi
     sleep 2
done
