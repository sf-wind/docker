#!/bin/bash

function usage {
  echo "Backup/Restore Database from/to docker container"
  echo "    database.sh <arguments> <dbfile>"
  echo "Arguments:"
  echo "    -h --help : print this message"
  echo "    -b --backup : backup the database"
  echo "    -r --restore : restore the database"
  echo "    -d --database : the database to restore"
  echo "    -c --container : the container to restore"
}

DATABASE="" 
DBFILE=""
CONTAINER=""
BACKUP=""
RESTORE=""

if [ $# -lt 3 ]; then 
  echo "Must have at least 3 arguemnts"
  usage
  exit
fi

while [[ $#>1 ]] 
do

key="$1"
case $key in
  -h|--help)
    usage
    exit
    ;;
  -b|--backup)
    BACKUP="true"
    ;;
  -r|--restore)
    RESTORE="true"
    ;;
  -d|--database)
    DATABASE="$2"
    shift
    ;;
  -c|--container)
    CONTAINER="$2"
    shift
    ;;
  *)
    echo "Unknown argument: " + $key
    usage
    exit
  ;;
esac
shift
done

DBFILE=$1

if [[ $BACKUP -ne "true" && $RESTORE -ne "true" ]]; then
  echo "Must specify backup or restore argument"
  exit
fi

if [[ $BACKUP = "true" && $RESTORE = "true" ]]; then
  echo "Cannot specify both back and restore arguments"
  exit
fi  

if [[ ! -d backups ]]; then
  echo "Error, backups directory does not exist"
  exit
fi

CONTAINER_RUNNING=$(docker inspect --format="{{ .State.Running }}" $CONTAINER 2> /dev/null)

if [[ $? -eq 1 ]]; then
  echo "UNKNOWN - $CONTAINER does not exist."
  exit
fi

if [[ "$CONTAINER_RUNNING" == "false" ]]; then
  echo "CRITICAL - $CONTAINER is not running."
  exit
fi

DATE=`date +%Y_%m_%d`

if [[ $BACKUP == "true" ]]; then
  if [[ ! -f "$DBFILE" ]]; then
    if [[ $DATABASE = "" ]]; then
      DBFILE="${CONTAINER}_${DATE}.sql.gz"
    else
      DBFILE="${DATABASE}_${DATE}.sql.gz"
    fi   
  fi
  if [[ $DATABASE = "" ]]; then
    DATABASE="--all-databases"
  fi

  echo "Backing up database $DATABASE in container $CONTAINER to $DBFILE"
  docker run --name backup_mysql --link ${CONTAINER}:sql --rm -v $(pwd)/backups:/backups mysql sh -c 'mysqldump -u root -p$SQL_ENV_MYSQL_ROOT_PASSWORD -h $SQL_PORT_3306_TCP_ADDR '$DATABASE' | gzip > /backups/'$DBFILE
  (ls backups/*mysql* -t | head -n 5;ls backups/*mysql*) | sort |uniq -u | xargs rm -f 
  echo "Done"
fi

if [[ $RESTORE == "true" ]]; then
  if [[ ! -f $DBFILE ]]; then
    echo "Database file $DBFILE cannot be found"
    exit
  fi

  if [[ ! -z $DATABASE ]]; then
    DATABASE="--one-database $DATABASE"
  fi

  echo "Restoring database $DATABASE in container $CONTAINER from $DBFILE" 
  docker run --name restore_mysql --link ${CONTAINER}:sql --rm -v $(pwd)/backups:/backups mysql sh -c "gzip -dc /${DBFILE} | mysql -u root -p\$SQL_ENV_MYSQL_ROOT_PASSWORD -h \$SQL_PORT_3306_TCP_ADDR ${DATABASE}"
  echo "Done"
fi
