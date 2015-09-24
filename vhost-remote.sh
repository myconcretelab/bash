#!/bin/bash

if [ "$2" == "" ]
  then
    echo 'ERROR : No instalation name'
    exit
fi


## Fill variable
root=`pwd`
dirRel='www'
globalApplicationFolder="applications57"
globalPackagesFolder="packages57"
globalConcreteFolder="concrete5_engine"
globalMysqlFolder="mysql"
boilerplateFolder="c5-boilerplate"

domain=$2
subDomain=$3
packageTheme=$1

sqlU="111990"
sqlP="SQL@myconcretelab"
mysqlHost="mysql-myconcretelab.alwaysdata.net"


## Si le domaine est myconcretelab alors le domaine est myconcretelab.com
## Sinon, c'est lenomdusite.myconcretelab.com
if [ "$domain" = "myconcretelab" ]
  then
  domain="$domain.com"
else
  domain="$domain.myconcretelab.com"
fi

# Si il n'y a pas de sous domaine le domaine est le parametre
# sionon c'est domaine.sous-domaine
if [ "$subDomain" != "" ]
then
  vhost="$subDomain.$domain"
  handle=$2"_"$subDomain
  databaseName="myconcretelab_$handle"
else
  vhost=$domain
  handle=$2
  databaseName="myconcretelab_$handle"
fi

## On duplique le boilerplate, on y place concrete et packages.
## si le vhost existe on suppose que tout ce folders sont OK

## rm -rf $root/$dirRel/$vhost

if [ ! -d $root/$dirRel/$vhost ]
  then
  echo "## Creation of $vhost with the $1 ##"
  echo " - Create Site at Alwaysdata"
  curl --user '7375bf1d975c4851951523c3babed476 account=myconcretelab:' -d '{"type":"apache_standard","name":"'$handle'","path":"/www/'$vhost'","addresses":["'$vhost'"]}' https://api.alwaysdata.com/v1/site/
  echo " - Duplicate boilerplate"
  mkdir $root/$dirRel/$vhost
  cp -r $root/$boilerplateFolder/*  $root/$dirRel/$vhost/
  cp -r $root/$boilerplateFolder/.htaccess  $root/$dirRel/$vhost/.htaccess
  rm -r -f $root/$dirRel/$vhost/.git
  echo " - Creating symbolic links to concrete, packages"
  ln -s $root/$globalConcreteFolder/concrete $root/$dirRel/$vhost/concrete
  ln -s $root/$globalPackagesFolder $root/$dirRel/$vhost/packages
  ## Deplacer application dans le depot git si il n'y existe pas encore
  if [ ! -d $root/$globalApplicationFolder/$handle ]
    then
      echo " - Copying $vhost/application to the global application folder"
      mv -f $root/$dirRel/$vhost/application $root/$globalApplicationFolder/$handle
    else
      # Si le dossier existe dans le depot git on supprime celui qui était dans le boilerplate
      echo " - Deleting application folder from boilerplate"
      rm -r -f $root/$dirRel/$vhost/application
  fi
    # et en faire un lien symbolique du depot git vers le vhost
    echo " - Create symbolic link from $handle application to $vhost/application"
    ln -s $root/$globalApplicationFolder/$handle $root/$dirRel/$vhost/application

  if [ -a $root/$dirRel/$vhost/.htaccess ]
    then
    echo " - Update .htaccess"
    relativevhost="index.php"
    sed -i.original 's/vhost/'$relativevhost'/g' $root/$dirRel/$vhost/.htaccess
    rm -f $root/$vhost/.htaccess.original
  fi

  ## on efface le fichier database.php si il existe
  if [ -a $root/$dirRel/$vhost/application/config/database.php ]
    echo " - Deleting database config file"
    then rm -f $root/$dirRel/$vhost/application/config/database.php
  fi
  
    ## On crée la DB Même si elle existe..
    echo " - Creating database $databaseName"
    curl --user '7375bf1d975c4851951523c3babed476 account=myconcretelab:' -d '{"permissions":{"'$sqlU'":"FULL"},"type":"MYSQL","name":"'$databaseName'","encoding":"utf8"}' https://api.alwaysdata.com/v1/database/

  # on met a jour les donnée de connection de la DB du fichier database.php
    echo " - Create database config file + update database name"
    cp $root/$globalMysqlFolder/database.php $root/$dirRel/$vhost/application/config/database.php
    sed -i.original 's/databaseName/'$databaseName'/g; s/localhost/'$mysqlHost'/g; s/Uname/'$sqlU'/g; s/Pwd/'$sqlP'/g'  $root/$dirRel/$vhost/application/config/database.php
    rm -f $root/$dirRel/$vhost/application/config/database.php.original
else
  echo "## Updating $vhost with $1 ##"
fi

## On nettoie le dossier application
if [ -d $root/$dirRel/$vhost/application/files/cache ]
  then
  echo " - Deleting Files in cache"
  rm -r -f $root/$dirRel/$vhost/application/files/cache
fi


# Si le fichier de DB existe dans le depot git, on importe,
if [ -a $root/$globalMysqlFolder/$databaseName.sql.txt ]
  then
    if [ "$dbExist" = true ]; then
      echo " - Importing database..."
    else
      echo " - Updating database $databaseName"
    fi
    mysql -u $sqlU -p$sqlP -h $mysqlHost -D $databaseName < $root/$globalMysqlFolder/$databaseName.sql.txt
fi

echo " - Finished. You may need to update the C5 instalation : http://localhost:8888/$vhost/index.php/ccm/system/upgrade"
