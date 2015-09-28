#!/bin/bash

root="/Applications/MAMP/htdocs/_mysql";

### Server Setup ###
MUSER="root";
MPASS="root";
MHOST="localhost";
MPORT="8889";

#* MySQL binaries *#
MYSQL=`which mysql`;
MYSQLDUMP=`which mysqldump`;
GZIP=`which gzip`;

# get all database listing
if [ ! $1 == "" ]
  then
    DBS="$@"
    completeDbName=true
  else
    DBS="$(mysql -u $MUSER -p$MPASS -h $MHOST -P $MPORT -Bse 'show databases')"
    completeDbName=false
fi
# start to dump database one by one
for db in $DBS
do
  if [ "$completeDbName" = true ]; then
    db="myconcretelab_$db"
  fi
  if [[ $db =~ .*myconcretelab_.* ]]
    then
    if [ -d /Applications/MAMP/db/mysql/$db ]
      then
      file="$root/$db.sql.txt";
      if [ -a $file ]
        then
        echo " - Deleting $db.sql.txt from git repository"
        rm -f $file
      fi
      echo " - Dumping $db and save to $file";
      mysqldump --add-drop-database --opt --lock-all-tables -u $MUSER -p$MPASS -h $MHOST -P $MPORT $db > $file
    else
      echo " - It seems that this DB doesn't exist anymore"
    fi
  else
    echo "ERROR - Not a MCL DB"
  fi

done
