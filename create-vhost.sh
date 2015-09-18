#!/bin/bash

if [ "$2" == "" ]
  then
    echo 'ERROR : No instalation name'
    exit
fi


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

cd $root

### Check for git repos ####

if [ ! -d $globalApplicationFolder ]
  then
  echo " - Add concrete5-applications.git"
  git clone git@github.com:myconcretelab/concrete5-applications.git $globalApplicationFolder
else
  cd $globalApplicationFolder
  echo " - Update concrete5-applications.git"
  git pull
fi
cd $root

if [ ! -d $globalMysqlFolder ]
  then
  echo " - Add mysql.git"
  git clone git@github.com:myconcretelab/mysql.git $globalMysqlFolder
else
  cd $globalMysqlFolder
  echo " - Update mysql.git"
  git pull
fi
cd $root

if [ ! -d $globalConcreteFolder ]
  then
  echo " - Add concrete5_engine.git"
  git clone git@github.com:myconcretelab/concrete5_engine.git $globalConcreteFolder
else
  cd $globalConcreteFolder
  echo " - Update concrete5_engine.git"
  git pull
fi
cd $root

if [ ! -d $boilerplateFolder ]
  then
  echo " - Add c5boilerplate.git"
  git clone git@github.com:myconcretelab/c5-boilerplate.git $boilerplateFolder
else
  cd $boilerplateFolder
  echo " - Update c5-boilerplate.git"
  git pull
fi

## Maintenant on va verifier si le package existe et le mettre a jour sionon

cd $root/$globalPackagesFolder

if [ ! -d $1 ]
  then
  echo " - Add $1.git"
  git clone git@github.com:myconcretelab/c5-boilerplate.git $boilerplateFolder
else
  cd $1
  echo " - Update $1.git"
  git pull
fi
cd $root

# Si il n'y a pas de sous domaine le domaine est le parametre
# sionon c'est domaine.sous-domaine
if [ "$3" != "" ]
then
  vhost="$2.$3"
  dirname="$2_$3"
  databaseName="myconcretelab_$2_$3"
else
  vhost=$2
  dirname="$2"
  databaseName="myconcretelab_$2"
fi

## On duplique le boilerplate, on y place concrete et packages.
## si le vhost existe on suppose que tout ce folders sont OK
if [ ! -d $root/$vhost ]
  then
  echo "## Creation of $vhost with the $1 ##"
  echo " - Duplicate boilerplate"
  cp -r $root/$boilerplateFolder $root/$vhost
  echo " - Creating symbolic links to concrete, packages"
  ln -s $root/$globalConcreteFolder/concrete $root/$vhost/concrete
  ln -s $root/$globalPackagesFolder $root/$vhost/packages
  ## Deplacer application dans le depot git si il n'y existe pas encore
  if [ ! -d $root/$globalApplicationFolder/$dirname ]
    then
      # On est dans l'instalation d'un nouveau site
      echo " - Copying $vhost/application to the global application folder"
      mv -f $root/$vhost/application $root/$globalApplicationFolder/$dirname
    else
      # Si le dossier existe dans le depot git on supprime celui qui était dans le boilerplate
      echo " - Deleting application folder from boilerplate"
      rm -r -f $root/$vhost/application
      ## on efface le fichier database.php si il existe
      if [ -a $root/$vhost/application/config/database.php ]
        echo " - Deleting database config file"
        then rm -f $root/$vhost/application/config/database.php
      fi
      # on met a jour les donnée de connection de la DB du fichier database.php
      echo " - Create database config file + update database name"
      cp $root/$globalMysqlFolder/database.php $root/$vhost/application/config/database.php
      sed -i.original 's/databaseName/'$databaseName'/g' $root/$vhost/application/config/database.php
      rm -f $root/$vhost/application/config/database.php.original
  fi
    # et en faire un lien symbolique du depot git vers le vhost
    echo " - Create symbolic link from global application to $vhost"
    ln -s $root/$globalApplicationFolder/$dirname $root/$vhost/application

  ## On nettoie le dossier application
  if [ -d $root/$vhost/application/files/cache ]
    then
    rm -r -f $root/$vhost/application/files/cache
  fi
  if [ -a $root/$vhost/.htaccess ]
    then
    relativevhost="$vhost\/index.php"
    sed -i.original 's/vhost/'$relativevhost'/g' $root/$vhost/.htaccess
    rm -f $root/$vhost/.htaccess.original
  fi

else
  echo "## Updating $vhost with $1 ##"
fi


## On crée la DB si elle n'existe pas
if [ ! -d /Applications/MAMP/db/mysql/$databaseName ]
  then
    echo " - Creating database $databaseName"
    dbExist=true
    mysql -u$sqlU -p$sqlP -e "create database $databaseName"
fi

# Si le fichier de DB existe dans le depot git, on importe,
if [ -a $root/$globalMysqlFolder/$databaseName.sql.txt ]
  then
    if [ "$dbExist" = true ]; then
      echo " - Importing database..."
    else
      echo " - Updating database $databaseName"
    fi
    mysql -u$sqlU -p$sqlP $databaseName < $root/$globalMysqlFolder/$databaseName.sql.txt
fi

echo " - Finished. You may need to update the C5 instalation : http://localhost:8888/$vhost/index.php/ccm/system/upgrade"

if which xdg-open > /dev/null
then
  xdg-open "http://localhost:8888/$vhost/index.php/ccm/system/upgrade"
elif which gnome-open > /dev/null
then
  gnome-open "http://localhost:8888/$vhost/index.php/ccm/system/upgrade"
fi
