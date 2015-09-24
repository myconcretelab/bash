#!/bin/bash

##  USAGE :
##  ./create-vhost.sh handle_theme domain subdomain : create subdomain.domain and .git application
##  ./create-vhost.sh none domain subdomain : create subdomain.domain BUT do not .git application

while [[ $# > 0 ]]
do
key="$1"

case $key in
    -t|--theme)
    theme="$2"
    shift # past argument
    ;;
    -d|--domain)
    domain="$2"
    shift # past argument
    ;;
    -s|--subdomain)
    subdomain="$2"
    shift # past argument
    ;;
    -l|--lock)
    ## Quand on ne veut pas que le dossier application soit un lien symbolique mais une copie.
    ## Ceci arrive quand un site peut être edité par un client.
    ## Il peut tout détruire sans conséquences pour les git
    lock=true
    ;;
    --e|--extern)
    ## Quand on ne veut pas que le site soit ajouté aux différent git
    ## que la DB soit avec le prefixe "local_" pluto que "myconcretelab_"
    extern=true
    ;;
    --u|--update)
    ## Quand on veut mettre a jour les git
    update=true
    ;;
    --d|--delete)
    ## Quand on veut Supprimer le dossier vhost avant de l'installer
    delete=true
    ;;
    *)
    # unknown option
    ;;
esac
shift # past argument or value
done

## Maintenant on va voir si on est en local ou en remote

if [[ $PWD == *"MAMP"* ]]; then
  situation="local"
elif [[ $PWD == *"myconcretelab"* ]]; then
  situation="remote"
else
  echo "I don't know where I am : EXIT"
  exit
fi



if [ ! -z ${subdomain+x} ]; then
  echo " - subdomain : $subdomain"
fi



## Fill variable
if [ $situation == "local" ]
  then
    root="/Applications/MAMP/htdocs/"
    dirRel=""
    globalApplicationFolder="_applications"
    globalPackagesFolder="_packages5.7"
    globalConcreteFolder="_concrete5_engine"
    globalMysqlFolder="_mysql"
    boilerplateFolder="c5-boilerplate"

    sqlU="root"
    sqlP="root"
    mysqlHost="localhost"

  else
    root="/home/myconcretelab/"
    dirRel='www/'
    globalApplicationFolder="applications57"
    globalPackagesFolder="packages57"
    globalConcreteFolder="concrete5_engine"
    globalMysqlFolder="mysql"
    boilerplateFolder="c5-boilerplate"

    sqlU="111990"
    sqlP="SQL@myconcretelab"
    mysqlHost="mysql-myconcretelab.alwaysdata.net"
fi

## Le prefixe de la DB
if [ ! -z ${extern+x} ]
  then
  databasePrefix='local_'
else
  databasePrefix='myconcretelab_'
fi

# Si il n'y a pas de sous domaine le domaine est le parametre
# sinon c'est domaine.sous-domaine
if [ ! -z ${domain+x} ]; then
  ## Si le domaine est myconcretelab alors le domaine est myconcretelab.com
  ## Sinon, c'est lenomdusite.myconcretelab.com
  if [ "$domain" = "myconcretelab" ]
    then
    domain="$domain.com"
  else
    domain="$domain.myconcretelab.com"
  fi

  if [ ! -z ${subdomain+x} ]; then
    vhost="$subdomain.$domain"
    handle=$2"_"$subdomain
    databaseName="$databasePrefix$handle"
  else
    vhost="$domain"
    handle=$2
    databaseName="$databasePrefix$handle"
  fi
fi

## On defini les path pour les differents endroits
dirVhost=$root$dirRel$vhost
dirBoilerPlate=$root$dirRel$boilerplateFolder
dirPackage=$root$dirRel$globalPackagesFolder
dirConcrete=$root$dirRel$globalConcreteFolder
dirMysql=$root$dirRel$globalMysqlFolder
dirApplication=$root$dirRel$globalApplicationFolder

echo $vhost
exit

### Check for git repos ####
if [ ! -z ${update+x} ]
  then
  if [ ! -d $dirApplication ]
    then
    echo " - Add concrete5-applications.git"
    git clone git@github.com:myconcretelab/concrete5-applications.git $dirApplication
  else
    cd $dirApplication
    echo " - Update concrete5-applications.git"
    git pull
  fi

  if [ ! -d $dirMysql ]
    then
    echo " - Add mysql.git"
    git clone git@github.com:myconcretelab/mysql.git $dirMysql
  else
    cd $dirMysql
    echo " - Update mysql.git"
    git pull
  fi


  if [ ! -d $dirConcrete ]
    then
    echo " - Add concrete5_engine.git"
    git clone git@github.com:myconcretelab/concrete5_engine.git $dirConcrete
  else
    cd $dirConcrete
    echo " - Update concrete5_engine.git"
    git pull
  fi


  if [ ! -d $dirBoilerPlate ]
    then
    echo " - Add c5boilerplate.git"
    git clone git@github.com:myconcretelab/c5-boilerplate.git $dirBoilerPlate
  else
    cd $dirBoilerPlate
    echo " - Update c5-boilerplate.git"
    git pull
  fi

  ## Maintenant on va verifier si le package existe et le mettre a jour sionon
  cd $dirPackage
  if [ ! -z ${theme+x} ]
    then
      if [ ! -d $theme ]
        then
        echo " - Add $theme.git"
        git clone git@github.com:myconcretelab/$theme.git
      else
        cd $theme
        echo " - Update $theme.git"
        git pull
      fi
    fi
