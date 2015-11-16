#!/bin/bash

function usage {
  echo "Backup Database/Code from/to docker container"
  echo "    backup.sh <arguments> directory"
  echo "Arguments:"
  echo "    -h --help : print this message"
  echo "    -t --type : database to backup the database and code to backup code"
}


# Then iterate all subdirectories and start them


ROOT_DIR=""
TYPE=""

while [[ $#>1 ]]
do

key="$1"
case $key in
  -h|--help)
    usage
    exit
    ;;
  -t|--type)
    TYPE="$2"
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

if [[ $TYPE != "database" && $TYPE != "code" ]]; then
  echo "Type must be either database or code"
  exit
fi

ROOT_DIR=$1

if [[ -z $ROOT_DIR ]]; then
  echo "Root directory is required"
  exit
fi

for dir in $ROOT_DIR/*
do
  if [[ -d $dir ]]; then
    cd $dir
    if [[ -f docker-compose.yml ]]; then
      if [[ $TYPE = "database" ]]; then
        MYSQL_CONTAINER="$(sed -r -n 's/container_name:\s+(.*_mysql)$/\1/p' docker-compose.yml)"
        if [[ ! -z $MYSQL_CONTAINER ]]; then
          #echo $MYSQL_CONTAINER
          mysqlBR.sh -b -c $MYSQL_CONTAINER 
        fi
      elif [[ $TYPE = "code" ]]; then
        WORDPRESS_CONTAINER="$(sed -r -n 's/container_name:\s+(.*_wordpress)$/\1/p' docker-compose.yml)"
        if [[ ! -z $WORDPRESS_CONTAINER ]]; then
          wordpressBR.sh -b -c $WORDPRESS_CONTAINER
        fi
      fi
    fi
  fi
done

