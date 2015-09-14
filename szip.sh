#!/bin/bash

if [ "$1" == "" ]
  then
  echo "ERROR : Nothing to zip"
  exit
fi

find $1 -path '*/.*' -prune -o -type f -print | zip $1.zip -@
