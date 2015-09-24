#!/bin/bash

##  USAGE :
##  ./create-vhost.sh handle_theme domain subdomain : create subdomain.domain and .git application
##  ./create-vhost.sh none domain subdomain : create subdomain.domain BUT do not .git application



## Fill variable
root="/Applications/MAMP/htdocs"
globalApplicationFolder="_applications"
globalPackagesFolder="_packages5.7"
globalConcreteFolder="_concrete5_engine"
globalMysqlFolder="_mysql"
boilerplateFolder="c5-boilerplate"

sqlU="root"
sqlP="root"
dbExist=false

if [ $1 == 'none' ]
  then
  databasePrefix='local_'
else
  databasePrefix='myconcretelab_'
fi

# Si il n'y a pas de sous domaine le domaine est le parametre
# sionon c'est domaine.sous-domaine
if [ "$3" != "" ]
then
  vhost="$2.$3"
  dirname="$2_$3"
  databaseName="$databasePrefix$2_$3"
else
  vhost=$2
  dirname="$2"
  databaseName="$databasePrefix$2"
fi

## On duplique le boilerplate, on y place concrete et packages.
## si le vhost existe on suppose que tout ce folders sont OK

if [  -d $root/$vhost ]
  then
  echo "## Deletion of $vhost with the $1 ##"
  rm -r -f $root/$vhost
fi

## DB


if [ -d /Applications/MAMP/db/mysql/$databaseName ]
  then
    echo " - Deleting database $databaseName"
    dbExist=true
    mysqladmin -u$sqlU -p$sqlP -f drop $databaseName
fi

  echo " - Finished."
