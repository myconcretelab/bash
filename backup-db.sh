#!/bin/bash

NOW=`date +"%Y-%m"`;
root="/Applications/MAMP/htdocs/_mysql";

### Server Setup ###
#* MySQL login user name *#
MUSER="root";

#* MySQL login PASSWORD name *#
MPASS="root";

#* MySQL login HOST name *#
MHOST="localhost";
MPORT="8889";

# DO NOT BACKUP these databases
IGNOREDB="
information_schema
mysql
test
"

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
