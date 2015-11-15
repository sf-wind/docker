#!/bin/bash

function usage {
  echo "Backup/Restore Database from/to docker container"
  echo "    database.sh <arguments> <file>"
  echo "Arguments:"
  echo "    -h --help : print this message"
  echo "    -b --backup : backup the database"
  echo "    -r --restore : restore the database"
  echo "    -c --container : the container to restore"
}

FILE=""
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

FILE=$1

if [[ $BACKUP -ne "true" && $RESTORE -ne "true" ]]; then
  echo "Must specify backup or restore argument"
  exit
fi

if [[ $BACKUP = "true" && $RESTORE = "true" ]]; then
  echo "Cannot specify both back and restore arguments"
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

if [[ ! -d backups ]]; then
  echo "Error, backups directory does not exist"
  exit
fi

DATE=`date +%Y_%m_%d`

if [[ $BACKUP == "true" ]]; then
  if [[ ! -f "$FILE" ]]; then
    FILE="${CONTAINER}_${DATE}.tar.gz"
  fi
  echo "Backing up wordpress code in container $CONTAINER to $FILE"
  docker run --name backup_wordpress --volumes-from $CONTAINER -v $(pwd)/backups:/var/backups --rm debian sh -c "tar -czf /var/backups/$FILE -C /var/www/html wp-content/"
  (ls backups/*wordpress* -t | head -n 5;ls backups/*wordpress*) | sort |uniq -u | xargs rm -f
  echo "Done"
fi

if [[ $RESTORE == "true" ]]; then
  if [[ ! -f $FILE  ]]; then
    echo "Wordpress code backup file $FILE cannot be found"
    exit
  fi

  echo "Restoring wordpress code to container $CONTAINER from $FILE"
  docker run --name restore_wordpress --volumes-from $CONTAINER -v $(pwd)/backups:/var/backups --rm debian sh -c "tar -xzf /var/$FILE -C /var/www/html"
  echo "Done"
fi

