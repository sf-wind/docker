#!/bin/bash

function usage() {
  echo "Create wordpress docker container and related backup/restore routines"
  echo "    create-wordpress.sh <arguments> <target-directory>"
  echo "Arguments:"
  echo "    -h --help : print this message"
  echo "    -d --domain : the domain the wordpress is installed on"
}

DOMAIN=""

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
  -d|--domain)
    DOMAIN="$2"
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


DIR=$1

if [[ -z $DIR ]]; then
  echo "Error, the target directory is not specified"
  exit
fi

if [[ ! -d $DIR ]]; then
  echo "Error, target directory does not exist"
  exit
fi

if [[ -d $DIR/$DOMAIN ]]; then
  echo "Error, directory $DIR/$DOMAIN exists"
  exit
else
  mkdir $DIR/$DOMAIN
  mkdir $DIR/$DOMAIN/backups
fi

ROOT_PASSWORD="$(rand-pw.sh)"
DB_PASSWORD="$(rand-pw.sh)"

sed -e "s;%DOMAIN%;$DOMAIN;g" -e "s;%ROOT_PASSWORD%;$ROOT_PASSWORD;g" -e "s;%DB_PASSWORD%;$DB_PASSWORD;g" ~/docker/templates/docker-compose-wordpress.yml > $DIR/$DOMAIN/docker-compose.yml
chmod -w $DIR/$DOMAIN/docker-compose.yml