fi

## On supprime le vhost si c'est demandé

if [ ! -z ${delete+x} ] && [ -d $dirVhost ]; then
  rm -rf $dirVhost
fi


## si le vhost existe on suppose que tout ce folders sont OK
if [ ! -d $dirVhost ]
  then
  echo "## Creation of $vhost ##"

  if [ situation = "remote" ]; then
    echo " - Create Site at Alwaysdata"
    curl --user '7375bf1d975c4851951523c3babed476 account=myconcretelab:' -d '{"type":"apache_standard","name":"'$handle'","path":"/www/'$vhost'","addresses":["'$vhost'"]}' https://api.alwaysdata.com/v1/site/
  fi


  ## Symbolic links ##

  ## On duplique le boilerplate, on y place concrete et packages.
  echo " - Duplicate boilerplate"
  cp -r $dirBoilerPlate $dirVhost
  echo " - Creating symbolic links to concrete, packages"
  ln -s $dirConcrete/concrete $dirVhost/concrete
  ln -s $dirPackage $dirVhost/packages


  ## Application ##


  # Deplacer application dans le depot git si il n'y existe pas encore
  # Et que l'option "extern" n'est pas specifié
  if [ -z ${lock+x} ]  && [ -z ${extern+x} ] ## Si lock && extern ne sont pas defini
    then
    if [ ! -d $dirApplication/$handle ]; then
        echo " - Copying $vhost/application to the global application folder"
        mv -f $dirVhost/application $dirApplication/$handle
      else
        # Si le dossier existe dans le depot git on supprime celui qui était dans le boilerplate
        echo " - Deleting application folder from boilerplate"
        rm -r -f $dirVhost/application
    fi
    # et en faire un lien symbolique du depot git vers le vhost
    echo " - Create symbolic link from global application to $vhost"
    ln -s $dirApplication/$handle $dirVhost/application
  else
    if [ -d $dirApplication/$handle ]; then
      echo " ** Locked mode ON **"
      echo " - Deleting application folder from boilerplate"
      rm -rf $dirVhost/application
      echo " - Duplicate the global application to $vhost"
      cp $dirApplication/$handle $dirVhost/application
    fi
  fi


  ## .htaccess ##


  if [ -a $dirVhost/.htaccess ]; then
    if [ $situation = "remote" ]; then
      relativevhost="index.php"
    else
      ## Si on est en local il faut specifier le dossier du site
      relativevhost="$vhost\/index.php"
    fi
    sed -i.original 's/vhost/'$relativevhost'/g' $dirVhost/.htaccess
    rm -f $dirVhost/.htaccess.original
  fi


  ## database.php ##


  databaseFile=$dirVhost/application/config/database.php
  ## on efface le fichier database.php si il existe
  if [ -a $databaseFile ]
    then
    echo " - Deleting database config file"
    rm -f $databaseFile
  fi

  if [ $situation = "remote" ]; then
    ## On crée la DB Même si elle existe..
    echo " - Creating database $databaseName"
    curl --user '7375bf1d975c4851951523c3babed476 account=myconcretelab:' -d '{"permissions":{"'$sqlU'":"FULL"},"type":"MYSQL","name":"'$databaseName'","encoding":"utf8"}' https://api.alwaysdata.com/v1/database/
  ## Sinon on teste si la DB existe
  elif [ ! -d /Applications/MAMP/db/mysql/$databaseName ]; then
    echo " - Creating database $databaseName"
    mysql -u$sqlU -p$sqlP -e "create database $databaseName"
  fi
  ## Maintenant on suppose que si le fichier app.php n'existe pas
  ## cela revient a dire que le site n'a jamais été installé
  ## donc on ne crée pas de fichier database
  ## pour que la procédure d'instalation C5 s'enclenche
  if [ -a $dirVhost/application/config/app.php ]
    then
    # on met a jour les donnée de connection de la DB du fichier database.php
    echo " - Create database config file + update database name"
    cp $dirMysql/database.php $databaseFile
    sed -i.original 's/databaseName/'$databaseName'/g; s/localhost/'$mysqlHost'/g; s/Uname/'$sqlU'/g; s/Pwd/'$sqlP'/g'  $databaseFile
    rm -f $databaseFile.original
  fi



else ## if [ ! -d $dirVhost ]
  echo "## Updating $vhost with $1 ##"
fi

## DB ##

# Si le fichier de DB existe dans le depot git, on importe,
if [ -a $dirMysql/$databaseName.sql.txt ]
  then
    echo " - Creating/Updating database $databaseName"
    mysql -u $sqlU -p$sqlP -h $mysqlHost -D $databaseName < $dirMysql/$databaseName.sql.txt
fi

## On nettoie le dossier application

if [ -d $dirVhost/application/files/cache ]
  then
  rm -r -f $dirVhost/application/files/cache
fi

if [ -a $dirVhost/application/config/app.php ]
  then
  echo " - Enjoy installing at http://localhost:8888/$vhost with the database : $databaseName"
else
  echo " - Finished. You may need to update the C5 instalation : http://localhost:8888/$vhost/index.php/ccm/system/upgrade"
fi
