#!/bin/sh
#
# Script to create full and incremental backups (for all databases on server) using innobackupex from Percona.
#
# Every time it runs will generate an incremental backup except for the first time (full backup).

INNOBACKUPEX=innobackupex
INNOBACKUPEXFULL=/usr/bin/$INNOBACKUPEX
USEROPTIONS="--user= --password= --host= -P3306"
MYCNF=$1
MYSQL=/usr/local/mysql/bin/mysql
MYSQLADMIN=/usr/local/mysql/bin/mysqladmin
BACKUPDIR=/data/backup # Backups base directory
#LSNDIR=$BACKUPDIR/lsndir              # save an extra copy of the xtrabackup_checkpoints and xtrabackup_info files in this directory
TMPFILE="$BACKUPDIR/innobackupex-runner.$$.tmp"

REMOTE_BACKUPHOST=backup  # Remote backup host
SSH_OPTION="ssh root@$REMOTE_BACKUPHOST"
USER_HOST="root@$REMOTE_BACKUPHOST"
HOST_IP_SUFFIX=`ifconfig|grep eth -A 1|grep inet |awk -F '.' '{print $4}' |awk -F ' ' '{print $1}'`
HOST_NAME=$2
HISTORY_NAME="$HOST_NAME"_"$HOST_IP_SUFFIX"
BACKUPDIR_SUFFIX=$HISTORY_NAME             # DB'name and ip'suffix
REMOTE_BACKUPDIR=/mysql_backup/backup/$HOST_NAME/$BACKUPDIR_SUFFIX  # Remote backup host

FULLBACKUPDIR=$REMOTE_BACKUPDIR/full # Full backups directory
INCRBACKUPDIR=$REMOTE_BACKUPDIR/incr # Incremental backups directory

PARALLEL=2
PV=50M
FULLBACKUPLIFE=518400 # Lifetime of the latest full backup in seconds 547200 (7*24-16)*3600
BAK_TIME=`date +%Y%m%d_%H%M%S`
KEEP=6 # Number of full backups (and its incrementals) to keep

# Grab start time
STARTED_AT=`date +%s`

#############################################################################
# Display error message and exit
#############################################################################
error()
{
    echo "$1" 1>&2
    exit 1
}

# Check options before proceeding
if [ ! -x $INNOBACKUPEXFULL ]; then
  error "$INNOBACKUPEXFULL does not exist."
fi

if [ ! "$MYCNF" -a "$HISTORY_NAME" ]; then
  error "my.cnf or backup history name does not exist."
fi

#if [ ! "$HISTORY_NAME" ]; then
#  error "."
#fi

#if [ ! -d $LSNDIR ]; then
#  error "Backup lsndir folder: $LSNDIR does not exist."
#fi

$SSH_OPTION "if [ ! -d $REMOTE_BACKUPDIR ]; then mkdir -p $REMOTE_BACKUPDIR;fi"
$SSH_OPTION "if [ ! -d $REMOTE_BACKUPDIR ]; then error 'Backup destination folder: backupdir is not exist.';fi"

$SSH_OPTION "if [ ! -d $FULLBACKUPDIR ]; then mkdir -p $FULLBACKUPDIR;fi"
$SSH_OPTION "if [ ! -d $FULLBACKUPDIR ]; then error 'Backup destination folder: $FULLBACKUPDIR is not exist.';fi"

$SSH_OPTION "if [ ! -d $INCRBACKUPDIR ]; then mkdir -p $INCRBACKUPDIR;fi"
$SSH_OPTION "if [ ! -d $INCRBACKUPDIR ]; then error 'Backup destination folder: $INCRBACKUPDIR is not exist.';fi"

if [ -z "`$MYSQLADMIN $USEROPTIONS status | grep 'Uptime'`" ] ; then
 error "HALTED: MySQL does not appear to be running."
fi

if ! `echo 'exit' | $MYSQL -s $USEROPTIONS` ; then
 error "HALTED: Supplied mysql username or password appears to be incorrect (not copied here for security, see script)."
fi

# Some info output
echo "-------------------------------------------------------"
echo "----------start:`date +%Y%m%d_%H%M%S`------------------"
echo
echo "$0: MySQL backup script"
echo "started: `date`"
echo

# Create full and incr backup directories if they not exist.
#mkdir -p $FULLBACKUPDIR
#mkdir -p $INCRBACKUPDIR

# Find latest full backup
LATEST_FULL=`$SSH_OPTION "find $FULLBACKUPDIR -mindepth 1 -maxdepth 1 -type d -printf \"%P\n\" | sort -nr | head -1"`
OLD_FULL=`$SSH_OPTION "find $FULLBACKUPDIR -mindepth 1 -maxdepth 1 -type d  | sort -nr | tail -1"`
# Get latest backup last modification time
LATEST_FULL_CREATED_AT=`$SSH_OPTION "stat -c %Y $FULLBACKUPDIR/$LATEST_FULL"`

