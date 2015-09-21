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
DBS="$(mysql -u $MUSER -p$MPASS -h $MHOST -P $MPORT -Bse 'show databases')"
# start to dump database one by one
for db in $DBS
do
  if [[ $db =~ .*myconcretelab_.* ]]
    then
    file="$root/$db.sql.txt";
    if [ -a $file ]
      then
      echo " - Deleting $db.sql.txt from git repository"
      rm -f $file
    fi
    echo " - Dumping $db and save to $file";
    $MYSQLDUMP --add-drop-database --opt --lock-all-tables -u $MUSER -p$MPASS -h $MHOST -P $MPORT $db > $file
  fi
done