# Run an incremental backup if latest full is still valid. Otherwise, run a new full one.
if [ "$LATEST_FULL" -a `expr $LATEST_FULL_CREATED_AT + $FULLBACKUPLIFE ` -ge $STARTED_AT ] ; then
  # Create incremental backups dir if not exists.
  TMPINCRDIR=$INCRBACKUPDIR/$LATEST_FULL
  $SSH_OPTION "mkdir -p $TMPINCRDIR"

  # Find latest incremental backup.
  # LATEST_INCR=`find $TMPINCRDIR -mindepth 1 -maxdepth 1 -type d | sort -nr | head -1`

  # If this is the first incremental, use the full as base. Otherwise, use the latest incremental as base.
  #if [ ! $LATEST_INCR ] ; then
  #  INCRBASEDIR=$FULLBACKUPDIR/$LATEST_FULL
  #else
  #  INCRBASEDIR=$LATEST_INCR
  #fi

  #echo "Running new incremental backup using $INCRBASEDIR as base."
  echo "Running new incremental backup. incremental dir: incr_$BAK_TIME"
  $SSH_OPTION "mkdir -p $TMPINCRDIR/incr_$BAK_TIME"
  $INNOBACKUPEXFULL --defaults-file=$MYCNF $USEROPTIONS --no-timestamp --compress --incremental --slave-info --stream=xbstream --parallel=$PARALLEL --history=$HISTORY_NAME --incremental-history-name=$HISTORY_NAME $BACKUPDIR 2> $TMPFILE |pv -q -L$PV |$SSH_OPTION "xbstream -x -C $TMPINCRDIR/incr_$BAK_TIME"
  #$INNOBACKUPEXFULL --defaults-file=$MYCNF $USEROPTIONS --no-timestamp --compress --incremental $TMPINCRDIR/incr_$BAK_TIME --incremental-basedir $INCRBASEDIR > $TMPFILE 2>&1
  #$INNOBACKUPEXFULL --defaults-file=$MYCNF $USEROPTIONS --no-timestamp  --incremental $TMPINCRDIR/incr_$BAK_TIME --incremental-basedir $INCRBASEDIR > $TMPFILE 2>&1

  if [ -z "`tail -1 $TMPFILE | grep 'completed OK!'`" ] ; then
    echo "$INNOBACKUPEX failed:"; echo
    echo "---------- ERROR OUTPUT from $INNOBACKUPEX ----------"
    scp  $TMPFILE $USER_HOST:$TMPINCRDIR/incr_$BAK_TIME
    exit 1
  else
    scp  $TMPFILE $USER_HOST:$TMPINCRDIR/incr_$BAK_TIME
  fi

else
  echo "Running new full backup."
  $SSH_OPTION "mkdir -p $FULLBACKUPDIR/full_$BAK_TIME"
 #$MYSQL $USEROPTIONS -e "flush logs;"
  #$INNOBACKUPEXFULL --defaults-file=$MYCNF $USEROPTIONS --no-timestamp --compress  $FULLBACKUPDIR/full_$BAK_TIME > $TMPFILE 2>&1
  #$INNOBACKUPEXFULL --defaults-file=$MYCNF $USEROPTIONS --no-timestamp   $FULLBACKUPDIR/full_$BAK_TIME > $TMPFILE 2>&1
  $INNOBACKUPEXFULL --defaults-file=$MYCNF $USEROPTIONS --no-timestamp --compress --slave-info --stream=xbstream --parallel=$PARALLEL --history=$HISTORY_NAME $BACKUPDIR 2> $TMPFILE |pv -q -L$PV |$SSH_OPTION "xbstream -x -C $FULLBACKUPDIR/full_$BAK_TIME"

  if [ -z "`tail -1 $TMPFILE | grep 'completed OK!'`" ] ; then
    echo "$INNOBACKUPEX failed:"; echo
    echo "---------- ERROR OUTPUT from $INNOBACKUPEX ----------"
    scp  $TMPFILE $USER_HOST:$FULLBACKUPDIR/full_$BAK_TIME
    exit 1
  else
    scp  $TMPFILE $USER_HOST:$FULLBACKUPDIR/full_$BAK_TIME
  fi
fi

if [  "`tail -1 $TMPFILE | grep 'completed OK!'`" ] ; then
THISBACKUP=`awk -- "/Backup created in directory/ { split( \\\$0, p, \"'\" ) ; print p[2] }" $TMPFILE`
#rm -f $TMPFILE
echo "Databases backed up successfully to: $THISBACKUP"
echo "Remote backup dir: $REMOTE_BACKUPDIR"
echo
fi

## Cleanup
#echo "Cleanup. Keeping only $KEEP full backups and its incrementals."
#AGE=$(($FULLBACKUPLIFE * $KEEP / 60))
#find $FULLBACKUPDIR -maxdepth 1 -type d -mmin +$AGE -execdir echo "removing: "$FULLBACKUPDIR/{} \; \
#-execdir rm -rf $FULLBACKUPDIR/{} \; -execdir echo "removing: "$INCRBACKUPDIR/{} \; \
#-execdir rm -rf $INCRBACKUPDIR/{} \;

echo
echo "----------completed:`date +%Y%m%d_%H%M%S`------------------"
exit 0
